# Standard Library Internals: Vec, String, HashMap, BTreeMap, and the Rest

Prerequisite: §05 (smart pointer internals -- `Arc`/`Mutex`/etc. covered there aren't repeated here beyond a pointer back). Handbook §24/§7.1 already covers `Vec`/`HashMap` basics; this file is the "read the source until you can explain it" pass the roadmap explicitly asks for.

## Vec\<T\>

```rust
pub struct Vec<T> { buf: RawVec<T>, len: usize }
struct RawVec<T> { ptr: NonNull<T>, cap: usize }
```

`RawVec` is the actual allocation-owning core -- `Vec` itself just adds a `len` on top of "an owned, growable buffer." Growth is **amortized doubling**: when `push` finds `len == cap`, it reallocates to (typically) `2 * cap` -- doubling means the *total* cost of growing from empty to `n` elements across all the reallocations is `O(n)`, not `O(n²)`, even though any single reallocation copies the existing elements (the classic amortized-analysis argument: each element is copied at most a bounded number of times across all its "growth" events, roughly `log(n)` times total in the worst case, summed geometrically to `O(n)`). `Vec::with_capacity(n)` sidesteps the doubling schedule entirely when the final size is known upfront, avoiding the intermediate reallocations altogether -- a real, common, worthwhile optimization for hot paths building a `Vec` of predictable size. `reserve`/`shrink_to_fit` occasionally trigger a **realloc-in-place** optimization (the allocator extends the existing block without moving it, when there happens to be free space immediately adjacent) -- not guaranteed, but when it happens it avoids the copy entirely, which is invisible from the `Vec` API but a real allocator-level win worth knowing exists.

## String

```rust
pub struct String { vec: Vec<u8> }
```

Literally a `Vec<u8>` with one additional, compiler-enforced invariant: its contents are always valid UTF-8. Every mutating method (`push_str`, `push`, `insert`) either only ever appends valid UTF-8 fragments or validates the input first (`String::from_utf8` returns a `Result`, rejecting invalid input rather than constructing a `String` that would violate the invariant) -- this is exactly why `unsafe fn from_utf8_unchecked` exists as a separate, explicitly-`unsafe` escape hatch: it skips the validation, and it's on the *caller* to uphold the invariant the type's safety otherwise guarantees. Indexing a `String` by byte offset (`&s[0..5]`) panics if that offset doesn't fall on a UTF-8 **char boundary** (some multi-byte characters span several bytes; slicing into the middle of one would produce invalid UTF-8) -- this is the concrete, checked mechanism preventing the exact class of bug an unchecked byte-offset slice into a UTF-8 buffer could otherwise silently produce.

## HashMap (hashbrown / SwissTable)

Rust's `std::collections::HashMap` is, since 2019, a thin wrapper around the `hashbrown` crate's implementation of Google's **SwissTable** design -- a genuinely different internal strategy than the separate-chaining most textbook/naive hash map implementations (and C++'s typical `std::unordered_map`) use:

```
 Simplified SwissTable layout:
 control bytes:  [ H2(k1) | H2(k2) | EMPTY | DELETED | H2(k4) | ... ]  <- one byte per slot
 slots:           [ (k1,v1) | (k2,v2) |   -    |    -     | (k4,v4) | ... ]
```

Each slot has a corresponding **control byte** storing a 7-bit hash fragment (`H2`) plus 1 bit distinguishing "full"/"empty"/"deleted" -- and probing for a key compares its `H2` fragment against **16 control bytes at once** using SIMD instructions (handbook §2.4), rather than one slot at a time as chaining-based probing does. This turns "is this key even plausibly in this group of slots" into one wide SIMD comparison producing a bitmask of candidate slots, only *then* falling back to an actual key-equality check on the (typically very few) candidates that bitmask flags -- dramatically better cache behavior (handbook §37.1: control bytes for many slots fit in one cache line, checked together, rather than following pointers to scattered per-bucket chain nodes) and dramatically fewer full key comparisons than naive chaining. **Deletion** uses a **DELETED** (tombstone) marker rather than truly emptying the slot immediately -- necessary because probing for a *different* key might need to continue past this slot's position (an EMPTY marker would incorrectly terminate the probe early, since EMPTY specifically means "no key was ever placed at or after this point in the probe sequence") -- tombstones are only reclaimed in bulk during a table resize/rehash.

## HashSet

```rust
pub struct HashSet<T> { map: HashMap<T, ()> }
```

Exactly what it looks like -- a `HashMap` where the value type is the zero-sized `()`, so no space is spent on values at all beyond the keys themselves and hashbrown's control-byte overhead.

## BTreeMap

Internally an actual B-tree (handbook §11's storage-engine material, applied here as an in-memory rather than on-disk structure) with a branching factor around 11 in the standard library's implementation -- chosen deliberately over a binary search tree (red-black tree, etc.) specifically for **cache-friendliness** (handbook §37.1): a B-tree node packs multiple keys contiguously, so a single cache-line fetch (or a few) examines several keys at once via a linear/binary scan *within* the node, versus a binary tree's one-key-per-node-plus-pointer-chase-to-the-next layout, which faults a new, likely-uncached memory location on essentially every comparison. This is precisely why `BTreeMap` frequently outperforms a naive binary-search-tree-based ordered map in practice, for exactly the same structural reason a B-tree beats a binary tree for on-disk indexes (§11) -- the "unit of transfer" is just a cache line instead of a disk page, but the high-fanout-minimizes-hops argument is identical.

## BinaryHeap

A **binary heap** (complete binary tree, heap-order invariant: every parent ≥ its children for a max-heap) stored flat in a `Vec<T>`, using the classic array-indexing trick (a node at index `i` has children at `2i+1` and `2i+2`, no pointers needed at all) -- `push` appends then **sifts up** (swaps with its parent repeatedly while it violates heap order), `pop` swaps the root with the last element, removes the last element (which was the actual minimum/maximum), then **sifts down** the new root into its correct position. Both operations are `O(log n)`, and the flat `Vec` backing means, again, far better cache behavior than a pointer-based tree representation would give for the same logical structure.

## Iterator, Default Methods, and Fusion

```rust
pub trait Iterator {
    type Item;
    fn next(&mut self) -> Option<Self::Item>;   // the ONE required method
    // map, filter, fold, zip, enumerate, take, skip, ... all have DEFAULT
    // implementations expressed purely in terms of next() -- a type only
    // needs to implement next() to get the entire adaptor ecosystem for free
}
```

Every other `Iterator` method has a default implementation built purely on repeated calls to `next()` -- implementing one four-line `next()` method is genuinely sufficient to inherit dozens of adaptor methods, which is the concrete mechanism behind how thin custom iterators (over a database cursor, a parser's token stream, anything) get the *entire* `map`/`filter`/`fold`/`zip`/... ecosystem essentially for free. `FusedIterator` is a marker trait signaling that once an iterator returns `None` once, it will *always* return `None` on every subsequent call -- a property not universally guaranteed (a poorly-behaved iterator could technically resume producing items after a `None`), but one the optimizer can exploit for iterators known to have it (skipping redundant `is_some` checks in adaptor chains that would otherwise need to keep calling `next()` defensively after the first `None`).

## VecDeque

A **ring buffer**: a fixed-capacity backing array plus `head`/`tail` indices that wrap around modulo the capacity, giving `O(1)` push/pop at *both* ends (unlike `Vec`, which is `O(1)` only at the end and `O(n)` at the front, since removing from the front would otherwise require shifting every remaining element). This is exactly why `VecDeque` is the standard choice for anything needing an efficient queue (FIFO) or double-ended queue behavior -- `Vec` structurally cannot offer `O(1)` front operations without becoming a different data structure.

## LinkedList

A genuine doubly-linked list -- and the standard library's own documentation explicitly steers users away from it for most use cases, for reasons directly traceable to handbook §37.1's cache-friendliness principle: each node is an independent heap allocation, scattered arbitrarily in memory, so traversal faults a new, likely-uncached cache line on essentially every step -- `Vec`/`VecDeque` (contiguous, cache-friendly) outperform `LinkedList` for the overwhelming majority of real workloads, *even* for operations (arbitrary-position insertion/removal) that `LinkedList`'s Big-O complexity suggests it should win at, simply because the constant-factor cache-miss cost dominates for realistic list sizes. `LinkedList` remains useful specifically when you need to **split or splice** large sublists in O(1) (moving a contiguous run of elements from one list to another without touching the elements themselves) -- a genuinely rare requirement in practice, which is why it's very much a "know it exists, and know specifically why it's usually the wrong default" entry rather than a general-purpose recommendation.

## Key Takeaways

- `Vec`'s amortized-doubling growth strategy is what makes `push` amortized `O(1)` despite occasional `O(n)` reallocation -- and `with_capacity` sidesteps the whole schedule when the final size is known.
- `HashMap`'s SwissTable design (control bytes, SIMD-width probing, tombstone deletion) is a genuinely different implementation strategy than naive chaining, not just an API-compatible drop-in -- the cache-friendliness payoff is real and measurable.
- `BTreeMap` and on-disk B-trees (§11) share the exact same "high fanout minimizes hops through a slow storage tier" argument, just applied to cache lines instead of disk pages.
- `LinkedList`'s Big-O advantages are real but rarely matter in practice against `Vec`/`VecDeque`'s cache-friendliness -- a case where asymptotic complexity and real-world performance diverge, and the standard library's own docs say so directly.

## Interview Notes

- "Why is `Vec::push` described as amortized O(1) rather than just O(1)?" -- most calls are O(1) (room already exists), but occasionally a call triggers a full reallocation and copy (O(n)) -- doubling the capacity each time bounds the *total* copying work across all reallocations to O(n) overall, which spread across n pushes averages out to O(1) per push.
- "Why does `HashMap`'s SwissTable design outperform simple separate chaining, mechanically?" -- it checks 16 control bytes at once via SIMD to find plausible candidate slots before doing any real key comparison, keeping the hot probing path within one or two cache lines instead of chasing pointers through scattered per-bucket chain nodes.
