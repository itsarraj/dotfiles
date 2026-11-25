# Rust Notes

## Rust Book and Notes Resources

Complete notes from "The Rust Programming Language" book with code references and brief explanations.

---

## 1. Getting Started

Rust uses `cargo` as its build system and package manager.

```rust
// hello world
fn main() {
    println!("Hello, world!");
}
```

Cargo commands:
- `cargo new project_name` -- create a new project
- `cargo build` -- compile the project
- `cargo run` -- compile and run
- `cargo check` -- check code without producing a binary (faster)
- `cargo build --release` -- compile with optimizations

---

## 2. Common Programming Concepts

### 2.1 Variables and Mutability

Variables are immutable by default. Use `mut` to make them mutable.

```rust
let x = 5;         // immutable
let mut y = 10;    // mutable
y = 15;            // ok

const MAX_POINTS: u32 = 100_000; // constants, always immutable, type required
```

Shadowing lets you reuse a variable name with a new type or value:

```rust
let x = 5;
let x = x + 1;       // shadows previous x
let x = "hello";     // can change type via shadowing
```

### 2.2 Data Types

Scalar types: integers, floats, booleans, characters.

```rust
let a: i32 = -42;       // signed 32-bit
let b: u64 = 100;       // unsigned 64-bit
let c: f64 = 3.14;      // 64-bit float (default)
let d: bool = true;
let e: char = 'z';      // 4 bytes, Unicode scalar value
```

Compound types: tuples and arrays.

```rust
let tup: (i32, f64, u8) = (500, 6.4, 1);
let (x, y, z) = tup;              // destructuring
let first = tup.0;                // index access

let arr: [i32; 5] = [1, 2, 3, 4, 5];
let zeroes = [0; 5];              // [0, 0, 0, 0, 0]
let first = arr[0];
```

### 2.3 Functions

```rust
fn add(x: i32, y: i32) -> i32 {
    x + y   // no semicolon = expression (returned)
}
```

Statements do something but don't return a value. Expressions evaluate to a value. A block `{}` is an expression -- its last expression (without semicolon) is the return value.

### 2.4 Control Flow

```rust
// if is an expression
let number = if condition { 5 } else { 6 };

// loop -- infinite, break returns a value
let result = loop {
    counter += 1;
    if counter == 10 {
        break counter * 2;
    }
};

// labeled loops
'outer: loop {
    loop {
        break 'outer;
    }
}

// while
while number != 0 {
    number -= 1;
}

// for -- preferred for iteration
for element in arr.iter() {
    println!("{element}");
}
for number in (1..4).rev() {
    println!("{number}");
}
```

---

## 3. Understanding Ownership

The core feature that makes Rust unique. No garbage collector needed.

### 3.1 Ownership Rules

1. Each value has an owner
2. Only one owner at a time
3. When the owner goes out of scope, the value is dropped

```rust
{
    let s = String::from("hello");  // s is valid from here
    // use s
}   // s goes out of scope, memory freed (drop called)
```

### 3.2 Move vs Clone

Stack-only data (integers, bools, chars, tuples of Copy types) is copied. Heap data is moved.

```rust
let s1 = String::from("hello");
let s2 = s1;           // s1 is MOVED into s2, s1 is now invalid
// println!("{s1}");    // ERROR: value used after move

let s3 = s2.clone();   // deep copy -- both s2 and s3 valid
```

### 3.3 References and Borrowing

References let you use a value without taking ownership.

```rust
fn calculate_length(s: &String) -> usize {   // immutable borrow
    s.len()
}

fn change(s: &mut String) {                   // mutable borrow
    s.push_str(", world");
}
```

Rules:
- You can have either ONE mutable reference OR any number of immutable references at a time
- References must always be valid (no dangling references)

### 3.4 The Slice Type

A reference to a contiguous sequence of elements.

```rust
let s = String::from("hello world");
let hello = &s[0..5];    // &str slice
let world = &s[6..11];

// string literals are slices
let s: &str = "hello world";

// array slices
let a = [1, 2, 3, 4, 5];
let slice = &a[1..3];    // &[i32], contains [2, 3]
```

---

## 4. Using Structs to Structure Data

### 4.1 Defining and Instantiating

```rust
struct User {
    username: String,
    email: String,
    active: bool,
    sign_in_count: u64,
}

let user1 = User {
    email: String::from("someone@example.com"),
    username: String::from("someuser"),
    active: true,
    sign_in_count: 1,
};

// field init shorthand (when variable name matches field name)
fn build_user(email: String, username: String) -> User {
    User {
        email,          // shorthand
        username,       // shorthand
        active: true,
        sign_in_count: 1,
    }
}

// struct update syntax
let user2 = User {
    email: String::from("another@example.com"),
    ..user1   // remaining fields from user1 (moves String fields)
};
```

### 4.2 Tuple Structs and Unit Structs

```rust
struct Color(i32, i32, i32);       // tuple struct
struct Point(i32, i32, i32);
let black = Color(0, 0, 0);

struct AlwaysEqual;                 // unit-like struct, useful for traits
```

### 4.3 Method Syntax

```rust
struct Rectangle {
    width: u32,
    height: u32,
}

impl Rectangle {
    // method -- &self as first parameter
    fn area(&self) -> u32 {
        self.width * self.height
    }

    fn can_hold(&self, other: &Rectangle) -> bool {
        self.width > other.width && self.height > other.height
    }

    // associated function (no self) -- like a static method
    fn square(size: u32) -> Self {
        Self { width: size, height: size }
    }
}

let sq = Rectangle::square(10);    // called with ::
let area = sq.area();              // called with .
```

---

## 5. Enums and Pattern Matching

### 5.1 Defining Enums

Enums can hold data directly in each variant.

```rust
enum IpAddr {
    V4(u8, u8, u8, u8),
    V6(String),
}

let home = IpAddr::V4(127, 0, 0, 1);
let loopback = IpAddr::V6(String::from("::1"));

enum Message {
    Quit,                        // no data
    Move { x: i32, y: i32 },    // named fields (like a struct)
    Write(String),               // single String
    ChangeColor(i32, i32, i32),  // three i32s
}

impl Message {
    fn call(&self) {
        // methods on enums work just like structs
    }
}
```

### 5.2 Option Enum

Rust has no null. `Option<T>` encodes the concept of a value being present or absent.

```rust
enum Option<T> {
    None,
    Some(T),
}

let some_number: Option<i32> = Some(5);
let no_number: Option<i32> = None;

// must handle the None case before using the value
```

### 5.3 The match Expression

Exhaustive pattern matching -- every possible case must be handled.

```rust
enum Coin {
    Penny,
    Nickel,
    Dime,
    Quarter(UsState),
}

fn value_in_cents(coin: Coin) -> u8 {
    match coin {
        Coin::Penny => 1,
        Coin::Nickel => 5,
        Coin::Dime => 10,
        Coin::Quarter(state) => {
            println!("State quarter from {state:?}");
            25
        }
    }
}

// matching Option<T>
fn plus_one(x: Option<i32>) -> Option<i32> {
    match x {
        None => None,
        Some(i) => Some(i + 1),
    }
}

// catch-all with _ or a variable
match dice_roll {
    3 => add_fancy_hat(),
    7 => remove_fancy_hat(),
    _ => (),                  // do nothing for all other values
}
```

### 5.4 if let

Concise syntax when you only care about one pattern.

```rust
// instead of match with one arm + catch-all
if let Some(value) = some_option {
    println!("{value}");
} else {
    println!("no value");
}
```

---

## 6. Managing Growing Projects

### 6.1 Packages, Crates, and Modules

- Package: a Cargo.toml + one or more crates
- Crate: a tree of modules producing a library or binary
- Module: organize code and control privacy

```rust
// src/lib.rs or src/main.rs is the crate root

mod front_of_house {
    pub mod hosting {           // pub makes module accessible
        pub fn add_to_waitlist() {}
    }
}

// paths
use crate::front_of_house::hosting;  // absolute path
hosting::add_to_waitlist();

use self::front_of_house::hosting;   // relative path
```

### 6.2 Module File Structure

```
src/
  main.rs
  lib.rs
  front_of_house/
    mod.rs          // or front_of_house.rs in parent
    hosting.rs
```

### 6.3 Use and Re-exporting

```rust
use std::collections::HashMap;
use std::io::{self, Write};       // nested paths
use std::collections::*;          // glob (usually for tests)

pub use crate::front_of_house::hosting;  // re-export
```

---

## 7. Common Collections

### 7.1 Vectors

```rust
let v: Vec<i32> = Vec::new();
let v = vec![1, 2, 3];            // vec! macro

let mut v = Vec::new();
v.push(5);
v.push(6);

// accessing elements
let third: &i32 = &v[2];          // panics if out of bounds
let third: Option<&i32> = v.get(2); // returns None if out of bounds

// iterating
for i in &v {
    println!("{i}");
}
for i in &mut v {
    *i += 50;                      // dereference to modify
}

// store multiple types via enum
enum SpreadsheetCell {
    Int(i32),
    Float(f64),
    Text(String),
}
let row = vec![
    SpreadsheetCell::Int(3),
    SpreadsheetCell::Text(String::from("blue")),
    SpreadsheetCell::Float(10.12),
];
```

### 7.2 Strings

Strings in Rust are UTF-8 encoded. `String` is a growable, heap-allocated type. `&str` is a string slice.

```rust
let mut s = String::new();
let s = "initial contents".to_string();
let s = String::from("initial contents");

// appending
let mut s = String::from("foo");
s.push_str("bar");               // append a string slice
s.push('!');                     // append a single char

// concatenation
let s1 = String::from("Hello, ");
let s2 = String::from("world!");
let s3 = s1 + &s2;              // s1 is moved, s2 is borrowed

// format! macro -- doesn't take ownership
let s = format!("{s1}-{s2}-{s3}");

// Rust doesn't allow indexing strings by integer
// iterate over chars or bytes explicitly
for c in "hello".chars() {
    println!("{c}");
}
```

### 7.3 Hash Maps

```rust
use std::collections::HashMap;

let mut scores = HashMap::new();
scores.insert(String::from("Blue"), 10);
scores.insert(String::from("Yellow"), 50);

// accessing
let team = String::from("Blue");
let score = scores.get(&team).copied().unwrap_or(0);

// iterating
for (key, value) in &scores {
    println!("{key}: {value}");
}

// insert only if key doesn't exist
scores.entry(String::from("Blue")).or_insert(50);

// update based on old value
let text = "hello world wonderful world";
let mut map = HashMap::new();
for word in text.split_whitespace() {
    let count = map.entry(word).or_insert(0);
    *count += 1;
}
```

---

## 8. Error Handling

### 8.1 Unrecoverable Errors with panic!

```rust
panic!("crash and burn");

// set RUST_BACKTRACE=1 to see the full backtrace
```

### 8.2 Recoverable Errors with Result

```rust
enum Result<T, E> {
    Ok(T),
    Err(E),
}

use std::fs::File;
use std::io::{self, Read};

let f = File::open("hello.txt");
let f = match f {
    Ok(file) => file,
    Err(error) => match error.kind() {
        ErrorKind::NotFound => match File::create("hello.txt") {
            Ok(fc) => fc,
            Err(e) => panic!("Problem creating file: {e:?}"),
        },
        other_error => panic!("Problem opening file: {other_error:?}"),
    },
};

// shortcuts
let f = File::open("hello.txt").unwrap();          // panic on Err
let f = File::open("hello.txt").expect("Failed");  // panic with message
```

### 8.3 Propagating Errors with ?

The `?` operator returns the error early if the Result is Err.

```rust
fn read_username_from_file() -> Result<String, io::Error> {
    let mut username = String::new();
    File::open("hello.txt")?.read_to_string(&mut username)?;
    Ok(username)
}

// even shorter
fn read_username_from_file() -> Result<String, io::Error> {
    fs::read_to_string("hello.txt")
}
```

`?` can also be used with `Option<T>` -- returns `None` early.

---

## 9. Generic Types, Traits, and Lifetimes

### 9.1 Generics

```rust
// generic function
fn largest<T: std::cmp::PartialOrd>(list: &[T]) -> &T {
    let mut largest = &list[0];
    for item in list {
        if item > largest {
            largest = item;
        }
    }
    largest
}

// generic struct
struct Point<T> {
    x: T,
    y: T,
}

// generic with different types
struct Point<T, U> {
    x: T,
    y: U,
}

// generic impl
impl<T> Point<T> {
    fn x(&self) -> &T {
        &self.x
    }
}

// impl only for specific type
impl Point<f32> {
    fn distance_from_origin(&self) -> f32 {
        (self.x.powi(2) + self.y.powi(2)).sqrt()
    }
}
```

No runtime cost -- Rust monomorphizes generics at compile time.

### 9.2 Traits (Defining Shared Behavior)

Similar to interfaces in other languages.

```rust
pub trait Summary {
    fn summarize_author(&self) -> String;

    // default implementation
    fn summarize(&self) -> String {
        format!("(Read more from {}...)", self.summarize_author())
    }
}

pub struct NewsArticle {
    pub headline: String,
    pub author: String,
    pub content: String,
}

impl Summary for NewsArticle {
    fn summarize_author(&self) -> String {
        self.author.clone()
    }
}

// traits as parameters
fn notify(item: &impl Summary) {
    println!("Breaking news! {}", item.summarize());
}

// trait bound syntax (equivalent)
fn notify<T: Summary>(item: &T) { ... }

// multiple trait bounds
fn notify(item: &(impl Summary + Display)) { ... }
fn notify<T: Summary + Display>(item: &T) { ... }

// where clause for cleaner signatures
fn some_function<T, U>(t: &T, u: &U) -> i32
where
    T: Display + Clone,
    U: Clone + Debug,
{ ... }

// returning types that implement traits
fn returns_summarizable() -> impl Summary { ... }
```

### 9.3 Lifetimes

Lifetimes ensure references are valid for as long as they need to be.

```rust
// lifetime annotation syntax
fn longest<'a>(x: &'a str, y: &'a str) -> &'a str {
    if x.len() > y.len() { x } else { y }
}

// lifetime in structs -- the struct can't outlive the reference it holds
struct ImportantExcerpt<'a> {
    part: &'a str,
}

// static lifetime -- lives for entire program duration
let s: &'static str = "I live forever";
```

Lifetime elision rules (compiler infers lifetimes):
1. Each input reference gets its own lifetime parameter
2. If there's exactly one input lifetime, it's assigned to all outputs
3. If one of the inputs is `&self` or `&mut self`, self's lifetime is assigned to all outputs

---

## 10. Writing Automated Tests

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_works() {
        let result = 2 + 2;
        assert_eq!(result, 4);
    }

    #[test]
    fn larger_can_hold_smaller() {
        let larger = Rectangle { width: 8, height: 7 };
        let smaller = Rectangle { width: 5, height: 1 };
        assert!(larger.can_hold(&smaller));
    }

    #[test]
    #[should_panic(expected = "less than or equal to 100")]
    fn greater_than_100() {
        Guess::new(200);
    }

    #[test]
    fn it_works_result() -> Result<(), String> {
        if 2 + 2 == 4 {
            Ok(())
        } else {
            Err(String::from("two plus two does not equal four"))
        }
    }
}
```

Useful assertions: `assert!`, `assert_eq!`, `assert_ne!`

Run tests:
- `cargo test` -- run all tests
- `cargo test test_name` -- run specific test
- `cargo test -- --show-output` -- show println output
- `cargo test -- --ignored` -- run only ignored tests

Integration tests go in `tests/` directory at the crate root (each file is a separate crate).

---

## 11. Closures and Iterators

### 11.1 Closures

Anonymous functions that capture their environment.

```rust
let expensive_closure = |num: u32| -> u32 {
    println!("calculating slowly...");
    num
};

// type inference -- no annotations needed if usage is clear
let add_one = |x| x + 1;

// closures capture values three ways:
// FnOnce -- takes ownership (consumes captured values)
// FnMut  -- borrows mutably
// Fn     -- borrows immutably

let list = vec![1, 2, 3];
let only_borrows = || println!("{list:?}");      // Fn

let mut list = vec![1, 2, 3];
let mut borrows_mutably = || list.push(7);       // FnMut

// move keyword forces ownership transfer
let list = vec![1, 2, 3];
let owns = move || println!("{list:?}");         // FnOnce
// list is no longer valid here
```

### 11.2 Iterators

```rust
let v1 = vec![1, 2, 3];
let v1_iter = v1.iter();        // immutable references
// v1.iter_mut()                // mutable references
// v1.into_iter()               // takes ownership

for val in v1_iter {
    println!("{val}");
}

// Iterator trait requires implementing next()
pub trait Iterator {
    type Item;
    fn next(&mut self) -> Option<Self::Item>;
}

// consuming adaptors -- call next and consume the iterator
let total: i32 = v1.iter().sum();

// iterator adaptors -- produce new iterators (lazy)
let v2: Vec<i32> = v1.iter().map(|x| x + 1).collect();

let v2: Vec<i32> = v1.iter()
    .filter(|x| **x > 1)
    .map(|x| x * 2)
    .collect();

// chaining for complex transformations
let shoes_in_size: Vec<&Shoe> = shoes.iter()
    .filter(|s| s.size == shoe_size)
    .collect();
```

---

## 12. Smart Pointers

### 12.1 Box<T> -- Heap Allocation

```rust
let b = Box::new(5);      // stores i32 on the heap
println!("b = {b}");

// used for: recursive types, large data, trait objects
enum List {
    Cons(i32, Box<List>),
    Nil,
}
```

### 12.2 Rc<T> -- Reference Counting

Multiple ownership for single-threaded scenarios.

```rust
use std::rc::Rc;

let a = Rc::new(Cons(5, Rc::new(Cons(10, Rc::new(Nil)))));
let b = Cons(3, Rc::clone(&a));    // increment reference count
let c = Cons(4, Rc::clone(&a));
println!("count = {}", Rc::strong_count(&a));  // 3
```

### 12.3 RefCell<T> -- Interior Mutability

Enforces borrowing rules at runtime instead of compile time.

```rust
use std::cell::RefCell;

let data = RefCell::new(5);
*data.borrow_mut() += 1;          // mutable borrow at runtime

// common pattern: Rc<RefCell<T>> for multiple owners with mutability
let value = Rc::new(RefCell::new(5));
*value.borrow_mut() += 10;
```

### 12.4 Deref and Drop Traits

```rust
// Deref allows * operator and automatic deref coercion
impl<T> Deref for MyBox<T> {
    type Target = T;
    fn deref(&self) -> &T {
        &self.0
    }
}

// Drop runs cleanup code when value goes out of scope
impl Drop for CustomSmartPointer {
    fn drop(&mut self) {
        println!("Dropping CustomSmartPointer with data `{}`", self.data);
    }
}

// force early drop
drop(pointer);   // std::mem::drop
```

Memory leak: `Rc<T>` reference cycles can leak memory. Use `Weak<T>` to break cycles.

---

## 13. Fearless Concurrency

### 13.1 Threads

```rust
use std::thread;

let handle = thread::spawn(|| {
    for i in 1..10 {
        println!("spawned thread: {i}");
    }
});

handle.join().unwrap();   // wait for thread to finish

// move closure to transfer ownership to thread
let v = vec![1, 2, 3];
let handle = thread::spawn(move || {
    println!("vector: {v:?}");
});
```

### 13.2 Message Passing (Channels)

```rust
use std::sync::mpsc;   // multiple producer, single consumer

let (tx, rx) = mpsc::channel();

thread::spawn(move || {
    let val = String::from("hi");
    tx.send(val).unwrap();      // val is moved
});

let received = rx.recv().unwrap();   // blocks until message

// multiple producers
let tx1 = tx.clone();

// iterate over received messages
for received in rx {
    println!("Got: {received}");
}
```

### 13.3 Shared State (Mutex)

```rust
use std::sync::{Arc, Mutex};

let counter = Arc::new(Mutex::new(0));   // Arc for multi-thread Rc
let mut handles = vec![];

for _ in 0..10 {
    let counter = Arc::clone(&counter);
    let handle = thread::spawn(move || {
        let mut num = counter.lock().unwrap();
        *num += 1;
    });
    handles.push(handle);
}

for handle in handles {
    handle.join().unwrap();
}

println!("Result: {}", *counter.lock().unwrap());
```

Key types:
- `Mutex<T>` -- mutual exclusion, one thread at a time
- `Arc<T>` -- atomic reference counting, thread-safe Rc
- `Send` trait -- type can be transferred between threads
- `Sync` trait -- type can be referenced from multiple threads

---

## 14. Object-Oriented Features

### 14.1 Trait Objects for Dynamic Dispatch

```rust
pub trait Draw {
    fn draw(&self);
}

pub struct Screen {
    pub components: Vec<Box<dyn Draw>>,   // trait object
}

impl Screen {
    pub fn run(&self) {
        for component in self.components.iter() {
            component.draw();
        }
    }
}

pub struct Button {
    pub width: u32,
    pub height: u32,
    pub label: String,
}

impl Draw for Button {
    fn draw(&self) {
        // draw a button
    }
}
```

`dyn Trait` uses dynamic dispatch (vtable at runtime). `impl Trait` uses static dispatch (monomorphized at compile time).

### 14.2 State Pattern

```rust
pub struct Post {
    state: Option<Box<dyn State>>,
    content: String,
}

trait State {
    fn request_review(self: Box<Self>) -> Box<dyn State>;
    fn approve(self: Box<Self>) -> Box<dyn State>;
    fn content<'a>(&self, _post: &'a Post) -> &'a str { "" }
}

struct Draft {}
impl State for Draft {
    fn request_review(self: Box<Self>) -> Box<dyn State> {
        Box::new(PendingReview {})
    }
    fn approve(self: Box<Self>) -> Box<dyn State> { self }
}
```

---

## 15. Patterns and Matching

### 15.1 All Places Patterns Can Be Used

```rust
// match arms
match x {
    1 => println!("one"),
    2 | 3 => println!("two or three"),
    4..=9 => println!("four through nine"),
    _ => println!("anything"),
}

// if let, while let
if let Some(x) = some_option { ... }
while let Some(top) = stack.pop() { ... }

// for loops
for (index, value) in v.iter().enumerate() { ... }

// let statements
let (x, y, z) = (1, 2, 3);

// function parameters
fn print_coordinates(&(x, y): &(i32, i32)) { ... }
```

### 15.2 Pattern Syntax

```rust
// matching literals
match x { 1 => ..., _ => ... }

// matching named variables (shadows outer)
match x { Some(y) => println!("{y}"), None => ... }

// destructuring structs
let Point { x, y } = point;
match p {
    Point { x, y: 0 } => println!("on x axis at {x}"),
    Point { x: 0, y } => println!("on y axis at {y}"),
    Point { x, y } => println!("({x}, {y})"),
}

// destructuring enums
match msg {
    Message::Quit => ...,
    Message::Move { x, y } => ...,
    Message::Write(text) => ...,
    Message::ChangeColor(r, g, b) => ...,
}

// ignoring values
let (_, second, _) = (1, 2, 3);
let Point { x, .. } = point;      // .. ignores remaining fields

// match guards
match num {
    Some(x) if x % 2 == 0 => println!("even: {x}"),
    Some(x) => println!("odd: {x}"),
    None => (),
}

// @ bindings -- bind a value while testing it
match msg {
    Message::Hello { id: id_variable @ 3..=7 } => {
        println!("id in range: {id_variable}")
    }
    Message::Hello { id: 10..=12 } => println!("in another range"),
    Message::Hello { id } => println!("other id: {id}"),
}
```

---

## 16. Advanced Features

### 16.1 Unsafe Rust

Unsafe unlocks five superpowers:
1. Dereference a raw pointer
2. Call an unsafe function
3. Access/modify a mutable static variable
4. Implement an unsafe trait
5. Access fields of unions

```rust
let mut num = 5;
let r1 = &num as *const i32;      // raw pointer (immutable)
let r2 = &mut num as *mut i32;    // raw pointer (mutable)

unsafe {
    println!("r1: {}", *r1);
    println!("r2: {}", *r2);
}

unsafe fn dangerous() { ... }
unsafe { dangerous(); }

// safe abstraction over unsafe code
fn split_at_mut(values: &mut [i32], mid: usize) -> (&mut [i32], &mut [i32]) {
    let len = values.len();
    let ptr = values.as_mut_ptr();
    assert!(mid <= len);
    unsafe {
        (
            slice::from_raw_parts_mut(ptr, mid),
            slice::from_raw_parts_mut(ptr.add(mid), len - mid),
        )
    }
}

// extern for FFI
extern "C" {
    fn abs(input: i32) -> i32;
}
unsafe { println!("{}", abs(-3)); }
```

### 16.2 Advanced Traits

```rust
// associated types
pub trait Iterator {
    type Item;
    fn next(&mut self) -> Option<Self::Item>;
}

// default generic type parameters and operator overloading
use std::ops::Add;
impl Add for Point {
    type Output = Point;
    fn add(self, other: Point) -> Point {
        Point { x: self.x + other.x, y: self.y + other.y }
    }
}

// fully qualified syntax for disambiguation
<Type as Trait>::function(receiver_if_method, args);

// supertraits
trait OutlinePrint: fmt::Display { ... }

// newtype pattern to implement external traits on external types
struct Wrapper(Vec<String>);
impl fmt::Display for Wrapper { ... }
```

### 16.3 Advanced Types

```rust
// type aliases
type Kilometers = i32;
type Thunk = Box<dyn Fn() + Send + 'static>;

// never type (!) -- for functions that never return
fn bar() -> ! {
    panic!("This call never returns");
}

// dynamically sized types (DST)
// str, [T], dyn Trait are all DSTs
// always used behind a pointer: &str, &[T], Box<dyn Trait>
// Sized trait bound is implicit; use ?Sized to opt out
fn generic<T: ?Sized>(t: &T) { ... }
```

### 16.4 Advanced Functions and Closures

```rust
// function pointers
fn add_one(x: i32) -> i32 { x + 1 }
fn do_twice(f: fn(i32) -> i32, arg: i32) -> i32 {
    f(arg) + f(arg)
}

// returning closures
fn returns_closure() -> Box<dyn Fn(i32) -> i32> {
    Box::new(|x| x + 1)
}
```

### 16.5 Macros

```rust
// declarative macros (macro_rules!)
macro_rules! vec {
    ( $( $x:expr ),* ) => {
        {
            let mut temp_vec = Vec::new();
            $( temp_vec.push($x); )*
            temp_vec
        }
    };
}

// procedural macros: derive, attribute-like, function-like
#[derive(HelloMacro)]          // derive macro
#[route(GET, "/")]             // attribute-like macro
let sql = sql!(SELECT * FROM posts WHERE id=1);  // function-like macro
```

---

## 17. Async/Await (Edition 2021+)

```rust
async fn fetch_data() -> Result<String, Error> {
    let response = reqwest::get("https://example.com").await?;
    let body = response.text().await?;
    Ok(body)
}

// async functions return a Future
// .await suspends execution until the Future resolves

// requires an async runtime (tokio, async-std)
#[tokio::main]
async fn main() {
    let result = fetch_data().await.unwrap();
    println!("{result}");
}

// run multiple futures concurrently
let (res1, res2) = tokio::join!(
    fetch_data(),
    fetch_other_data(),
);
```

---

## 18. Common Patterns and Idioms

### Builder Pattern

```rust
struct RequestBuilder {
    url: String,
    method: String,
    headers: Vec<(String, String)>,
}

impl RequestBuilder {
    fn new(url: &str) -> Self {
        Self {
            url: url.to_string(),
            method: "GET".to_string(),
            headers: vec![],
        }
    }
    fn method(mut self, method: &str) -> Self {
        self.method = method.to_string();
        self
    }
    fn header(mut self, key: &str, value: &str) -> Self {
        self.headers.push((key.to_string(), value.to_string()));
        self
    }
    fn build(self) -> Request { ... }
}
```

### From/Into Conversions

```rust
impl From<i32> for MyType {
    fn from(val: i32) -> Self {
        MyType { value: val }
    }
}

let my_val = MyType::from(5);
let my_val: MyType = 5.into();    // Into is auto-implemented
```

### The ? Operator Chain

```rust
fn process() -> Result<Output, Box<dyn Error>> {
    let data = fs::read_to_string("input.txt")?;
    let parsed: Config = serde_json::from_str(&data)?;
    let result = compute(&parsed)?;
    Ok(result)
}
```

---

## Quick Reference -- Common Traits

| Trait | Purpose |
|-------|---------|
| Display | user-facing string formatting ({}) |
| Debug | programmer-facing formatting ({:?}) |
| Clone | explicit deep copy |
| Copy | implicit bitwise copy (stack only) |
| PartialEq / Eq | equality comparison (==) |
| PartialOrd / Ord | ordering comparison (<, >) |
| Hash | produce hash for HashMap keys |
| Default | default value for a type |
| From / Into | type conversions |
| Iterator | for loops and iterator chains |
| Drop | cleanup on scope exit |
| Deref | smart pointer dereferencing |
| Send | safe to transfer across threads |
| Sync | safe to share references across threads |

---

## 19. Advanced Unsafe Rust for Systems Programming

Beyond the five superpowers in §16.1 -- the invariants you must uphold by hand when writing a container runtime (raw syscalls, memory-mapped structures, FFI).

### 19.1 Raw Pointers and Provenance

```rust
let mut x = 5;
let p: *mut i32 = &mut x;

unsafe {
    *p = 10;
    let q = p.add(1);        // pointer arithmetic -- UB if it leaves the allocation
}

// pointers into a syscall-returned buffer
let ptr = buf.as_mut_ptr();
unsafe {
    std::ptr::write(ptr, value);       // no old value dropped
    let v = std::ptr::read(ptr);       // bitwise copy out, doesn't invalidate ptr
    std::ptr::copy_nonoverlapping(src, dst, len);  // memcpy
}
```

Rule of thumb: a raw pointer is only valid as long as the allocation it points into is alive and you haven't violated aliasing (no `&mut` and any other live reference to the same bytes). This matters constantly when working with `mmap`'d cgroup files or shared memory segments.

### 19.2 MaybeUninit

Needed whenever you get memory from a syscall (e.g. `read()`, `recvmsg()`) before it's initialized -- creating a `T` "empty" via zeroed memory is UB for most types.

```rust
use std::mem::MaybeUninit;

let mut buf: MaybeUninit<[u8; 4096]> = MaybeUninit::uninit();
let ptr = buf.as_mut_ptr() as *mut u8;
let n = unsafe { libc::read(fd, ptr as *mut _, 4096) };
// only the first `n` bytes are actually initialized -- treat the rest as garbage
let initialized: &[u8] = unsafe { std::slice::from_raw_parts(ptr, n as usize) };
```

### 19.3 Unsafe Traits and Manual Send/Sync

```rust
// a raw fd wrapper isn't Send/Sync by default once it holds a raw pointer
struct RawFdHandle(*mut libc::c_void);

// SAFETY: the pointer is only read, never mutated concurrently, and the
// kernel guarantees the fd stays valid for the process lifetime.
unsafe impl Send for RawFdHandle {}
unsafe impl Sync for RawFdHandle {}
```

Every `unsafe impl` or `unsafe fn` should carry a `// SAFETY:` comment stating *why* the invariant holds -- this is the idiomatic convention (`clippy::missing_safety_doc` enforces it on public unsafe fns).

### 19.4 transmute and repr

```rust
#[repr(C)]                     // guarantees field layout matches C -- required for FFI/syscall structs
struct Winsize {
    ws_row: u16,
    ws_col: u16,
    ws_xpixel: u16,
    ws_ypixel: u16,
}

// transmute reinterprets bits -- last resort, easy to get wrong
let bytes: [u8; 4] = unsafe { std::mem::transmute(4u32.to_ne_bytes()) };
// prefer safe alternatives when they exist:
let n = u32::from_ne_bytes(bytes);
```

### 19.5 Testing Unsafe Code with Miri

```bash
rustup +nightly component add miri
cargo +nightly miri test    # catches UB: out-of-bounds, use-after-free, data races, uninit reads
```

Run Miri on any crate that touches raw pointers, FFI, or `unsafe impl Send/Sync` -- it is the single highest-value tool for this kind of code and catches bugs `cargo test` alone never will.

---

## 20. FFI and libc Interop

### 20.1 Calling C from Rust

```rust
use std::ffi::{CStr, CString};
use std::os::raw::c_char;

extern "C" {
    fn strlen(s: *const c_char) -> usize;
    fn getpid() -> i32;
}

let s = CString::new("hello").unwrap();   // owned, nul-terminated
let len = unsafe { strlen(s.as_ptr()) };

// converting a C string back to Rust
let c_str: &CStr = unsafe { CStr::from_ptr(raw_ptr) };
let rust_str: &str = c_str.to_str().unwrap();
```

### 20.2 The libc Crate

In practice you rarely write raw `extern "C"` blocks yourself -- the `libc` crate provides pre-declared bindings for the whole POSIX/Linux surface.

```rust
use libc::{c_int, pid_t, fork, execvp, waitpid};

let pid: pid_t = unsafe { fork() };
match pid {
    -1 => panic!("fork failed: {}", std::io::Error::last_os_error()),
    0 => { /* child */ }
    _ => { /* parent, pid = child's pid */ }
}
```

### 20.3 errno and Error Handling

C functions signal failure via return value + `errno`, not `Result`. Always check immediately -- another libc call in between can clobber it.

```rust
let ret = unsafe { libc::mount(src.as_ptr(), target.as_ptr(), fstype.as_ptr(), flags, data) };
if ret != 0 {
    return Err(std::io::Error::last_os_error());   // reads errno, wraps as io::Error
}
```

### 20.4 bindgen for Larger Surfaces

For a big C API (e.g. a vendor's cgroup or seccomp headers) generate bindings instead of hand-writing them:

```toml
# build-dependencies in Cargo.toml
bindgen = "0.69"
```

```rust
// build.rs
fn main() {
    let bindings = bindgen::Builder::default()
        .header("wrapper.h")
        .generate()
        .expect("bindgen failed");
    bindings.write_to_file("src/bindings.rs").unwrap();
}
```

---

## 21. Linux Syscalls from Rust (namespaces, cgroups, containers)

This is the direct Rust translation of TLPI/Container Security's `clone`, `unshare`, `setns` material -- the mechanics [youki](https://github.com/containers/youki) and `runc` are built on. Prefer the `nix` crate over raw `libc` where it has a safe wrapper.

```toml
[dependencies]
nix = { version = "0.28", features = ["sched", "mount", "process", "signal"] }
```

### 21.1 Namespaces via clone/unshare

```rust
use nix::sched::{clone, unshare, CloneFlags};
use nix::sys::signal::Signal;

// unshare -- move the CALLING process into new namespaces
unshare(CloneFlags::CLONE_NEWNS      // mount namespace
      | CloneFlags::CLONE_NEWUTS     // hostname
      | CloneFlags::CLONE_NEWPID     // pid namespace (affects children, not self)
      | CloneFlags::CLONE_NEWNET     // network namespace
).expect("unshare failed");

// clone -- create a CHILD directly into new namespaces (what a runtime actually uses,
// since CLONE_NEWPID only takes effect for processes created after the call)
let mut stack = [0u8; 1024 * 1024];
let child_pid = unsafe {
    clone(
        Box::new(child_fn),
        &mut stack,
        CloneFlags::CLONE_NEWPID | CloneFlags::CLONE_NEWNS | CloneFlags::CLONE_NEWUTS,
        Some(Signal::SIGCHLD as i32),
    )
}.expect("clone failed");
```

### 21.2 setns -- Joining an Existing Namespace

```rust
use nix::sched::{setns, CloneFlags};
use std::fs::File;
use std::os::unix::io::AsRawFd;

let ns_file = File::open("/proc/1234/ns/net").unwrap();
setns(ns_file.as_raw_fd(), CloneFlags::CLONE_NEWNET).unwrap();
// used by `docker exec`-style tooling to run a new process inside a running container
```

### 21.3 Mount Namespace, chroot, and pivot_root

```rust
use nix::mount::{mount, MsFlags};
use nix::unistd::{chdir, pivot_root};

// make mount propagation private first, or changes leak to the host
mount::<str, str, str, str>(None, "/", None, MsFlags::MS_REC | MsFlags::MS_PRIVATE, None).unwrap();

mount(Some(rootfs), rootfs, None::<&str>, MsFlags::MS_BIND | MsFlags::MS_REC, None::<&str>).unwrap();
chdir(rootfs).unwrap();
pivot_root(".", "old_root").unwrap();   // preferred over chroot() -- properly changes the mount tree root
chdir("/").unwrap();
```

### 21.4 cgroups v2 -- Plain File I/O

No special crate needed -- cgroups v2 is a filesystem interface (`cgroupfs`).

```rust
use std::fs;

let cg = "/sys/fs/cgroup/mycontainer";
fs::create_dir_all(cg).unwrap();
fs::write(format!("{cg}/cgroup.procs"), pid.to_string()).unwrap();     // move pid in
fs::write(format!("{cg}/memory.max"), "512M").unwrap();                // set memory limit
fs::write(format!("{cg}/cpu.max"), "100000 100000").unwrap();          // 1 CPU worth
```

(The `cgroups-rs` crate wraps this in a typed API once the raw mechanics feel familiar.)

### 21.5 Capabilities and Seccomp

```rust
use caps::{Capability, CapSet};
caps::drop(None, CapSet::Bounding, Capability::CAP_SYS_ADMIN).unwrap();   // drop before exec

// seccomp-rs / libseccomp-rs for syscall filtering -- restrict what the
// containerized process can call, mirroring runc's default seccomp profile
```

### 21.6 Putting It Together -- Minimal Container Skeleton

```rust
fn create_container(rootfs: &str, cmd: &[&str]) -> nix::Result<Pid> {
    let mut stack = vec![0u8; 1024 * 1024];
    let flags = CloneFlags::CLONE_NEWPID
        | CloneFlags::CLONE_NEWNS
        | CloneFlags::CLONE_NEWUTS
        | CloneFlags::CLONE_NEWNET
        | CloneFlags::CLONE_NEWIPC;

    unsafe {
        clone(
            Box::new(|| {
                pivot_root_into(rootfs);
                setup_cgroup_limits();
                drop_capabilities();
                let prog = CString::new(cmd[0]).unwrap();
                let args: Vec<CString> = cmd.iter().map(|s| CString::new(*s).unwrap()).collect();
                execvp(&prog, &args).unwrap();   // replaces this process image entirely
                0
            }),
            &mut stack,
            flags,
            Some(Signal::SIGCHLD as i32),
        )
    }
}
```

This mirrors the exact lifecycle `youki`/`runc` implement for the OCI `create`/`start` operations -- read their `libcontainer`/`libcontainer.rs` source right after working through this section.

---

## 22. Memory Ordering, Atomics, and Lock-Free Programming

Rust Atomics and Locks material -- needed once a container runtime has multiple worker threads managing container state concurrently.

### 22.1 Atomic Types

```rust
use std::sync::atomic::{AtomicUsize, AtomicBool, Ordering};

let counter = AtomicUsize::new(0);
counter.fetch_add(1, Ordering::Relaxed);
let running = AtomicBool::new(true);
running.store(false, Ordering::Release);
let is_running = running.load(Ordering::Acquire);

// compare-and-swap loop -- the building block of lock-free structures
loop {
    let current = counter.load(Ordering::Relaxed);
    let new = current + 1;
    if counter.compare_exchange(current, new, Ordering::AcqRel, Ordering::Relaxed).is_ok() {
        break;
    }
}
```

### 22.2 Memory Ordering Explained

| Ordering | Meaning |
|----------|---------|
| `Relaxed` | Atomicity only, no ordering guarantee with other memory ops. Use for simple counters. |
| `Acquire` | No later read/write can be reordered before this load. Pairs with `Release`. |
| `Release` | No earlier read/write can be reordered after this store. Pairs with `Acquire`. |
| `AcqRel` | Both -- typical for read-modify-write ops like `compare_exchange`. |
| `SeqCst` | Acquire+Release plus a single global total order across all `SeqCst` ops. Safest, slowest. |

The classic pattern: one thread `store`s data then a flag with `Release`; another thread `load`s the flag with `Acquire` then reads the data -- the `Acquire`/`Release` pair guarantees the data write is visible once the flag is observed true.

### 22.3 A Minimal Spinlock

```rust
use std::sync::atomic::{AtomicBool, Ordering};
use std::cell::UnsafeCell;

struct SpinLock<T> {
    locked: AtomicBool,
    data: UnsafeCell<T>,
}

unsafe impl<T: Send> Sync for SpinLock<T> {}

impl<T> SpinLock<T> {
    fn lock(&self) -> &mut T {
        while self.locked.compare_exchange_weak(
            false, true, Ordering::Acquire, Ordering::Relaxed
        ).is_err() {
            std::hint::spin_loop();
        }
        unsafe { &mut *self.data.get() }
    }
    fn unlock(&self) {
        self.locked.store(false, Ordering::Release);
    }
}
```

### 22.4 False Sharing

Atomics on adjacent fields sharing a cache line cause invisible contention between unrelated counters. Pad hot fields to a cache line (`#[repr(align(64))]`) when profiling shows this.

---

## 23. Async Runtime Internals

Understanding what `tokio` actually does under the hood -- relevant if the runtime's control plane (API server, event watching) is async while the container-launching path stays synchronous/`unsafe`-heavy (§21).

### 23.1 The Future Trait

```rust
use std::pin::Pin;
use std::task::{Context, Poll};

trait Future {
    type Output;
    fn poll(self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Self::Output>;
}

// async fn desugars to a state machine implementing this trait.
// .await == "poll me; if Pending, return Pending and register a Waker; if Ready, continue"
```

### 23.2 Why Pin

Async state machines can be self-referential (a local variable borrowed across an `.await` point becomes a field pointing at another field). `Pin<P>` guarantees the pointee won't move in memory once polled, which makes such self-references sound. You rarely construct `Pin` by hand -- `async fn`/`async {}` handle it -- but library code implementing `Future` manually needs it.

### 23.3 Executor + Reactor Model

- **Executor** (tokio's scheduler) -- polls tasks (`Future`s) when woken, distributes across a thread pool.
- **Reactor** -- registers interest in OS events (epoll on Linux) for I/O resources; when the OS signals readiness, it calls the `Waker` for the task waiting on that fd.
- A `Waker` is the handle a `Future` stashes so the reactor/timer can tell the executor "poll this task again."

```rust
#[tokio::main(flavor = "multi_thread", worker_threads = 4)]
async fn main() {
    // spawns run on the executor's thread pool; tasks are cooperatively scheduled,
    // not preemptively -- a task that never yields (no .await, no blocking-safe call)
    // starves the whole worker thread
    let handle = tokio::spawn(watch_container_events());
    handle.await.unwrap();
}

// CPU-bound or blocking-syscall work must NOT run directly on an async task --
// it blocks the executor thread. Offload it:
tokio::task::spawn_blocking(|| do_blocking_syscall());
```

### 23.4 When to Use Async vs. Threads Here

Async suits high-fan-out I/O-bound work (watching many container log streams, serving an API). The actual `clone`/`execve`/namespace setup in §21 is inherently synchronous, single-shot, and `unsafe`-sensitive -- run it on `spawn_blocking` or a dedicated OS thread rather than forcing it into the async model.

---

## 24. Designing a Container Runtime in Rust (OCI Patterns)

Ties §21-23 into the actual shape of a `youki`/`runc`-style project.

### 24.1 OCI Runtime Lifecycle

```rust
enum ContainerState { Creating, Created, Running, Stopped }

trait Runtime {
    fn create(&mut self, id: &str, bundle: &Path) -> Result<()>;  // sets up namespaces/cgroups, execve's into a paused state
    fn start(&mut self, id: &str) -> Result<()>;                  // signals the paused process to exec the real entrypoint
    fn kill(&mut self, id: &str, sig: Signal) -> Result<()>;
    fn delete(&mut self, id: &str) -> Result<()>;                 // tears down cgroup, removes state dir
    fn state(&self, id: &str) -> Result<ContainerState>;
}
```

`create` and `start` are split because OCI requires the container process to exist (so its pid is known and hooks/cgroup setup can happen) before the user's actual command starts running -- this is why §21.6's clone'd child blocks on a pipe/socket read before its `execvp`, rather than exec'ing immediately.

### 24.2 Error Handling Shape for Daemon Code

```rust
// library errors: thiserror, so callers can match on variants
#[derive(thiserror::Error, Debug)]
enum RuntimeError {
    #[error("namespace setup failed: {0}")]
    Namespace(#[from] nix::Error),
    #[error("cgroup write failed: {0}")]
    Cgroup(#[from] std::io::Error),
}

// binary/CLI-level errors: anyhow, for ergonomic `?` + context without
// defining a variant for every leaf error
fn run() -> anyhow::Result<()> {
    let bundle = load_bundle(path).context("failed to load OCI bundle")?;
    Ok(())
}
```

### 24.3 Key Crates for This Project

| Crate | Purpose |
|-------|---------|
| `nix` | Safe(r) wrappers over syscalls: clone, mount, setns, signals |
| `libc` | Raw FFI bindings when `nix` doesn't cover something |
| `oci-spec` | Typed (de)serialization of `config.json` / OCI runtime spec |
| `caps` | Linux capabilities get/set/drop |
| `cgroups-rs` | Typed cgroups v1/v2 management |
| `thiserror` / `anyhow` | Error types (library vs. binary, respectively) |
| `tokio` | Async runtime for the control-plane/API side |
| `tracing` | Structured logging/spans for a long-running daemon |

Read `youki`'s `crates/libcontainer` next to this section -- it is a working, idiomatic answer to nearly everything in §21 and §24.

---

## 25. Staged Learning Path Toward the Container Runtime Goal

Maps this file's sections and the [systems-engineering.md](../../systems-engineering.md) book list into an order that keeps theory and hands-on Rust close together.

**Phase 0 -- Rust fluency** (§1-18 above)
Finish the Book-level material if any part still feels shaky, especially ownership/borrowing (§3), traits/generics (§9), and smart pointers (§12) -- everything downstream leans on these being automatic.

**Phase 1 -- Syscalls, in Rust, immediately**
Read TLPI chapters on processes/fork/exec/namespaces *alongside* §21 above -- for each syscall TLPI covers in C, write the Rust (`nix`) equivalent yourself before moving to the next chapter. Don't read TLPI cover to cover first and translate later.

**Phase 2 -- Unsafe, FFI, and the Rust-specific books**
*Rust for Rustaceans* + *Programming Rust*, read against §19-20 above. Do this before touching namespaces/cgroups seriously -- you'll be writing plenty of `unsafe` and want the invariants internalized, not looked up mid-debug.

**Phase 3 -- Build a minimal container by hand**
Using §21.6 as a skeleton: fork/clone into new namespaces, pivot_root into a rootfs, apply a cgroup memory limit, execve a shell. Read *Container Security* (Liz Rice) and *Linux Kernel Programming* chapters on cgroups in parallel -- they explain the *why* behind what you just made work.

**Phase 4 -- Study youki/runc source in parallel**
Once your toy container works, read youki's `libcontainer` crate end to end. Every difference between your toy version and theirs is a concrete question to chase down (why do they order operations differently, what edge case are they handling).

**Phase 5 -- Concurrency and the control plane**
*Rust Atomics and Locks* against §22, then build the async API/event-watching layer (§23) on top of the synchronous container-launch core from Phase 3-4. This is also where *C++ Concurrency in Action* pays off by contrast -- seeing the same problems solved without the borrow checker.

**Phase 6 -- Performance and production concerns**
*Systems Performance* + *BPF Performance Tools* once something real exists to profile -- flame graph your own runtime's container-start latency, not a toy benchmark.

Keep §24's crate table as the running reference for what to reach for at each phase instead of hand-rolling syscall wrappers from scratch.

---

## 26. Process Supervision and Signal Handling (Being PID 1)

The container's init process inherits PID 1's kernel responsibilities inside its own PID namespace: default signal disposition changes (unhandled signals are ignored, not fatal, unless you install a handler) and orphaned grandchildren get reparented to it. A runtime that ignores this leaks zombies until the container is killed.

### 26.1 Reaping Zombies

```rust
use nix::sys::wait::{waitpid, WaitPidFlag, WaitStatus};
use nix::unistd::Pid;

fn reap_zombies() {
    loop {
        match waitpid(Pid::from_raw(-1), Some(WaitPidFlag::WNOHANG)) {
            Ok(WaitStatus::StillAlive) => break,       // nothing to reap right now
            Ok(WaitStatus::Exited(pid, code)) => {
                tracing::info!(?pid, code, "reaped child");
            }
            Ok(_) => continue,
            Err(nix::errno::Errno::ECHILD) => break,   // no children left
            Err(e) => { tracing::error!(?e, "waitpid failed"); break; }
        }
    }
}
```

### 26.2 signalfd -- Signals Inside an Event Loop

Traditional signal handlers can't safely call most functions (async-signal-safety). `signalfd` turns signal delivery into a readable fd, so it composes with `epoll`/`tokio` instead of a handwritten handler.

```rust
use nix::sys::signalfd::{SignalFd, SfdFlags};
use nix::sys::signal::{SigSet, Signal};

let mut mask = SigSet::empty();
mask.add(Signal::SIGCHLD);
mask.add(Signal::SIGTERM);
mask.thread_block().unwrap();   // block normal delivery -- only readable via the fd now

let mut sfd = SignalFd::with_flags(&mask, SfdFlags::SFD_NONBLOCK).unwrap();
if let Ok(siginfo) = sfd.read_signal() {
    // siginfo.ssi_signo tells you which signal fired; SIGCHLD -> reap_zombies()
}
```

### 26.3 Signal Forwarding

A runtime's supervising process must forward signals it receives (e.g. `docker stop` sending SIGTERM to the runtime) into the container's namespace, targeting the right process group so the container's own init gets a chance to shut down cleanly before a SIGKILL.

```rust
use nix::sys::signal::{kill, Signal};
use nix::unistd::Pid;

fn forward(container_init_pid: Pid, sig: Signal) -> nix::Result<()> {
    kill(Pid::from_raw(-container_init_pid.as_raw()), sig)   // negative pid == signal the whole process group
}
```

---

## 27. Container Networking from Rust

Ties Computer Networking / TCP-IP Illustrated theory to the actual veth+bridge+netns mechanics behind container networking (CNI, `docker0`, Kubernetes pod networking).

### 27.1 Netlink -- the Kernel's Networking Config API

`ip link`, `ip addr`, `ip route` are thin wrappers over netlink sockets. `rtnetlink` gives you the same access programmatically.

```toml
rtnetlink = "0.14"
tokio = { version = "1", features = ["rt", "macros"] }
```

```rust
use rtnetlink::new_connection;

#[tokio::main]
async fn main() -> Result<(), rtnetlink::Error> {
    let (connection, handle, _) = new_connection().unwrap();
    tokio::spawn(connection);

    // create a veth pair -- one end stays on the host, one moves into the container netns
    handle.link().add().veth("veth-host".into(), "veth-ctr".into()).execute().await?;

    let mut links = handle.link().get().match_name("veth-ctr".into()).execute();
    if let Some(link) = links.try_next().await? {
        handle.link().set(link.header.index).setns_by_pid(container_pid).execute().await?;
    }
    Ok(())
}
```

### 27.2 Moving an Interface Into a Namespace and Configuring It

Once `veth-ctr` is inside the container's netns (via `setns`, §21.2, from the container process itself or by pid as above), assign an address and bring it up:

```rust
handle.address().add(veth_ctr_index, "172.17.0.2".parse().unwrap(), 24).execute().await?;
handle.link().set(veth_ctr_index).up().execute().await?;

// default route via the bridge/gateway
handle.route().add().v4()
    .destination_prefix("0.0.0.0".parse().unwrap(), 0)
    .gateway("172.17.0.1".parse().unwrap())
    .execute().await?;
```

### 27.3 Bridge + NAT (the docker0-equivalent)

```rust
handle.link().add().bridge("cbr0".into()).execute().await?;
// attach the host end of each veth pair to the bridge
handle.link().set(veth_host_index).master(bridge_index).execute().await?;
```

Outbound NAT (so containers can reach the internet through the host's IP) still typically goes through `iptables`/`nftables` rules -- either shell out to `nft`, or use the `rustables` crate for a typed nftables API. This is the one piece most runtimes still delegate to CNI plugins rather than reimplementing.

---

## 28. eBPF from Rust (Observability and Security)

Systems Performance / BPF Performance Tools territory -- once a toy runtime exists, this is how you'd instrument or sandbox it the way `bpftrace`/`cilium` do.

### 28.1 aya -- Writing eBPF in Rust

```toml
aya = "0.13"
aya-log = "0.2"
```

```rust
// eBPF side (compiled separately to a BPF target, loaded into the kernel)
#[kprobe]
pub fn trace_execve(ctx: ProbeContext) -> u32 {
    match try_trace_execve(ctx) {
        Ok(ret) => ret,
        Err(ret) => ret,
    }
}
```

```rust
// userspace side -- loads and attaches the compiled BPF program
use aya::programs::KProbe;

let mut bpf = aya::Bpf::load(include_bytes_aligned!("../target/bpfel/trace_execve"))?;
let program: &mut KProbe = bpf.program_mut("trace_execve").unwrap().try_into()?;
program.load()?;
program.attach("sys_execve", 0)?;
```

### 28.2 What This Buys a Container Runtime

- **Observability**: trace every `execve`/`openat` a container makes without modifying the workload -- exactly what `Systems Performance`'s flame-graph chapter builds toward.
- **Security**: an eBPF LSM hook or seccomp-with-BPF-filter can enforce syscall policy at a finer grain than the static seccomp profiles in §21.5.

This is an advanced, optional layer -- treat it as a Phase 6+ topic (after §25's Phase 6), not something to reach for before the core runtime works.

---

## 29. Building a Minimal Async Executor From Scratch

§23 described tokio's model at a high level. Building a tiny executor yourself is the fastest way to make `Future`/`Waker`/`Pin` stop feeling abstract.

```rust
use std::collections::VecDeque;
use std::future::Future;
use std::pin::Pin;
use std::sync::{Arc, Mutex};
use std::task::{Context, Poll, Wake, Waker};

type Task = Pin<Box<dyn Future<Output = ()> + Send>>;

struct Executor {
    queue: Mutex<VecDeque<Task>>,
}

struct TaskWaker(Arc<Executor>);   // waking just re-enqueues -- no real park/unpark here

impl Wake for TaskWaker {
    fn wake(self: Arc<Self>) {
        // in a real executor: push the task back onto the queue and unpark the worker thread
    }
}

impl Executor {
    fn spawn(&self, fut: impl Future<Output = ()> + Send + 'static) {
        self.queue.lock().unwrap().push_back(Box::pin(fut));
    }

    fn run(self: &Arc<Self>) {
        while let Some(mut task) = self.queue.lock().unwrap().pop_front() {
            let waker = Waker::from(Arc::new(TaskWaker(self.clone())));
            let mut cx = Context::from_waker(&waker);
            match task.as_mut().poll(&mut cx) {
                Poll::Ready(()) => {}                              // task finished
                Poll::Pending => self.queue.lock().unwrap().push_back(task),  // naive: just retry later
            }
        }
    }
}
```

This version busy-polls instead of truly sleeping until woken (a real executor parks the thread and only re-polls when `wake()` fires) -- but it's enough to see exactly what tokio automates: task storage, polling, and the waker contract.

---

## 30. Testing and Fuzzing Syscall-Heavy Code

Namespace/cgroup code is exactly the kind that's easy to get subtly wrong and hard to unit-test conventionally (it needs real kernel privileges).

### 30.1 Fuzzing the OCI Config Parser

The `config.json` parsing/validation path takes untrusted input (from whatever calls the runtime) and is a good fuzz target -- unlike the syscall path, it needs no privileges to fuzz.

```toml
[dependencies]
libfuzzer-sys = "0.4"
```

```rust
#![no_main]
use libfuzzer_sys::fuzz_target;

fuzz_target!(|data: &[u8]| {
    if let Ok(s) = std::str::from_utf8(data) {
        let _ = serde_json::from_str::<oci_spec::runtime::Spec>(s);   // must never panic/UB, only Ok or Err
    }
});
```

```bash
cargo install cargo-fuzz
cargo fuzz run config_fuzz
```

### 30.2 Integration Testing Namespace Code

Real `CLONE_NEWPID`/`CLONE_NEWNET` etc. need `CAP_SYS_ADMIN` (or a user namespace). Two practical approaches:

```rust
// 1. rootless testing via a user namespace first -- CLONE_NEWUSER lets an
//    unprivileged process gain the other namespace capabilities inside it
unshare(CloneFlags::CLONE_NEWUSER | CloneFlags::CLONE_NEWNS | CloneFlags::CLONE_NEWPID)?;

// 2. gate privileged tests and require --features integration, run in CI as root/in a container
#[test]
#[cfg_attr(not(feature = "integration"), ignore)]
fn pivot_root_into_minimal_rootfs() { ... }
```

Build a tiny static busybox-based rootfs fixture once (checked into the repo or fetched in CI) rather than depending on a full distro image for these tests -- keeps them fast and hermetic.

---

## 31. Static Linking and Cross-Compilation

Runtime binaries commonly need to run against arbitrary/minimal root filesystems, so avoiding a dynamic glibc dependency mismatch matters.

```bash
rustup target add x86_64-unknown-linux-musl
cargo build --release --target x86_64-unknown-linux-musl
# result: a fully static binary -- no runtime dependency on the host's libc version
```

```toml
# .cargo/config.toml
[target.x86_64-unknown-linux-musl]
linker = "musl-gcc"
```

Caveats: `getaddrinfo`/NSS-based DNS resolution behaves differently under musl (no dynamic NSS module loading), and some `libc`-crate functions are gated by target. For a container runtime binary specifically (not the containerized workloads) this rarely matters -- you're not doing DNS lookups in the runtime itself.

---

## 32. Observability: Structured Tracing for a Long-Running Daemon

```toml
tracing = "0.1"
tracing-subscriber = { version = "0.3", features = ["json", "env-filter"] }
```

```rust
use tracing::{info, instrument};

#[instrument(skip(spec), fields(container_id = %id))]
fn create(id: &str, spec: &Spec) -> anyhow::Result<()> {
    info!("setting up namespaces");
    setup_namespaces()?;
    info!("applying cgroup limits");
    apply_cgroups()?;
    Ok(())
}

fn main() {
    tracing_subscriber::fmt()
        .json()                                   // structured, machine-parseable logs
        .with_env_filter(tracing_subscriber::EnvFilter::from_default_env())
        .init();
}
```

`#[instrument]` automatically creates a span per call with entry/exit timing -- across `create`/`start`/`kill`/`delete` this gives you per-container-operation latency for free, feeding directly into the `Systems Performance` style analysis from §28.2 without hand-rolled timing code.

---

## 33. End-to-End Skeleton -- Tying §21, §24, §26-27 Together

A condensed shape of what a single `create` call ends up looking like once every prior section's piece is wired in. Not runnable as-is (elides error plumbing) -- it's the map of *where* each section's material plugs in.

```rust
fn create_container(id: &str, spec: &Spec) -> anyhow::Result<Pid> {
    // §24.1: state transition Creating -> Created starts here
    let rootfs = &spec.root.path;

    // §21.1/21.6: clone into new namespaces; child blocks on a pipe read
    // until `start` is called, per the OCI create/start split (§24.1)
    let (sync_r, sync_w) = nix::unistd::pipe()?;
    let child = unsafe {
        clone(Box::new(move || {
            nix::unistd::read(sync_r, &mut [0u8; 1]).unwrap();   // wait for `start`

            // §21.3: mount namespace setup
            pivot_root_into(rootfs).unwrap();

            // §21.5: drop capabilities, apply seccomp profile before exec
            drop_capabilities(&spec.linux.capabilities).unwrap();

            // §27.2: the container's own netns config (if not handled by a CNI plugin)
            configure_loopback_and_iface().unwrap();

            let prog = CString::new(spec.process.args[0].clone()).unwrap();
            execvp(&prog, &to_cstrings(&spec.process.args)).unwrap();
            unreachable!("execvp replaces this process or returns Err above");
        }),
        &mut stack, namespace_flags(&spec), Some(Signal::SIGCHLD as i32),
    )}?;

    // §21.4: cgroup limits applied from the PARENT, targeting the child's pid
    apply_cgroup_limits(id, child, &spec.linux.resources)?;

    // §26.1/26.3: parent registers this pid for reaping and signal forwarding
    register_supervised_child(child);

    Ok(child)   // `start` later writes to sync_w, unblocking the child's execve
}
```

Everything above this line in the file is material to actually understand each piece; this section is just the connective tissue showing how §21/24/26/27 compose into the two OCI-spec calls (`create` blocks here up to the pipe read; `start` is a one-line write to `sync_w`).
