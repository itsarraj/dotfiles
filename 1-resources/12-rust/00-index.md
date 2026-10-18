# Rust Mastery Roadmap -- Index

This directory is the deep-dive library for the "top 1% Rust systems engineer" roadmap (Levels 0-22 + capstones). It deliberately does **not** duplicate what's already written in full depth elsewhere in this notes tree -- each entry below either links to existing material or lives in its own file here. **All 22 files are now written.**

## Already Covered Elsewhere (Do Not Duplicate)

| Roadmap Level | Where it lives | What's there |
|---|---|---|
| Level 0 -- Rust Fundamentals | [`../16a-rust.md`](../16a-rust.md) §1-18 | Full Rust Book notes: ownership, structs, enums, traits, generics, modules, collections, error handling, closures/iterators, smart pointers, concurrency basics, OOP features, pattern matching, advanced features, async, idioms -- each with a C/C++/Assembly comparison subsection |
| Level 1 (partial) -- Memory (stack/heap/move/Drop/alignment/padding/fat pointers) | [`../16a-rust-systems-programming.md`](../16a-rust-systems-programming.md) Ch 4-5, 10, 22 | Stack frames, heap allocators, struct layout/padding/alignment, `repr(Rust)` vs `repr(C)`, niche optimization |
| Level 2 (partial) -- Unsafe basics, FFI | Handbook Ch 19-20, 31 | Raw pointers, `MaybeUninit`, `transmute`, `extern "C"`, `libc`, `bindgen` basics -- expanded in full in [`04`](04-unsafe-memory-model.md)/[`13`](13-ffi-deep.md) here |
| Level 5 -- Compiler Internals (pipeline shape) | Handbook Ch 9 | AST → HIR → MIR → LLVM IR, why borrow-checking runs on MIR specifically -- expanded in [`08`](08-mir-llvm-deep.md) |
| Level 6-9 -- Assembly, OS, Linking, Performance | Handbook Part I, Ch 8, 36-37 | Full treatment; pointer file with the two remaining gaps (huge pages, NUMA) in [`09`](09-assembly-os-linking-performance.md) |
| Level 21 -- Debugging & Profiling | Handbook Ch 38 | gdb/objdump/readelf/nm/perf/valgrind/sanitizers/cargo-asm/cargo-expand |
| Capstone #21: Container runtime | Handbook Part VI, Ch 40-53 | Full build: namespaces, cgroups, capabilities/seccomp, signals, networking, eBPF, OCI patterns, testing, static linking, observability |

## This Directory -- All Written

| File | Roadmap Level(s) |
|---|---|
| [`01-ownership-internals.md`](01-ownership-internals.md) | L1 Ownership Internals (NLL, reborrowing, two-phase borrows, variance, HRTB) |
| [`02-traits-deep.md`](02-traits-deep.md) | L1 Traits (associated types, GATs, object safety, auto traits, blanket/negative impls, specialization) |
| [`03-generics-deep.md`](03-generics-deep.md) | L1 Generics (monomorphization/code bloat, `PhantomData`, const generics) |
| [`04-unsafe-memory-model.md`](04-unsafe-memory-model.md) | L2 Unsafe, Memory Model (Stacked Borrows, provenance, alias analysis), Pinning in full |
| [`05-smart-pointers-impl.md`](05-smart-pointers-impl.md) | L2 Smart Pointers implementation internals (`Box`/`Rc`/`Arc`/`Weak`/`Cell`/`RefCell`/`UnsafeCell`/`Mutex`/`RwLock`/`OnceCell`/`LazyLock`) |
| [`06-concurrency-atomics-lockfree.md`](06-concurrency-atomics-lockfree.md) | L3 Concurrency (scoped threads, CAS/LL-SC, ABA, hazard pointers, epoch GC, Treiber stack, Michael-Scott queue, sync primitives compared) |
| [`07-async-runtime-build-your-own.md`](07-async-runtime-build-your-own.md) | L4 Async (readiness vs. completion I/O, epoll/kqueue/IOCP/io_uring, a real reactor, Tokio internals) |
| [`08-mir-llvm-deep.md`](08-mir-llvm-deep.md) | L5 remainder (move analysis, drop elaboration, SSA, key LLVM passes, instruction selection) |
| [`09-assembly-os-linking-performance.md`](09-assembly-os-linking-performance.md) | L6-9 pointer file + huge pages/NUMA (the two subtopics not yet in the handbook) |
| [`10-networking.md`](10-networking.md) | L10 Networking (TCP/UDP, TLS/QUIC, HTTP2/3, zero-copy, DPDK, eBPF/XDP, RDMA) |
| [`11-storage-engines.md`](11-storage-engines.md) | L11 Storage (mmap, O_DIRECT, page cache, B-tree vs. LSM-tree, WAL, NVMe/SSD internals) |
| [`12-rust-ecosystem-crates.md`](12-rust-ecosystem-crates.md) | L12 Ecosystem (tokio/hyper/axum/tonic/tower/serde/bytes/parking_lot/crossbeam/rayon/dashmap/moka/sqlx/diesel/reqwest/tracing) |
| [`13-ffi-deep.md`](13-ffi-deep.md) | L13 remainder (bindgen/cbindgen, libloading, JNI, PyO3, napi-rs/neon, WebAssembly/wasm-bindgen) |
| [`14-embedded.md`](14-embedded.md) | L14 Embedded (embedded-hal, RTIC, interrupts, DMA, memory-mapped I/O, bare metal/bootloader) |
| [`15-compiler-construction.md`](15-compiler-construction.md) | L15 Build-your-own compiler (lexer, Pratt parsing, type checker, CFG-based borrow checker, tree-walking interpreter, LLVM/inkwell backend) |
| [`16-database-internals.md`](16-database-internals.md) | L16 Database internals (buffer pool, MVCC, txn/lock manager, ARIES recovery, query optimization) |
| [`17-distributed-systems.md`](17-distributed-systems.md) | L17 Distributed systems (Raft, Paxos, vector clocks, CRDTs, replication, sharding, 2PC/Sagas, CAP/PACELC) |
| [`18-kernel-programming.md`](18-kernel-programming.md) | L18 Kernel programming (top/bottom-half interrupts, buddy/slab allocators, CFS, VFS, sk_buff, Rust-for-Linux) |
| [`19-stdlib-internals.md`](19-stdlib-internals.md) | L19 Standard library internals (Vec/String/HashMap-SwissTable/BTreeMap/BinaryHeap/Iterator/VecDeque/LinkedList source study) |
| [`20-design-patterns.md`](20-design-patterns.md) | L20 Advanced design patterns (typestate, newtype, marker traits/ZSTs, arena, ECS) |
| [`21-capstone-projects.md`](21-capstone-projects.md) | L22 reading real source (rustc/std/tokio/hyper/axum/serde/crossbeam/rayon/polars/bevy/ripgrep/cargo/rust-analyzer) + all 25 capstone project architectures |

## How to Use This Library

Read in roadmap order, but treat the "Already Covered Elsewhere" table as load-bearing -- there's no point re-deriving what the systems-programming handbook already built. Each file here assumes you've read the relevant handbook chapters and cross-references them rather than re-explaining (e.g. lock-free structures assume you already have handbook §1.7's out-of-order-execution model and §22/§30's atomics vocabulary).

For the 25 capstone projects specifically, [`21-capstone-projects.md`](21-capstone-projects.md) notes which prior files each one draws on -- #21 (container runtime) and #22 (Raft-based KV store) have the most ready-to-use scaffolding already built out (handbook Part VI and [`17`](17-distributed-systems.md), respectively).
