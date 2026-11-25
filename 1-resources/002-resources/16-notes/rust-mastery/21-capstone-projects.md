# Reading Real Source Code, and the 25 Capstone Projects

This file closes the roadmap: where to read in the wild, and an architectural starting point for each of the 25 capstone projects -- enough to know what you're actually building and which prior files in this library/the handbook it draws on, not full implementations (each of these is realistically a multi-week-to-multi-month project on its own).

## Reading Real Source Code -- Where to Start in Each

- **`rustc`**: start with `compiler/rustc_middle` (the core data structures -- MIR, `ty::Ty`) and `compiler/rustc_borrowck` once §01/§08 feel solid -- reading the borrow checker's actual dataflow implementation is the natural next step after understanding it conceptually.
- **`std`/`core`/`alloc`**: exactly what §19 walked through -- `library/alloc/src/vec/mod.rs`, `library/std/src/collections/hash/map.rs` (thin wrapper over `hashbrown`), `library/core/src/future/mod.rs`.
- **`tokio`**: `tokio/src/runtime/scheduler` for the work-stealing executor (§07); `tokio/src/io/driver.rs` for the `mio`-based reactor.
- **`hyper`**: `src/proto/h1`/`src/proto/h2` for the actual protocol state machines underneath the ergonomic API (§12).
- **`axum`**: small enough to read end-to-end in a sitting once you understand `tower::Service` (§12) -- start at `axum/src/routing/mod.rs`.
- **`serde`**: `serde/src/ser/mod.rs`'s `Serializer` trait is the entire visitor-pattern mechanism (§12) laid bare.
- **`crossbeam`**: `crossbeam-epoch/src/internal.rs` for epoch-based reclamation (§06) in a real, production-hardened implementation.
- **`rayon`**: `rayon-core/src/job.rs` and `registry.rs` for its work-stealing implementation, directly comparable to tokio's (§07/§12).
- **`polars`**: a DataFrame library built around Apache Arrow's columnar memory layout -- excellent real-world SIMD/vectorization (handbook §37.5) and cache-friendly (§37.1) design in practice.
- **`bevy`**: its ECS (`bevy_ecs`) is the production-grade version of §20's ECS pattern -- read `bevy_ecs/src/storage` for the actual component-array implementation.
- **`ripgrep`**: small, focused, exceptionally well-organized -- a great first "real CLI tool" codebase to read end-to-end; also demonstrates the `regex` crate's own finite-automaton engine internals if you follow the dependency.
- **`cargo`**: `src/cargo/core/resolver` for dependency resolution (a real-world constraint-satisfaction problem, conceptually related to §17's distributed-systems-adjacent coordination problems, though solved as a single-node SAT-like search rather than a distributed protocol).
- **`rust-analyzer`**: demonstrates incremental computation at scale (`salsa`, its query-caching framework) -- relevant well beyond IDE tooling, as a real example of the general "recompute only what actually changed" problem.

## The 25 Capstones

**1. Custom memory allocator (`malloc`/`free`)** -- implement a free-list allocator (handbook §5.1) from raw `mmap`/`sbrk`-obtained memory, then a `GlobalAlloc` wrapper (§05) so ordinary Rust code can use it as `#[global_allocator]`. Verify correctness with a fuzzer (§30 of the systems-programming handbook's fuzzing chapter) hammering random alloc/free/realloc sequences against a reference allocator.

**2. Async runtime (Tokio-like)** -- build directly on §07: a reactor over `mio`, a single-threaded executor first, then extend to work-stealing across a thread pool. The single hardest correctness property to get right is the `Waker` contract (a task must be guaranteed to be re-polled after registering interest, exactly once per readiness event, never lost).

**3. Lock-free concurrent queue** -- implement the Michael-Scott queue (§06) with epoch-based reclamation (`crossbeam-epoch`) for safe memory reclamation; verify with `loom` (a Rust concurrency-testing tool that exhaustively explores interleavings for small test cases, the practical tool of choice for this specific capstone).

**4. Thread pool and work-stealing scheduler** -- the CPU-bound-parallelism analog of #2; study `rayon`'s internals (above) as the reference implementation once yours works.

**5. HTTP/3 server** -- build on `quinn` (a mature Rust QUIC implementation) rather than implementing QUIC's wire protocol from scratch; the actual learning value here is in the HTTP/3 semantics layer and understanding exactly how it avoids HTTP/2's head-of-line blocking (§10).

**6. gRPC framework** -- essentially reimplementing a slice of `tonic` (§12): protobuf wire-format encoding/decoding, HTTP/2 framing, and a code generator turning `.proto` service definitions into client/server stubs.

**7. Redis-compatible server** -- a genuinely approachable, high-value capstone: implement the RESP wire protocol, an in-memory hash-map-backed store, and enough of Redis's command set (`GET`/`SET`/`EXPIRE`/`LPUSH` etc.) to pass against a real `redis-cli`. Naturally extends into #3/#4 once you add concurrent client handling.

**8. PostgreSQL-like storage engine** -- draws directly on §11/§16: a B-tree or LSM-tree storage layer, a WAL, and a minimal transaction manager with at least snapshot-isolation-level MVCC.

**9. Git implementation** -- reimplement Git's content-addressed object model (blobs/trees/commits, hashed by content) and the core plumbing commands (`hash-object`, `cat-file`, `commit-tree`) -- an excellent, self-contained exercise in content-addressed storage design, unrelated to but good practice alongside #8's storage-engine work.

**10. LSM-tree key-value database** -- the focused version of #8's storage layer alone: memtable, SSTable flush, and at least one compaction strategy (§11) implemented and benchmarked against read/write amplification tradeoffs.

**11. B+ Tree index** -- the focused version of the *other* half of #8: node splitting/merging on insert/delete, leaf-linked-list range scans (§11/§16), as a standalone on-disk (or in-memory) index structure.

**12. Bytecode virtual machine** -- design a small stack-based (or register-based) instruction set, a compiler from a toy language's AST (§15) into that bytecode, and an interpreter loop executing it -- a natural extension of §15's tree-walking interpreter into something with a real instruction-dispatch loop.

**13. JIT compiler** -- extend #12: instead of interpreting bytecode, compile hot code paths directly to machine code at runtime (via `cranelift`, a Rust-native code generator designed for exactly this use case, as a considerably more approachable starting point than hand-writing x86-64 machine code emission or wrapping LLVM's heavier C++ API).

**14. Small programming language compiler** -- the full pipeline from §15, end to end: lexer → parser → type checker → LLVM IR (via `inkwell`) → an actual compiled, runnable executable.

**15. Linux shell** -- implement `fork`/`exec`/pipe/redirection handling (handbook §36's process model), job control (`SIGTSTP`/`SIGCONT`, process groups -- directly related to handbook §45's signal-forwarding material), and a parser for shell syntax (pipelines, redirection operators).

**16. ELF loader** -- parse an ELF file's headers (handbook §7.6) and actually `mmap` its segments into a new process's address space with correct permissions, resolve any needed dynamic symbols (§8), and transfer control to its entry point -- essentially reimplementing the core of what `ld.so`/the kernel's own ELF loader does.

**17. x86-64 emulator** -- decode and emulate x86-64 instructions (handbook §3's instruction catalog is your starting instruction set) against an in-memory representation of registers/memory -- start with a small, deliberately restricted instruction subset (enough to run simple hand-assembled test programs) rather than attempting full ISA coverage.

**18. Userspace TCP/IP stack** -- implement Ethernet/IP/TCP framing and state-machine handling yourself over a raw/TAP network interface, bypassing the kernel's own stack entirely -- directly illuminates everything in §10's TCP handshake/congestion-control material by making you implement it.

**19. WebAssembly runtime** -- implement a Wasm bytecode interpreter (parse the module format, execute its stack-machine instruction set) -- draws on #12's bytecode-VM experience directly, applied to a real, standardized instruction set instead of a custom one, and touches §13's linear-memory sandboxing model from the runtime-implementer's side.

**20. Tiny operating system kernel** -- the deepest capstone: a bootloader (or use an existing one, e.g. via the `bootloader` crate for x86-64), your own minimal paging setup (handbook §1.8), a basic scheduler (§36.7's ideas, drastically simplified), and enough of a driver layer to talk to a serial port for output -- realistically draws on nearly every chapter in handbook Part I plus §18's kernel-internals material, from the implementer's side rather than the reader's.

**21. Container runtime (Docker-like)** -- this is handbook Part VI, built end to end: namespaces, cgroups, capabilities/seccomp, the OCI create/start lifecycle, signal handling, and (optionally) the networking/eBPF layers -- the handbook's own capstone, with a full staged learning path already laid out there (handbook §53).

**22. Distributed Raft-based key-value store** -- implement Raft (§17) yourself (leader election, log replication, the safety properties) backing a simple key-value API -- test correctness specifically by injecting simulated network partitions and node crashes/restarts, since the entire point of Raft is behaving correctly under exactly those conditions.

**23. High-performance RAG/vector database** -- an index structure for approximate nearest-neighbor search over embedding vectors (HNSW -- Hierarchical Navigable Small World graphs -- being the dominant modern algorithm) plus a storage layer (§11/§16) for the vectors and associated metadata; the performance-critical inner loop (distance computation between vectors) is an excellent, concrete target for the SIMD/vectorization techniques in handbook §37.5.

**24. eBPF/XDP packet processor** -- using `aya` (handbook Part VI's eBPF material), write an XDP program doing real packet filtering/redirection at line rate (§10's eBPF/XDP material) -- a focused, narrower-scope alternative to #18's full userspace TCP/IP stack, operating at the opposite end of the kernel-bypass-vs-kernel-integration spectrum.

**25. Rust compiler plugin or `rustc` contribution** -- by far the best "final exam" for this entire roadmap: either a working `rustc_driver`-based tool (a custom lint, using the same APIs `clippy` is built on) or an actual small, well-scoped contribution to `rustc` itself (a diagnostics improvement, a small MIR-lint) -- genuinely requires having internalized §01/§08/handbook §9's compiler-internals material well enough to navigate `rustc`'s own (large, real-world, occasionally under-documented) codebase productively.

## Key Takeaways

- Nearly every capstone here is a focused, standalone application of two or three files from this library plus the handbook, rather than requiring wholly new knowledge -- the roadmap's depth was front-loaded specifically so these projects are "apply what you learned" rather than "learn while building blind."
- Reading real production source code (the first section above) alongside building your own toy version of the same kind of system is consistently more valuable than either alone -- your toy version's design decisions become concrete, answerable questions the moment you compare them against a battle-tested implementation's different choices.
- #21 (container runtime) and #22 (Raft-based KV store) are the two capstones with the most existing, ready-to-use scaffolding already built out in this notes tree (handbook Part VI and this file's §17, respectively) -- reasonable candidates to attempt first if you want the shortest path from "finished reading" to "actually building."
