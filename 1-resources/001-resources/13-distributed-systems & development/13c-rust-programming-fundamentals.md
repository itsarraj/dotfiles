---
id: 20250419231647
title: Rust Programming Fundamentals Syntax Reference and Concepts
date: 2025-04-19 23:16
type: reference # note | concept | snippet | bug | journal | reference
status: stable # draft | stable | evergreen
tags: [rust, programming, syntax, fundamentals]
links: []
---
# Log
- 2025-04-19 23:16 - Created note.

# Notes

# Rust notes 

## String Interpolation
```rust
fn main() {
  let greeting = "Hello";
  let subject = "World";

  println!("{}, {}!", greeting, subject);
}
```
This `println!` is macro.

```rust
let subject = "World";
let greeting = format!("Hello, {}!", subject);

fn main(){
  let crash_reason = "Server need a nap.";
  panic!("I crashed! {}", crash_reason); // program or function ends here.
  println!("This will never run"); // This will not run, and will get a compiler warning
}
```



In function signatures, you must declare the type of each parameter.
```rust
fn another_function(x: i32) {
    println!("The value of x is: {x}");
}```


Statements are instructions that perform some action and do not return a value.
let y = 6; is a statement.
```rust
fn main() {
    let y = 6;
}
```
calling a function is not a statement
Statements do not return values

Expressions evaluate to a resultant value. Let’s look at some examples.

Expressions do not include ending semicolons

```rust
fn main() {
    let y = {
        let x = 3;
        x + 1 // Expressions do not include ending semicolons
    };

    println!("The value of y is: {y}");
}
```

This expression:
{
    let x = 3;
    x + 1
}
is a block that, in this case, evaluates to 4. That value gets bound to y as part of the let statement. Note that the x + 1 line doesn’t have a semicolon at the end.

If you add a semicolon to the end of an expression, you turn it into a statement, and it will then not return a value.

--- 

## Scalar Types

Scalar types represent single values. Rust has four primary scalar types: integers, floating-point numbers, Booleans, and characters.

### Integers

Integers are numbers without a fractional component. They come in signed and unsigned variants with different sizes:

```rust
fn main() {
    // Signed integers (can be negative)
    let x: i8 = -10;    // 8-bit (1 byte): -128 to 127
    let y: i16 = 300;   // 16-bit (2 bytes): -32,768 to 32,767
    let z: i32 = 100000; // 32-bit (4 bytes): -2^31 to 2^31-1 (default)
    let w: i64 = 1234567890; // 64-bit (8 bytes)
    let v: i128 = 170141183460469231731687303715884105727; // 128-bit (16 bytes)

    // Unsigned integers (only positive, including zero)
    let a: u8 = 255;    // 8-bit (1 byte): 0 to 255
    let b: u16 = 65535; // 16-bit (2 bytes): 0 to 65,535
    let c: u32 = 4294967295; // 32-bit (4 bytes): 0 to 2^32-1
    let d: u64 = 18446744073709551615; // 64-bit (8 bytes): 0 to 2^64-1
    let e: u128 = 340282366920938463463374607431768211455; // 128-bit (16 bytes): 0 to 2^128-1

    // Architecture-dependent sizes (isize/usize)
    let size: isize = 42;  // Pointer-sized signed integer (4 or 8 bytes)
    let usize: usize = 100; // Pointer-sized unsigned integer (4 or 8 bytes)
}
```

Integer literals can be written with suffixes (`42i32`, `100u8`) or inferred from context.

### Floating-Point Numbers

Floating-point numbers are numbers with decimal points. Rust has two primitive floating-point types:

```rust
fn main() {
    let x: f32 = 3.14159;   // 32-bit (4 bytes) float (single precision)
    let y: f64 = 2.718281828459045; // 64-bit (8 bytes) float (double precision, default)

    // Scientific notation
    let million = 1e6;      // 1000000.0
    let microsecond = 1e-6; // 0.000001

    // Operations
    let sum = 5.5 + 3.2;    // 8.7
    let difference = 10.0 - 4.5; // 5.5
    let product = 2.5 * 4.0; // 10.0
    let quotient = 15.0 / 3.0; // 5.0
}
```

### Booleans

The Boolean type (`bool`) has two possible values: `true` and `false`. It occupies 1 byte of memory:

```rust
fn main() {
    let is_rust_awesome: bool = true;
    let is_learning_hard: bool = false;

    // Boolean operations
    let and_result = true && false;  // false
    let or_result = true || false;   // true
    let not_result = !true;          // false

    // Comparison operators return booleans
    let is_greater = 5 > 3;          // true
    let is_equal = 10 == 10;         // true
    let is_not_equal = 7 != 8;       // true
}
```

### Characters

The `char` type represents a single Unicode scalar value and occupies 4 bytes of memory:

```rust
fn main() {
    let letter: char = 'A';
    let number: char = '5';
    let emoji: char = '😊';
    let heart: char = '❤️';

    // Unicode characters
    let cyrillic: char = 'Ж';      // Cyrillic
    let arabic: char = 'ع';        // Arabic
    let chinese: char = '中';       // Chinese

    // Special characters
    let newline: char = '\n';
    let tab: char = '\t';
    let quote: char = '\'';
    let backslash: char = '\\';
}
```

Note: `char` in Rust is 4 bytes and represents a Unicode scalar value, allowing it to represent any Unicode character including emojis and international characters.


## Overflow

Integer overflow occurs when an arithmetic operation attempts to create a value outside the valid range for a type. For example, adding 1 to the maximum value of a `u8` (255) would overflow.

### Debug Mode (Default)

In debug builds, Rust panics on integer overflow to help catch bugs early:

```rust
fn main() {
    let max_u8: u8 = 255;
    let result = max_u8 + 1; // This will panic in debug mode!
    println!("Result: {}", result);
}
```

**Output in debug mode:** `thread 'main' panicked at 'attempt to add with overflow'`

### Release Mode

In release builds (`--release`), Rust performs two's complement wrapping, which is the behavior of most programming languages:

```rust
fn main() {
    let max_u8: u8 = 255;
    let result = max_u8 + 1; // Wraps to 0 in release mode
    println!("Result: {}", result); // Prints: 0
}
```

### Explicit Overflow Handling

Rust provides methods for explicit overflow handling:

#### Checked Operations
Return `None` on overflow:

```rust
fn main() {
    let max_u8: u8 = 255;

    match max_u8.checked_add(1) {
        Some(result) => println!("No overflow: {}", result),
        None => println!("Overflow occurred!"),
    }

    match max_u8.checked_add(0) {
        Some(result) => println!("No overflow: {}", result),
        None => println!("Overflow occurred!"),
    }
}
```

#### Wrapping Operations
Explicitly wrap on overflow:

```rust
fn main() {
    let max_u8: u8 = 255;
    let wrapped = max_u8.wrapping_add(1);
    println!("Wrapped result: {}", wrapped); // 0

    let also_wrapped = max_u8.wrapping_add(256);
    println!("Also wrapped: {}", also_wrapped); // 0 (256 % 256 = 0)
}
```

#### Saturating Operations
Clamp to minimum/maximum values on overflow:

```rust
fn main() {
    let max_u8: u8 = 255;
    let saturated = max_u8.saturating_add(1);
    println!("Saturated result: {}", saturated); // 255 (clamped to max)

    let min_u8: u8 = 0;
    let saturated_sub = min_u8.saturating_sub(1);
    println!("Saturated subtraction: {}", saturated_sub); // 0 (clamped to min)
}
```

#### Overflowing Operations
Perform the operation and return both result and overflow flag:

```rust
fn main() {
    let max_u8: u8 = 255;
    let (result, overflowed) = max_u8.overflowing_add(1);
    println!("Result: {}, Overflowed: {}", result, overflowed); // Result: 0, Overflowed: true

    let (result2, overflowed2) = max_u8.overflowing_add(0);
    println!("Result: {}, Overflowed: {}", result2, overflowed2); // Result: 255, Overflowed: false
}
```

### When to Use Each Method

- **Panic (debug mode)**: During development to catch bugs
- **Checked**: When overflow should be treated as an error condition
- **Wrapping**: When implementing modular arithmetic (like counters, hashes)
- **Saturating**: When you want to clamp values (like audio levels, colors)
- **Overflowing**: When you need both the result and overflow status

### Floating-Point Overflow

Floating-point types (`f32`, `f64`) handle overflow differently - they produce special values:

```rust
fn main() {
    let max_f32 = f32::MAX;
    let infinity = max_f32 * 2.0;
    println!("Infinity: {}", infinity); // inf

    let zero = 0.0_f32;
    let nan = 0.0_f32 / 0.0_f32;
    println!("NaN: {}", nan); // NaN
}
```

**Note:** Always consider overflow behavior when choosing numeric types. Use `usize` for sizes/collections, and be explicit about overflow handling in performance-critical or safety-critical code. 

## Tuple

Tuples are compound types that group multiple values of potentially different types into a single compound type. Tuples have a fixed length and cannot grow or shrink once declared.

### Creating Tuples

```rust
fn main() {
    // Empty tuple (unit type)
    let empty: () = ();

    // Tuple with different types
    let person: (&str, i32, bool) = ("Alice", 30, true);

    // Type annotation is optional - Rust can infer
    let coordinates = (10.5, 20.3, 5.0);  // (f64, f64, f64)

    // Single element tuple (note the comma)
    let single = (42,);  // (i32,) - different from just 42

    // Mixed types
    let mixed = ("Hello", 42, true, 3.14);  // (&str, i32, bool, f64)
}
```

### Accessing Tuple Elements

#### By Index

```rust
fn main() {
    let person = ("Alice", 30, true);

    // Access elements by index (zero-based)
    let name = person.0;    // "Alice"
    let age = person.1;     // 30
    let is_active = person.2; // true

    println!("Name: {}, Age: {}, Active: {}", name, age, is_active);
}
```

#### Destructuring

```rust
fn main() {
    let person = ("Alice", 30, true);

    // Destructure all elements
    let (name, age, is_active) = person;
    println!("Name: {}, Age: {}, Active: {}", name, age, is_active);

    // Partial destructuring with _
    let (name, _, _) = person;
    println!("Name: {}", name);

    // Nested destructuring
    let coordinates = ((0, 0), (10, 5), (20, 15));
    let ((x1, y1), (x2, y2), (x3, y3)) = coordinates;
    println!("Point 1: ({}, {}), Point 2: ({}, {})", x1, y1, x2, y2);
}
```

### Tuple Methods

```rust
fn main() {
    let tuple = (1, 2, 3);

    // Clone the tuple
    let cloned = tuple.clone();

    // Compare tuples (lexicographical order)
    let t1 = (1, 2);
    let t2 = (1, 3);
    println!("t1 < t2: {}", t1 < t2);  // true

    // Tuples can be printed if all elements implement Display
    println!("Tuple: {:?}", tuple);    // Tuple: (1, 2, 3)
}
```

### Functions and Tuples

#### Returning Multiple Values

```rust
fn calculate(x: i32, y: i32) -> (i32, i32, i32) {
    let sum = x + y;
    let difference = x - y;
    let product = x * y;

    (sum, difference, product)  // Return tuple
}

fn main() {
    let (sum, diff, prod) = calculate(10, 5);
    println!("Sum: {}, Difference: {}, Product: {}", sum, diff, prod);

    // Or access by index
    let results = calculate(10, 5);
    println!("Sum: {}", results.0);
}
```

#### Tuple Parameters

```rust
fn print_coordinates((x, y): (f64, f64)) {
    println!("Coordinates: ({}, {})", x, y);
}

fn main() {
    let point = (3.5, 7.2);
    print_coordinates(point);  // Destructures automatically
}
```

### When to Use Tuples vs Structs

**Use tuples when:**
- You need a simple, temporary grouping of values
- The data doesn't need named fields
- You want to return multiple values from a function
- The structure is simple and unlikely to change

**Use structs when:**
- You need named fields for clarity
- The data structure is permanent/complex
- You want to implement methods on the type
- You need to track the structure over time

### Tuple Limitations

```rust
fn main() {
    let tuple = (1, "hello", true);

    // ❌ Cannot add/remove elements
    // tuple.3 = 42;  // Compile error

    // ❌ Cannot iterate over elements directly
    // for item in tuple { ... }  // Won't work

    // ✅ But you can destructure
    let (num, text, flag) = tuple;
}
```

### Advanced Patterns

#### Tuple of Tuples

```rust
fn main() {
    // Matrix represented as tuple of tuples
    let matrix: ((i32, i32), (i32, i32)) = ((1, 2), (3, 4));

    // Access elements
    let ((a, b), (c, d)) = matrix;
    println!("Matrix:\n{} {}\n{} {}", a, b, c, d);
}
```

#### Using Tuples with Generics

```rust
fn swap<T, U>(pair: (T, U)) -> (U, T) {
    let (first, second) = pair;
    (second, first)
}

fn main() {
    let pair = ("hello", 42);
    let swapped = swap(pair);
    println!("{:?}", swapped);  // (42, "hello")
}
```

**Note:** Tuples are most useful for simple, temporary data grouping. For more complex data structures with named fields and methods, consider using structs instead. The empty tuple `()` is also known as the unit type and is used extensively in Rust for functions that don't return meaningful values.

## Array

Arrays are fixed-size collections of elements of the same type stored in contiguous memory. Unlike vectors, arrays have a compile-time known size and are allocated on the stack rather than the heap.

### Creating Arrays

```rust
fn main() {
    // Explicit type and size annotation
    let numbers: [i32; 5] = [1, 2, 3, 4, 5];

    // Type inferred from values, size explicit
    let fruits = ["apple", "banana", "cherry"];

    // Initialize with default values
    let zeros: [i32; 10] = [0; 10];  // [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

    // Initialize with repeated values
    let threes: [i32; 5] = [3; 5];   // [3, 3, 3, 3, 3]
}
```

### Accessing Elements

#### By Index

```rust
fn main() {
    let numbers = [10, 20, 30, 40, 50];

    // Access by index (zero-based)
    let first = numbers[0];   // 10
    let third = numbers[2];   // 30
    let last = numbers[4];    // 50

    println!("First: {}, Third: {}, Last: {}", first, third, last);

    // Mutable arrays can be modified
    let mut mutable_numbers = [1, 2, 3, 4, 5];
    mutable_numbers[2] = 99;
    println!("Modified: {:?}", mutable_numbers);  // [1, 2, 99, 4, 5]
}
```

#### Safe Access with `get()`

```rust
fn main() {
    let numbers = [10, 20, 30];

    // Safe access returns Option
    match numbers.get(0) {
        Some(&value) => println!("Found: {}", value),
        None => println!("Index out of bounds"),
    }

    match numbers.get(10) {
        Some(&value) => println!("Found: {}", value),
        None => println!("Index out of bounds"),  // This will print
    }

    // Or use unwrap_or for defaults
    let safe_value = numbers.get(10).unwrap_or(&0);
    println!("Safe value: {}", safe_value);  // 0
}
```

### Array Properties

```rust
fn main() {
    let array = [1, 2, 3, 4, 5];

    // Get length
    println!("Length: {}", array.len());  // 5

    // Check if empty
    println!("Is empty: {}", array.is_empty());  // false

    // Get first/last elements safely
    println!("First: {:?}", array.first());     // Some(&1)
    println!("Last: {:?}", array.last());       // Some(&5)

    // Arrays have known size at compile time
    println!("Size in bytes: {}", std::mem::size_of_val(&array));  // 20 (5 * 4 bytes for i32)
}
```

### Iteration

```rust
fn main() {
    let numbers = [10, 20, 30, 40, 50];

    // Iterate by value (consumes array)
    for num in numbers {
        print!("{} ", num);
    }
    println!();

    // Iterate by reference (borrows array)
    for &num in &numbers {
        print!("{} ", num);
    }
    println!();

    // Iterate with index
    for (index, &value) in numbers.iter().enumerate() {
        println!("Index {}: {}", index, value);
    }

    // Mutable iteration
    let mut mutable_array = [1, 2, 3];
    for num in &mut mutable_array {
        *num *= 2;  // Dereference and modify
    }
    println!("Doubled: {:?}", mutable_array);  // [2, 4, 6]
}
```

### Array Methods

```rust
fn main() {
    let array = [3, 1, 4, 1, 5];

    // Sort (requires mutable reference)
    let mut sorted = array;
    sorted.sort();
    println!("Sorted: {:?}", sorted);  // [1, 1, 3, 4, 5]

    // Reverse
    let mut reversed = [1, 2, 3, 4];
    reversed.reverse();
    println!("Reversed: {:?}", reversed);  // [4, 3, 2, 1]

    // Contains
    println!("Contains 3: {}", array.contains(&3));  // true

    // Binary search (requires sorted array)
    let sorted_array = [1, 2, 3, 4, 5];
    match sorted_array.binary_search(&3) {
        Ok(index) => println!("Found at index {}", index),
        Err(_) => println!("Not found"),
    }

    // Partition (split based on predicate)
    let (even, odd): (Vec<i32>, Vec<i32>) = array.iter().partition(|&&x| x % 2 == 0);
    println!("Even: {:?}, Odd: {:?}", even, odd);  // Even: [4], Odd: [3, 1, 1, 5]
}
```

### Array Slices

```rust
fn main() {
    let array = [10, 20, 30, 40, 50];

    // Create slices (references to portions of arrays)
    let slice1 = &array[1..4];    // [20, 30, 40]
    let slice2 = &array[..3];     // [10, 20, 30] (from start to index 3)
    let slice3 = &array[2..];     // [30, 40, 50] (from index 2 to end)

    println!("Slice 1: {:?}", slice1);
    println!("Slice 2: {:?}", slice2);
    println!("Slice 3: {:?}", slice3);

    // Slices are also arrays in function parameters
    fn sum_slice(slice: &[i32]) -> i32 {
        slice.iter().sum()
    }

    println!("Sum of slice1: {}", sum_slice(slice1));  // 90
}
```

### Multidimensional Arrays

```rust
fn main() {
    // 2D array (3x3 matrix)
    let matrix: [[i32; 3]; 3] = [
        [1, 2, 3],
        [4, 5, 6],
        [7, 8, 9]
    ];

    // Access elements
    println!("Top-left: {}", matrix[0][0]);     // 1
    println!("Center: {}", matrix[1][1]);       // 5
    println!("Bottom-right: {}", matrix[2][2]); // 9

    // Iterate over 2D array
    for row in &matrix {
        for &element in row {
            print!("{} ", element);
        }
        println!();
    }
    // Output:
    // 1 2 3
    // 4 5 6
    // 7 8 9
}
```

### Arrays vs Vectors

**Use arrays when:**
- Size is known at compile time
- Performance is critical (stack allocation)
- Working with fixed-size data (like coordinates, colors)
- Memory layout matters

**Use vectors when:**
- Size changes at runtime
- Need dynamic resizing
- Working with collections of unknown size
- Need heap allocation for large data

```rust
fn main() {
    // Array: Fixed size, stack allocated
    let array: [i32; 3] = [1, 2, 3];

    // Vector: Dynamic size, heap allocated
    let mut vector = vec![1, 2, 3];
    vector.push(4);  // Can grow

    // Both can be sliced
    let array_slice: &[i32] = &array;
    let vector_slice: &[i32] = &vector;

    println!("Array slice: {:?}", array_slice);
    println!("Vector slice: {:?}", vector_slice);
}
```

### Common Patterns

#### Array Initialization Patterns

```rust
fn main() {
    // Initialize with computed values
    let squares: [i32; 5] = [0; 5];  // Start with zeros
    let squares = {
        let mut arr = [0; 5];
        for i in 0..5 {
            arr[i] = (i as i32 + 1).pow(2);
        }
        arr
    };
    println!("Squares: {:?}", squares);  // [1, 4, 9, 16, 25]

    // Array of arrays (jagged arrays possible)
    let jagged = [
        [1, 2],
        [3, 4, 5],
        [6]
    ];
    println!("Jagged: {:?}", jagged);
}
```

#### Working with Array References

```rust
fn main() {
    let array = [1, 2, 3, 4, 5];

    // Function taking array by reference
    fn print_array(arr: &[i32]) {
        for &item in arr {
            print!("{} ", item);
        }
        println!();
    }

    print_array(&array);

    // Function returning array reference
    fn get_middle(arr: &[i32]) -> Option<&i32> {
        if arr.len() % 2 == 1 {
            Some(&arr[arr.len() / 2])
        } else {
            None
        }
    }

    if let Some(&middle) = get_middle(&array) {
        println!("Middle element: {}", middle);
    }
}
```

**Note:** Arrays are one of Rust's fundamental types, providing efficient, fixed-size storage. They're ideal for scenarios where you know the exact size at compile time and want stack allocation for performance. For dynamic collections, use `Vec<T>` instead.

## String and str

Rust has two main string types: `String` (owned, growable, heap-allocated) and `&str` (borrowed, fixed-size string slice). Understanding the difference is crucial for effective Rust programming.

### String vs &str

```rust
fn main() {
    // &str - string slice (reference to UTF-8 bytes)
    let string_slice: &str = "Hello, World!";  // Static string literal

    // String - owned, growable string (heap-allocated)
    let owned_string: String = String::from("Hello, World!");

    // Converting between them
    let slice_from_string: &str = &owned_string;      // Borrow as slice
    let string_from_slice: String = string_slice.to_string();  // Create owned copy
    let string_from_slice2: String = string_slice.to_owned();   // Alternative
}
```

### Creating Strings

```rust
fn main() {
    // From string literal
    let s1 = String::from("Hello");
    let s2 = "Hello".to_string();
    let s3 = "Hello".to_owned();

    // From other types
    let s4 = format!("Number: {}", 42);
    let s5 = 42.to_string();

    // Empty string
    let s6 = String::new();
    let s7 = String::with_capacity(100);  // Pre-allocate capacity

    // From vector of bytes (UTF-8)
    let bytes = vec![72, 101, 108, 108, 111];  // "Hello" in UTF-8
    let s8 = String::from_utf8(bytes).unwrap();

    // From iterator of chars
    let chars = ['H', 'e', 'l', 'l', 'o'];
    let s9: String = chars.iter().collect();
}
```

### String Operations

#### Concatenation

```rust
fn main() {
    let hello = String::from("Hello");
    let world = String::from("World");

    // Using + operator (moves hello, borrows world)
    let hello_world = hello + " " + &world;
    println!("{}", hello_world);  // "Hello World"
    // hello is moved and can no longer be used

    // Using format! macro (borrows both)
    let hello2 = String::from("Hello");
    let world2 = String::from("World");
    let hello_world2 = format!("{} {}", hello2, world2);
    println!("{}", hello_world2);  // "Hello World"
    // Both hello2 and world2 are still accessible

    // Using push_str (appends to existing String)
    let mut greeting = String::from("Hello");
    greeting.push_str(", ");
    greeting.push_str("World!");
    println!("{}", greeting);  // "Hello, World!"

    // Using push for single characters
    let mut s = String::from("Hello");
    s.push('!');  // Note: single quotes for char
    println!("{}", s);  // "Hello!"
}
```

#### Indexing and Slicing

```rust
fn main() {
    let s = String::from("Hello, 世界!");  // Contains Unicode

    // Get length (in bytes, not characters)
    println!("Length in bytes: {}", s.len());  // 13 (not 8!)

    // Get characters
    for c in s.chars() {
        print!("{} ", c);
    }
    println!();
    // Output: H e l l o ,   世 界 !

    // Get bytes
    for b in s.bytes() {
        print!("{} ", b);
    }
    println!();

    // Safe slicing (returns &str)
    let hello = &s[0..5];    // "Hello" (first 5 bytes)
    println!("Hello: {}", hello);

    // This would panic if not at character boundary:
    // let partial = &s[0..4];  // Between UTF-8 code points

    // Safe character-based slicing
    let chars: Vec<char> = s.chars().collect();
    let first_three: String = chars[0..3].iter().collect();
    println!("First three chars: {}", first_three);  // "Hel"
}
```

### String Methods

```rust
fn main() {
    let s = String::from("   Hello, World!   ");

    // Trim whitespace
    let trimmed = s.trim();
    println!("Trimmed: '{}'", trimmed);  // "Hello, World!"

    // Case conversion
    println!("Upper: {}", s.to_uppercase());  // "   HELLO, WORLD!   "
    println!("Lower: {}", s.to_lowercase());  // "   hello, world!   "

    // Replace
    let replaced = s.replace("World", "Rust");
    println!("Replaced: {}", replaced);  // "   Hello, Rust!   "

    // Split
    for word in s.split_whitespace() {
        print!("'{}' ", word);
    }
    println!();  // 'Hello,' 'World!'

    // Check contents
    println!("Starts with '  H': {}", s.starts_with("  H"));  // true
    println!("Ends with '!  ': {}", s.ends_with("!  "));     // true
    println!("Contains 'World': {}", s.contains("World"));   // true

    // Find substrings
    if let Some(pos) = s.find("World") {
        println!("'World' found at position {}", pos);  // 9
    }

    // Substring extraction
    let substring = &s[3..8];
    println!("Substring: '{}'", substring);  // "Hello"
}
```

### String Searching and Manipulation

```rust
fn main() {
    let text = "The quick brown fox jumps over the lazy dog";

    // Split by character
    for part in text.split(' ') {
        print!("{} ", part);
    }
    println!();

    // Split by pattern
    let parts: Vec<&str> = text.split("the").collect();
    println!("Split by 'the': {:?}", parts);
    // ["The quick brown fox jumps over ", " lazy dog"]

    // Split with limit
    let limited: Vec<&str> = text.splitn(3, ' ').collect();
    println!("Split 3 parts: {:?}", limited);
    // ["The", "quick", "brown fox jumps over the lazy dog"]

    // Reverse string
    let reversed: String = text.chars().rev().collect();
    println!("Reversed: {}", reversed);

    // Remove characters
    let mut mutable = String::from("Hello, World!");
    mutable.retain(|c| c.is_alphabetic());  // Keep only letters
    println!("Only letters: {}", mutable);  // "HelloWorld"

    // Insert and remove
    let mut s = String::from("Hello!");
    s.insert(5, ',');  // Insert at index
    s.insert_str(6, " World");  // Insert string at index
    println!("After inserts: {}", s);  // "Hello, World!"

    s.remove(5);  // Remove character at index
    println!("After remove: {}", s);  // "Hello World!"
}
```

### UTF-8 and Unicode Handling

```rust
fn main() {
    let s = "Hello, 世界! 👋";

    // Count characters (not bytes)
    println!("Characters: {}", s.chars().count());  // 11

    // Count bytes
    println!("Bytes: {}", s.len());  // 18 (varies by character)

    // Iterate over grapheme clusters (user-perceived characters)
    use unicode_segmentation::UnicodeSegmentation;

    for grapheme in s.graphemes(true) {
        print!("'{}' ", grapheme);
    }
    println!();
    // 'H' 'e' 'l' 'l' 'o' ',' ' ' '世' '界' '!' '👋'

    // Check if valid UTF-8
    let valid_utf8 = "Hello, 世界!";
    let invalid_utf8 = &[72, 101, 108, 108, 111, 255];  // Contains invalid UTF-8

    match String::from_utf8(invalid_utf8.to_vec()) {
        Ok(s) => println!("Valid UTF-8: {}", s),
        Err(e) => println!("Invalid UTF-8: {}", e),
    }
}
```

### Common Patterns and Best Practices

```rust
fn main() {
    // Pattern 1: Building strings efficiently
    let mut result = String::with_capacity(100);  // Pre-allocate
    for i in 0..10 {
        result.push_str(&format!("Number: {}\n", i));
    }
    println!("{}", result);

    // Pattern 2: String interpolation with format!
    let name = "Alice";
    let age = 30;
    let message = format!("Hello, my name is {} and I am {} years old!", name, age);
    println!("{}", message);

    // Pattern 3: Conditional string building
    let mut query = String::from("SELECT * FROM users");
    let mut conditions = Vec::new();

    conditions.push("active = true");
    conditions.push("age > 18");

    if !conditions.is_empty() {
        query.push_str(" WHERE ");
        query.push_str(&conditions.join(" AND "));
    }
    println!("Query: {}", query);

    // Pattern 4: Working with &str vs String in functions
    fn process_text(text: &str) -> String {
        text.to_uppercase()  // Works with both &str and String
    }

    let owned = String::from("hello");
    let borrowed = "world";

    println!("{}", process_text(&owned));   // Borrow owned string
    println!("{}", process_text(borrowed)); // Use borrowed string directly
}
```

### String Conversions

```rust
fn main() {
    // Numbers to strings
    let num = 42;
    let s1 = num.to_string();
    let s2 = format!("{}", num);
    let s3 = format!("{:04}", num);  // Zero-padded: "0042"

    // Strings to numbers
    let s = "42";
    let parsed: i32 = s.parse().unwrap();
    let parsed_u64: u64 = s.parse().unwrap();

    // Handle parsing errors
    match "not_a_number".parse::<i32>() {
        Ok(n) => println!("Parsed: {}", n),
        Err(e) => println!("Parse error: {}", e),
    }

    // Advanced formatting
    let pi = 3.14159;
    println!("Pi with 2 decimals: {:.2}", pi);    // 3.14
    println!("Pi in scientific: {:.2e}", pi);     // 3.14e0
    println!("Pi with width: {:10.2}", pi);       // "      3.14"

    // Binary, hex, octal
    println!("Binary: {:b}", 42);   // 101010
    println!("Hex: {:x}", 42);     // 2a
    println!("Octal: {:o}", 42);   // 52
}
```

### Memory Considerations

```rust
fn main() {
    // String capacity management
    let mut s = String::with_capacity(10);
    println!("Capacity: {}", s.capacity());  // 10

    s.push_str("hello");
    println!("Length: {}, Capacity: {}", s.len(), s.capacity());  // 5, 10

    s.push_str(" world!");  // Exceeds capacity, will reallocate
    println!("Length: {}, Capacity: {}", s.len(), s.capacity());  // 12, >=12

    // Shrink to fit current length
    s.shrink_to_fit();
    println!("After shrink - Length: {}, Capacity: {}", s.len(), s.capacity());

    // Clear and reuse
    s.clear();
    println!("After clear - Length: {}, Capacity: {}", s.len(), s.capacity());
    // Capacity remains for reuse
}
```

### When to Use String vs &str

**Use `String` when:**
- You need to own and modify the string data
- The string needs to grow or change
- You need to return a string from a function
- You need to store strings in data structures

**Use `&str` when:**
- You just need to read/borrow string data
- Function parameters (accept both owned and borrowed strings)
- String literals and temporary string operations
- Performance-critical code (avoids allocations)

```rust
// Good: Accept &str to work with both String and &str
fn greet(name: &str) {
    println!("Hello, {}!", name);
}

fn main() {
    let owned_name = String::from("Alice");
    let borrowed_name = "Bob";

    greet(&owned_name);  // Borrow owned string
    greet(borrowed_name); // Use borrowed string directly
}
```

**Note:** Rust's string handling emphasizes memory safety and performance. `String` owns heap-allocated UTF-8 data, while `&str` is a borrowed reference to UTF-8 bytes. Always prefer `&str` for function parameters to accept both types. String operations are UTF-8 aware, making them safe for international text but requiring careful handling of byte vs character boundaries.


## Enums 

Rust enums are custom data types that define a set of possible variants. Each variant can optionally hold data, making enums incredibly powerful for modeling complex state and behavior. Unlike enums in many other languages, Rust enums can store different types and amounts of data in each variant, enabling type-safe pattern matching and compile-time guarantees.

basic example 
```rust 
enum Direction {
    Up,
    Down,
    Left,
    Right
}
```

with Data
```rust 
enum Message {
    Quit,
    Move { x: i32, y: i32 },
    Write(String),
    ChangeColor(i32,i32,i32),
}
```
using with match
```rust
let msg = Message::Write(String::from("Hi"));

match msg {
    Message::Quit => println("Quit");
    Message::Write(text) => println("{}", text),
    _ => {}
}
```
Enums are powerful for modeling states and variants safely.

```rust
enum Option<T> {
    None,
    Some(T),
}```

---

```rust
enum Command {
    Play,
    Stop,
    Skip(u32),
    Back(u32),
    Resize { width: u32, height: u32 }
}

fn main() {
    let play_cmd = Command::Play;
    let skip_cmd = Command::Skip(10);
    let resize_cmd = Command::Resize { width: 100, height: 50 };

    // Pattern matching to handle different variants
    match play_cmd {
        Command::Play => println!("Playing"),
        Command::Stop => println!("Stopped"),
        Command::Skip(track) => println!("Skipping to track {}", track),
        Command::Back(track) => println!("Going back to track {}", track),
        Command::Resize { width, height } => println!("Resizing to {}x{}", width, height),
    }
}
```

## Struct

Structs are user-defined types that group related data together. They allow you to create complex data types by combining primitive types and other structs.

### Defining and Using Structs

#### Classic Structs (Named Fields)

```rust
// Define a struct
#[derive(Debug)]  // Enable debug printing
struct User {
    username: String,
    email: String,
    sign_in_count: u64,
    active: bool,
}

fn main() {
    // Create an instance
    let user1 = User {
        email: String::from("someone@example.com"),
        username: String::from("someusername123"),
        active: true,
        sign_in_count: 1,
    };

    // Access fields
    println!("Username: {}", user1.username);
    println!("Email: {}", user1.email);
    println!("User: {:?}", user1);  // Debug print

    // Create mutable instance
    let mut user2 = User {
        email: String::from("another@example.com"),
        username: String::from("anotherusername"),
        active: true,
        sign_in_count: 1,
    };

    // Modify fields
    user2.email = String::from("newemail@example.com");
    println!("Updated email: {}", user2.email);
}
```

#### Field Init Shorthand

```rust
fn build_user(email: String, username: String) -> User {
    User {
        email,      // Same as email: email
        username,   // Same as username: username
        active: true,
        sign_in_count: 1,
    }
}

fn main() {
    let user = build_user(
        String::from("user@example.com"),
        String::from("user123")
    );
    println!("Created user: {}", user.username);
}
```

#### Struct Update Syntax

```rust
fn main() {
    let user1 = User {
        email: String::from("user1@example.com"),
        username: String::from("user1"),
        active: true,
        sign_in_count: 1,
    };

    // Create user2 with most fields from user1
    let user2 = User {
        email: String::from("user2@example.com"),
        username: String::from("user2"),
        ..user1  // Copy remaining fields from user1
    };

    println!("User1 active: {}", user1.active);
    println!("User2 active: {}", user2.active);
    // Note: user1 is still valid since we only moved String fields
}
```

### Tuple Structs

```rust
// Tuple structs have no field names, just types
#[derive(Debug)]
struct Color(i32, i32, i32);  // RGB values

#[derive(Debug)]
struct Point(i32, i32);       // 2D coordinates

fn main() {
    let black = Color(0, 0, 0);
    let origin = Point(0, 0);

    // Access by index
    println!("Red: {}", black.0);
    println!("Green: {}", black.1);
    println!("Blue: {}", black.2);

    // Destructure
    let Color(r, g, b) = black;
    println!("Destructured - R:{}, G:{}, B:{}", r, g, b);

    // Useful for newtypes (type aliases with semantics)
    #[derive(Debug)]
    struct Inches(i32);

    let length = Inches(24);
    println!("Length: {} inches", length.0);
}
```

### Unit Structs

```rust
// Unit structs have no fields
#[derive(Debug)]
struct Unit;

fn main() {
    let unit = Unit;
    println!("Unit struct: {:?}", unit);

    // Often used as markers or for generics
    struct Marker;
    let _marker = Marker;
}
```

### Struct Methods and Associated Functions

```rust
#[derive(Debug)]
struct Rectangle {
    width: u32,
    height: u32,
}

impl Rectangle {
    // Associated function (like static methods)
    fn new(width: u32, height: u32) -> Rectangle {
        Rectangle { width, height }
    }

    // Method (takes &self)
    fn area(&self) -> u32 {
        self.width * self.height
    }

    // Method that can modify self
    fn scale(&mut self, factor: u32) {
        self.width *= factor;
        self.height *= factor;
    }

    // Method with parameters
    fn can_hold(&self, other: &Rectangle) -> bool {
        self.width > other.width && self.height > other.height
    }

    // Associated function (constructor pattern)
    fn square(size: u32) -> Rectangle {
        Rectangle {
            width: size,
            height: size,
        }
    }
}

fn main() {
    // Using associated functions
    let rect1 = Rectangle::new(30, 50);
    let rect2 = Rectangle::square(20);

    // Using methods
    println!("Area of rect1: {}", rect1.area());
    println!("Can rect1 hold rect2? {}", rect1.can_hold(&rect2));

    // Mutable methods
    let mut rect3 = Rectangle::new(10, 10);
    rect3.scale(2);
    println!("Scaled rect3: {}x{}", rect3.width, rect3.height);
}
```

### Multiple impl Blocks

```rust
impl Rectangle {
    // First impl block
    fn perimeter(&self) -> u32 {
        2 * (self.width + self.height)
    }
}

impl Rectangle {
    // Second impl block (can split implementations)
    fn diagonal(&self) -> f64 {
        ((self.width.pow(2) + self.height.pow(2)) as f64).sqrt()
    }
}

fn main() {
    let rect = Rectangle::new(3, 4);
    println!("Perimeter: {}", rect.perimeter());
    println!("Diagonal: {:.2}", rect.diagonal());
}
```

### Visibility and Privacy

```rust
mod shapes {
    // Public struct with private fields
    pub struct Circle {
        pub radius: f64,    // Public field
        center: (f64, f64), // Private field
    }

    impl Circle {
        // Constructor (since fields are private)
        pub fn new(radius: f64) -> Circle {
            Circle {
                radius,
                center: (0.0, 0.0),
            }
        }

        // Public method to access private field
        pub fn center(&self) -> (f64, f64) {
            self.center
        }

        // Method to modify private field
        pub fn move_to(&mut self, x: f64, y: f64) {
            self.center = (x, y);
        }

        // Private method
        fn validate_radius(radius: f64) -> Result<f64, String> {
            if radius > 0.0 {
                Ok(radius)
            } else {
                Err("Radius must be positive".to_string())
            }
        }
    }
}

fn main() {
    let mut circle = shapes::Circle::new(5.0);
    println!("Radius: {}", circle.radius);  // Public field accessible

    // circle.center = (1.0, 1.0);  // Error: private field
    println!("Center: {:?}", circle.center());  // Use public method

    circle.move_to(10.0, 20.0);
    println!("New center: {:?}", circle.center());
}
```

### Advanced Patterns

#### Builder Pattern

```rust
#[derive(Debug)]
struct ServerConfig {
    host: String,
    port: u16,
    tls: bool,
    max_connections: Option<u32>,
}

struct ServerConfigBuilder {
    host: String,
    port: u16,
    tls: bool,
    max_connections: Option<u32>,
}

impl ServerConfigBuilder {
    fn new() -> ServerConfigBuilder {
        ServerConfigBuilder {
            host: "localhost".to_string(),
            port: 8080,
            tls: false,
            max_connections: None,
        }
    }

    fn host(mut self, host: &str) -> ServerConfigBuilder {
        self.host = host.to_string();
        self
    }

    fn port(mut self, port: u16) -> ServerConfigBuilder {
        self.port = port;
        self
    }

    fn tls(mut self, tls: bool) -> ServerConfigBuilder {
        self.tls = tls;
        self
    }

    fn max_connections(mut self, max: u32) -> ServerConfigBuilder {
        self.max_connections = Some(max);
        self
    }

    fn build(self) -> ServerConfig {
        ServerConfig {
            host: self.host,
            port: self.port,
            tls: self.tls,
            max_connections: self.max_connections,
        }
    }
}

fn main() {
    let config = ServerConfigBuilder::new()
        .host("127.0.0.1")
        .port(443)
        .tls(true)
        .max_connections(1000)
        .build();

    println!("Server config: {:?}", config);
}
```

#### Newtype Pattern

```rust
// Type-safe wrappers around primitive types
#[derive(Debug)]
struct Kilometers(f64);

#[derive(Debug)]
struct Miles(f64);

// Prevent mixing up units
impl Kilometers {
    fn to_miles(self) -> Miles {
        Miles(self.0 * 0.621371)
    }
}

impl Miles {
    fn to_kilometers(self) -> Kilometers {
        Kilometers(self.0 * 1.60934)
    }
}

fn main() {
    let distance_km = Kilometers(100.0);
    let distance_mi = distance_km.to_miles();

    println!("100 km = {:?} miles", distance_mi);

    // This won't compile (different types):
    // let wrong = distance_km + distance_mi;  // Error!
}
```

### Structs with References

```rust
#[derive(Debug)]
struct User<'a> {
    name: &'a str,      // Reference with lifetime
    email: &'a str,
}

fn main() {
    let name = String::from("Alice");
    let email = String::from("alice@example.com");

    // User borrows from the strings
    let user = User {
        name: &name,
        email: &email,
    };

    println!("User: {:?}", user);
    // name and email must live longer than user
}
```

### Destructuring Structs

```rust
struct Point3D {
    x: f64,
    y: f64,
    z: f64,
}

fn main() {
    let point = Point3D { x: 1.0, y: 2.0, z: 3.0 };

    // Destructure named fields
    let Point3D { x, y, z } = point;
    println!("x: {}, y: {}, z: {}", x, y, z);

    // Destructure with different variable names
    let Point3D { x: a, y: b, z: c } = point;
    println!("a: {}, b: {}, c: {}", a, b, c);

    // Partial destructuring
    let Point3D { x, .. } = point;  // Only extract x
    println!("x: {}", x);

    // In function parameters
    fn distance(Point3D { x, y, z }: Point3D) -> f64 {
        (x*x + y*y + z*z).sqrt()
    }

    println!("Distance from origin: {}", distance(point));
}
```

### Memory Layout and Considerations

```rust
use std::mem;

#[derive(Debug)]
struct Example {
    a: u8,      // 1 byte
    b: u32,     // 4 bytes (but might have padding)
    c: u8,      // 1 byte
}

fn main() {
    let example = Example { a: 1, b: 2, c: 3 };

    println!("Size of Example: {} bytes", mem::size_of::<Example>());
    println!("Alignment of Example: {} bytes", mem::align_of::<Example>());

    // Rust may add padding for alignment
    // Total size might be larger than sum of field sizes

    // Compare with repr(C) for C compatibility
    #[repr(C)]
    struct CExample {
        a: u8,
        b: u32,
        c: u8,
    }

    println!("Size of CExample: {} bytes", mem::size_of::<CExample>());
}
```

### When to Use Structs vs Other Types

**Use structs when:**
- You need to group related data with meaningful names
- You want to define methods on your data
- You need to implement traits
- Data has a fixed structure that won't change

**Consider alternatives:**
- **Tuple**: For simple, unnamed data groups
- **Enum**: For data that can be different types
- **Vector/HashMap**: For dynamic collections

```rust
// Struct for complex, named data
struct Person {
    name: String,
    age: u32,
    email: String,
}

// Tuple for simple, positional data
type Point = (f64, f64);

// Enum for different variants
enum Shape {
    Circle { radius: f64 },
    Rectangle { width: f64, height: f64 },
}
```

**Note:** Structs are fundamental to Rust's type system, enabling encapsulation, abstraction, and type safety. They provide the building blocks for creating domain-specific types that make your code more expressive and maintainable. Always derive `Debug` for development and consider implementing common traits like `Clone`, `Copy`, `PartialEq` when appropriate.
## Vector

Vectors (`Vec<T>`) are growable arrays that store multiple values of the same type in contiguous memory. They're heap-allocated and can grow or shrink dynamically.

### Creating Vectors

```rust
fn main() {
    // Empty vector (type annotation needed)
    let v1: Vec<i32> = Vec::new();

    // Vector with initial values
    let v2 = vec![1, 2, 3, 4, 5];

    // Vector with default values
    let v3 = vec![0; 10];  // [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

    // Vector with capacity pre-allocation
    let mut v4: Vec<i32> = Vec::with_capacity(10);
    println!("Capacity: {}", v4.capacity());  // 10

    // From iterator
    let v5: Vec<i32> = (0..5).collect();  // [0, 1, 2, 3, 4]

    // From array
    let arr = [1, 2, 3];
    let v6: Vec<i32> = arr.into();

    // Clone existing vector
    let v7 = v2.clone();
}
```

### Accessing Elements

#### Safe Access

```rust
fn main() {
    let v = vec![10, 20, 30, 40, 50];

    // get() returns Option<&T> (safe)
    match v.get(0) {
        Some(&value) => println!("First element: {}", value),
        None => println!("No element at index 0"),
    }

    match v.get(10) {
        Some(&value) => println!("Found: {}", value),
        None => println!("Index 10 out of bounds"),
    }

    // get_mut() for mutable access
    let mut v2 = vec![1, 2, 3];
    if let Some(value) = v2.get_mut(1) {
        *value = 99;
    }
    println!("Modified vector: {:?}", v2);  // [1, 99, 3]
}
```

#### Direct Indexing (Unsafe)

```rust
fn main() {
    let v = vec![10, 20, 30];

    // Direct indexing with [] - panics on out of bounds
    let first = v[0];    // 10
    let second = v[1];   // 20

    // This would panic in debug mode:
    // let out_of_bounds = v[10];  // panic!

    println!("First: {}, Second: {}", first, second);
}
```

#### First/Last Access

```rust
fn main() {
    let v = vec![1, 2, 3, 4, 5];

    // Safe access to first/last elements
    if let Some(&first) = v.first() {
        println!("First element: {}", first);
    }

    if let Some(&last) = v.last() {
        println!("Last element: {}", last);
    }

    // For empty vectors
    let empty: Vec<i32> = vec![];
    println!("Empty first: {:?}", empty.first());  // None
    println!("Empty last: {:?}", empty.last());    // None
}
```

### Adding and Removing Elements

```rust
fn main() {
    let mut v = vec![1, 2, 3];

    // Add to end (O(1) amortized)
    v.push(4);
    v.push(5);
    println!("After push: {:?}", v);  // [1, 2, 3, 4, 5]

    // Remove from end (O(1))
    let popped = v.pop();
    println!("Popped: {:?}, Vector: {:?}", popped, v);  // Some(5), [1, 2, 3, 4]

    // Insert at index (O(n) - shifts elements)
    v.insert(1, 99);
    println!("After insert: {:?}", v);  // [1, 99, 2, 3, 4]

    // Remove at index (O(n) - shifts elements)
    let removed = v.remove(1);
    println!("Removed: {}, Vector: {:?}", removed, v);  // 99, [1, 2, 3, 4]

    // Extend with another vector
    let mut v1 = vec![1, 2];
    let v2 = vec![3, 4, 5];
    v1.extend(&v2);  // v2 is borrowed, not moved
    println!("Extended: {:?}", v1);  // [1, 2, 3, 4, 5]

    // Append (moves the other vector)
    let mut v3 = vec![1, 2];
    let mut v4 = vec![3, 4];
    v3.append(&mut v4);
    println!("Appended: {:?}, v4 is now: {:?}", v3, v4);  // [1, 2, 3, 4], []
}
```

### Iteration

```rust
fn main() {
    let mut v = vec![1, 2, 3, 4, 5];

    // Immutable iteration
    println!("Immutable iteration:");
    for &value in &v {
        print!("{} ", value);
    }
    println!();

    // Mutable iteration
    println!("Mutable iteration (doubling values):");
    for value in &mut v {
        *value *= 2;
        print!("{} ", *value);
    }
    println!();

    // Consuming iteration (moves values)
    let v2 = vec![10, 20, 30];
    println!("Consuming iteration:");
    for value in v2 {
        print!("{} ", value);
    }
    // v2 is no longer accessible here
    println!();

    // Iterator methods
    let v3 = vec![1, 2, 3, 4, 5, 6];
    let sum: i32 = v3.iter().sum();
    let count = v3.iter().count();
    let max = v3.iter().max();
    let min = v3.iter().min();

    println!("Sum: {}, Count: {}, Max: {:?}, Min: {:?}", sum, count, max, min);
}
```

### Common Vector Methods

```rust
fn main() {
    let mut v = vec![3, 1, 4, 1, 5, 9, 2, 6];

    // Length and capacity
    println!("Length: {}, Capacity: {}", v.len(), v.capacity());

    // Check if empty
    println!("Is empty: {}", v.is_empty());

    // Clear all elements
    v.clear();
    println!("After clear: {:?}", v);  // []

    // Resize with default values
    v.resize(5, 0);
    println!("After resize: {:?}", v);  // [0, 0, 0, 0, 0]

    // Sort
    let mut nums = vec![3, 1, 4, 1, 5];
    nums.sort();
    println!("Sorted: {:?}", nums);  // [1, 1, 3, 4, 5]

    // Reverse
    nums.reverse();
    println!("Reversed: {:?}", nums);  // [5, 4, 3, 1, 1]

    // Deduplicate (requires sorted)
    let mut dupes = vec![1, 2, 2, 3, 3, 3];
    dupes.dedup();
    println!("Deduped: {:?}", dupes);  // [1, 2, 3]

    // Retain elements matching predicate
    let mut nums2 = vec![1, 2, 3, 4, 5, 6];
    nums2.retain(|&x| x % 2 == 0);  // Keep even numbers
    println!("Even only: {:?}", nums2);  // [2, 4, 6]
}
```

### Searching and Finding

```rust
fn main() {
    let v = vec![10, 20, 30, 40, 50];

    // Contains
    println!("Contains 30: {}", v.contains(&30));  // true
    println!("Contains 60: {}", v.contains(&60));  // false

    // Find first element matching predicate
    let found = v.iter().find(|&&x| x > 25);
    println!("First > 25: {:?}", found);  // Some(&30)

    // Find position
    let position = v.iter().position(|&x| x == 40);
    println!("Position of 40: {:?}", position);  // Some(3)

    // Binary search (requires sorted vector)
    let sorted = vec![10, 20, 30, 40, 50];
    match sorted.binary_search(&30) {
        Ok(pos) => println!("Found at position {}", pos),
        Err(pos) => println!("Not found, would insert at {}", pos),
    }

    // Filter
    let filtered: Vec<i32> = v.iter().filter(|&&x| x > 25).cloned().collect();
    println!("Filtered > 25: {:?}", filtered);  // [30, 40, 50]
}
```

### Capacity and Memory Management

```rust
fn main() {
    // Start with capacity
    let mut v: Vec<i32> = Vec::with_capacity(4);
    println!("Initial capacity: {}", v.capacity());

    v.push(1);
    v.push(2);
    println!("Length: {}, Capacity: {}", v.len(), v.capacity());

    v.push(3);
    v.push(4);
    v.push(5);  // Triggers reallocation
    println!("After growth - Length: {}, Capacity: {}", v.len(), v.capacity());

    // Shrink to fit current length
    v.shrink_to_fit();
    println!("After shrink - Length: {}, Capacity: {}", v.len(), v.capacity());

    // Reserve additional capacity
    v.reserve(10);
    println!("After reserve - Capacity: {}", v.capacity());

    // Reserve exactly
    v.reserve_exact(5);
    println!("After reserve_exact - Capacity: {}", v.capacity());
}
```

### Vector of Vectors and Complex Types

```rust
fn main() {
    // Vector of vectors (2D vector)
    let mut matrix: Vec<Vec<i32>> = vec![
        vec![1, 2, 3],
        vec![4, 5, 6],
        vec![7, 8, 9]
    ];

    // Access elements
    println!("Element at [1][2]: {}", matrix[1][2]);  // 6

    // Add a row
    matrix.push(vec![10, 11, 12]);
    println!("Matrix has {} rows", matrix.len());

    // Vector of structs
    #[derive(Debug)]
    struct Point {
        x: i32,
        y: i32,
    }

    let points = vec![
        Point { x: 0, y: 0 },
        Point { x: 1, y: 1 },
        Point { x: 2, y: 2 },
    ];

    for point in &points {
        println!("Point: {:?}", point);
    }

    // Vector of Options
    let optional_values: Vec<Option<i32>> = vec![Some(1), None, Some(3)];
    for value in optional_values {
        match value {
            Some(v) => println!("Value: {}", v),
            None => println!("No value"),
        }
    }
}
```

### Common Patterns and Idioms

```rust
fn main() {
    // Pattern 1: Building vectors efficiently
    let mut result = Vec::with_capacity(100);
    for i in 0..100 {
        result.push(i * i);
    }
    println!("Built vector with {} elements", result.len());

    // Pattern 2: Collect from iterator
    let squares: Vec<i32> = (1..=10).map(|x| x * x).collect();
    println!("Squares: {:?}", squares);

    // Pattern 3: Filter and transform
    let numbers = vec![1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
    let even_squares: Vec<i32> = numbers
        .iter()
        .filter(|&&x| x % 2 == 0)
        .map(|&x| x * x)
        .collect();
    println!("Even squares: {:?}", even_squares);

    // Pattern 4: Vector as stack
    let mut stack = Vec::new();
    stack.push(1);
    stack.push(2);
    stack.push(3);

    while let Some(top) = stack.pop() {
        println!("Popped: {}", top);
    }

    // Pattern 5: Safe element access with unwrap_or
    let v = vec![1, 2, 3];
    let safe_value = v.get(5).unwrap_or(&0);
    println!("Safe access result: {}", safe_value);
}
```

### Vector vs Array

**Use Vector when:**
- Size is unknown at compile time
- Collection needs to grow/shrink
- Need heap allocation for large data
- Need dynamic collections

**Use Array when:**
- Size is known at compile time
- Performance is critical (stack allocation)
- Fixed-size data (like coordinates, RGB values)
- Memory layout is important

```rust
fn main() {
    // Array: Fixed size, stack allocated
    let array: [i32; 3] = [1, 2, 3];

    // Vector: Dynamic size, heap allocated
    let mut vector = vec![1, 2, 3];
    vector.push(4);  // Can grow

    // Both can be sliced
    let array_slice: &[i32] = &array;
    let vector_slice: &[i32] = &vector;

    println!("Array slice: {:?}", array_slice);
    println!("Vector slice: {:?}", vector_slice);
}
```

### Performance Considerations

```rust
fn main() {
    // Pre-allocate capacity for better performance
    let mut v = Vec::with_capacity(1000);
    for i in 0..1000 {
        v.push(i);
    }
    // Avoids multiple reallocations

    // Use retain instead of creating new vector when filtering
    let mut numbers = vec![1, 2, 3, 4, 5, 6];
    numbers.retain(|&x| x % 2 == 0);  // More efficient than filter().collect()

    // Use into_iter() when consuming the vector
    let v = vec![1, 2, 3];
    let sum: i32 = v.into_iter().sum();  // Moves values directly
    // v is no longer accessible

    // Consider VecDeque for frequent front operations
    use std::collections::VecDeque;
    let mut deque: VecDeque<i32> = VecDeque::new();
    deque.push_front(1);  // O(1) for VecDeque
    deque.push_back(2);
}
```

**Note:** Vectors are Rust's primary dynamic collection type, providing efficient random access and growth. They're heap-allocated and automatically manage memory, but understanding capacity and growth patterns is key to optimal performance. Always prefer vectors over linked lists for most use cases due to better cache locality and memory efficiency. 
## HashMap

`HashMap<K, V>` is a hash table implementation that stores key-value pairs. Keys must be hashable and comparable for equality, while values can be any type.

### Creating HashMaps

```rust
use std::collections::HashMap;

fn main() {
    // Empty HashMap (type annotation needed)
    let mut scores: HashMap<String, i32> = HashMap::new();

    // HashMap with initial values
    let mut scores2 = HashMap::from([
        ("Alice".to_string(), 100),
        ("Bob".to_string(), 85),
        ("Charlie".to_string(), 92),
    ]);

    // Using collect from iterator of tuples
    let scores3: HashMap<_, _> = [("Alice", 100), ("Bob", 85)].into_iter().collect();

    // With capacity pre-allocation
    let mut scores4: HashMap<String, i32> = HashMap::with_capacity(10);

    // From vectors (zip creates tuples)
    let keys = vec!["Alice", "Bob", "Charlie"];
    let values = vec![100, 85, 92];
    let scores5: HashMap<_, _> = keys.into_iter().zip(values.into_iter()).collect();

    println!("Scores: {:?}", scores2);
}
```

### Inserting and Accessing Values

```rust
use std::collections::HashMap;

fn main() {
    let mut scores = HashMap::new();

    // Insert key-value pairs (takes ownership of key and value)
    scores.insert(String::from("Alice"), 100);
    scores.insert(String::from("Bob"), 85);

    // Access values
    let alice_score = scores.get("Alice");
    println!("Alice's score: {:?}", alice_score);  // Some(&100)

    let nonexistent = scores.get("Dave");
    println!("Dave's score: {:?}", nonexistent);  // None

    // Check if key exists
    println!("Has Alice: {}", scores.contains_key("Alice"));
    println!("Has Dave: {}", scores.contains_key("Dave"));

    // Get mutable reference to value
    if let Some(score) = scores.get_mut("Alice") {
        *score += 5;  // Modify in place
    }
    println!("Alice's updated score: {:?}", scores.get("Alice"));
}
```

### Ownership and Borrowing

```rust
use std::collections::HashMap;

fn main() {
    let mut map = HashMap::new();

    // String keys are moved into the map
    let key1 = String::from("hello");
    let value1 = String::from("world");
    map.insert(key1, value1);
    // key1 and value1 are no longer accessible

    // &str keys are copied (Copy trait)
    let key2 = "hello";
    map.insert(key2, "world");  // &str implements Copy
    println!("Key2 is still accessible: {}", key2);

    // Accessing returns references
    if let Some(value) = map.get("hello") {
        println!("Found value: {}", value);
        // value is &String, can be dereferenced or borrowed
    }

    // To get owned values, use remove()
    if let Some(owned_value) = map.remove("hello") {
        println!("Removed value: {}", owned_value);  // String, not &String
    }
}
```

### Updating Values

```rust
use std::collections::HashMap;

fn main() {
    let mut scores = HashMap::new();

    // Insert or update with insert (overwrites existing)
    scores.insert("Alice", 100);
    scores.insert("Alice", 95);  // Overwrites 100 with 95
    println!("Alice's score: {:?}", scores.get("Alice"));

    // Insert only if key doesn't exist
    let old_value = scores.entry("Alice").or_insert(100);
    println!("Alice already had: {}", old_value);

    let new_value = scores.entry("Bob").or_insert(85);
    println!("Bob's new score: {}", new_value);

    // Update based on current value
    let count = scores.entry("Alice").or_insert(0);
    *count += 10;
    println!("Alice's updated score: {}", count);

    // Complex updates with closures
    scores.entry("Charlie")
        .and_modify(|score| *score += 5)
        .or_insert(90);
    println!("Charlie's score: {:?}", scores.get("Charlie"));
}
```

### Iteration

```rust
use std::collections::HashMap;

fn main() {
    let mut scores = HashMap::from([
        ("Alice".to_string(), 100),
        ("Bob".to_string(), 85),
        ("Charlie".to_string(), 92),
    ]);

    // Iterate over key-value pairs (&String, &i32)
    println!("All scores:");
    for (name, score) in &scores {
        println!("{}: {}", name, score);
    }

    // Iterate over keys only
    println!("Names:");
    for name in scores.keys() {
        println!("{}", name);
    }

    // Iterate over values only
    println!("Scores:");
    for score in scores.values() {
        println!("{}", score);
    }

    // Mutable iteration
    println!("Doubling all scores:");
    for score in scores.values_mut() {
        *score *= 2;
    }

    // Consuming iteration (moves values)
    let consumed: Vec<(String, i32)> = scores.into_iter().collect();
    println!("Consumed pairs: {:?}", consumed);

    // Iterator methods
    let total_score: i32 = scores.values().sum();
    let highest_score = scores.values().max();
    let count = scores.len();

    println!("Total: {}, Highest: {:?}, Count: {}", total_score, highest_score, count);
}
```

### Common HashMap Methods

```rust
use std::collections::HashMap;

fn main() {
    let mut map = HashMap::new();
    map.insert("Alice", 100);
    map.insert("Bob", 85);
    map.insert("Charlie", 92);

    // Length and capacity
    println!("Length: {}, Capacity: {}", map.len(), map.capacity());

    // Check if empty
    println!("Is empty: {}", map.is_empty());

    // Clear all entries
    map.clear();
    println!("After clear: {}", map.is_empty());

    // Rebuild for examples
    map.insert("Alice", 100);
    map.insert("Bob", 85);

    // Remove entries
    let alice_score = map.remove("Alice");
    println!("Removed Alice's score: {:?}", alice_score);

    let dave_score = map.remove("Dave");
    println!("Dave's score (nonexistent): {:?}", dave_score);

    // Remove with condition
    map.insert("Bob", 85);
    let removed = map.remove_entry("Bob");
    println!("Removed entry: {:?}", removed);

    // Retain entries matching predicate
    map.insert("Alice", 100);
    map.insert("Bob", 85);
    map.insert("Charlie", 92);

    map.retain(|_, &mut score| score >= 90);
    println!("After retaining >= 90: {:?}", map);  // Only Alice and Charlie
}
```

### HashMap with Custom Types

```rust
use std::collections::HashMap;

#[derive(Debug, Hash, Eq, PartialEq)]
struct Person {
    name: String,
    age: u32,
}

fn main() {
    let mut people = HashMap::new();

    let alice = Person {
        name: "Alice".to_string(),
        age: 30,
    };

    let bob = Person {
        name: "Bob".to_string(),
        age: 25,
    };

    people.insert(alice, "Engineer".to_string());
    people.insert(bob, "Designer".to_string());

    // Look up by key
    let search_person = Person {
        name: "Alice".to_string(),
        age: 30,
    };

    if let Some(job) = people.get(&search_person) {
        println!("Alice is a {}", job);
    }

    // Iterate over people
    for (person, job) in &people {
        println!("{:?} is a {}", person, job);
    }
}
```

### Advanced Patterns

```rust
use std::collections::HashMap;

fn main() {
    // Pattern 1: Counting occurrences
    let text = "the quick brown fox jumps over the lazy dog";
    let mut word_count = HashMap::new();

    for word in text.split_whitespace() {
        let count = word_count.entry(word).or_insert(0);
        *count += 1;
    }

    println!("Word counts: {:?}", word_count);

    // Pattern 2: Grouping by key
    let people = vec![
        ("Alice", "Engineering"),
        ("Bob", "Engineering"),
        ("Charlie", "Design"),
        ("Dave", "Design"),
        ("Eve", "Engineering"),
    ];

    let mut dept_groups: HashMap<&str, Vec<&str>> = HashMap::new();

    for (name, dept) in &people {
        dept_groups.entry(dept).or_insert(Vec::new()).push(name);
    }

    println!("Department groups: {:?}", dept_groups);

    // Pattern 3: Memoization/cache
    fn fibonacci(n: u64, cache: &mut HashMap<u64, u64>) -> u64 {
        if n <= 1 {
            return n;
        }

        if let Some(&result) = cache.get(&n) {
            return result;
        }

        let result = fibonacci(n - 1, cache) + fibonacci(n - 2, cache);
        cache.insert(n, result);
        result
    }

    let mut cache = HashMap::new();
    println!("Fibonacci 10: {}", fibonacci(10, &mut cache));
    println!("Cache size: {}", cache.len());
}
```

### HashMap vs Other Collections

**Use HashMap when:**
- Need key-value lookup (O(1) average)
- Keys are not sequential/integer-based
- Need associative array functionality
- Order doesn't matter

**Consider alternatives:**
- **BTreeMap**: When you need ordered keys or range queries
- **Vec**: For integer-indexed sequential access
- **HashSet**: When you only need keys (no values)

```rust
use std::collections::{HashMap, BTreeMap, HashSet};

fn main() {
    // HashMap: Unordered, fast lookup
    let mut hash_map = HashMap::new();

    // BTreeMap: Ordered keys, logarithmic operations
    let mut btree_map = BTreeMap::new();

    // HashSet: Only keys, no values
    let mut hash_set = HashSet::new();

    // All can store similar data
    hash_map.insert("Alice", 100);
    btree_map.insert("Alice", 100);
    hash_set.insert("Alice");

    println!("HashMap lookup: {:?}", hash_map.get("Alice"));
    println!("BTreeMap lookup: {:?}", btree_map.get("Alice"));
    println!("HashSet contains: {}", hash_set.contains("Alice"));
}
```

### Performance and Memory

```rust
use std::collections::HashMap;

fn main() {
    // Pre-allocate capacity for better performance
    let mut map: HashMap<String, i32> = HashMap::with_capacity(1000);

    for i in 0..1000 {
        map.insert(format!("key{}", i), i);
    }

    // Check load factor and capacity
    println!("Length: {}, Capacity: {}", map.len(), map.capacity());

    // Shrink to fit when done growing
    map.shrink_to_fit();
    println!("After shrink - Capacity: {}", map.capacity());

    // Reserve additional space
    map.reserve(100);
    println!("After reserve - Capacity: {}", map.capacity());
}
```

### Custom Hashers and Keys

```rust
use std::collections::HashMap;
use std::hash::{BuildHasherDefault, Hasher};

// Custom hasher (simple example)
#[derive(Default)]
struct SimpleHasher {
    state: u64,
}

impl Hasher for SimpleHasher {
    fn finish(&self) -> u64 {
        self.state
    }

    fn write(&mut self, bytes: &[u8]) {
        for &byte in bytes {
            self.state = self.state.wrapping_add(byte as u64);
        }
    }
}

// Using custom hasher
fn main() {
    let mut map: HashMap<String, i32, BuildHasherDefault<SimpleHasher>> = HashMap::default();

    map.insert("Alice".to_string(), 100);
    map.insert("Bob".to_string(), 85);

    println!("Map with custom hasher: {:?}", map);
}
```

### Common Gotchas

```rust
use std::collections::HashMap;

fn main() {
    let mut map = HashMap::new();

    // Gotcha 1: Keys are moved/consumed
    let key = String::from("hello");
    map.insert(key, 42);
    // key is no longer accessible

    // Gotcha 2: String literals vs String keys
    map.insert("world", 24);  // &str key (copied)
    println!("Can access 'world': {}", map.contains_key("world"));

    // Gotcha 3: Entry API for conditional inserts
    // Instead of:
    if !map.contains_key("new_key") {
        map.insert("new_key", 0);
    }
    // Use:
    map.entry("better_key").or_insert(0);

    // Gotcha 4: Iteration order is not guaranteed
    map.insert("a", 1);
    map.insert("b", 2);
    map.insert("c", 3);
    println!("Order may vary: {:?}", map.keys().collect::<Vec<_>>());

    // Gotcha 5: Floating point keys (not recommended)
    let mut float_map: HashMap<f64, String> = HashMap::new();
    float_map.insert(0.1 + 0.2, "not 0.3".to_string());  // Precision issues!
    println!("Float key issues: {:?}", float_map.get(&0.3));
}
```

**Note:** HashMap provides average O(1) lookup, insert, and delete operations. Keys must implement `Hash` and `Eq` traits. For ordered operations, consider `BTreeMap`. HashMaps are heap-allocated and automatically resize as needed. The iteration order is not guaranteed and may change between operations.
