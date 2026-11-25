# Plans

**Updated**: 2026-11-25

---

## Mission

Move to Bangalore. Build the stack layer by layer. Find or build the right thing. Exit India.

---

## The Stack Layers — What Each Needs

### Layer 1 — Browser / Backend (partial — day job)
```
TypeScript + Rust (Axum, Tokio, WASM)
```
Status: active in day job (Rust iced + LangChain backend).  
Bottleneck: none for now. Don't spend extra time here.

---

### Layer 2 — OS / Systems (building now — primary personal track)
```
Rust + C + x86-64 ASM + Linux internals
```
What you need:
- Rust: deep ownership, unsafe, FFI, raw syscalls — via RfR
- C: readable, writable — C maps to ASM 1:1, use it as a lens
- ASM: read x86-64 output from Rust/C, write inline `asm!()` in Rust
- Linux: processes, file descriptors, mmap, epoll, signals, /proc, namespaces

Bottleneck: kernel is in C. Rust is a guest. You need to be comfortable in both.

Resources:
- Rust for Rustaceans (Jon Gjengset) — primary
- OSTEP (Operating Systems: Three Easy Pieces) — free online
- TLPI (The Linux Programming Interface) — reference
- Compiler Explorer (godbolt.org) — read ASM output constantly
- Ardan Labs Ultimate Rust (Wolverson) — video reference on own machine

---

### Layer 3 — CPU / SIMD (next after Layer 2 is solid)
```
Rust std::arch + AVX-512 / NEON + microarchitecture awareness
```
What you need:
- CPU microarchitecture: cache hierarchy (L1/L2/L3), instruction latencies, pipelining
- SIMD: `std::arch` in Rust, `packed_simd`, `portable-simd` (nightly)
- Profiling: `perf`, `cachegrind`, `flamegraph`
- Reading: Agner Fog's optimization manuals (free, authoritative)

Bottleneck: most people write slow SIMD. Cache misses kill performance before you even vectorize.  
Entry project: write a GEMM (matrix multiply) in Rust — scalar first, then SIMD-optimized.

---

### Layer 4 — GPU Compute / AI Chip Software Stack (the target)
```
CUDA + PTX + cudarc + wgpu + inference runtimes + MLIR
```
What this actually is (NOT chip design):
- Writing kernels that run ON the GPU
- Optimizing AI inference (like llama.cpp, tinygrad, candle — but you built it)
- Writing compiler passes for AI accelerators (MLIR, LLVM backends)

What you need:
- CUDA programming model: thread/block/grid hierarchy, shared memory, warp execution
- GPU memory hierarchy: global → shared → registers — most people get this wrong
- PTX: the GPU's "assembly" — NVIDIA compiles CUDA → PTX → SASS. You can write PTX directly.
- Rust on GPU: `cudarc` (CUDA bindings), `wgpu` (cross-platform), `burn`, `candle`
- Inference runtimes: study llama.cpp, tinygrad, candle source — then build your own slice

Bottleneck: Rust has no first-class CUDA support. You write CUDA kernels in C/CUDA, call from Rust via cudarc. Or drop to PTX. This is the real gap to close.

Your existing edge: containerd + AI runtime work is directly adjacent. You understand the runtime layer.

Entry project: implement a fused softmax kernel in CUDA, call it from Rust via cudarc.

Resources:
- CUDA Programming Guide (NVIDIA docs) — free
- Programming Massively Parallel Processors (Kirk & Hwu) — the textbook
- tinygrad source — read it, it's small and brilliant
- candle (HuggingFace) — Rust ML framework, study the source

---

## The Two Running Tracks

### Track A: Day Job — Execute Well (ITC Infotech / SAP Labs)

Project: screen recording + AI demo tool, Rust iced + LangChain/LangGraph backend.  
You are solo dev. Treat it like a founder project.

Extract maximum value:
- Write clean, documented Rust — it is your portfolio code
- Push to GitHub (check NDA carefully — if not possible, write about it)
- Document design decisions — blog post or tweet thread showing your thinking
- Ask SAP seniors for intros to anyone doing infra or AI infra work
- Every deliverable is a demo of what you can build solo

---

### Track B: Personal Portfolio (own time — 1-2 hours daily minimum)

**Phase A: Rust for Rustaceans — finish this first**

One chapter → one build project → one ASM dissection. In order. No skipping.

| # | Chapter | Build | Dissect with ASM/C |
|---|---|---|---|
| 1 | Types — layout, variance, PhantomData, ZST | typed newtype fd wrappers | struct Fd(i32) vs i32 — verify zero cost |
| 2 | Traits & Generics — dyn, vtables, monomorphization | trait Read/Write on custom types | dyn dispatch vs impl Trait in ASM |
| 3 | Designing Interfaces — type-state, builder, sealed | type-state Fd (Open/Closed) | PhantomData in ASM — verify zero bytes |
| 4 | Error Handling — thiserror, anyhow, context | syscall wrapper + typed errno enum | Result<i32,Errno> layout vs C int+errno |
| 5 | Project Structure — workspaces, features, cfg | multi-crate: syscall-raw / syscall-safe / CLI | nm + readelf on final binary |
| 6 | Testing — proptest, cargo-fuzz | /proc/self/status parser + fuzzer | compare to C parser output |
| 7 | Macros — macro_rules!, tt-muncher | macro-generated syscall wrappers | do macro fns inline? cargo-asm |
| 8 | Async — Future, Waker, Pin, state machine | minimal single-threaded async executor | Poll::Pending state machine in ASM |
| 9 | Unsafe — raw pointers, invariants, soundness | arena/bump allocator, no_std | compare to C bump allocator — near-identical ASM |
| 10 | Concurrency — atomics, ordering, lock-free | lock-free stack, AtomicPtr + compare_exchange | lock cmpxchg instruction in output |

**Phase B: Tokio (non-negotiable for jobs)**

After RfR. Required for almost every Bangalore Rust role.
- Tokio book: tasks, channels, select!, timeouts
- Build: async TCP server, multiple clients
- Build: async file watcher with inotify + Tokio

**Phase C: Portfolio Projects (GitHub — this is what gets you interviews)**

| Project | Layer | What it shows |
|---|---|---|
| `fd-safe` — type-safe Linux syscall wrappers | OS | unsafe Rust, Linux API, type design |
| `bump-alloc` — arena allocator, no_std | OS | unsafe Rust, memory model |
| `lockfree-stack` — AtomicPtr, compare_exchange | OS/CPU | concurrency, atomics |
| `mini-executor` — hand-rolled async executor | OS | Future/Waker internals |
| `gemm-simd` — matrix multiply, scalar then SIMD | CPU | microarchitecture awareness, perf |
| `cuda-softmax` — fused softmax kernel + Rust caller | GPU | CUDA model, cudarc, kernel writing |

Each project needs: clean README explaining *why*, error handling, tests, clean commits.

---

## Bangalore Move (do this now)

Job is remote. Move anyway. The environment and network are worth more than the commute saved.

- Budget: 3k–6k/month PG or room share
- Areas: HSR Layout, Koramangala, Indiranagar, Whitefield
- Communities to plug into immediately:
  - HasGeek events — best tech community in Bangalore, systems/infra people
  - Rust India — Telegram group + meetups
  - Nasscom 10000 Startups — free coworking, founder events
  - Dukaan, Setu, Hasura, Obvious — Bangalore startups worth watching

What to do at events: talk about what you're building (day job + personal projects). Listen for the problem worth solving.

---

## Founder / Startup Path

You don't need the idea yet. You need to be in the room.

What to look for in a co-founder or early team:
- Building in infra, AI infra, developer tools, GPU compute
- Technical, pre-seed or just seed
- Needs someone who can own engineering solo

When to move:
- Find something worth betting on → join part-time first, then full
- Nothing fits → build your own once you have savings + depth in Layer 3-4
- Systems role abroad opens → take it, startup follows later

---

## Job Search (keep warm, don't stop)

Even with current job, stay visible.

Titles: `Rust Engineer`, `Systems Engineer`, `Infrastructure Engineer`, `Platform Engineer`

Companies (Bangalore, in priority order):
- Zscaler, Fortanix — security/networking, real low-level Rust
- Nutanix, Commvault, Druva, Aerospike — storage/infra
- MongoDB, Databricks — database internals
- NVIDIA Bangalore — if GPU layer is solid enough
- Startups on Wellfound, Cutshort with Rust in stack

Boards: LinkedIn, Cutshort, Instahyre, Wellfound, Hirist, RustJobs.dev

Interview prep (run alongside, not after):
- Rust: ownership, lifetimes, trait objects, async internals, unsafe
- Linux: processes, threads, fd, epoll, signals, mmap
- DS&A: arrays, trees, hash maps, BFS/DFS — implement in Rust
- System design: queues, caches, consistent hashing, distributed basics

---

## Daily Execution

One thing at a time. No context switching mid-session.

```
Morning     →  Day job (ship, build clean, document)
Evening     →  Personal track (RfR chapter or portfolio project)
Weekends    →  Events, meetups, founder conversations, CUDA exploration
```

---

## What's Parked

- GATE — not relevant
- MS Europe/USA — revisit after Bangalore, savings, depth in Layer 3-4
- Actual chip design (Verilog, RTL, silicon) — different career, not mine
- AVX-512 / NEON deep work — after Tokio + portfolio done
- MLIR / compiler passes — after CUDA layer is entered

Not abandoned. Sequenced. Exit first. Go deep from a position of strength.
