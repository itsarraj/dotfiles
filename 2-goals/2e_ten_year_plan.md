# 10-Year Master Plan: 2026 - 2036

Low-Level Systems, High-Performance Compute, European Relocation, and Deep-Tech Infrastructure.

One single path. 10000 hours of deep work. Zero lateral pivoting until completion.

---

## 1. Understanding The Instrument: Core Operating Philosophy

### Who You Are
You are an all-or-nothing operator. Moderation does not work for you; it never has.
When you attempt casual engagement with distractions (gaming, videos, social feeds, browsing), you do not dabble for 15 minutes. You slide into auto-mode, lose days or weeks, and construct rationalizations to protect your self-image.
Conversely, when you cut off all secondary paths and lock your environment down to a single target, you achieve extraordinary transformations:
- In Class 12, after falling behind and feeling cornered, you eliminated everything for the final 2 months and secured 91.4% with 94 in Physics and 90 in Mathematics.
- In Trivandrum, feeling sluggish and out of shape at 90 kg, you imposed strict physical discipline, trained without compromise, and cut down to 67 kg of lean muscle.
- In 2025, when you locked yourself into low-level systems and Rust, you absorbed complex concepts rapidly because your hyperfocus had only one direction to flow.

### The Dopamine Vulnerability and Self-Handicapping
Your ADHD neurochemistry has a low baseline dopamine level. Silence, routine, and difficult foundational study (like reading dense textbooks or debugging assembly in gdb) do not feel neutral; they feel agonizing to an under-stimulated brain.
When faced with high-stakes goals, fear of failure activates self-handicapping:
- If you study with 100% focus and struggle, your ego fears finding out that you are not capable.
- If you sabotage yourself with 2x rage-bait videos, gaming, or hopping to a new tech stack, you retain a comfortable excuse: you failed because you were distracted, not because of your intellect.
- The cure is not more willpower. The cure is radical structural elimination. If secondary options do not exist in your physical and digital environment, your focus has nowhere else to go.

### The Physical-Cognitive Coupling
Your mind and body are the exact same machine.
When nutrition slips into refined carbohydrates, sugar, or late-night snacking, insulin spikes and systemic inflammation create immediate brain fog. The ADHD brain immediately seeks cheap noradrenaline to wake itself up, driving you straight into screens and video rabbit holes.
When physical training, clean nutrition, and sleep hygiene are kept airtight, mental friction drops and deep technical work becomes natural.

---

## 2. The 10-Year Macro Architecture (2026 - 2036)

The 10-year horizon is organized into four consecutive phases. Each phase unlocks the next. No jumping ahead.

### Phase 1: Foundations, Systems Mastery, and European Launchpad (2026 - 2027)
- Duration: October 2026 to August 2027 (10 months).
- Primary Focus: Full mastery of computer science fundamentals via GATE CSE syllabus, low-level systems programming (Assembly, C, C++, Rust, Linux internals), AI mathematical foundations and first-principles inference kernels.
- Operational Focus: Save 80% of income, build an untouchable financial runway, clear APS verification, secure Fall 2027 European MS admission (tuition-free or low-cost English-taught programs).
- Benchmark: 1500+ logged deep work hours, fully working SIMD and CUDA compute kernels on GitHub, admission letter in hand.

### Phase 2: European Master of Science and Applied Research (2027 - 2029)
- Duration: September 2027 to August 2029 (2 years).
- Primary Focus: MS in Computer Engineering at a European public university (Germany, Italy, Nordic, or Central European research institution).
- Academic and Technical Specialization: Hardware-aware compilers, accelerator architectures (GPUs, TPUs, RISC-V vector extensions), low-latency distributed runtimes.
- Industry and Lab Focus: Secure research assistantships and elite industry internships in European systems and hardware infrastructure teams.
- Thesis: A high-performance inference engine, custom accelerator kernel runtime, or distributed systems component with direct industrial utility.
- Benchmark: European degree completed, top-tier systems network established, working prototype of proprietary infrastructure software.

### Phase 3: Systems Foundry and High-Performance Infrastructure (2029 - 2032)
- Duration: September 2029 to December 2032 (3 years).
- Primary Focus: Commercializing deep-tech systems software.
- Path A (Primary): Launch a B2B infrastructure startup directly out of MS research or incubator support, focusing on high-throughput compute runtimes, AI inference acceleration, or specialized memory-tier engines.
- Path B (Direct Precursor): Principal/Senior Systems Engineer at an elite high-performance computing, semiconductor, or AI infrastructure firm in Europe, amassing domain authority, commercial insight, and capital reserves while architecting the venture.
- Economic Model: Zero marginal cost software leverage. High enterprise contract values. Retaining substantial equity.
- Benchmark: 6000+ cumulative deep work hours, enterprise revenue or significant venture backing, permanent European residency trajectory locked.

### Phase 4: Technical Hegemony, Capital Compounding, and Sovereignty (2032 - 2036)
- Duration: 2032 to 2036 (4 years).
- Primary Focus: Scaling the systems enterprise or high-level technical leadership, turning high-leverage software output into compounding global assets.
- Lifestyle: Intellectual solitude, complete financial independence, freedom from corporate politics, deep immersion in pure engineering and philosophical pursuits.
- Benchmark: 10000+ deep work hours milestone reached, complete location and temporal freedom, robust investment portfolio independent of active labor.

---

## 3. What To Learn: The Technical Curriculum (Silicon to Runtime)

The technical curriculum spans 6 tiers, moving from raw hardware up to distributed compute runtimes. Everything learned must be verified by writing working code, building benchmarks, and profiling down to the assembly and hardware counters.

### Tier 1: Digital Logic and Computer Architecture
The goal is to understand precisely how electrons and logic gates become instruction execution.
- Digital Logic:
  - Boolean algebra, logic gates, Karnaugh maps, logic minimization.
  - Combinational circuits: adders, subtractors, multiplexers, demultiplexers, encoders, decoders, ALUs.
  - Sequential circuits: latches, flip-flops (SR, JK, D, T), counters, shift registers, finite state machines (Mealy and Moore models).
  - Timing: propagation delay, setup time, hold time, clock jitter, critical path analysis.
  - Primary References: Morris Mano & Ciletti (Digital Design).
- Computer Organization and Architecture (COA):
  - Instruction Set Architectures (ISA): RISC vs CISC principles, register files, instruction encoding.
  - Processor Datapath and Control: single-cycle datapath, multi-cycle datapath, micro-operations, control unit design (hardwired and microprogrammed).
  - Pipelining: 5-stage pipeline, instruction throughput, pipeline hazards (structural, data, control), forwarding, branch prediction (static, 2-bit dynamic, branch target buffer).
  - Memory Hierarchy: SRAM vs DRAM, cache organization (direct mapped, set-associative, fully associative), cache write policies (write-through, write-back, write-allocate), cache line replacement (LRU, FIFO, random).
  - Cache Performance: miss rate, miss penalty, hit time, average memory access time (AMAT), multilevel caches (L1, L2, L3).
  - Virtual Memory: page tables, multi-level paging, Translation Lookaside Buffer (TLB), page faults, inverted page tables.
  - Memory consistency and bus architectures: PCIe, DDR channels, memory controllers, DMA.
  - Primary References: CS:APP (Computer Systems: A Programmer's Perspective by Bryant & O'Hallaron), Morris Mano (Computer System Architecture), Hennessy & Patterson (Computer Architecture: A Quantitative Approach).

### Tier 2: Low-Level Systems Programming and Core Algorithms
The goal is to write software with complete awareness of hardware memory layouts, CPU caches, and instruction streams.
- C and Assembly:
  - Assembly languages: x86-64 (AT&T and Intel syntax), ARM64 (AArch64), RISC-V (RV64I).
  - Calling conventions: System V AMD64 ABI, stack frames, register preservation, parameter passing, return values.
  - C systems programming: pointers, pointer arithmetic, manual memory management (malloc, free, custom arena allocators), struct alignment, padding, bit fields, bitwise manipulation, unions, volatile keyword, inline assembly.
  - Toolchain mastery: GCC, Clang, binutils (as, ld, objdump, readelf, nm), GDB debugging, Valgrind, AddressSanitizer, UndefinedBehaviorSanitizer.
  - Primary References: Kernighan & Ritchie (The C Programming Language), Jonathan Bartlett (Programming from the Ground Up), CS:APP.
- Modern Rust for Systems:
  - Ownership, borrowing, lifetimes, interior mutability (Cell, RefCell), smart pointers (Rc, Arc, Box).
  - Zero-cost abstractions, traits, generics, monomorphization.
  - Unsafe Rust: raw pointers, layout guarantees, FFI (Foreign Function Interface with C), building safe abstractions over raw hardware pointers.
  - Concurrency: Send and Sync traits, atomics, lock-free data structures, channels, Tokio async runtime architecture.
- Data Structures and Algorithms for Systems:
  - Core structures: dynamic arrays, cache-friendly contiguous arrays, linked lists, ring buffers, binary search trees, red-black trees, heaps, priority queues, hash tables (open addressing, robin hood hashing, linear probing vs chaining).
  - Algorithmic analysis: Big-O asymptotic notation, amortized analysis, space-time tradeoffs.
  - Algorithms: sorting (quicksort, mergesort, heapsort, radix sort), graph algorithms (BFS, DFS, Dijkstra, A-star, Bellman-Ford, Prim, Kruskal, topological sort), dynamic programming, divide and conquer, greedy algorithms.
  - Cache-aware and cache-oblivious algorithms: B-trees, matrix transpositions, Morton Z-order curve layouts.
  - Primary References: CLRS (Introduction to Algorithms), Karumanchi (Data Structures and Algorithms Made Easy).

### Tier 3: Operating Systems, Linux Kernel, and Concurrency
The goal is to master the boundary between user space and kernel space, and control process and thread execution.
- OS Foundations:
  - Three pillars: Virtualization (CPU and memory), Concurrency (threads and synchronization), Persistence (file systems and I/O).
  - Process management: process lifecycle, context switching, fork, exec, wait, signals, IPC (pipes, shared memory, message queues, sockets).
  - CPU Scheduling: FIFO, Round Robin, Multi-Level Feedback Queue (MLFQ), completely fair scheduler (CFS), real-time scheduling.
  - Memory virtualization: address spaces, base and bounds, segmentation, paging, page replacement algorithms (FIFO, LRU, Clock), copy-on-write (COW), swap space.
  - Concurrency: race conditions, critical sections, mutual exclusion, locks (spinlocks, mutexes), semaphores, condition variables, reader-writer locks, deadlock conditions and prevention (Coffman conditions).
  - Storage and File Systems: disk mechanics, SSD flash translation layer (FTL), file descriptors, inodes, directories, file allocation (contiguous, linked, indexed), crash consistency and journaling.
  - Primary References: OSTEP (Operating Systems: Three Easy Pieces by Remzi & Andrea Arpaci-Dusseau), Silberschatz (Operating System Concepts).
- Linux Systems Internals:
  - POSIX API: deep dive into system calls (open, read, write, ioctl, mmap, munmap, brk, sbrk, clone).
  - High-performance I/O: select, poll, epoll, non-blocking I/O, event-driven loops, io_uring architecture (submission queue, completion queue, zero-copy kernel transfers).
  - Kernel profiling and tracing: perf, eBPF (BCC, bpftrace), strace, ftrace, hardware performance counters (cache misses, branch mispredictions, IPC).
  - Primary References: TLPI (The Linux Programming Interface by Michael Kerrisk), Brendan Gregg (Systems Performance).

### Tier 4: Accelerated Compute, SIMD, and GPU Architecture
The goal is to exploit massive parallelism for matrix multiplication and high-throughput compute.
- CPU SIMD Vectorization:
  - Vector instruction sets: x86 AVX, AVX2, AVX-512; ARM NEON, ARM SVE; Intel AMX (Advanced Matrix Extensions).
  - SIMD intrinsics: vector data types, load/store (aligned vs unaligned), arithmetic, fused multiply-add (FMA), broadcast, permute, gather/scatter.
  - Optimization of General Matrix Multiply (GEMM): loop tiling/blocking for L1/L2/L3 caches, register blocking, packing matrices into cache-friendly layouts, vectorizing inner loops, instruction-level parallelism.
  - Case study: Analyze VLC hand-tuned assembly and BLIS / OpenBLAS GEMM implementations.
- GPU Architecture and CUDA Programming:
  - GPU hardware model: Streaming Multiprocessors (SM), Warp schedulers, CUDA cores, Tensor Cores, register files, shared memory (scratchpad), L1/L2 caches, high-bandwidth memory (HBM3, GDDR6).
  - CUDA execution model: grids, thread blocks, warps (32 threads), SIMT (Single Instruction Multiple Threads) execution, warp divergence and branch penalty.
  - Memory hierarchy and access patterns: global memory coalescing, bank conflicts in shared memory, texture memory, constant memory.
  - CUDA programming: kernel launches, dynamic shared memory, synchronization (__syncthreads, warp shuffle intrinsics __shfl_sync), cooperative groups, asynchronous memory copies (cudaMemcpyAsync), CUDA streams, CUDA graphs.
  - PTX (Parallel Thread Execution): reading and inspecting intermediate assembly, register allocation limits, occupancy analysis.
  - Tensor Core programming: WMMA (Warp Matrix Multiply and Accumulate) API, MMA PTX instructions.
  - Primary References: David Kirk & Wen-mei Hwu (Programming Massively Parallel Processors: A Hands-on Approach), NVIDIA CUDA C++ Programming Guide.

### Tier 5: AI Mathematical Foundations and High-Performance Inference Runtimes
The goal is to master AI from first principles without relying on high-level frameworks like PyTorch or HuggingFace in production. Python is used only as an executable mathematical scratchpad.
- Mathematical Foundations:
  - Linear Algebra: vector spaces, basis, linear transformations, matrix factorizations (LU, QR, SVD, Cholesky), eigenvalues and eigenvectors, spectral theorem, positive definite matrices.
  - Calculus and Optimization: partial derivatives, gradients, Jacobians, Hessians, Taylor series, convex functions, gradient descent, momentum, Adam optimizer math.
  - Probability and Statistics: random variables, conditional probability, Bayes rule, common distributions, expectation, variance, covariance, maximum likelihood estimation (MLE), central limit theorem.
  - Primary References: Gilbert Strang (Linear Algebra and Its Applications), Grewal (Higher Engineering Mathematics), Marc Peter Deisenroth (Mathematics for Machine Learning).
- Deep Learning Architecture Internals:
  - Neural network fundamentals: multilayer perceptrons (MLP), forward pass, backpropagation from scratch using raw matrix calculus.
  - Transformer architecture: token embeddings, positional encodings (RoPE, sinusoidal), multi-head self-attention (MHA), multi-query attention (MQA), grouped-query attention (GQA), feed-forward networks (SwiGLU, GeLU), layer normalization (RMSNorm, LayerNorm).
- Inference Engine Architecture:
  - Memory bottleneck in LLM inference: compute-bound prefill phase vs memory-bandwidth-bound decode phase (arithmetic intensity analysis).
  - FlashAttention: online softmax algorithm, tiling attention matrices to fit entirely within GPU SRAM / shared memory, avoiding high-latency HBM round-trips.
  - KV Cache optimization: continuous batching, PagedAttention (virtual memory paging applied to transformer KV caches), prefix caching.
  - Quantization algorithms: uniform symmetric/asymmetric quantization, INT8 weight-only, INT4 (AWQ, GPTQ), FP8 formats (E4M3, E5M2), dequantization kernels.
  - Project implementations: build a standalone C/C++/Rust transformer inference engine (similar to llama.cpp / mistral.rs architecture) from raw pointers, SIMD, and custom CUDA kernels with zero Python runtime dependencies.

### Tier 6: Compilers and Hardware-Software Co-Design
The goal is to translate high-level computational graphs into optimal machine code for diverse silicon targets.
- Classic Compiler Architecture:
  - Front-end: lexical analysis (lexers, DFA), syntax analysis (LL and LR parsing, AST construction), semantic analysis, type systems.
  - Intermediate Representation (IR): control flow graphs (CFG), static single assignment (SSA) form.
  - Optimizations: constant propagation, dead code elimination, loop invariant code motion, common subexpression elimination (CSE), inlining, register allocation (graph coloring).
  - Code generation: instruction selection, instruction scheduling, peephole optimizations.
  - Primary References: Aho, Lam, Sethi, Ullman (Compilers: Principles, Techniques, and Tools - Dragon Book).
- Modern ML Compilers and IR:
  - LLVM infrastructure: LLVM IR, passes, target backends.
  - MLIR (Multi-Level Intermediate Representation): dialects, progressive lowering from graph level to hardware primitives.
  - Polyhedral compilation: loop nest representations, affine transformations, tiling, skewing, automatic vectorization and parallelization.
  - Primary References: Chris Lattner papers on MLIR, TVM / IREE architecture documentation.

---

## 4. How To Approach Future Things: Strategic Playbook

### The Elimination Rule
- Never rely on willpower to resist distraction. An ADHD brain under stress will lose that battle.
- Eradicate the alternative: if games are uninstalled, phone is physically separated in another room, social media accounts are deleted, and video feeds are hard-blocked at the DNS and hosts level, focus naturally channels into the terminal and the textbook.
- Reject the trap of exploring multiple languages and frameworks. When a concept is hard, your brain will scream to switch to a shiny new technology (Go, Web3, game dev, mobile apps). Recognize that urge as fear of inadequacy. Remain locked on Assembly, C, C++, Rust, and Linux.

### The 15-Minute Airlock Protocol
- When dopamine overload strikes (bingeing on 2x videos, sudden restlessness, mental burnout), never attempt to switch immediately to dense technical study. The contrast will feel unbearable.
- Execute the airlock: screen off, phone away, lie on the floor or sit staring at a wall in total silence for 15 minutes.
- Let the noradrenaline and dopamine surge drain away. Once your baseline settles into quiet neutrality, open your editor and write one single function or assemble one small program. Momentum will handle the rest.

### The Two-Minute Activation Rule
- Large goals paralyze the ADHD prefrontal cortex. Saying "I must master CUDA tonight" triggers threat avoidance and internet distraction.
- Shrink the initiation threshold to two minutes: "I will open my editor, write ten lines of C, and compile with gcc -O3 -S to inspect the generated assembly."
- Once your hands are on the keyboard and the terminal is active, hyperfocus takes over and the block is won.

### Physical Grounding as the Operating Foundation
- Physical exercise is not a recreational hobby; it is neurological maintenance for your brain.
- Maintain calisthenics and progressive bodyweight/weight training 4 to 5 days per week.
- Eliminate refined carbohydrates, liquid sugars, and snacking. Adopt intermittent fasting to maintain stable blood glucose and razor-sharp mental acuity during deep work windows.
- When restlessness or agitated noradrenaline spikes occur, discharge them into physical grit (push-ups to failure, pull-ups, cold showers) rather than visual stimulation on screens.

### Relocation Strategy: The European Path
- Financial discipline: With low monthly overhead, save 80% of your software engineering income. Build an untouchable financial buffer for visa requirements and initial relocation runway.
- Educational route: Target tuition-free or low-fee public universities in Germany (TUs like TU Munich, RWTH Aachen, TU Berlin, Karlsruhe, Stuttgart), Italy (Politecnico di Milano, Politecnico di Torino), Nordic countries, or Austria.
- Language barrier elimination: Focus strictly on programs taught 100% in English. Leverage your B.E. English medium of instruction certificate or clear IELTS early to remove all academic friction. Clear APS early.
- Treat the European MS not as academic pedigree, but as a low-cost geographic anchor and institutional gateway to elite labs, high-throughput systems teams, and European deep-tech funding.

### Commercialization and Wealth Creation
- Real wealth is never built on hourly wages or salaried corporate employment; it is created by owning equity in scalable infrastructure that solves high-friction enterprise bottlenecks.
- Low-level systems engineering has immense economic leverage because high-performance kernels and inference runtimes directly reduce enterprise cloud computing bills by millions of dollars.
- When an inference runtime delivers a 3x speedup with half the GPU memory footprint, the value proposition to enterprise clients is immediate, quantitative, and undeniable.
- Maintain intense focus on low-level technical depth during Phases 1 and 2, then leverage that mastery to build proprietary, high-throughput systems infrastructure in Phase 3.

---

## 5. Year-by-Year Milestone Roadmap (2026 - 2036)

### Year 1 (Oct 2026 - Sep 2027): Foundation and Relocation Launch
- Months 1-4 (Oct 2026 - Jan 2027): Complete all core GATE CSE and DA subjects. Digital logic, engineering mathematics, discrete maths, C, data structures, algorithms, COA, OS, compilers, networks, databases.
- Months 5-7 (Feb 2027 - Apr 2027): Deep dive into CS:APP, OSTEP, TLPI. Implement custom SIMD GEMM on x86-64 and ARM. Write a multithreaded HTTP/1.1 and TCP server from scratch in C using epoll.
- Months 8-10 (May 2027 - Jul 2027): CUDA architecture, warp mechanics, Tensor Core programming. Build a standalone transformer inference runtime in C++/CUDA with FlashAttention and INT8 quantization. Finalize European MS applications and visa documentation.
- Months 11-12 (Aug 2027 - Sep 2027): Relocate to Europe. Settle into university, establish physical training environment, integrate into systems lab.

### Years 2-3 (Oct 2027 - Sep 2029): European MS and Systems Lab Immersion
- Focus on hardware-software co-design, accelerator architectures, compiler intermediate representations (MLIR, LLVM), and distributed memory systems.
- Complete high-performance research internships at European systems companies or compute research labs.
- Deliver an outstanding Master's thesis on accelerated inference engines or memory-tier runtimes.
- Build deep relationships with technical peers, professors, and industry researchers.

### Years 4-6 (Oct 2029 - Dec 2032): Deep-Tech Systems Foundry
- Commercialize proprietary infrastructure software or lead high-performance systems engineering at an elite deep-tech firm.
- Target high-throughput inference runtimes, custom accelerator kernels, or distributed storage/compute engines.
- Acquire first enterprise contracts, build recurring infrastructure revenue, or secure deep-tech grant and venture funding.
- Cross the 6000 deep work hours milestone. Secure European permanent residency status.

### Years 7-10 (2033 - 2036): Scale, Technical Hegemony, and Sovereignty
- Expand enterprise infrastructure adoption, license proprietary compute runtimes, or transition into principal technical authority.
- Reinvest software cash flows into global productive assets and compounding capital reserves.
- Achieve total financial sovereignty, intellectual solitude, and independence from corporate bureaucracy.
- Cross the 10000 deep work hours mark as a world-class authority in low-level systems and compute infrastructure.

---

## 6. The Non-Negotiable Operating Laws

These laws are permanent. They are not open for daily renegotiation.

1. The Single Path Law: Low-level systems, high-performance compute, and modern computer architecture. No game dev, no web frontend, no crypto, no random app ideas. 10000 hours before any reconsideration.
2. The Environment Law: Willpower is a biological illusion. Control the environment and the behavior follows automatically. Screen locks, feed blockers, clean desk, offline technical resources.
3. The Body-Mind Law: The physical body is the hardware that runs the cognitive software. Sleep 7-8 hours, train with calisthenics, cut refined sugar and fast carbs, practice intermittent fasting.
4. The No-Zero-Day Law: Even on days with low energy or emotional friction, sit down and execute a minimal 15-minute block. Read two pages of architecture or assemble one instruction file. Never allow inertia to reverse direction.
5. The Radical Responsibility Law: Zero blame on parents, college, past failures, or external circumstances. You are the sole architect of your trajectory.
6. The Output Verification Law: Reading textbooks is only stage one. Knowledge is not locked in until verified by writing working code, running tests under GDB/Valgrind, and measuring execution cycles on real silicon.
