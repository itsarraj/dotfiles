**Here is the complete consolidated list of all books mentioned** in the provided note, with their short specialties (based on the context given in the notes for your container runtime / replacing `containerd` project).

### Underrated & Deep-Dive Gems
1. **Linux Kernel Programming (2024 Edition)** — Kaiwan N. Billimoria  
   Modern kernel (6.x) focus; code-level details on synchronization, memory allocation, and cgroup management.

2. **Professional Linux Kernel Architecture** — Wolfgang Mauerer  
   Extremely detailed breakdown of Virtual Filesystem (VFS), process management, and kernel data structures.

3. **Container Security** — Liz Rice  
   Practical guide to container internals: namespaces, cgroups, system calls (`clone`, `unshare`, `setns`) from scratch.

### Indispensable Standards
4. **The Linux Programming Interface (TLPI)** — Michael Kerrisk  
   The bible for Linux system calls, namespaces, cgroups, processes, signals, epoll, and low-level APIs.

5. **Linux System Programming** — Robert Love  
   Pragmatic, code-focused bridge between kernel calls and efficient user-space implementation.

### Rust-Specific
6. **Rust Systems Programming (2024)** — Marko Boros  
   Rust-centric guide to Linux kernel abstractions, signals, file descriptors, and safe low-level systems code.

7. **Rust for Rustaceans** — Jon Gjengset  
   Advanced Rust architecture: unsafe code, zero-cost abstractions, memory management, and concurrency.

8. **Programming Rust**  
   Comprehensive coverage of ownership, lifetimes, unsafe Rust, FFI, concurrency, and performance.

9. **Rust Atomics and Locks**  
   Deep dive into memory ordering, atomics, mutexes, and lock-free programming for concurrent runtimes.

### Classic C / UNIX Systems Programming
10. **Advanced Programming in the UNIX Environment (APUE)** — W. Richard Stevens  
    Definitive reference on processes, fork/exec, file descriptors, signals, and streams.

11. **Expert C Programming: Deep C Secrets**  
    Memory layout, undefined behavior, ABI, linkers, and low-level C details.

12. **UNIX Systems Programming**  
    Practical coverage of pipes, fork, IPC, signals, and daemons.

### Kernel-Focused
13. **Linux Kernel Development**  
    Scheduler, virtual memory, interrupts, filesystems, synchronization, and kernel internals.

14. **Understanding the Linux Kernel**  
    In-depth on task structures, memory allocator, VFS, signals, scheduler, and system calls.

15. **Linux Insides** (Free online)  
    Real kernel code walkthrough: boot process, memory, scheduler, syscalls.

### Performance & Observability
16. **Systems Performance**  
    CPU, memory, NUMA, page cache, eBPF, perf, flame graphs, and bottleneck analysis (critical for cost reduction).

17. **BPF Performance Tools**  
    eBPF, tracing, latency analysis, scheduler, and syscall tracing.

### Foundational Computer Systems
18. **Computer Systems: A Programmer's Perspective**  
    CPU architecture, memory hierarchy, ELF, linking, processes, virtual memory, caches, and performance.

19. **Operating Systems: Three Easy Pieces** (Free)  
    Clear explanations of virtual memory, scheduling, filesystems, concurrency, and threads.

### Networking
20. **Computer Networking: A Top-Down Approach**  
    Networking fundamentals relevant to veth, bridges, NAT, iptables, and overlay networks.

21. **TCP/IP Illustrated, Volume 1**  
    Detailed TCP/IP protocol behavior for container networking.

### Distributed Systems / Orchestration
22. **Designing Data-Intensive Applications**  
    Core concepts for building reliable distributed systems (useful for orchestration).

23. **Site Reliability Engineering**  
    Google’s practices for running large-scale production systems.

### C++ Books (Supplementary)
24. **Hands-On System Programming with C++** — Rian Quinn  
    Modern C++ for systems: caching, memory alignment, namespaces, and cgroups.

25. **Effective Modern C++**  
    Modern C++ best practices (helpful for reading C++ codebases).

26. **C++ Concurrency in Action**  
    Concurrency patterns that translate well to Rust.

---

**Recommended Reading Priority** (synthesized from the notes):
- Start with **TLPI**, **Computer Systems: A Programmer's Perspective**, and **Systems Performance**.
- Then go deeper into kernel books and Rust-specific ones.
- Study **youki** + **runc/containerd** source code in parallel.

This list covers everything mentioned. Let me know if you want publication years, editions, a prioritized study plan, or summaries for any specific book!
