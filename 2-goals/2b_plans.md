# Plans

**Updated**: 2026-10-18

---

## Mission

Get a Rust/low-level systems job in Bangalore. Move out. Decide what's next from there.

---

## Reality Check: What Bangalore Rust Jobs Actually Look Like

Most Rust roles in Bangalore fall into these buckets:

| Tier | Type | Companies | Alignment |
|---|---|---|---|
| 🎯 Best fit | Security / networking systems | Zscaler, Fortanix | High — real low-level Rust |
| 🎯 Best fit | Storage / distributed infra | Nutanix, Aerospike, Commvault, Druva | High — systems work |
| ✅ Good fit | Database internals | MongoDB, Databricks | Medium — real engineering |
| ✅ Good fit | AI infra / serving | deep-tech startups | Medium — growing space |
| ⚠️ Fallback | Backend/fintech | Zerodha, fintechs | Lower — Rust but not systems |

**What they all require:**
- Rust ownership/borrowing/lifetimes — deep, not surface level
- Tokio / async Rust — almost universal
- Linux / Unix systems knowledge — processes, file descriptors, signals, sockets
- Adjacent: C/C++ readable at minimum, some DS&A for interviews

---

## The Two Tracks (run in parallel)

### Track 1: Rust Depth + Portfolio

**Phase A: Rust for Rustaceans (current)**

Read and build. One chapter, one project. In order.

| # | Chapter | Concept | Build |
|---|---|---|---|
| 1 | Ch 1 — Types | memory layout, variance, PhantomData, ZST | typed newtype wrappers for file descriptors |
| 2 | Ch 2 — Traits & Generics | dyn vs impl, vtables, monomorphization, orphan rule | trait-based Read/Write over custom types |
| 3 | Ch 3 — Designing Interfaces | type-state, builder pattern, sealed traits, must-use | type-state file descriptor (Open/Closed) |
| 4 | Ch 4 — Error Handling | thiserror, anyhow, error wrapping, context chains | syscall wrapper with typed errno enum |
| 5 | Ch 5 — Project Structure | workspaces, feature flags, cfg, conditional compilation | multi-crate workspace: syscall-raw / syscall-safe / CLI |
| 6 | Ch 6 — Testing | proptest, cargo-fuzz, test isolation | fuzz parser for /proc/self/status |
| 7 | Ch 7 — Macros | macro_rules!, hygiene, tt-muncher | macro that generates typed syscall wrappers |
| 8 | Ch 8 — Async | Future, Waker, Poll, Pin, state machine desugaring | minimal single-threaded async executor |
| 9 | Ch 9 — Unsafe | raw pointers, invariants, soundness, safe abstractions | arena/bump allocator, no_std compatible |
| 10 | Ch 10 — Concurrency | atomics, memory ordering, ABA, lock-free patterns | lock-free stack with AtomicPtr + compare_exchange |

**Phase B: Async Rust (after RfR — non-negotiable for jobs)**

Tokio is in almost every Bangalore Rust job description.

- Tokio tutorial — tasks, channels, select!, timeouts
- Build: async TCP server that handles multiple clients
- Build: async file watcher using inotify + Tokio

**Phase C: Portfolio Projects (build alongside, don't wait)**

These go on GitHub with clean READMEs. This is what gets you interviews.

| Project | What it shows | README must cover |
|---|---|---|
| `fd-safe` — type-safe Linux syscall wrappers | unsafe Rust, Linux API knowledge, type design | why type-state, what errors it prevents, code examples |
| `bump-alloc` — arena allocator, no_std | unsafe Rust, memory model, allocator interface | benchmark vs system alloc, safety invariants documented |
| `lockfree-stack` — AtomicPtr lock-free stack | concurrency, atomics, unsafe Rust | ABA discussion, memory ordering rationale, stress test results |
| `mini-executor` — hand-rolled async executor | deep async understanding, Future/Waker internals | how it works diagram, comparison to Tokio's design |
| `proc-parser` — /proc/self/maps parser + fuzzer | byte parsing, cargo-fuzz, Linux proc knowledge | fuzzing setup, bugs found, format documented |

**What makes a project hireable vs toy:**
- Handles error cases explicitly — not just `unwrap()` everywhere
- Has tests — at minimum unit, ideally property or fuzz
- README explains *why*, not just *what*
- Commits are clean and tell a story (no "fix", "wip", "stuff")

---

### Track 2: Job Search (start now, don't wait for "ready")

**Role titles to search (use these exact strings on LinkedIn/Cutshort):**
- `Rust Engineer` / `Rust Developer`
- `Systems Engineer Rust`
- `Software Engineer - Storage`
- `Infrastructure Engineer`
- `Platform Engineer Rust`
- `Backend Engineer Systems`

**Companies to target (Bangalore):**

Priority 1 — Systems/infra (best alignment):
- Zscaler — networking/security systems in Rust+C++
- Fortanix — cryptography, confidential compute, Rust-first
- Nutanix — distributed storage, infra
- Commvault — data protection, storage systems
- Druva — cloud data management
- Aerospike — high-performance database

Priority 2 — Good engineering:
- MongoDB — database internals
- Databricks — data infra
- Flipkart / Myntra infra teams
- ThoughtSpot — analytics infra

Priority 3 — Fallback, apply broadly:
- Startups on Wellfound/Instahyre with Rust in stack
- Any company using Tokio / async Rust in production

**Where to apply:**
- LinkedIn (set open to work: Bangalore, Rust, systems)
- Cutshort — best for Bangalore product startups
- Instahyre — good for MNC tech centers
- Wellfound — startups
- Hirist — tech-focused
- RustJobs.dev — Rust-specific board
- Direct career pages: Zscaler, Fortanix, Nutanix

**Resume must-haves:**
- Current role and what you built (be specific: language, scale, what it does)
- Rust projects with links to GitHub
- Linux / systems keywords: syscalls, file descriptors, async, concurrency
- No fluff — every bullet = what you built + how + result

**Interview prep (do alongside, not after):**
- Rust: ownership, borrowing, lifetimes, trait objects, async runtime model
- Linux basics: processes, threads, file descriptors, epoll, signals, mmap
- DS&A: arrays, linked lists, trees, hash maps, BFS/DFS — Rust impls preferred
- System design: basic distributed systems (queues, caches, consistent hashing)

---

## Daily Execution

One thing at a time. Finish it. Then next.

No parallel tasks open at the same time.  
No switching mid-session.

Morning block → Rust reading + build  
Spare time → job applications, resume, LinkedIn

---

## What's Parked

Everything below is parked until after the move to Bangalore:

- GATE prep
- MS applications
- Assembly, CUDA, SIMD, AVX-512 deep work
- COA, OS from scratch, Digital Logic
- x86-64 / ARM / RISC-V architecture deep dives
- GPU compute (CUDA, PTX, Tensor Cores)
- Matrix extensions (AMX, SME, NEON)

Not abandoned. Queued. Focus on the exit first.

---

## North Star (post-Bangalore, post-job)

Low-level systems mastery: modern architecture (x86-64, ARM, RISC-V), SIMD/matrix extensions (AVX-512, NEON, AMX, SME), GPU compute (CUDA, PTX, Tensor Cores), C/C++/Rust, Linux internals — inference runtimes, high-performance compute kernels, distributed infrastructure.

The Rust job is step one on this path, not a detour from it.  
Book → portfolio → job → Bangalore → then go deep.

---

## Clarity Layer: C and ASM woven into Rust (not separate tracks)

The goal is not three parallel tracks. It is one track -- Rust -- read through two lenses
that make the machine-level behavior visible.

### The method: Read, Build, Dissect

For every RfR chapter + build project, add two dissection steps:

1. Compile Rust to ASM and read it.
   cargo rustc --release -- --emit=asm
   cargo asm --lib <function_name>        # if cargo-asm is installed
   Look at Compiler Explorer (godbolt.org) -- paste Rust, read x86-64 output.

2. Write the equivalent in C (10-30 lines). Compile both. Compare the output.
   gcc -O2 -S file.c -o file_c.s
   The C is not a deliverable. It is a lens. You are not learning C -- you are using C
   to see what Rust is doing underneath, because C maps to ASM almost 1:1.

### Per-chapter dissection targets

These are NOT extra projects. They are add-ons to existing build projects (15-30 min each).

| RfR Ch | Rust build | What to dissect in ASM/C |
|---|---|---|
| Ch 1 -- Types | newtype fd wrapper | What does newtype cost? Compare `struct Fd(i32)` vs bare `i32` in ASM. Zero. |
| Ch 2 -- Traits | trait Read/Write over types | What does dyn dispatch look like in ASM vs impl Trait? See the vtable call vs direct call. |
| Ch 3 -- Interfaces | type-state Fd | Does PhantomData appear in ASM? No. Verify it. ZST = zero bytes in output. |
| Ch 4 -- Error Handling | syscall errno wrapper | What does a Result<i32, Errno> look like in memory? Compare to C's int + errno. |
| Ch 5 -- Project Structure | multi-crate workspace | How does static linking look? Use nm and readelf on the final binary. |
| Ch 6 -- Testing | /proc parser + fuzzer | What does the parser compile to? Compare handwritten C parser output. |
| Ch 7 -- Macros | macro syscall wrappers | Do macro-generated functions inline? Check with cargo-asm. |
| Ch 8 -- Async | mini executor | What does Poll::Pending look like in ASM? Trace one state machine transition. |
| Ch 9 -- Unsafe | arena allocator | Compare to a C bump allocator. The ASM should be nearly identical. |
| Ch 10 -- Concurrency | lock-free stack | What does compare_exchange compile to? See the lock cmpxchg instruction directly. |

### What to read when you need a concept explained

When a concept in a chapter is unclear, look it up in your existing reference files -- not Google:

- Rust ownership/borrowing mechanics at machine level: 1-resources/12-rust/01-ownership-internals.md
- How the Rust compiler actually works (MIR, LLVM, drop flags): 1-resources/12-rust/08-mir-llvm-deep.md
- x86-64 instruction reference when you read the ASM output: 1-resources/11-assembly/01-instruction-reference-deep.md
- Inline asm syntax (asm! macro in Rust): 1-resources/11-assembly/08-inline-assembly-c-rust.md
- Syscall mechanics (for Ch 4 errno work): 1-resources/11-assembly/04-syscalls-os-interface.md
- Atomics at the instruction level (for Ch 10): 1-resources/11-assembly/05-interrupts-exceptions-privileged-atomics.md

### Tools to install once

cargo install cargo-asm      # reads ASM for specific Rust functions
cargo install cargo-expand   # expands macros, useful for Ch 7
# objdump, nm, readelf -- already on your Linux install

