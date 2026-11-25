# Traits Deep Dive: Associated Types, GATs, Object Safety, Auto Traits, Specialization

Prerequisite: handbook Ch 26 (monomorphization, static vs. dynamic dispatch, the vtable mechanism shared with C++). This file covers the trait-system machinery underneath that comparison.

## Associated Types vs. Generic Parameters

```rust
trait Iterator {
    type Item;                      // associated type -- ONE Item type per impl
    fn next(&mut self) -> Option<Self::Item>;
}

trait Converter<T> {                 // generic parameter -- MULTIPLE impls per type possible
    fn convert(&self) -> T;
}
```

Rule of thumb: use an associated type when a type has *exactly one* sensible choice per implementor (a given iterator only ever yields one kind of item -- `impl Iterator<Item=T>` and `impl Iterator<Item=U>` for the same concrete type would be nonsensical); use a generic parameter when a type could reasonably implement the trait multiple times for different type arguments (`From<i32> for MyNum` and `From<f64> for MyNum` coexisting is normal and desired). This is also why `Iterator::Item` doesn't need `Iterator<Item=T>` turbofish-style disambiguation at every call site the way a generic-parameter version would.

## Generic Associated Types (GATs)

An associated type that itself takes generic parameters -- most commonly a lifetime, unlocking associated types that borrow from `&self`:

```rust
trait LendingIterator {
    type Item<'a> where Self: 'a;                    // parameterized by the borrow's lifetime
    fn next<'a>(&'a mut self) -> Option<Self::Item<'a>>;
}
```

Without GATs, `Item` would have to be a single fixed type independent of any particular call's borrow -- which makes it impossible to express "the yielded item borrows from `self` for exactly as long as this specific call's `&mut self` borrow lasts" (ordinary `Iterator::next(&mut self) -> Option<Self::Item>` can *only* yield owned or `'static`-bound data, or data borrowed from somewhere *other* than `self`, because `Item` has no way to reference the per-call lifetime). GATs close this gap -- the canonical motivating example is exactly a "lending iterator" that yields a mutable view into its own internal buffer, reused across calls, which the standard `Iterator` trait structurally cannot express.

## Trait Objects and Object Safety

Not every trait can back a `dyn Trait` (handbook §14.3/§26's vtable mechanism) -- a trait is **object-safe** only if every method satisfies:

- No generic type parameters on the method itself (a vtable has a fixed number of slots -- it can't have "one slot per possible instantiation" of an unbounded generic).
- Doesn't return `Self` by value (the vtable's caller doesn't statically know the concrete `Self` type's size to allocate space for the return).
- `Self` isn't taken by value unless the method opts out via `where Self: Sized` (same reasoning -- a `dyn Trait` value has no statically known size, so a by-value `self` parameter is unconstructable through it).
- No associated constants (nothing to put in a vtable *slot* for a compile-time constant -- constants aren't dispatched, they're substituted).

```rust
trait Clone {
    fn clone(&self) -> Self;    // returns Self by value -- NOT object-safe
}
// dyn Clone doesn't exist; this is exactly why Box<dyn Trait + Clone> patterns
// need a separate helper trait (a common workaround: a `clone_box(&self) -> Box<dyn Trait>`
// method that IS object-safe, implemented via a blanket impl over T: Clone + Trait)
```

## Auto Traits

`Send`, `Sync`, `Unpin`, `Sized`, and (unstably) a few others are **auto traits**: implemented automatically for a type based purely on its structure -- a struct is `Send` if and only if every field is `Send`, with no explicit `impl Send for MyStruct {}` ever written for the ordinary case. This structural, compiler-derived nature is exactly what makes `Send`/`Sync` (handbook §30) a *whole-program* guarantee rather than something each type author has to remember to opt into -- a single non-`Send` field anywhere in a struct's transitive composition makes the whole struct non-`Send`, automatically, with no action required from whoever wrote the outer struct.

## Blanket Implementations

```rust
impl<T: std::fmt::Display> ToString for T {
    fn to_string(&self) -> String { format!("{self}") }
}
```

A single `impl` covering *every* type satisfying a bound, rather than one type at a time -- this is why every `Display` type in the standard library and in your own code automatically has `.to_string()` with zero additional code. Blanket impls are also the source of a real, sometimes-confusing coherence restriction: you can't add your own `impl MyTrait for SomeExternalType` if a blanket impl already covers it, and diagnosing "why doesn't my impl apply" sometimes means finding the blanket impl that already claims the type.

## Negative Impls (Nightly)

```rust
#![feature(negative_impls)]
struct NotThreadSafe { /* ... */ }
impl !Send for NotThreadSafe {}    // explicitly OPT OUT of the auto-derived Send
```

Necessary when a type's fields would structurally qualify it as `Send`/`Sync` (all fields happen to be `Send`) but the type's actual *semantics* make cross-thread use unsound (e.g., it wraps a raw pointer into thread-local OS state that the fields alone don't reveal). `PhantomData<*const ()>` is the stable-Rust workaround (a raw pointer field is not `Send`/`Sync`, so including a zero-sized `PhantomData` of one achieves the same opt-out without needing the nightly feature).

## Specialization (Nightly, `min_specialization`)

Lets a more-specific `impl` override a more-general blanket `impl` for particular types, rather than coherence rejecting the overlap outright:

```rust
#![feature(min_specialization)]
trait Speak { fn speak(&self) -> String; }
impl<T> Speak for T { default fn speak(&self) -> String { "...".into() } }
impl Speak for i32 { fn speak(&self) -> String { "I'm an integer!".into() } }
```

Full specialization (arbitrary overlapping impls, not just "more specific type replaces a blanket default") remains unstable years after the original RFC, because it's been shown **unsound** in its general form when combined with lifetimes: a specialized impl chosen based on a *concrete* lifetime can produce behavior that differs from the generic impl in a way that breaks a safe abstraction relying on parametricity (the assumption that generic code behaves identically regardless of which concrete lifetime is substituted in) -- `min_specialization` is a deliberately restricted subset (roughly: specializing on concrete types only, never on lifetimes) carved out specifically to dodge the known unsoundness while still being useful for the standard library's own internal optimizations (e.g., specializing a generic `Vec<T>` method for `T: Copy` to use `memcpy` instead of an element-by-element loop).

## Key Takeaways

- Associated types encode "exactly one per impl"; generic trait parameters encode "possibly many impls per type" -- picking the wrong one is a common API design mistake that's hard to fix later without breaking changes.
- Object safety's rules all trace back to one constraint: a vtable is a fixed-size table of function pointers, so anything requiring per-call-site type information (generic methods, unknown `Self` size) can't be represented in it.
- Auto traits make `Send`/`Sync` compose automatically and structurally -- the actual enforcement mechanism behind handbook §30's "forgetting to synchronize becomes a compile error" claim.
- Full specialization is unstable specifically because of a proven unsoundness with lifetimes, not because it's merely unfinished -- `min_specialization`'s restriction to concrete types is a deliberate soundness firewall, not an arbitrary limitation.

## Interview Notes

- "Why can't `Clone` be used as a trait object (`dyn Clone`)?" -- `clone(&self) -> Self` returns `Self` by value, and a `dyn Clone` caller has no static knowledge of the concrete `Self` type's size to allocate for that return value.
- "What real problem do GATs solve that plain associated types can't?" -- expressing an associated type whose *lifetime* is tied to a specific method call's borrow (a "lending iterator" yielding a view into its own state) rather than being a single fixed type for the whole implementation.
