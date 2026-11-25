---
id: 20260714172019
title: Rust Data Structures and Algorithms (DSA)
date: 2026-07-14 17:20
tags: [rust, dsa, programming]
links: [16a-rust.md]
---

# Rust Data Structures and Algorithms (DSA)

Implementing Data Structures and Algorithms in Rust presents unique challenges due to **ownership, lifetimes, and memory safety rules**. This guide covers idiomatic Rust implementations, complexity analysis, and best practices.

---

## 1. Introduction: DSA & The Rust Memory Model

Implementing classic data structures (like linked lists or graphs) in Rust requires shifting your mindset from garbage-collected or raw-pointer languages (C/C++, Java, Go) to Rust's **single-owner** paradigm.

### Key Smart Pointers for DSA
- **`Box<T>`**: Heap allocation with unique ownership. Perfect for recursive types (e.g., Binary Tree nodes, Singly Linked Lists).
- **`Rc<T>` / `Arc<T>`**: Reference Counted wrappers for multiple read-only owners. Use `Rc` for single-threaded and `Arc` for multi-threaded structures.
- **`RefCell<T>`**: Interior Mutability. Enables mutating data even when held behind an immutable reference (`&T`). Used in conjunction with `Rc` to implement shared mutable data structures (like doubly linked lists or graphs) with runtime borrow-checking.

> [!WARNING]
> While `Rc<RefCell<T>>` allows you to write cyclic graph or list structures, it introduces runtime overhead and the risk of **memory leaks** via reference cycles. When possible, prefer array-based index trees/graphs or safe parent-child wrappers.

---

## 2. Linear Data Structures

| Structure | Access | Search | Insertion | Deletion | Space Complexity |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Singly Linked List** | $O(N)$ | $O(N)$ | $O(1)$ | $O(1)$ | $O(N)$ |
| **Stack (Vec)** | $O(1)$ | $O(N)$ | $O(1)$ amortized | $O(1)$ | $O(N)$ |
| **Queue (VecDeque)** | $O(1)$ | $O(N)$ | $O(1)$ | $O(1)$ | $O(N)$ |

### 2.1 Singly Linked List (Safe Option-Box)
Using safe Rust, a singly linked list is best represented as nested `Option<Box<ListNode<T>>>`.

```rust
pub struct ListNode<T> {
    pub value: T,
    pub next: Option<Box<ListNode<T>>>,
}

pub struct SinglyLinkedList<T> {
    head: Option<Box<ListNode<T>>>,
}

impl<T> SinglyLinkedList<T> {
    pub fn new() -> Self {
        SinglyLinkedList { head: None }
    }

    // O(1) prepend
    pub fn push_front(&mut self, value: T) {
        let new_node = Box::new(ListNode {
            value,
            next: self.head.take(), // Takes the current head, leaving None in its place
        });
        self.head = Some(new_node);
    }

    // O(1) remove head
    pub fn pop_front(&mut self) -> Option<T> {
        self.head.take().map(|node| {
            self.head = node.next;
            node.value
        })
    }

    // O(1) peek
    pub fn peek(&self) -> Option<&T> {
        self.head.as_ref().map(|node| &node.value)
    }

    pub fn is_empty(&self) -> bool {
        self.head.is_none()
    }
}
```

### 2.2 Doubly Linked List (Shared Mutable Concept)
Doubly linked lists require nodes to point to both successors and predecessors. In safe Rust, this requires `Rc<RefCell<Node<T>>>`.

```rust
use std::rc::Rc;
use std::cell::RefCell;

pub struct DoubleNode<T> {
    pub value: T,
    pub next: Option<Rc<RefCell<DoubleNode<T>>>>,
    pub prev: Option<Rc<RefCell<DoubleNode<T>>>>, // Raw weak pointer or Rc to prevent cycles
}
```
> [!TIP]
> In production code, **always** prefer `std::collections::LinkedList` (implemented with raw pointers under `unsafe` for high performance) instead of trying to write your own `Rc<RefCell<T>>` doubly linked list.

### 2.3 Stack (LIFO)
Rust's standard `Vec` acts as an extremely efficient stack.

```rust
pub struct Stack<T> {
    data: Vec<T>,
}

impl<T> Stack<T> {
    pub fn new() -> Self {
        Stack { data: Vec::new() }
    }

    pub fn push(&mut self, value: T) {
        self.data.push(value); // O(1) amortized
    }

    pub fn pop(&mut self) -> Option<T> {
        self.data.pop() // O(1)
    }

    pub fn peek(&self) -> Option<&T> {
        self.data.last()
    }

    pub fn is_empty(&self) -> bool {
        self.data.is_empty()
    }
}
```

### 2.4 Queue (FIFO)
Rust's standard `VecDeque` (double-ended queue) is a ring buffer that provides efficient $O(1)$ inserts and removals at both ends.

```rust
use std::collections::VecDeque;

pub struct Queue<T> {
    data: VecDeque<T>,
}

impl<T> Queue<T> {
    pub fn new() -> Self {
        Queue { data: VecDeque::new() }
    }

    pub fn enqueue(&mut self, value: T) {
        self.data.push_back(value); // O(1)
    }

    pub fn dequeue(&mut self) -> Option<T> {
        self.data.pop_front() // O(1)
    }

    pub fn peek(&self) -> Option<&T> {
        self.data.front()
    }

    pub fn is_empty(&self) -> bool {
        self.data.is_empty()
    }
}
```

---

## 3. Non-Linear Data Structures

### 3.1 Binary Search Tree (BST)
A Binary Search Tree using `Option<Box<TreeNode<T>>>`.

```rust
pub struct TreeNode<T> {
    pub value: T,
    pub left: Option<Box<TreeNode<T>>>,
    pub right: Option<Box<TreeNode<T>>>,
}

pub struct BinarySearchTree<T> {
    root: Option<Box<TreeNode<T>>>,
}

impl<T: Ord> BinarySearchTree<T> {
    pub fn new() -> Self {
        BinarySearchTree { root: None }
    }

    pub fn insert(&mut self, value: T) {
        Self::insert_rec(&mut self.root, value);
    }

    fn insert_rec(node: &mut Option<Box<TreeNode<T>>>, value: T) {
        match node {
            None => {
                *node = Some(Box::new(TreeNode {
                    value,
                    left: None,
                    right: None,
                }));
            }
            Some(ref mut n) => {
                if value < n.value {
                    Self::insert_rec(&mut n.left, value);
                } else if value > n.value {
                    Self::insert_rec(&mut n.right, value);
                }
            }
        }
    }

    pub fn contains(&self, value: &T) -> bool {
        Self::contains_rec(&self.root, value)
    }

    fn contains_rec(node: &Option<Box<TreeNode<T>>>, value: &T) -> bool {
        match node {
            None => false,
            Some(ref n) => {
                if value == &n.value {
                    true
                } else if value < &n.value {
                    Self::contains_rec(&n.left, value)
                } else {
                    Self::contains_rec(&n.right, value)
                }
            }
        }
    }

    // Inorder Traversal (sorted order)
    pub fn inorder(&self) -> Vec<&T> {
        let mut result = Vec::new();
        Self::inorder_rec(&self.root, &mut result);
        result
    }

    fn inorder_rec<'a>(node: &'a Option<Box<TreeNode<T>>>, result: &mut Vec<&'a T>) {
        if let Some(ref n) = node {
            Self::inorder_rec(&n.left, result);
            result.push(&n.value);
            Self::inorder_rec(&n.right, result);
        }
    }
}
```

### 3.2 Trie (Prefix Tree)
Tries are highly performant for autocomplete and dictionary searches. We represent the child nodes using a `HashMap`.

```rust
use std::collections::HashMap;

#[derive(Default)]
pub struct TrieNode {
    children: HashMap<char, TrieNode>,
    is_word_end: bool,
}

pub struct Trie {
    root: TrieNode,
}

impl Trie {
    pub fn new() -> Self {
        Trie {
            root: TrieNode::default(),
        }
    }

    // Insert a word into the trie
    pub fn insert(&mut self, word: &str) {
        let mut current = &mut self.root;
        for c in word.chars() {
            current = current.children.entry(c).or_default();
        }
        current.is_word_end = true;
    }

    // Search for a word in the trie
    pub fn search(&self, word: &str) -> bool {
        let mut current = &self.root;
        for c in word.chars() {
            if let Some(next) = current.children.get(&c) {
                current = next;
            } else {
                return false;
            }
        }
        current.is_word_end
    }

    // Check if any word starts with the prefix
    pub fn starts_with(&self, prefix: &str) -> bool {
        let mut current = &self.root;
        for c in prefix.chars() {
            if let Some(next) = current.children.get(&c) {
                current = next;
            } else {
                return false;
            }
        }
        true
    }
}
```

### 3.3 Binary Heap (Min-Heap)
Binary heaps are represented using contiguous arrays (`Vec`), making child/parent navigation index-based.
- **Parent Index**: `(i - 1) / 2`
- **Left Child Index**: `2 * i + 1`
- **Right Child Index**: `2 * i + 2`

```rust
pub struct MinHeap<T> {
    data: Vec<T>,
}

impl<T: Ord> MinHeap<T> {
    pub fn new() -> Self {
        MinHeap { data: Vec::new() }
    }

    pub fn push(&mut self, value: T) {
        self.data.push(value);
        self.sift_up(self.data.len() - 1);
    }

    pub fn pop(&mut self) -> Option<T> {
        if self.data.is_empty() {
            return None;
        }
        let last_idx = self.data.len() - 1;
        self.data.swap(0, last_idx);
        let result = self.data.pop();
        if !self.data.is_empty() {
            self.sift_down(0);
        }
        result
    }

    pub fn peek(&self) -> Option<&T> {
        self.data.first()
    }

    fn sift_up(&mut self, mut idx: usize) {
        while idx > 0 {
            let parent = (idx - 1) / 2;
            if self.data[idx] < self.data[parent] {
                self.data.swap(idx, parent);
                idx = parent;
            } else {
                break;
            }
        }
    }

    fn sift_down(&mut self, mut idx: usize) {
        let len = self.data.len();
        loop {
            let left = 2 * idx + 1;
            let right = 2 * idx + 2;
            let mut smallest = idx;

            if left < len && self.data[left] < self.data[smallest] {
                smallest = left;
            }
            if right < len && self.data[right] < self.data[smallest] {
                smallest = right;
            }

            if smallest != idx {
                self.data.swap(idx, smallest);
                idx = smallest;
            } else {
                break;
            }
        }
    }
}
```
> [!NOTE]
> Rust's standard library provides `std::collections::BinaryHeap`, which is a **Max-Heap** by default. To turn it into a Min-Heap, wrap your items in `std::cmp::Reverse`.

### 3.4 Graph (Adjacency List)
We use a `HashMap` mapping nodes to a list of neighbors.

```rust
use std::hash::Hash;
use std::collections::{HashMap, VecDeque};

pub struct Graph<T> {
    adj_list: HashMap<T, Vec<T>>,
}

impl<T: Hash + Eq + Clone> Graph<T> {
    pub fn new() -> Self {
        Graph {
            adj_list: HashMap::new(),
        }
    }

    pub fn add_edge(&mut self, from: T, to: T) {
        self.adj_list.entry(from.clone()).or_default().push(to.clone());
    }

    // Breadth-First Search (BFS)
    pub fn bfs(&self, start: T) -> Vec<T> {
        let mut visited = HashMap::new();
        let mut queue = VecDeque::new();
        let mut result = Vec::new();

        visited.insert(start.clone(), true);
        queue.push_back(start);

        while let Some(node) = queue.pop_front() {
            result.push(node.clone());
            if let Some(neighbors) = self.adj_list.get(&node) {
                for neighbor in neighbors {
                    if !visited.contains_key(neighbor) {
                        visited.insert(neighbor.clone(), true);
                        queue.push_back(neighbor.clone());
                    }
                }
            }
        }
        result
    }

    // Depth-First Search (DFS)
    pub fn dfs(&self, start: T) -> Vec<T> {
        let mut visited = HashMap::new();
        let mut result = Vec::new();
        self.dfs_rec(&start, &mut visited, &mut result);
        result
    }

    fn dfs_rec(&self, node: &T, visited: &mut HashMap<T, bool>, result: &mut Vec<T>) {
        visited.insert(node.clone(), true);
        result.push(node.clone());
        if let Some(neighbors) = self.adj_list.get(node) {
            for neighbor in neighbors {
                if !visited.contains_key(neighbor) {
                    self.dfs_rec(neighbor, visited, result);
                }
            }
        }
    }
}
```

---

## 4. Sorting & Searching

### Complexity Comparison

| Algorithm | Best Time | Average Time | Worst Time | Space Complexity | Stable? |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Bubble Sort** | $O(N)$ | $O(N^2)$ | $O(N^2)$ | $O(1)$ | Yes |
| **Selection Sort** | $O(N^2)$ | $O(N^2)$ | $O(N^2)$ | $O(1)$ | No |
| **Insertion Sort** | $O(N)$ | $O(N^2)$ | $O(N^2)$ | $O(1)$ | Yes |
| **Merge Sort** | $O(N \log N)$ | $O(N \log N)$ | $O(N \log N)$ | $O(N)$ | Yes |
| **Quick Sort** | $O(N \log N)$ | $O(N \log N)$ | $O(N^2)$ | $O(\log N)$ | No |
| **Binary Search** | $O(1)$ | $O(\log N)$ | $O(\log N)$ | $O(1)$ | N/A |

### 4.1 Sorting Algorithms

```rust
// Bubble Sort (with early exit optimization)
pub fn bubble_sort<T: Ord>(arr: &mut [T]) {
    let len = arr.len();
    if len <= 1 {
        return;
    }
    for i in 0..len {
        let mut swapped = false;
        for j in 0..len - i - 1 {
            if arr[j] > arr[j + 1] {
                arr.swap(j, j + 1);
                swapped = true;
            }
        }
        if !swapped {
            break;
        }
    }
}

// Selection Sort
pub fn selection_sort<T: Ord>(arr: &mut [T]) {
    let len = arr.len();
    for i in 0..len {
        let mut min_idx = i;
        for j in i + 1..len {
            if arr[j] < arr[min_idx] {
                min_idx = j;
            }
        }
        if min_idx != i {
            arr.swap(i, min_idx);
        }
    }
}

// Insertion Sort
pub fn insertion_sort<T: Ord>(arr: &mut [T]) {
    let len = arr.len();
    for i in 1..len {
        let mut j = i;
        while j > 0 && arr[j] < arr[j - 1] {
            arr.swap(j, j - 1);
            j -= 1;
        }
    }
}

// Merge Sort
pub fn merge_sort<T: Ord + Clone>(arr: &mut [T]) {
    let len = arr.len();
    if len <= 1 {
        return;
    }
    let mid = len / 2;
    merge_sort(&mut arr[..mid]);
    merge_sort(&mut arr[mid..]);
    
    let mut temp = Vec::with_capacity(len);
    let mut i = 0;
    let mut j = mid;

    while i < mid && j < len {
        if arr[i] <= arr[j] {
            temp.push(arr[i].clone());
            i += 1;
        } else {
            temp.push(arr[j].clone());
            j += 1;
        }
    }
    while i < mid {
        temp.push(arr[i].clone());
        i += 1;
    }
    while j < len {
        temp.push(arr[j].clone());
        j += 1;
    }
    arr.clone_from_slice(&temp);
}

// Quick Sort (Lomuto Partitioning)
pub fn quick_sort<T: Ord>(arr: &mut [T]) {
    if arr.len() <= 1 {
        return;
    }
    let pivot_idx = partition(arr);
    quick_sort(&mut arr[..pivot_idx]);
    quick_sort(&mut arr[pivot_idx + 1..]);
}

fn partition<T: Ord>(arr: &mut [T]) -> usize {
    let len = arr.len();
    let pivot_idx = len - 1;
    let mut i = 0;
    for j in 0..pivot_idx {
        if arr[j] <= arr[pivot_idx] {
            arr.swap(i, j);
            i += 1;
        }
    }
    arr.swap(i, pivot_idx);
    i
}
```

### 4.2 Binary Search

```rust
use std::cmp::Ordering;

pub fn binary_search<T: Ord>(arr: &[T], target: &T) -> Option<usize> {
    if arr.is_empty() {
        return None;
    }
    let mut low = 0;
    let mut high = arr.len() - 1;

    while low <= high {
        let mid = low + (high - low) / 2;
        match arr[mid].cmp(target) {
            Ordering::Equal => return Some(mid),
            Ordering::Less => {
                low = mid + 1;
            }
            Ordering::Greater => {
                if mid == 0 {
                    break; // Prevents overflow underflow on usize
                }
                high = mid - 1;
            }
        }
    }
    None
}
```

---

## 5. Advanced Algorithms

### 5.1 Dijkstra's Shortest Path Algorithm
Finds the shortest path in a weighted graph using a Min-Heap.

```rust
use std::cmp::Ordering;
use std::collections::BinaryHeap;

#[derive(Copy, Clone, Eq, PartialEq)]
struct Edge {
    node: usize,
    cost: usize,
}

// We implement Ord for Edge to create a Min-Heap instead of the default Max-Heap
impl Ord for Edge {
    fn cmp(&self, other: &Self) -> Ordering {
        other.cost.cmp(&self.cost) // Reverse comparisons for Min-Heap
            .then(self.node.cmp(&other.node))
    }
}

impl PartialOrd for Edge {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}

// dijkstra takes an adjacency list where adj_list[node] = Vec<(neighbor_node, weight)>
pub fn dijkstra(adj_list: &Vec<Vec<(usize, usize)>>, start: usize, end: usize) -> Option<usize> {
    let mut dist: Vec<usize> = (0..adj_list.len()).map(|_| usize::MAX).collect();
    let mut heap = BinaryHeap::new();

    dist[start] = 0;
    heap.push(Edge { node: start, cost: 0 });

    while let Some(Edge { node, cost }) = heap.pop() {
        if node == end {
            return Some(cost);
        }
        if cost > dist[node] {
            continue; // We found a shorter path to this node already
        }
        for &(neighbor, weight) in &adj_list[node] {
            let next_cost = cost + weight;
            if next_cost < dist[neighbor] {
                dist[neighbor] = next_cost;
                heap.push(Edge { node: neighbor, cost: next_cost });
            }
        }
    }
    None
}
```

### 5.2 Dynamic Programming (DP)

#### 0/1 Knapsack (Bottom-Up Space-Optimized)
Time Complexity: $O(N \cdot W)$, Space Complexity: $O(W)$ where $N$ is item count and $W$ is capacity.

```rust
pub fn knapsack(weights: &[usize], values: &[usize], capacity: usize) -> usize {
    let n = weights.len();
    if n == 0 || capacity == 0 {
        return 0;
    }
    let mut dp = vec![0; capacity + 1];

    for i in 0..n {
        // Iterate backwards to prevent using the same item multiple times
        for w in (weights[i]..=capacity).rev() {
            dp[w] = dp[w].max(dp[w - weights[i]] + values[i]);
        }
    }
    dp[capacity]
}
```

#### Memoized Fibonacci (Top-Down with HashMap)
Time Complexity: $O(N)$, Space Complexity: $O(N)$.

```rust
use std::collections::HashMap;

pub fn fibonacci(n: u32) -> u64 {
    let mut memo = HashMap::new();
    fn fib(n: u32, memo: &mut HashMap<u32, u64>) -> u64 {
        if n <= 1 {
            return n as u64;
        }
        if let Some(&val) = memo.get(&n) {
            return val;
        }
        let val = fib(n - 1, memo) + fib(n - 2, memo);
        memo.insert(n, val);
        val
    }
    fib(n, &mut memo)
}
```

### 5.3 Sliding Window
**Max Sum Subarray of size K**: $O(N)$ Time Complexity, $O(1)$ Space Complexity.

```rust
pub fn max_sum_subarray(arr: &[i32], k: usize) -> Option<i32> {
    if arr.len() < k || k == 0 {
        return None;
    }
    let mut window_sum: i32 = arr[..k].iter().sum();
    let mut max_sum = window_sum;

    for i in k..arr.len() {
        window_sum += arr[i] - arr[i - k]; // Slide window right
        max_sum = max_sum.max(window_sum);
    }
    Some(max_sum)
}
```

### 5.4 Two Pointers
**Two Sum on Sorted Array**: $O(N)$ Time Complexity, $O(1)$ Space Complexity.

```rust
use std::cmp::Ordering;

pub fn two_sum_sorted(arr: &[i32], target: i32) -> Option<(usize, usize)> {
    if arr.len() < 2 {
        return None;
    }
    let mut left = 0;
    let mut right = arr.len() - 1;

    while left < right {
        let sum = arr[left] + arr[right];
        match sum.cmp(&target) {
            Ordering::Equal => return Some((left, right)),
            Ordering::Less => left += 1, // Increase sum
            Ordering::Greater => right -= 1, // Decrease sum
        }
    }
    None
}
```
