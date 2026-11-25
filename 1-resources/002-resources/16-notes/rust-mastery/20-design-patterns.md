# Advanced Rust Design Patterns: Typestate, Newtype, Phantom Types, Arena, ECS

Prerequisite: §03/§04 (PhantomData, ZSTs), §05 (RAII/Drop). This file is a catalog of patterns that use Rust's type system to move a runtime concern into compile-time checking -- the same general move as ownership/borrowing itself (handbook §34.1), applied by library/application authors rather than baked into the language.

## Typestate

Encode a value's **protocol state** into its *type*, so that calling a method invalid for the current state is a compile error rather than a runtime panic/error:

```rust
struct Connection<State> { socket: TcpStream, _state: PhantomData<State> }
struct Disconnected; struct Connected; struct Authenticated;

impl Connection<Disconnected> {
    fn connect(self) -> Connection<Connected> { /* ... */ }
}
impl Connection<Connected> {
    fn authenticate(self, creds: Creds) -> Connection<Authenticated> { /* ... */ }
}
impl Connection<Authenticated> {
    fn send(&self, data: &[u8]) { /* only callable once actually authenticated */ }
}
// Connection<Disconnected>::send() doesn't exist -- calling send() before
// authenticate() is a COMPILE ERROR, not a runtime "not authenticated" error
```

Each transition consumes `self` and returns a *different-typed* `Connection`, so a value literally cannot exist in an invalid combination of "state" and "available methods" -- this is `PhantomData` (§03) used specifically to attach a zero-runtime-cost type-level tag distinguishing otherwise-identical structs, and it's the general pattern behind `Pin`'s `Unpin`/`!Unpin` split (§04) and the OCI container lifecycle's create/start state modeling (handbook §48.1) alike -- protocol correctness pushed to compile time wherever the full state machine is known statically.

## Newtype

Wrapping an existing type in a single-field tuple struct, purely to give it a **distinct type identity**:

```rust
struct UserId(u64);
struct ProductId(u64);

fn get_user(id: UserId) { /* ... */ }
// get_user(ProductId(5))  -- COMPILE ERROR, even though both are "just a u64" underneath
```

Solves the "primitive obsession" bug class where two semantically unrelated `u64` parameters can be silently swapped at a call site with no compiler complaint -- the newtype wrapper costs nothing at runtime (a `#[repr(transparent)]` single-field struct has identical layout to its inner type) while making an entire class of argument-order mistakes a compile error. It's also the standard, idiomatic way around Rust's **orphan rule** (you can't `impl ExternalTrait for ExternalType` -- but wrapping `ExternalType` in your own newtype gives you a type you *do* locally own, which you can implement any trait for).

## Marker Traits and Zero-Sized Types

A trait with no methods at all, existing purely to *tag* a type for the compiler/other trait bounds to check against -- `Send`/`Sync`/`Sized`/`Copy` (handbook §02's auto-trait material) are the standard library's own examples. A **zero-sized type (ZST)** (`struct Marker;`, or `PhantomData<T>` itself) occupies zero bytes at runtime -- the compiler doesn't even need to allocate space for it, and a `Vec<ZST>` is a real, if unusual, working construct (no actual heap allocation needed at all, since there's nothing to store per element beyond the count) -- ZSTs are how typestate's `PhantomData<State>` field and marker-trait-bearing wrapper types cost genuinely nothing at runtime despite existing as real, distinct types the compiler tracks.

## Interior Mutability and Self-Referential Types, Revisited

§04/§05 already covered `Cell`/`RefCell`/`UnsafeCell` and `Pin`'s self-referential-struct problem in full detail -- worth restating here as *design patterns in their own right*, not just language mechanisms: reaching for interior mutability is a deliberate choice to move a specific invariant from compile-time-checked to runtime-checked (or, for `Cell`, entirely unchecked-but-provably-safe due to single-threaded-only access) precisely because the surrounding design (a graph with back-references, a builder pattern needing to mutate shared state during construction) doesn't fit the borrow checker's flow-sensitive analysis -- and recognizing *that* tradeoff explicitly, rather than reaching for `RefCell` reflexively, is the actual skill.

## Arena Allocation

Covered mechanically in handbook §5.5 -- worth restating as a *design* pattern: an arena (`bumpalo` or a hand-rolled equivalent) is the right choice specifically when a batch of objects share one clear lifetime scope (all allocated during, and all freed together at the end of, processing one request, one AST-parsing pass, one game-simulation frame) -- trading the ability to free objects individually for both allocation speed (a bump allocator's `alloc` is just a pointer increment, no free-list search at all) and, often, a much simpler ownership story (everything in the arena has exactly one collective lifetime, sidestepping what might otherwise require a tangle of individual `Rc`/`RefCell`-based shared ownership just to model a graph-shaped structure that's really just "all these things live and die together").

## ECS (Entity Component System)

A data-oriented architecture (common in game engines, e.g. Rust's `bevy`) that deliberately inverts typical object-oriented composition: rather than each "entity" being an object bundling its own data and behavior, an entity is just an ID; **components** are plain data (position, velocity, health) stored in separate, contiguous arrays *indexed by* entity ID (not embedded inside per-entity objects); and **systems** are functions operating over *all* entities that have a particular combination of components, iterating those components' arrays directly. This is a direct, deliberate application of handbook §37.1's cache-friendliness principle at the architectural level: iterating "every entity's position component" as one tight, contiguous array scan is dramatically more cache-friendly than following a pointer-chasing traversal through scattered, heterogeneous per-entity objects that happen to also contain a position field buried among unrelated data -- ECS trades the OOP-familiar "object bundles its own data and methods" ergonomics for a data layout specifically optimized for the "iterate this one kind of data across everything, every frame" access pattern that a real-time simulation loop actually has.

## Key Takeaways

- Typestate, newtype, and marker traits/ZSTs are all instances of the same underlying move: push a runtime invariant (protocol ordering, unit confusion, capability tagging) into the type system, at zero runtime cost, so the compiler rejects violations instead of a test suite or production incident catching them later.
- Interior mutability and arena allocation are both *deliberate, situational* tradeoffs (runtime-checked flexibility, or collective-lifetime simplicity) rather than defaults -- recognizing when the surrounding design actually calls for them, versus reaching for them reflexively, is the real skill being tested.
- ECS is cache-friendliness (handbook §37.1) elevated to an architectural principle -- component-arrays-indexed-by-entity-ID exists specifically to make "iterate one kind of data across everything" a tight sequential scan instead of a pointer-chasing traversal.

## Interview Notes

- "What problem does the typestate pattern solve that a runtime state-check (an enum field plus an `if` at the top of each method) doesn't?" -- it turns an invalid-operation-for-current-state bug from a runtime error (or, if forgotten, a silent bug) into a compile error -- the invalid call simply has no corresponding method to call at all, for that state's type.
- "Why does an ECS architecture store components in arrays-by-type rather than bundled per-entity?" -- so that a system operating on one component type across every entity performs one contiguous, cache-friendly array scan, instead of chasing pointers through scattered, heterogeneous per-entity objects to reach the one field it actually needs from each.
