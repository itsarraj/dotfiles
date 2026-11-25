# Smart Pointer Implementations: Box, Rc, Arc, Cell, RefCell, UnsafeCell, Mutex, RwLock, OnceCell

Prerequisite: handbook §29 (what each of these *is for*). This file is about how each is actually built, bottom-up, starting from the one real primitive everything else rests on.

## UnsafeCell: The Actual Root Primitive

Every other type in this file is built on `UnsafeCell<T>` -- it is the **only** legal way in Rust to obtain a `*mut T` from a `&T` at all. Ordinary references (`&T`) are, by the compiler's own aliasing assumptions (§04's `noalias`/Stacked Borrows material), assumed never to change through an immutable path -- `UnsafeCell<T>` is the specific type the compiler recognizes as an *exception* to that assumption, disabling those optimizations for exactly the memory it wraps.

```rust
pub struct UnsafeCell<T> { value: T }
impl<T> UnsafeCell<T> {
    pub const fn get(&self) -> *mut T { self as *const UnsafeCell<T> as *mut T }
}
```

`Cell`, `RefCell`, `Mutex`, `RwLock`, and every atomic type contain an `UnsafeCell` (directly or via the atomic intrinsics) internally -- there is no other sanctioned way to mutate through a shared reference in safe Rust; every interior-mutability type in the language is, underneath, "an `UnsafeCell` plus some access-discipline layered on top to make using it sound."

## Cell\<T\>

```rust
pub struct Cell<T> { value: UnsafeCell<T> }
impl<T: Copy> Cell<T> {
    pub fn get(&self) -> T { unsafe { *self.value.get() } }
    pub fn set(&self, val: T) { unsafe { *self.value.get() = val; } }
}
```

No runtime check at all -- and none is needed, because `Cell<T>` is **not `Sync`** (it can never be shared across threads), so every access to a given `Cell` happens from a single thread, in the ordinary sequential order the compiler already reasons about. `get`/`set` copying the *whole* value in and out (rather than handing back a reference) is precisely what sidesteps the aliasing question that would otherwise apply -- there's never a live reference into the cell's interior to conflict with a `set` call.

## RefCell\<T\>

```rust
pub struct RefCell<T> {
    value: UnsafeCell<T>,
    borrow: Cell<isize>,   // 0 = unborrowed; N > 0 = N shared borrows; -1 = one exclusive borrow
}
impl<T> RefCell<T> {
    pub fn borrow(&self) -> Ref<T> {
        let b = self.borrow.get();
        assert!(b >= 0, "already mutably borrowed");   // panics -- this is the runtime check
        self.borrow.set(b + 1);
        Ref { cell: self }
    }
    pub fn borrow_mut(&self) -> RefMut<T> {
        assert_eq!(self.borrow.get(), 0, "already borrowed");
        self.borrow.set(-1);
        RefMut { cell: self }
    }
}
// Ref/RefMut's Drop impls decrement/reset `borrow` -- exactly like a lock guard
```

`RefCell` moves the borrow-checker's compile-time rule (one mutable XOR many immutable) to *runtime*, tracked in that `isize` counter, enforced by panicking on violation instead of refusing to compile. This is the genuine middle ground between C's "no check at all" and the borrow checker's "fully static check" -- necessary for patterns (graph structures with shared, mutably-updated nodes; a callback registry that needs to mutate shared state from within a callback) the static borrow checker's flow-insensitive-across-Rc-boundaries analysis can't verify, even though the *access pattern itself* is perfectly fine at runtime.

## Rc\<T\> and Arc\<T\>

```rust
struct RcBox<T> {
    strong: Cell<usize>,
    weak: Cell<usize>,
    value: T,
}
pub struct Rc<T> { ptr: *mut RcBox<T> }

impl<T> Clone for Rc<T> {
    fn clone(&self) -> Self {
        unsafe { (*self.ptr).strong.set((*self.ptr).strong.get() + 1); }
        Rc { ptr: self.ptr }
    }
}
impl<T> Drop for Rc<T> {
    fn drop(&mut self) {
        unsafe {
            let strong = (*self.ptr).strong.get() - 1;
            (*self.ptr).strong.set(strong);
            if strong == 0 {
                std::ptr::drop_in_place(&mut (*self.ptr).value);   // drop the VALUE...
                if (*self.ptr).weak.get() == 0 {
                    dealloc(self.ptr);                                // ...free the ALLOCATION
                }                                                       // only once weak count is ALSO 0
            }
        }
    }
}
```

The strong/weak split matters: reaching **zero strong references** drops the *value* (running its destructor -- resources are released promptly), but the backing allocation itself (the `RcBox`, including its counters) stays alive as long as **any** `Weak<T>` still exists, so that a subsequent `Weak::upgrade()` can safely check the strong count without touching freed memory. Only when *both* counts hit zero is the allocation actually freed. `Arc<T>` is structurally identical except `strong`/`weak` are `AtomicUsize` (handbook §30) instead of `Cell<usize>` -- the only difference between "cheap, single-threaded-only" and "thread-safe" reference counting is which counter type backs it, exactly as the original comparison material noted: C++'s `shared_ptr` always pays the atomic cost, where Rust makes the choice explicit via which type you pick.

## Weak\<T\>

```rust
impl<T> Weak<T> {
    pub fn upgrade(&self) -> Option<Rc<T>> {
        let strong = unsafe { (*self.ptr).strong.get() };
        if strong == 0 { None }                          // value already dropped -- can't upgrade
        else {
            unsafe { (*self.ptr).strong.set(strong + 1); }
            Some(Rc { ptr: self.ptr })
        }
    }
}
```

`upgrade` is the entire reason the strong/weak split exists: it needs to check "is the value still alive" *without* the allocation itself having already been freed out from under it -- which is exactly what deferring deallocation until weak count also reaches zero guarantees.

## Mutex\<T\> and RwLock\<T\>

```rust
pub struct Mutex<T> {
    inner: sys::Mutex,        // a thin wrapper over the OS primitive (futex on Linux)
    data: UnsafeCell<T>,
}
impl<T> Mutex<T> {
    pub fn lock(&self) -> MutexGuard<T> {
        self.inner.lock();                    // blocks (parks the thread, §36.2) until acquired
        MutexGuard { mutex: self }
    }
}
// MutexGuard derefs to &T/&mut T, and its Drop impl calls self.mutex.inner.unlock()
```

On Linux, `std::sync::Mutex` is backed by a **futex** (`FUTEX_WAIT`/`FUTEX_WAKE`) -- a syscall that lets the kernel *actually park the thread* (removing it from the scheduler's runnable set, handbook §36.7) rather than spinning, waking it only when the lock is released; the uncontended fast path (lock currently free) is a single atomic compare-and-swap with no syscall at all, and only the *contended* path pays the syscall cost of parking. `RwLock<T>` extends the same wrapped-data pattern with two acquisition modes (`read()`/`write()`), typically implemented with a single atomic state word encoding "N readers" or "one writer," plus the same OS-parking fallback for the contended case.

`parking_lot`'s `Mutex`/`RwLock` are a commonly-reached-for alternative to `std`'s: smaller (1 byte vs. `std`'s OS-primitive-sized inner state on some platforms), faster in the uncontended case, no lock poisoning by default (`std::sync::Mutex` marks itself "poisoned" if a thread panics while holding the lock, forcing every subsequent `.lock()` to explicitly handle that possibility -- `parking_lot` opts out of this by default, on the judgment that poisoning's safety benefit rarely outweighs its ergonomic cost), and an *eventually fair* scheduling policy (prevents a pathological case where one thread could theoretically re-acquire a contended lock indefinitely, starving others).

## OnceCell / OnceLock and LazyLock

```rust
pub struct OnceLock<T> {
    inner: UnsafeCell<Option<T>>,
    state: AtomicU8,   // Uninitialized / Initializing / Initialized
}
impl<T> OnceLock<T> {
    pub fn get_or_init(&self, f: impl FnOnce() -> T) -> &T {
        // CAS state Uninitialized -> Initializing; the thread that wins runs f()
        // and stores it, then sets state to Initialized; other threads that lose
        // the race (or arrive later) block until Initialized, then just read
        // ...
    }
}
```

`OnceLock<T>` guarantees a value is initialized *exactly once*, safely, even under concurrent first-access from multiple threads -- the standard tool for lazily-constructed global state that used to require a `lazy_static!`-style macro workaround. `LazyLock<T, F>` (stabilized after being a long-standing `once_cell::sync::Lazy` crate staple first) pairs a `OnceLock` with the initializing closure itself, so the *first* deref triggers `get_or_init` automatically:

```rust
static CONFIG: std::sync::LazyLock<Config> = std::sync::LazyLock::new(|| load_config_from_disk());
// CONFIG is only actually loaded on first use, thread-safely, exactly once
```

## Box\<T\>

The simplest of the group: a `Box<T>` is, at the representation level, just a unique, owning raw pointer plus compiler-inserted drop glue at scope exit (handbook §16.2's `unique_ptr` comparison) -- no refcount, no borrow-flag, nothing beyond ordinary heap allocation (§5) and RAII-style cleanup (§16.1). `Box<dyn Trait>` is the one case with extra structure: it's a **fat pointer** (handbook's DST material) -- a data pointer plus a vtable pointer (§14.3/§26), twice the width of an ordinary `Box<T>` for a sized `T`.

## Key Takeaways

- Every interior-mutability type in Rust reduces to `UnsafeCell<T>` plus some access discipline -- there is no other sanctioned mechanism for mutating through `&T`.
- `Rc`/`Arc`'s strong/weak split exists specifically so `Weak::upgrade()` can safely check liveness without touching a potentially-freed allocation -- the allocation itself outlives the value by design, until weak count also reaches zero.
- `std::sync::Mutex` is a thin wrapper over a futex on Linux -- uncontended locking costs one atomic CAS, no syscall; only contention pays the parking cost.

## Interview Notes

- "Why does `Cell<T>` need no runtime borrow check while `RefCell<T>` does?" -- `Cell` is `!Sync` and only ever hands back owned copies (never a live reference into its interior), so there's nothing to check; `RefCell` hands back actual references (`Ref`/`RefMut`) that must not alias incompatibly, which is exactly what its runtime counter enforces.
- "Why do `Rc` and `Weak` need separate strong and weak counts instead of one shared count?" -- dropping the *value* (strong count reaching zero) and freeing the *allocation* (both counts reaching zero) are different events; a `Weak` must be able to check whether the value is still alive without risking a use-after-free on an already-deallocated control block, which requires the allocation to outlive the value whenever a `Weak` still references it.
