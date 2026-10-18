# Assembly, OS, Linking, and Performance -- Pointer File (Levels 6-9)

These four roadmap levels are already covered in full depth in [`../16a-rust-systems-programming.md`](../16a-rust-systems-programming.md) -- this file exists so the numbering here is complete and traceable, and adds the two specific subtopics from the roadmap (Huge Pages, NUMA) that weren't yet covered there.

| Roadmap Level | Topic | Where |
|---|---|---|
| L6 Assembly | Registers, calling conventions, SIMD/AVX/SSE, stack, heap, instructions, branch prediction, pipelines, caches, interrupts, syscalls, context switching | Handbook Part I, Ch 1-6 |
| L7 OS | Processes, threads, ELF, scheduler, signals, memory mapping, virtual memory, paging, MMU, TLB, copy-on-write, syscalls, namespaces, cgroups | Handbook Ch 36, and Part VI Ch 41-45 for namespaces/cgroups/signals in full applied depth |
| L8 Linking | Object files, relocations, ELF, GOT, PLT, PIC, PIE, symbol visibility | Handbook Ch 8 |
| L9 Performance | Caches, cache lines, false sharing, SIMD, alignment, prefetching, instruction latency/throughput, branch prediction, loop unrolling, inlining | Handbook Ch 37 |

## Filling the Two Gaps: Huge Pages and NUMA

### Huge Pages

Ordinary pages are 4 KiB (handbook §1.8) -- every one requires its own TLB entry, and the TLB has a limited number of slots (typically dozens to a few hundred). A process with a large working set (many gigabytes) touches far more distinct 4 KiB pages than the TLB can hold entries for, causing frequent **TLB misses**, each of which costs a full page-table walk (handbook §1.8) -- multiple extra memory accesses just to translate an address, on top of the actual access itself.

**Huge pages** (2 MiB or 1 GiB on x86-64, vs. the standard 4 KiB) reduce the number of distinct pages covering the same amount of memory by three to six orders of magnitude -- a 1 GiB working set needs ~262,144 standard pages but only 1 single 1 GiB huge page, meaning far fewer (or zero) TLB misses for the same memory footprint. Linux offers two mechanisms: **`hugetlbfs`** (explicitly reserved, pre-allocated huge pages an application requests directly) and **THP (Transparent Huge Pages)** (the kernel opportunistically backs ordinary allocations with huge pages automatically, no application changes needed, at the cost of some unpredictability -- THP's background page-compaction work to *find* contiguous huge-page-sized regions can itself cause latency spikes, which is why latency-sensitive systems, including many databases, often explicitly disable THP and manage huge pages themselves via `hugetlbfs` instead, trading automatic convenience for predictable behavior).

### NUMA (Non-Uniform Memory Access)

On multi-socket servers, each CPU socket has its own **locally-attached** memory -- a core can access its own socket's local memory faster than memory attached to a *different* socket, which it must reach over an inter-socket interconnect (AMD's Infinity Fabric, Intel's UPI) adding real, measurable extra latency and reduced bandwidth. This is **NUMA**: memory access is *non-uniform* depending on which core is accessing which memory, in contrast to older/smaller single-socket systems where every core reached all memory at the same cost (**UMA**, Uniform Memory Access).

```
 Socket 0                          Socket 1
 ┌─────────────────┐            ┌─────────────────┐
 │  Cores 0-15         │            │  Cores 16-31        │
 │       │               │◀──interconnect──▶│       │               │
 │  Local RAM (fast)     │            │  Local RAM (fast)     │
 └─────────────────┘            └─────────────────┘
   Core 0 accessing Socket 0's RAM: fast (local)
   Core 0 accessing Socket 1's RAM: slower (remote, crosses interconnect)
```

**NUMA-aware** software explicitly controls **thread/memory affinity**: pinning a thread to run on a specific socket's cores (`sched_setaffinity` on Linux) *and* ensuring the memory it primarily accesses is allocated on that *same* socket (`numactl`, or the `libnuma` API's `numa_alloc_onnode`) -- so the common-case access pattern stays local. A NUMA-*unaware* multi-threaded program can suffer real, substantial throughput loss simply from the OS scheduler migrating a thread to a different socket's core than the one whose local memory it allocated on, turning what should be fast local accesses into slow remote ones with no change to the program's logic at all -- exactly the kind of performance cliff that only shows up on multi-socket hardware and is invisible on a single-socket development machine, which is why NUMA effects are a common source of "why is this so much slower in production than on my laptop" investigations for high-throughput systems software (databases, in particular, are frequently built with explicit NUMA-aware memory allocation for exactly this reason).

## Key Takeaways

- Huge pages and NUMA awareness are both about minimizing the cost of *crossing a boundary* -- the TLB-reach boundary for huge pages, the socket-locality boundary for NUMA -- rather than reducing the amount of work done per se.
- THP's convenience (no application changes) trades against predictability (background compaction latency spikes) -- exactly why latency-sensitive systems often opt for explicit `hugetlbfs` management instead.
- NUMA effects are invisible on single-socket hardware and can be a major, otherwise-mysterious performance cliff the first time equivalent code runs on a multi-socket server -- a concrete reason to test performance-sensitive systems software on representative hardware, not just a laptop.
