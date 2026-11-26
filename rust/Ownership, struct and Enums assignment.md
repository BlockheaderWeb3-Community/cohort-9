# Understanding Structs, Enums, and Ownership in Rust

This document breaks down three core pillars of the Rust programming language: **Structs**, **Enums**, and **Ownership**.

---

## 1. Ownership: Rust’s Memory Management Core

Ownership is Rust’s unique system for managing memory safely and efficiently without needing a garbage collector or manual memory allocation. It relies on three strict rules enforced at compile time.

### The Three Rules of Ownership
1. Every value in Rust has a variable that is called its **owner**.
2. There can only be **one owner** at a time.
3. When the owner goes out of scope, the value is automatically dropped and memory is freed.

How Data Moves vs. Borrows

#### Ownership Transfers (Moves)
When you assign a heap-allocated variable (like a `String`) to another variable, ownership transfers. The original variable becomes invalid.

  EXAMPLE
  
let s1 = String::from("Rust");
let s2 = s1; // Ownership moves to s2

// println!("{}", s1); // Compile Error! s1 is no longer valid.







Borrowing with References

Instead of transferring ownership, you can lend data using references (&).

Immutable References (&T): Allows reading data without taking ownership. You can have multiple immutable references at the same time.

Mutable References (&mut T): Allows modifying the borrowed data. However, to prevent data races, you can only have one active mutable reference at a time in a given scope.

Rust
fn calculate_length(s: &String) -> usize {
    s.len()
} // s goes out of scope, but because it's a reference, the underlying String isn't dropped.



2. Structs: Grouping Related Data
A Struct (structure) is a custom data type that lets you bundle multiple related values under a single named type.

Defining and Instantiating
Structs are defined with named fields to give structure to complex data.

Rust
struct Developer {
    name: String,
    language: String,
    years_experience: u8,
    is_active: bool,
}

fn main() {
    let dev = Developer {
        name: String::from("Kennedy"),
        language: String::from("Rust"),
        years_experience: 1,
        is_active: true,
    };
}
Adding Methods with impl Blocks
You can define methods attached to a struct using an implementation (impl) block.

Methods use &self to read struct data.

Methods use &mut self to modify struct data.

Rust
impl Developer {
    // Constructor-like associated function
    fn new(name: String, language: String) -> Self {
        Self {
            name,
            language,
            years_experience: 0,
            is_active: true,
        }
    }

    // Method reading struct data
    fn profile(&self) {
        println!("{} builds with {}.", self.name, self.language);
    }
}


3. Enums: Enumerating Possibilities
An Enum (enumeration) defines a custom type that can represent one of a fixed set of possibilities, known as variants.

Basic Enums & Data Payloads
Unlike enums in many other languages, Rust enums can embed data directly inside each variant.

Rust
enum NetworkStatus {
    Connecting,
    Connected(String), // Stores an IP address or URL
    Disconnected { reason: String, code: u16 }, // Stores detailed error payload
}
Pattern Matching with match
Rust forces you to handle every variant when evaluating an enum using match, ensuring no unexpected runtime cases occur.

Rust
fn handle_status(status: NetworkStatus) {
    match status {
        NetworkStatus::Connecting => println!("Establishing connection..."),
        NetworkStatus::Connected(ip) => println!("Connected to {}", ip),
        NetworkStatus::Disconnected { reason, code } => {
            println!("Disconnected (Error {}): {}", code, reason);
        }
    }
}
Core Built-in Enums
Rust avoids traditional null errors by replacing them with powerful built-in enums:

Option<T>: Represents either a value (Some(T)) or nothing (None).

Result<T, E>: Used for operations that can fail, returning success (Ok(T)) or error (Err(E)).





4. `String` vs `&str`: Managing Text Data

In Rust, string handling is split between two main types depending on how memory is managed: **`String`** and **`&str`** (string slice).

1. `String` (Heap-Allocated, Owned, Dynamic)
* **What it is:** An owned, growable, UTF-8 encoded text buffer stored on the heap.
* **When to use:** Use `String` when you need to own the text data, mutate it, append characters, or construct text dynamically at runtime.

```rust
let mut owned_string = String::from("Hello");
owned_string.push_str(", World!"); // Can be modified


2. &str (String Slice, Borrowed, Fixed-Size)

What it is: An immutable view or reference pointing to a sequence of UTF-8 data stored elsewhere in memory (on the heap, stack, or hardcoded in the binary as a literal).
When to use: Use &str as function parameter types when you only need to read string data without taking ownership.Rustlet slice: &str = "Hello, World!"; // String literal stored in read-only binary memory


Key Differences Summary

### Key Differences Summary

* **Memory Allocation:**
  * `String`: Allocated dynamically on the heap.
  * `&str`: Points to memory stored elsewhere (heap, stack, or binary).

* **Ownership:**
  * `String`: Owned by the variable (freed when out of scope).
  * `&str`: Borrowed reference (does not own the underlying data).

* **Mutability:**
  * `String`: Can be modified when declared as mutable (`mut String`).
  * `&str`: Always an immutable view of text.

* **Performance:**
  * `String`: Requires dynamic heap allocation on creation.
  * `&str`: Zero-cost reference passing for fast execution.

  
    5. The Option Enum: Handling Absence of Values
Rust does not feature null or nil values, preventing common Null Pointer Exceptions at runtime. 
Instead, Rust handles the concept of a value being present or absent using the built-in Option<T> enum.

Definition
The Option enum is defined in the standard library with two variants:

Rust
enum Option<T> {
    Some(T), // Contains a valid value of type T
    None,    // Represents no value
}


Practical Usage


Rustfn find_user_id(username: &str) -> Option<u32> {
    if username == "Kennedy" {
        Some(101) // User found
    } else {
        None      // User does not exist
    }
}

fn main() {
    let result = find_user_id("Kennedy");

    // Pattern matching forces developer to handle both cases explicitly
    match result {
        Some(id) => println!("Found User ID: {}", id),
        None => println!("User not found."),
    }
}

Summary
Ownership manages memory safely at compile time through strict borrowing rules without requiring a garbage collector.

Structs organize related properties and methods together under a unified type.

Enums represent a fixed choice between distinct variants, capable of holding dynamic payloads and enforced safely via pattern matching.
