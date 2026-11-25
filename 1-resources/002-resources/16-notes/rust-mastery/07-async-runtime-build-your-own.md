# Async Runtime Internals: epoll/kqueue/IOCP/io_uring, and Building Your Own Executor

Prerequisite: handbook §23 (Future/Poll/Waker, executor/reactor split), §29 (the minimal from-scratch executor), §33 (Tokio's high-level model). This file covers the OS-level reactor mechanisms in full and extends the from-scratch executor into something with a real reactor.

## The Readiness vs. Completion Split

Every async I/O model on every OS answers the same question -- "how does userspace find out an I/O operation can proceed, without a dedicated blocking thread per operation" -- via one of two fundamentally different strategies:

**Readiness-based** (Linux `epoll`, BSD/macOS `kqueue`): the kernel tells you *"this fd is now ready for a read/write that probably won't block."* You still have to actually issue the `read`/`write` syscall yourself, and it can occasionally still block or return less data than expected (readiness is a hint, not a guarantee) -- but the model is comparatively simple, and it's what `mio` (the reactor underneath both `tokio` and most other Rust async runtimes) is built directly on for Linux/BSD/macOS.

**Completion-based** (Windows **IOCP** -- I/O Completion Ports): you submit the *actual* read/write operation upfront (kernel takes ownership of the buffer for the operation's duration), and the kernel notifies you when it has **already finished**, with the result -- no follow-up syscall needed to actually perform the operation once notified. This is a structurally different contract: readiness tells you "you may now attempt work," completion tells you "the work is done."

```
 epoll/kqueue (readiness):                IOCP (completion):
 1. register interest in fd                1. submit read(fd, buf) NOW
 2. wait -- "fd is readable"                2. wait -- kernel does the read itself
 3. YOU call read(fd, buf)                  3. "here's your completed read, with data"
 4. read() returns data (usually)
```

## io_uring: Linux's Completion-Based Model

`io_uring` (Linux 5.1+) is Linux belatedly adopting a **completion-based** model closer to IOCP's, via two ring buffers shared between userspace and the kernel: a **submission queue (SQ)** userspace writes operation requests into, and a **completion queue (CQ)** the kernel writes finished results into -- both **without requiring a syscall per operation**. A program can batch dozens of I/O requests into the SQ and submit them all with a single `io_uring_enter` syscall, then later drain however many completions have landed from the CQ with another single syscall -- a dramatic reduction in syscall count (handbook §36.3) versus one `epoll_wait` + one `read`/`write` *per operation* under the classic readiness model, which matters enormously at high I/O rates (a database or a proxy handling hundreds of thousands of operations per second pays real, measurable overhead per syscall, handbook §37's performance vocabulary).

```rust
// tokio-uring (an alternative, io_uring-specific runtime, not tokio's default reactor)
use tokio_uring::fs::File;

tokio_uring::start(async {
    let file = File::open("data.bin").await.unwrap();
    let buf = vec![0; 4096];
    let (res, buf) = file.read_at(buf, 0).await;   // the buffer is MOVED into the kernel
    let n = res.unwrap();                            // for the duration of the operation --
});                                                     // io_uring's ownership-transfer API shape
```

Note the API shape difference this forces: because the kernel needs ownership of the buffer while the operation is in flight (unlike `epoll`'s "you call read() yourself, whenever you like" model), `io_uring`-based Rust APIs pass buffers *by value* into the operation and hand them *back* alongside the result -- a genuinely different, more restrictive-feeling but ultimately safer API contract than the borrow-based `AsyncRead`/`AsyncWrite` traits `tokio`'s default `mio`-backed reactor uses.

## Building a Reactor: From the Handbook's Toy Executor to a Real One

Handbook §29 built an executor that busy-polls every task in a loop -- functional, but wasteful (it never actually *sleeps* while waiting on I/O). A real reactor closes that gap:

```rust
use mio::{Events, Interest, Poll, Token};
use std::collections::HashMap;
use std::task::Waker;

struct Reactor {
    poll: Poll,
    wakers: HashMap<Token, Waker>,   // maps a registered source to whichever task is waiting on it
}

impl Reactor {
    fn register(&mut self, source: &mut impl mio::event::Source, token: Token, waker: Waker) {
        self.poll.registry().register(source, token, Interest::READABLE).unwrap();
        self.wakers.insert(token, waker);
    }

    fn wait_and_wake(&mut self) {
        let mut events = Events::with_capacity(128);
        self.poll.poll(&mut events, None).unwrap();   // BLOCKS the reactor thread here --
                                                          // no busy-waiting, no wasted CPU --
                                                          // until the OS reports readiness
        for event in events.iter() {
            if let Some(waker) = self.wakers.remove(&event.token()) {
                waker.wake();   // tells the EXECUTOR "re-poll this task" -- it doesn't do the I/O itself
            }
        }
    }
}
```

This is the missing piece between §29's toy executor and a real async runtime: a `Future`'s `poll` implementation, when it hits an operation that isn't ready, registers its `Waker` (obtained from the `Context` argument `poll` receives) with the reactor for the relevant fd/token, and returns `Pending` -- the *executor* then has nothing to do with that task until the *reactor*, blocked in `poll()` above, observes readiness and calls the stored `Waker`, which re-queues the task for the executor to poll again. The executor and reactor are genuinely separate concerns running independently (often on separate threads in a real multi-threaded runtime): the executor's job is "run whichever tasks are ready to make progress"; the reactor's job is "sleep efficiently until the OS says something changed, then wake exactly the tasks that care."

## Tokio's Internals

**Work-stealing multi-threaded scheduler**: each worker thread owns a local task queue; a worker that runs out of local work steals tasks from another worker's queue rather than sitting idle -- the same load-balancing idea behind most modern work-stealing schedulers (Rayon, §17-adjacent parallel-computing runtimes, use an analogous design for CPU-bound work rather than I/O-bound tasks).

**The cooperative-scheduling "budget" system**: because async scheduling is cooperative (handbook §23.4 -- a task only yields at an `.await`), a task that repeatedly has cheap, immediately-ready `.await`s (e.g., reading from an in-memory channel that's always got data buffered) could in principle *never* actually yield back to the executor, starving every other task on that worker thread. Tokio's resource types (channels, timers, etc.) internally track a per-task "budget" that decrements on each poll and forces a yield back to the scheduler once exhausted, even though the operation itself was ready -- a deliberate, load-bearing fairness mechanism most users never see or configure, but that prevents a legitimately-fast task from monopolizing a worker thread indefinitely.

**The timer wheel**: rather than a naive sorted list of pending timeouts (O(log n) insert/remove, and a full scan to find "what's due next"), Tokio's timer implementation uses a **hierarchical timing wheel** -- an array of "buckets" representing time slots at increasing granularity (milliseconds, then tens of milliseconds, then hundreds, and so on), where a timer is placed into the coarsest bucket that still expires soon enough, and gets progressively moved into finer buckets as its actual deadline approaches. This gives amortized O(1) insertion and expiry-checking for the common case of many timers with varied durations, at the cost of some coarsening in exactly *when* a very-far-future timer's deadline gets refined to full precision (irrelevant in practice, since it's refined well before it actually needs to fire).

## Key Takeaways

- Readiness-based (`epoll`/`kqueue`) and completion-based (`IOCP`, and Linux's newer `io_uring`) are two structurally different contracts, not two implementations of the same idea -- one tells you "try now," the other tells you "already done, here's the result."
- `io_uring`'s ownership-transfer API shape (buffers passed by value into the kernel, handed back with results) is a direct, necessary consequence of its completion-based model, not an arbitrary Rust API design choice.
- A real reactor blocks efficiently in the OS poll call and wakes only the specific tasks whose registered interest became ready -- the executor and reactor are genuinely separate, independently-schedulable concerns.
- Tokio's per-task poll "budget" exists specifically to prevent a legitimately-fast, always-ready task from starving its worker thread's other tasks under cooperative scheduling.

## Interview Notes

- "What's the fundamental difference between epoll and IOCP, beyond 'one is Linux and one is Windows'?" -- epoll is readiness-based (tells you an operation *can* be attempted; you still issue it yourself and it can still not fully complete), IOCP is completion-based (you submit the operation upfront; the notification means it already finished) -- `io_uring` is Linux's more recent move toward the completion-based model epoll never provided.
- "Why does a cooperatively-scheduled async task need an artificial 'budget'/fairness mechanism at all?" -- because a task with a chain of cheap, always-immediately-ready `.await` points would otherwise never naturally return `Pending` and yield control, starving every other task queued on the same worker thread indefinitely.
