# Generics Deep Dive: Monomorphization Costs, Type Inference, PhantomData, Const Generics

Prerequisite: handbook §9.1/§26/§35.4 (monomorphization mechanics and the C++ template comparison). This file covers the practical consequences and the two features (`PhantomData`, const generics) that let generics express things ordinary type parameters can't.

## Monomorphization's Real Cost: Code Bloat

Every distinct concrete instantiation of a generic function/type produces a **separate compiled copy** (handbook §9.1) -- for a function called with 20 different types, that's 20 independent copies of the function body in the final binary, each individually eligible for inlining/optimization, but also each individually taking up code size (`.text`, handbook §7.2) and each individually needing to be compiled (real, measurable build-time cost for generic-heavy crates).

**Mitigation pattern**: extract the type-independent part of a generic function into a non-generic inner function, and have the generic wrapper just adapt types at the boundary:

```rust
// BEFORE: the entire body is monomorphized once per T
fn process<T: AsRef<str>>(items: &[T]) -> usize {
    items.iter().map(|s| s.as_ref().len()).sum()
}

// AFTER: only the thin generic shim is monomorphized per T; the real work
// compiles ONCE regardless of how many concrete T's call process()
fn process<T: AsRef<str>>(items: &[T]) -> usize {
    fn process_inner(items: &[&str]) -> usize {
        items.iter().map(|s| s.len()).sum()
    }
    let refs: Vec<&str> = items.iter().map(|t| t.as_ref()).collect();
    process_inner(&refs)
}
```

This exact pattern is how the standard library keeps generic-heavy APIs (`Vec<T>`'s internals, formatting machinery) from bloating every binary that uses them -- push as much logic as possible into a `dyn`-erased or concretely-typed inner function, and keep the generic surface as a thin adapter.

## Type Inference

Rust's inference is **local** -- it infers types within a function body (and across a chain of method calls via the types those methods are declared to return) but never infers a function's own signature from its body, and never infers across function boundaries the way some ML-family languages' full Hindley-Milner inference does. This is a deliberate design choice: fully-general HM inference over a language with subtyping-via-lifetimes, trait resolution, and coercions becomes both dramatically slower to compute and dramatically harder for a human to predict ("what type did the compiler infer here" needs to stay locally answerable by reading nearby code, not by tracing inference through arbitrarily distant call sites) -- which is why every `fn` item requires explicit parameter and return types even though the body's local `let` bindings usually don't.

## PhantomData

A zero-sized type (handbook's ZST material) that exists purely to tell the compiler "treat this struct as if it owned/borrowed a `T`," for cases where no field of type `T` (or `&T`) actually exists in the struct but the *variance* and *drop-check* behavior of owning one still needs to apply:

```rust
struct Slice<'a, T> {
    ptr: *const T,             // a raw pointer carries no lifetime/ownership information
    len: usize,
    _marker: PhantomData<&'a T>,  // tells the compiler: behave as if this struct
}                                  // holds a &'a T -- covariant in 'a and T, and
                                    // the borrow checker will correctly reject a
                                    // Slice outliving the data it points into
```

Without the `PhantomData` field, the compiler would have no basis for assigning `Slice<'a, T>` sensible variance (§01's variance material) or for including it in drop-check analysis (whether dropping a `Slice` could run a destructor that observes already-freed `'a`-borrowed data) -- raw pointers themselves carry none of that information. `PhantomData<T>` (owning, not borrowing) is the equivalent move for "this struct is conceptually responsible for a `T`'s destruction," relevant for custom collection types built on raw pointers/allocations that manage a `T`'s lifecycle manually (e.g. a hand-rolled `Vec`-like type) but store it as `*mut T` rather than `T` directly.

## Const Generics

Generic parameters over *values*, not just types -- most commonly array lengths:

```rust
struct Matrix<const ROWS: usize, const COLS: usize> {
    data: [[f64; COLS]; ROWS],
}

impl<const ROWS: usize, const COLS: usize> Matrix<ROWS, COLS> {
    fn zero() -> Self { Self { data: [[0.0; COLS]; ROWS] } }
}

let m: Matrix<3, 4> = Matrix::zero();   // ROWS and COLS are compile-time constants,
                                          // monomorphized exactly like a type parameter --
                                          // Matrix<3,4> and Matrix<4,3> are DIFFERENT,
                                          // separately-compiled types
```

Before const generics, working generically over array length required either giving up on fixed-size arrays entirely (falling back to `Vec<T>`, losing the stack-allocation and size-known-at-compile-time properties) or implementing a trait separately for every needed length (a genuinely common pre-2021 workaround: manual trait impls for `[T; 0]` through `[T; 32]`, mechanically generated by a macro, because there was no way to abstract over "any array length" at all). Const generics close this by letting `usize` (and other simple types) values participate in generics on equal footing with types -- monomorphized per distinct value exactly as a type parameter is monomorphized per distinct type, with the same code-size tradeoff discussed above.

## Key Takeaways

- Monomorphization's code-bloat cost is real and addressable -- extracting a non-generic inner function is the standard mitigation, used throughout the standard library itself.
- Rust's type inference is deliberately local, not fully Hindley-Milner -- every function signature is explicit specifically so "what type is this" stays answerable without tracing inference across the whole call graph.
- `PhantomData` exists to give the compiler variance/drop-check information about a relationship (ownership or borrowing of a `T`) that isn't otherwise visible from the struct's actual fields (typically because those fields are raw pointers).
- Const generics extend monomorphization to compile-time *values*, not just types -- solving the "generic over array length" problem that previously required per-length trait impls or giving up fixed-size arrays.

## Interview Notes

- "Why might a heavily generic Rust crate have a surprisingly large compiled binary?" -- monomorphization compiles a full separate copy of each generic function/type per distinct set of type arguments actually used -- code size scales with the number of instantiations, not just the amount of generic source code written.
- "What problem does `PhantomData` solve, concretely?" -- it tells the compiler to treat a struct as owning/borrowing a `T` for variance and drop-check purposes, needed whenever the actual relationship is expressed through a raw pointer (which carries none of that information itself) rather than a typed field.
