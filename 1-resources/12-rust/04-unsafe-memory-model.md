# Unsafe Rust and the Memory Model: Stacked Borrows, Provenance, Alias Analysis, and Pin

Prerequisite: handbook §19 (raw pointers, `MaybeUninit`, `transmute`), §34.2 (what UB means to an optimizer), §31.2 (Pin, briefly). This file formalizes what "the borrow checker's rules, extended to unsafe code" actually means, and gives Pin its full treatment.

## Why Rust Needs Its Own Memory Model At All

C's memory model (handbook §13's UB/strict-aliasing chapter) says nothing about references, borrowing, or exclusivity -- it only has pointers, with the narrow strict-aliasing rule as its sole aliasing-related constraint. Rust's *safe* subset has a much richer aliasing discipline (one mutable XOR many immutable, handbook §21.3) that the compiler wants to exploit for optimization (emitting `noalias` metadata to LLVM) -- but `unsafe` code routinely creates raw pointers *alongside* references to the same data. The open question **Stacked Borrows** answers: exactly when is that combination of a reference and a raw pointer to overlapping memory *actually* undefined behavior, versus merely unusual but fine?

## Stacked Borrows

The model (developed by Ralf Jung et al., implemented and checked by Miri, handbook §19.5) associates a conceptual **borrow stack** with every memory location: each time a reference or raw pointer is created *from* an existing one (a reborrow), a new tag is pushed onto that location's stack, representing the new pointer's claim to access it.

```
 let mut x = 5;
 let r1 = &mut x;        // push: stack = [Unique(r1)]
 let r2 = &mut *r1;       // reborrow -- push: stack = [Unique(r1), Unique(r2)]
 *r2 = 10;                 // access via r2 -- r2's tag is on top: OK
 *r1 = 20;                 // access via r1 -- r1's tag is NOT on top (r2's is) --
                             // this POPS r2's tag off (invalidating r2) and permits
                             // the access, since r1's tag is now exposed underneath
 // *r2 = 30;               // UB if used now -- r2's tag was popped; using r2 again
                             //   is exactly the "used a reference after a more-recent
                             //   reborrow invalidated it" bug Stacked Borrows exists
                             //   to catch
```

The practical payoff: Stacked Borrows gives a *precise, checkable* answer to "is this specific pattern of raw-pointer-plus-reference aliasing actually UB," rather than the vague "don't do anything weird" guidance C's aliasing rules leave you with. Miri implements this model and will report a Stacked-Borrows violation as a concrete error with a specific rule cited -- making it possible to *test* whether a piece of `unsafe` code is sound, rather than reasoning about it purely by hand. (A newer, related model -- **Tree Borrows** -- relaxes some of Stacked Borrows' stricter rejections while preserving the same soundness guarantees; both are actively maintained Miri backends as of this writing, reflecting that this is still an area of active research, not a fully settled question.)

## Provenance

A pointer is not *just* an integer address (handbook §10.2's simplified C model) -- in Rust's memory model, it also carries **provenance**: metadata recording which original allocation it's entitled to access, and (combined with Stacked Borrows) which tag in that allocation's borrow stack it currently holds. Two pointers can hold the *identical numeric address* and still not be interchangeable, if they carry different provenance:

```rust
let x: i32 = 5;
let y: i32 = 5;
let px = &x as *const i32;
// even if (by coincidence, or after some pointer-integer roundtrip) some other
// pointer py held the SAME numeric address as px, using py to access "x" would
// still be unsound if py's provenance doesn't trace back to x's allocation
```

This is precisely why an integer-to-pointer cast (`addr as *const T`) is a genuine problem for the model: the resulting pointer has an address but **no provenance** -- there's no allocation it's entitled to access. Rust's **strict provenance** APIs (`ptr.addr()`, `ptr.with_addr(new_addr)`, `ptr::from_exposed_addr` as a deliberately-named escape hatch) exist specifically to let code that needs to do integer arithmetic on addresses (common in allocators, and in the kind of low-level systems code this whole roadmap is aimed at) do so while keeping provenance well-defined -- `with_addr` takes an *existing, still-valid* pointer's provenance and combines it with a new address, rather than fabricating a provenance-less pointer from a bare integer.

## Alias Analysis and noalias

The borrow checker's guarantee (one mutable XOR many immutable, live at any point) is exactly the input LLVM's alias analysis wants: `rustc` emits `noalias` attributes on function parameters derived from `&mut T`/`&T`, telling LLVM's optimizer it may assume those pointers don't overlap with anything else the function can reach -- the identical optimization license C's `restrict` keyword grants manually, per pointer, per programmer promise (handbook §12.5) -- except here it's automatic and *proven*, not merely asserted. This is the concrete mechanism behind the claim (handbook §21.3) that ordinary Rust references get real optimization benefit from borrow-checking, not just a safety benefit.

## Interior Mutability and Freeze

`&T` being "read-only" is only true in the *absence* of interior mutability -- the compiler tracks this via the **`Freeze`** auto trait (unstable, but conceptually load-bearing): a type is `Freeze` if it contains no `UnsafeCell` anywhere in its structure. `&T` for a `Freeze` type genuinely cannot be used to mutate the pointee (backing real optimizations like assuming a value read through `&T` twice, with no intervening call, is unchanged); `&Cell<T>`/`&RefCell<T>`/`&Mutex<T>` are *not* `Freeze` (they contain `UnsafeCell` internally), which is the compiler's signal that reads through such a `&T` might observe a different value each time, defeating that specific optimization for exactly the types that need to defeat it.

## Pin, in Full

### The Problem

An `async fn`'s compiler-generated state machine (handbook §33) can be self-referential: a local variable borrowed across an `.await` point becomes a field holding a reference into an *earlier* field of the same generated struct.

```
 Generated state machine BEFORE being pinned:
 ┌─────────────────────┐
 │  buf: [u8; 256]        │  <- an earlier field
 ├─────────────────────┤
 │  buf_ref: &[u8]         │──┐ points INTO the struct's own `buf` field
 └─────────────────────┘  │
        ▲───────────────────┘
```

An ordinary Rust move is just a `memcpy` (handbook §21.2) -- moving this struct would copy `buf` to a new address but leave `buf_ref` pointing at the *old* address, a dangling reference the type system would otherwise have no way to catch, since nothing about `buf_ref`'s type reveals that it points at a sibling field rather than some independent allocation.

### The Guarantee

`Pin<P>` (where `P` is some pointer type, commonly `Pin<Box<T>>` or `Pin<&mut T>`) is a wrapper that, for a `T: !Unpin`, guarantees the pointee's memory address will **not change** for as long as it stays pinned -- specifically, it removes the ability to obtain an ordinary `&mut T` (which would let you `mem::swap` or otherwise move it out) without going through `unsafe` and explicitly re-asserting the pinning invariant still holds.

`Unpin` is (almost paradoxically named) an auto trait meaning "this type has **no** self-referential structure, so pinning it is unnecessary -- moving it is always fine." The overwhelming majority of types are `Unpin` automatically; only compiler-generated `async fn` state machines (and a few hand-written self-referential types) are `!Unpin`, and only *those* actually need `Pin`'s protection to be meaningful.

### Projection

Given a `Pin<&mut Struct>`, you often need a `Pin<&mut Field>` for one specific field -- but this is only sound if that field is *itself* never moved independently of the whole struct (moving one field out while leaving the rest pinned would violate the same guarantee at a finer grain). Manually writing this projection correctly requires `unsafe` and careful reasoning about exactly which fields are "structurally pinned" (must stay pinned along with the parent) versus safely projectable to an ordinary `&mut` (types like a plain `usize` counter field that has no self-referential relationship to anything). The `pin-project` crate exists specifically to generate this projection code correctly via a derive macro, so individual crates don't have to hand-write and re-verify the unsafe reasoning themselves every time they define a struct with a mix of pinned and unpinned fields.

### PhantomPinned

```rust
struct SelfReferential {
    data: String,
    ptr_to_data: *const String,
    _pin: std::marker::PhantomPinned,   // opts this struct OUT of the automatic Unpin impl
}
```

Since `Unpin` is auto-derived structurally (like `Send`/`Sync`, §02's auto-trait material) a hand-written self-referential struct would otherwise still end up `Unpin` (none of its literal fields are inherently `!Unpin`) unless it explicitly includes a `PhantomPinned` marker field -- the zero-sized-type signal that tells the compiler "treat this as if it required pinning," the same `PhantomData`-flavored trick §03 covers for variance/drop-check, applied here to opt out of an auto trait instead.

## Key Takeaways

- Stacked Borrows gives a precise, Miri-checkable answer to when raw-pointer/reference aliasing in `unsafe` code is actually UB -- replacing "don't do anything weird" with a concrete, testable model.
- Provenance means a pointer is address-plus-origin-metadata, not just an address -- which is exactly why integer-to-pointer roundtrips need the strict-provenance API (`with_addr`) to stay well-defined.
- Borrow-checker-derived `noalias` metadata is the same optimization license C's `restrict` grants manually -- Rust references get it automatically and provably, not by unenforced programmer promise.
- `Pin` exists for exactly one class of problem (compiler-generated self-referential `async fn` state machines) -- most types are, correctly, `Unpin` and never need to think about it.

## Interview Notes

- "What specific problem does Stacked Borrows solve that C's aliasing rules don't address?" -- it formalizes exactly when a raw pointer and a reference to overlapping memory can coexist safely versus when using one invalidates the other, a question C's much narrower strict-aliasing rule (about *type-based* aliasing only) never asks.
- "Why can't you just cast an arbitrary integer to a pointer and dereference it safely, even if the address happens to be valid memory?" -- the resulting pointer has an address but no provenance -- it isn't recognized as entitled to access any particular allocation, which is why the strict-provenance APIs require deriving the new pointer from an existing, validly-provenanced one instead.
