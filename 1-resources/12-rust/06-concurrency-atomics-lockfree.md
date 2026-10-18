# Concurrency Deep Dive: Threads, Atomics, ABA, Hazard Pointers, Epoch GC, Lock-Free Structures

Prerequisite: handbook §30 (Send/Sync/Mutex/RwLock/atomics vocabulary), §1.7 (out-of-order execution), §17.2 (the C++11-originated memory-ordering model both languages share). This file goes from "here's what atomics are" to "here's how you build an actual lock-free data structure correctly."

## Threads and Scoped Threads

```rust
std::thread::scope(|s| {
    let data = vec![1, 2, 3];
    s.spawn(|| println!("{:?}", data));   // borrows `data` from the ENCLOSING stack frame
    s.spawn(|| println!("{}", data.len()));
});   // scope() blocks here until every spawned thread has finished
```

Ordinary `thread::spawn` requires `'static` data (the closure might outlive the calling function, so it can't be allowed to borrow that function's stack frame) -- forcing an `Arc` wrap for genuinely scoped, short-lived parallel work. `thread::scope` closes this gap soundly: the compiler can *prove* every spawned thread is joined before `scope` returns (it's a compile-time-enforced structural guarantee, not a runtime promise), so borrowing stack data across the spawned threads is safe -- a direct, practical payoff of the borrow checker being able to reason about a closure's captured lifetime against a scope's guaranteed-to-complete-before-return contract.

**Parking**: `thread::park()`/`Thread::unpark()` is the low-level primitive underneath blocking synchronization -- park suspends the calling thread (removed from the scheduler's runnable set, handbook §36.7) until a matching `unpark` call, which is exactly the mechanism a `Mutex`'s contended-path futex wait (§05) is built from at a lower level still (an OS futex *is* effectively a more efficient, address-keyed version of park/unpark, avoiding a dedicated OS thread-control-block wakeup by letting the kernel wait on a plain memory address).

## Atomics, in Full

### Compare-and-Swap

```rust
use std::sync::atomic::{AtomicUsize, Ordering};
let a = AtomicUsize::new(0);

loop {
    let current = a.load(Ordering::Relaxed);
    let new = current + 1;
    match a.compare_exchange_weak(current, new, Ordering::AcqRel, Ordering::Relaxed) {
        Ok(_) => break,           // succeeded -- a was still `current`, now it's `new`
        Err(_) => continue,       // another thread changed it first -- retry with fresh `current`
    }
}
```

`compare_exchange` vs. `compare_exchange_weak`: the `_weak` variant is permitted to fail **spuriously** -- return `Err` even though the value actually did match -- because on **LL/SC (load-linked/store-conditional)** architectures (ARM, RISC-V), the underlying hardware primitive genuinely can fail for reasons unrelated to a concurrent modification (e.g. an interrupt landing between the load-linked and store-conditional instructions invalidates the reservation). x86-64 has a native, non-spurious `lock cmpxchg` instruction, so `compare_exchange` (the non-weak, non-spuriously-failing version) costs nothing extra there -- but `compare_exchange_weak` inside a retry loop (as above) is the portable, idiomatic choice, since the loop already handles "failed, retry" regardless of *why* it failed, and it lets ARM/RISC-V code avoid an unnecessary extra retry-on-spurious-failure layer.

### Memory Fences

```rust
use std::sync::atomic::{fence, Ordering};
fence(Ordering::Acquire);   // a standalone ordering constraint, not tied to any one atomic operation
```

An explicit fence enforces an ordering relationship independent of any single load/store -- occasionally needed when the ordering constraint you need doesn't map cleanly onto one specific atomic operation's built-in ordering parameter (common in hand-rolled lock-free structures where several plain, non-atomic writes need to become visible together, gated by one fence, rather than each needing its own atomic wrapper).

## The ABA Problem

```
 Thread 1: reads head = A, plans to CAS head from A to A.next
 Thread 2: pops A, pops B, then pushes a NEW node that happens to be
           allocated at the SAME ADDRESS as the old A (freed and reused)
 Thread 1: CAS(head, A, A.next) SUCCEEDS -- head is "still A" (same address!)
           but it's a DIFFERENT logical node now, and A.next is garbage/wrong
```

The CAS in Thread 1 only compares the *bit pattern* (here, an address) -- it has no way to detect that the value changed and changed back (A → gone → a new node reallocated at the identical freed address) between the read and the CAS. This is exactly why naive lock-free structures built on plain CAS over raw pointers are unsound for reclaimed memory -- the fix has to either prevent the memory from being reused while any thread might still be comparing against its old address (hazard pointers, epoch-based reclamation, below), or attach a version/generation counter alongside the pointer so "same address" is no longer sufficient for the CAS to succeed (a common alternative: a tagged pointer packing a monotonically-incrementing counter into unused address bits, so a reused address still fails the CAS because its counter differs).

## Hazard Pointers

A **hazard pointer** is a per-thread, published "I am currently dereferencing this specific address, do not free it" flag: before dereferencing a shared pointer read from a lock-free structure, a thread publishes that address into its own hazard-pointer slot (a globally visible, per-thread array); any thread wanting to *reclaim* (actually free) a retired node first scans every other thread's hazard-pointer slots, and only frees the node if no thread currently has it hazard-marked. This directly solves the ABA/use-after-free problem above: a node can't be freed and its address reused while any thread has published a hazard pointer to it, closing the exact window ABA exploits -- at the cost of that publish/scan overhead on every access, and needing to bound how many hazard pointers a thread can hold at once.

## Epoch-Based Reclamation (crossbeam-epoch)

A coarser-grained alternative that trades hazard pointers' precise per-node tracking for much lower per-access overhead:

```rust
use crossbeam_epoch::{self as epoch, Guard};

let guard: Guard = epoch::pin();          // "I am now in a critical section -- don't
                                            // reclaim anything retired after this point
                                            // until I unpin"
let shared = some_atomic.load(Ordering::Acquire, &guard);
// ... use shared ...
// guard drops (unpins) at end of scope
```

Threads periodically "pin" a global epoch counter; memory is **retired** (marked garbage, not yet freed) rather than freed immediately, and actually reclaimed only once every thread has advanced past the epoch in which it was retired -- i.e., once it's provable no thread could still hold a reference from before the retirement. This is cheaper than hazard pointers' per-access publish/scan (pinning is a single, cheap atomic operation, done once per operation batch rather than once per pointer dereference) at the cost of coarser reclamation granularity -- memory can sit retired-but-not-yet-freed longer than the strict minimum a perfectly precise scheme would achieve. `crossbeam`'s lock-free data structures (`SegQueue`, `SkipMap`, etc.) are built on exactly this mechanism.

## Treiber Stack

The canonical minimal lock-free structure -- a stack via CAS loop on the head pointer:

```rust
use std::sync::atomic::{AtomicPtr, Ordering};

struct Node<T> { value: T, next: *mut Node<T> }
struct TreiberStack<T> { head: AtomicPtr<Node<T>> }

impl<T> TreiberStack<T> {
    fn push(&self, value: T) {
        let new = Box::into_raw(Box::new(Node { value, next: std::ptr::null_mut() }));
        loop {
            let head = self.head.load(Ordering::Acquire);
            unsafe { (*new).next = head; }
            if self.head.compare_exchange_weak(head, new, Ordering::Release, Ordering::Relaxed).is_ok() {
                break;
            }
            // else: some other thread changed head first -- retry with the fresh value
        }
    }
    // pop() is the mirror image, and is exactly where the ABA problem above bites
    // if node memory is naively freed rather than reclaimed via hazard pointers/epochs
}
```

`push` is ABA-safe as written (it never frees anything) -- `pop` is where a correct implementation *must* defer reclamation (hazard pointers or epoch-based, above) rather than immediately `Box`-dropping the popped node, precisely because another thread's in-flight CAS might still be comparing against that node's address.

## Michael-Scott Queue

The lock-free FIFO queue analog of the Treiber stack, using two atomic pointers (`head` and `tail`) and a crucial extra step: because a queue needs to link a new node onto the *tail* while concurrent poppers might be advancing `head` independently, an MS queue's `enqueue` first CAS-links the new node onto the current tail's `next` pointer, and only *then* (in a separate step, possibly by a different thread that notices the tail is lagging) CAS-advances the `tail` pointer itself to the new node -- a deliberate two-step protocol that lets any thread "help" complete a lagging tail update it observes, rather than requiring the original enqueuing thread to be the only one that can ever fix it up (a technique generally called **helping**, common across lock-free algorithm designs, and part of why lock-free code is notoriously harder to get right than it looks from the pseudocode alone).

## Synchronization Primitives, Compared

| Primitive | When to prefer it |
|---|---|
| `Mutex` | General-purpose; critical section long enough that parking (avoiding busy-wait) is worth the syscall |
| Spinlock | Very short critical sections where the cost of parking/waking (a syscall, handbook §36.3) exceeds just busy-waiting a few cycles -- common in kernel code, rare to be the right choice in ordinary userspace Rust |
| `Condvar` | Waiting for a *condition* on shared state to become true, not just for exclusive access -- always paired with a `Mutex` guarding the condition's actual data |
| `Barrier` | Making N threads all wait until every one of them has reached the same point, then releasing all simultaneously |
| Semaphore | Bounding concurrent access to a resource with capacity > 1 (a connection pool's slot count, for instance) -- `Mutex` is a semaphore with capacity exactly 1 |
| `parking_lot`'s variants | Same API shape as `std`'s, smaller/faster uncontended path, no default poisoning, eventual fairness (§05) |

## Key Takeaways

- `compare_exchange_weak`'s spurious-failure allowance exists specifically for LL/SC architectures (ARM/RISC-V) -- x86's native CAS instruction never needs it, but the portable idiom uses `_weak` inside a retry loop regardless.
- The ABA problem is fundamentally about memory *reuse*, not about the CAS instruction being buggy -- solving it always comes down to either preventing reuse while referenced (hazard pointers, epochs) or making "same address" insufficient for the CAS to match (versioned/tagged pointers).
- Epoch-based reclamation trades hazard pointers' precise, per-access bookkeeping for coarser but much cheaper batch reclamation -- `crossbeam`'s lock-free structures are built on this tradeoff, not on hazard pointers.
- Lock-free FIFO queues need a "helping" protocol (Michael-Scott) that lock-free stacks don't, because enqueue's two logically-necessary pointer updates (link the node, then advance tail) can't be done as a single atomic operation.

## Interview Notes

- "Why does `compare_exchange_weak` exist as a separate operation from `compare_exchange`?" -- on LL/SC hardware, the underlying primitive can fail spuriously (an interrupt or intervening operation invalidates the reservation) even when the compared value genuinely matched; `_weak` permits that, letting the compiler avoid extra retry-detection overhead on those architectures, while a CAS retry loop already handles "failed, try again" regardless of the failure's cause.
- "Explain the ABA problem and name two ways to fix it." -- a value read as A, changed away, and changed back to (bit-identically) A between a thread's read and its CAS, causing the CAS to wrongly succeed as if nothing happened; fixed by preventing address reuse while any thread might still reference it (hazard pointers, epoch-based reclamation) or by attaching a version counter so a reused address doesn't compare equal (tagged/versioned pointers).
