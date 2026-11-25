# Interrupts, Exceptions, Privileged State, and Atomics

Prerequisite: handbook §1.8 (page faults, briefly) and §4.1's `int3` breakpoint mention. This file covers the full interrupt/exception mechanism they gestured at, the privileged CPU state normal userspace code never touches directly, and the `lock`-prefixed atomic instructions that back every language's atomic types.

## Interrupts vs. Exceptions vs. Traps

All three are the same underlying mechanism -- the CPU stops normal sequential execution and jumps to a fixed handler -- distinguished by *what triggers them*:

- **Hardware interrupts**: asynchronous, from external devices (a keyboard press, a network packet arriving, a timer tick) -- can happen between *any* two instructions, unrelated to what the CPU is currently executing.
- **Exceptions (faults/traps/aborts)**: synchronous, caused by the *currently executing instruction itself* -- a page fault (handbook §1.8), a divide-by-zero (`#DE`, handbook-adjacent [`01`](01-instruction-reference-deep.md)'s `div`/`idiv` note), an invalid opcode (`#UD`).
  - A **fault** is reported *before* completing the faulting instruction, with `RIP` pointing *at* the faulting instruction -- so that, once the kernel fixes the underlying problem (e.g. a page fault triggering a lazy page allocation, handbook §1.8), execution can transparently *retry* the same instruction and succeed.
  - A **trap** is reported *after* the instruction completes, with `RIP` pointing at the *next* instruction -- `int3` (the breakpoint instruction) is the canonical trap: the debugger's job is to inspect state *after* whatever was there originally, not re-execute it.
  - An **abort** signals a severe, generally unrecoverable problem (hardware failure, a double fault) -- the precise faulting state may not even be reliably reported.
- **Software interrupts**: deliberately triggered by an instruction (`int n`, `int3` specifically, `syscall`, handbook-adjacent [`04`](04-syscalls-os-interface.md)) -- synchronous like an exception, but intentional rather than an error condition.

## The IDT and the x86 Exception Vector Table

The **IDT (Interrupt Descriptor Table)** is a kernel-maintained array of 256 entries, each pointing at a handler function -- indexed by a **vector number**, which is either a fixed, architecturally-defined value (for CPU exceptions) or an OS-assigned value (for hardware interrupts and `int n` software interrupts). The CPU's `lidt` instruction (privileged, kernel-only) loads the IDT's location; every interrupt/exception/trap ultimately works by looking up its vector number in this table and jumping to whatever handler address is stored there.

| Vector | Mnemonic | Name | Cause |
|---|---|---|---|
| 0 | `#DE` | Divide Error | `div`/`idiv` by zero, or a quotient too large to fit |
| 1 | `#DB` | Debug | Single-step trap, hardware breakpoint (debug registers, §below) |
| 3 | `#BP` | Breakpoint | The `int3` instruction -- how software breakpoints work (handbook §4.1) |
| 4 | `#OF` | Overflow | The `into` instruction, if `OF` is set (rarely used in modern code) |
| 6 | `#UD` | Invalid Opcode | An unrecognized instruction, or a deliberate `ud2` (handbook-adjacent [`01`](01-instruction-reference-deep.md)) |
| 8 | `#DF` | Double Fault | An exception occurred *while already handling* another exception, and the CPU couldn't invoke the second handler normally -- a serious condition, often fatal (a triple fault, unhandleable, causes a full CPU reset) |
| 11 | `#NP` | Segment Not Present | Legacy segmentation-related, rare on flat-memory-model 64-bit code |
| 13 | `#GP` | General Protection Fault | The broad "you did something the CPU won't allow" bucket: writing to `.text` (handbook §7.2's W^X), a privileged instruction from ring 3, a misaligned `movaps` ([`02`](02-simd-vector-programming.md)) |
| 14 | `#PF` | Page Fault | The mechanism behind `SIGSEGV`, in full detail in handbook §1.8 |

The kernel's handler for each vector decides what to do -- fix the problem transparently and return (a minor page fault), or translate it into a **signal** delivered to the offending userspace process (`#PF` on a genuinely invalid address becomes `SIGSEGV`; `#DE` becomes `SIGFPE`, despite the name being about floating point historically -- it covers integer division-by-zero too; `#UD` becomes `SIGILL`). This is the concrete mechanism underneath every signal you've caught with a C `signal()`/`sigaction()` handler or Rust's panic-on-`SIGSEGV`-adjacent tooling: a CPU-level exception, translated by the kernel into a process-level software signal.

## Protection Rings and Privilege Levels

x86 defines four privilege levels (**rings** 0-3), though mainstream OSes (Linux, Windows, macOS) use only two in practice: **ring 0** (kernel) and **ring 3** (userspace) -- rings 1-2 exist architecturally but are essentially unused by modern general-purpose OSes (some older or specialized hypervisor designs used ring 1 for guest kernels before hardware virtualization extensions made that unnecessary). The current privilege level is tracked in the low 2 bits of the `CS` segment register. Privileged instructions (loading the IDT, modifying page tables, `in`/`out` port I/O, `hlt`) fault with `#GP` if attempted from ring 3 -- this is the actual hardware enforcement mechanism behind "a userspace program can't directly touch hardware or another process's memory," not a software convention.

## Control Registers

A small set of privileged registers configuring core CPU behavior, readable/writable only from ring 0 (`mov cr0, rax`-style instructions fault from ring 3):

| Register | Purpose |
|---|---|
| `CR0` | Core control bits -- bit 0 (`PE`) enables protected mode; bit 31 (`PG`) enables paging (handbook §1.8) |
| `CR2` | On a page fault, automatically holds the faulting **virtual address** -- this is literally how the kernel's page-fault handler knows *which* address triggered `#PF` |
| `CR3` | Physical address of the current process's top-level page table -- switching `CR3` *is* what a context switch between processes with different address spaces does at the hardware level; it's also why a TLB flush is often needed on a context switch (the cached translations, handbook §1.8, belonged to the *previous* `CR3`'s page tables) |
| `CR4` | Feature-enable bits: PAE (physical address extension), enabling SSE (`OSFXSR`), virtualization extensions, and more |

## MSRs

**Model-Specific Registers** are a much larger, vendor/generation-specific set of registers accessed indirectly via `rdmsr`/`wrmsr` (an MSR index in `ECX`, value in `EDX:EAX`), rather than having their own dedicated `mov`-style instructions the way control registers do -- "model-specific" because the exact set and meaning can differ between CPU generations and vendors, unlike the small fixed set of control registers. The `syscall`/`sysret` entry-point addresses referenced in [`04`](04-syscalls-os-interface.md) are configured via MSRs (`IA32_LSTAR` holds the kernel's syscall entry address) -- the kernel writes this once at boot, and every subsequent `syscall` instruction reads it as part of its hardwired mechanism. Performance-monitoring counters (the underlying mechanism `perf`, [`10`](10-performance-optimization.md), reads) are also exposed as MSRs.

## Debug Registers

`DR0`-`DR3` hold up to four **hardware breakpoint** addresses; `DR7` configures them (execute, read, or write triggers, and operand size). Unlike a software breakpoint (`int3`, which requires *modifying* the target code by splicing in `0xCC`), a hardware breakpoint needs no code modification at all -- the CPU itself compares every memory access or instruction fetch against the configured addresses and traps (`#DB`) on a match, which is the only way to set a **watchpoint** (break on a memory *write*, e.g. "stop when this variable changes") without instrumenting every single write in the program, and it's what a debugger's `watch` command (`gdb`, [`09`](09-debugging-disassembly-reversing.md)) uses under the hood, limited to four simultaneous watchpoints by the four available debug-address registers.

## Atomics: The lock Prefix and Memory Fences

`lock` is a prefix, not a standalone instruction, applied to a small set of read-modify-write instructions (`add`, `xadd`, `cmpxchg`, `and`/`or`/`xor`, `inc`/`dec`, `bts`/`btr`/`btc`) to make the entire operation atomic with respect to every other core: `lock add [counter], 1` guarantees no other core's access to that same memory location can interleave partway through the read-modify-write, typically implemented via the cache-coherence protocol claiming exclusive ownership of the relevant cache line for the operation's duration rather than a literal external bus lock on modern hardware (the "bus lock" framing is the historical origin of the name and still accurate for some older/uncached cases, but cache-coherence-based locking is the common case today).

`mfence`/`lfence`/`sfence` are memory-ordering fences: `sfence` orders stores (nothing after it is visible to other cores before everything before it), `lfence` orders loads similarly, `mfence` orders both. These are the literal hardware instructions Rust's `std::sync::atomic::fence` and C++'s `std::atomic_thread_fence` compile down to, and the concrete mechanism behind memory-ordering parameters (`Relaxed`/`Acquire`/`Release`/`SeqCst`) in both languages: a `Release` store needs to ensure every preceding write is visible before the store itself becomes visible (roughly an `sfence`-shaped guarantee, though x86-64's naturally strong memory model means many of these orderings compile to *no* extra fence instruction at all beyond what a plain `mov` already provides -- x86-64 famously already guarantees "loads aren't reordered after other loads, stores aren't reordered after other stores" for ordinary instructions, unlike weaker-memory-model architectures like ARM64, §11, where the compiler must emit genuinely extra fence-equivalent instructions to get the same ordering guarantee). This is a concrete, mechanical answer to "why does the exact same Rust atomics code sometimes compile to more instructions on ARM than on x86" -- it's not a compiler quality difference, it's the two ISAs making genuinely different baseline ordering guarantees.

`pause` deserves a specific mention: a near-no-op hint instruction, placed inside spin-lock retry loops (`while !try_lock() { pause(); }` shaped code) specifically to tell the CPU "this is a spin-wait, don't aggressively speculate past it" -- reducing power consumption and, on hyperthreaded cores, freeing up execution resources for the *other* logical core sharing the physical core, without meaningfully slowing down the spin loop's actual latency once the lock becomes available. `std::hint::spin_loop()` in Rust and `_mm_pause()` intrinsic in C both compile straight to this instruction.

## Key Takeaways

- Faults report `RIP` *at* the failing instruction (so it can be retried after a fix); traps report `RIP` *after* it -- the distinction is why a page fault can be transparently repaired and resumed, and why `int3` doesn't re-execute itself.
- `CR2` holding the faulting address on `#PF` and `CR3` holding the current page-table root are the two control-register facts that most directly explain observable OS behavior: how a page-fault handler knows *what* failed, and what a context switch across address spaces actually changes at the hardware level.
- The `lock` prefix and `mfence`/`lfence`/`sfence` are the literal hardware underneath every language's atomic types and memory-ordering parameters -- there's no deeper mechanism; "acquire/release semantics" bottoms out at these specific instructions (or, on x86-64, sometimes at *no* extra instruction, given the ISA's already-strong default ordering).

## Interview Notes

- "What's the practical difference between a fault and a trap?" -- a fault's saved `RIP` points at the faulting instruction itself, enabling transparent retry after the handler fixes the problem (e.g. a page fault triggering lazy allocation); a trap's saved `RIP` points past the triggering instruction, since there's nothing to retry (e.g. `int3`).
- "How does the kernel know which address caused a page fault?" -- the CPU automatically stores it in `CR2` as part of raising `#PF`; the handler reads it directly, no separate lookup needed.
- "Why does the same atomics code sometimes need more instructions on ARM64 than on x86-64?" -- x86-64's memory model already guarantees strong load/store ordering for plain instructions, so many Acquire/Release orderings need zero extra fence instructions there; ARM64's weaker default ordering means the compiler must emit genuine additional barrier instructions to provide the same guarantee.
