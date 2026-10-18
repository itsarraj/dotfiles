# Ownership Internals: NLL, Reborrowing, Two-Phase Borrows, Variance, HRTB

Prerequisite: the systems-programming handbook's Ch 21 (ownership/borrowing/lifetimes as a MIR-stage dataflow analysis). This file goes one level deeper into the specific mechanisms that make the borrow checker usable in practice rather than maximally strict.

## Non-Lexical Lifetimes (NLL)

Pre-2018, a borrow's lifetime lasted until the end of its *lexical scope* (the enclosing `{}`), even if the last actual use was much earlier -- which rejected obviously-fine code:

```rust
let mut v = vec![1, 2, 3];
let first = &v[0];
println!("{first}");     // last use of `first`
v.push(4);                 // pre-NLL: ERROR -- `first`'s borrow "lasts" to end of scope
                             // NLL (2018+): fine -- the borrow checker's dataflow analysis
                             // sees `first` is dead after the println, so `v.push`
                             // has no live immutable borrow to conflict with
```

NLL made the borrow checker's liveness analysis match what MIR (handbook §9.2) actually makes visible: a reference is live from its creation until its **last actual use** on some control-flow path, not until its lexical scope closes. This is a real dataflow analysis (backward liveness, the same category of analysis a compiler's register allocator runs, handbook §9.5) over the MIR control-flow graph, not a syntactic scope rule -- which is exactly why it needed MIR to exist first: the CFG-shaped representation is what makes "last actual use on this path" a well-defined, computable question.

## Reborrowing

`&mut T` is not `Copy` -- but you routinely pass one to a function and keep using the original afterward:

```rust
fn push_val(v: &mut Vec<i32>, x: i32) { v.push(x); }

let mut v = vec![1, 2, 3];
let r: &mut Vec<i32> = &mut v;
push_val(r, 4);      // this looks like it MOVES r into push_val...
push_val(r, 5);       // ...but r is used again here. Why does this compile?
```

The compiler implicitly inserts a **reborrow**: `push_val(r, 4)` desugars to `push_val(&mut *r, 4)` -- a *new*, shorter-lived mutable borrow *of* `*r`, not a move of `r` itself. The reborrow's lifetime ends when `push_val` returns, at which point `r` is live again. This is invisible in source (no explicit `&mut *` needed at the call site) but is the actual mechanism that makes passing `&mut` references around by value ergonomic instead of requiring constant explicit reborrow syntax.

## Two-Phase Borrows

Before two-phase borrows, this rejected code that's obviously fine:

```rust
let mut vec = vec![1, 2, 3];
vec.push(vec.len());   // vec.len() needs &vec; vec.push(..) needs &mut vec --
                         // pre-2018: ERROR, can't have both live at once
```

**Two-phase borrows** split a mutable borrow's life into a *reservation* phase (the borrow exists, but hasn't been used mutably yet -- shared reads are still permitted) and an *activation* phase (the first actual mutable use, from which point ordinary exclusivity rules apply). `vec.push(vec.len())` reserves the `&mut vec` for `push`'s receiver argument, evaluates `vec.len()` (a shared borrow, legal during reservation), and only *activates* the mutable borrow once `push`'s body actually starts running. This is specifically a method-call-argument-evaluation-order accommodation, not a general relaxation of the one-mutable-XOR-many-immutable rule.

## Variance

Variance answers: if `Sub` is a subtype of `Super`, is `F<Sub>` a subtype of `F<Super>`? Rust's only subtyping relationship is between lifetimes (`'long: 'short` means `'long` outlives `'short`, so `&'long T` can be used where `&'short T` is expected) -- variance determines how that propagates through generic types.

| | Meaning | Example |
|---|---|---|
| **Covariant** | `F<'long>` is a subtype of `F<'short>` (same direction as the inner relationship) | `&'a T` is covariant in `'a` -- a `&'long str` can be used wherever `&'short str` is expected |
| **Contravariant** | `F<'short>` is a subtype of `F<'long>` (opposite direction) | `fn(&'a T)` is contravariant in `'a` -- a function accepting a *shorter*-lived reference is more flexible to substitute where a longer one is expected, because it promises to need the data for less time |
| **Invariant** | No subtyping relationship at all -- `F<'a>` and `F<'b>` are unrelated unless `'a == 'b` | `&'a mut T` is invariant in `T` (and in `'a`) |

`&mut T` must be invariant in `T` -- if it were covariant, this would compile and be unsound:

```rust
fn evil<'a>(r: &mut &'a str, s: &'a str) { *r = s; }
// if &mut T were covariant in T, you could pass a &mut &'static str
// where a &mut &'short str was expected, then assign a SHORTER-lived
// string through it, leaving the original 'static binding pointing
// at freed/shorter-lived data -- a real, exploitable unsoundness
```

`Cell<T>`/`UnsafeCell<T>` are also invariant in `T` for the same underlying reason: interior mutability means someone could write a different (but nominally "compatible" under covariance) lifetime's value through the shared reference, corrupting the original binding's assumed lifetime.

## Higher-Ranked Trait Bounds (HRTB)

```rust
fn apply<F>(f: F) where F: for<'a> Fn(&'a str) -> &'a str { /* ... */ }
```

`for<'a>` reads "for *any* lifetime `'a`" -- necessary because a plain `F: Fn(&'a str) -> &'a str` would require picking *one specific* `'a` at `apply`'s definition site, but the closure needs to work for *whatever* lifetime the caller's string happens to have, which isn't known until each call site. This shows up constantly, invisibly, in ordinary closure-taking APIs (`Iterator::filter`'s `Fn(&Self::Item) -> bool` is actually a HRTB under the hood) -- most Rust programmers use HRTBs daily without ever writing `for<'a>` explicitly, because the compiler infers and elides it in the overwhelmingly common cases; it only needs to be spelled out explicitly when a `where` clause can't otherwise express "this must work for every possible lifetime the caller supplies."

## Key Takeaways

- NLL, reborrowing, and two-phase borrows are all *ergonomics* work on top of the same one invariant (handbook §21.2) -- they make more *correct* programs compile, they never relax the underlying soundness rule itself.
- Variance is about whether lifetime substitution is safe to do implicitly -- `&mut T`'s invariance in `T` is a direct, necessary consequence of interior mutability being unsound to alias with a different effective lifetime.
- HRTBs exist because some generic bounds need to hold for *every* lifetime a caller might supply, not one fixed lifetime chosen at the definition site -- and you already use them constantly via closure-accepting standard library methods, whether or not you've ever written `for<'a>` by hand.

## Interview Notes

- "Why did NLL require MIR to exist first?" -- NLL's liveness analysis is a dataflow analysis over a control-flow graph; MIR is the first Rust-compiler IR shaped like an explicit CFG of basic blocks, which is what makes "is this reference used on any path after this point" a computable, well-defined question.
- "Why is `&mut T` invariant in `T` but `&T` covariant?" -- `&T` can't be used to write a shorter-lived value into a longer-lived binding (no mutation possible through it), so covariance is sound; `&mut T` can write through it, so allowing covariance would let a shorter-lived value get written into a binding the compiler believes is longer-lived -- a soundness hole.
