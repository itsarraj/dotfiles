# Assembly Mastery -- Index

This directory is the deep-dive library for "everything about assembly," built on top of [`../16a-rust-systems-programming.md`](../16a-rust-systems-programming.md) Part I (Chapters 1-9), which already covers CPU architecture, registers, syntax, addressing modes, a curated instruction catalog, the stack, the heap, calling conventions/ABI, memory layout, linking, and the compiler pipeline. See [`../asm.md`](../asm.md) for that pointer table. Nothing here re-derives Part I -- every file cross-references it by chapter/section number instead.

Everything is x86-64 first (it's what you'll spend 95% of your time on: Linux servers, most desktops), with a dedicated ARM64 file for the second architecture you'll actually meet in the real world (Apple Silicon, AWS Graviton, mobile).

## Files

| File | Covers |
|---|---|
| [`01-instruction-reference-deep.md`](01-instruction-reference-deep.md) | The instruction set beyond the handbook's curated catalog: full data movement, arithmetic/logic with flags-affected tables, the complete condition-code table, bit manipulation (BT*/BMI1/BMI2), string instructions + `rep` prefixes, multi-precision arithmetic, misc (`cpuid`, `rdtsc`, `xlat`) |
| [`02-simd-vector-programming.md`](02-simd-vector-programming.md) | MMX -> SSE -> AVX -> AVX-512 lineage, packed data types, instruction naming conventions, alignment, shuffles/horizontal ops, VEX/EVEX encoding, intrinsics vs. hand-written asm |
| [`03-floating-point-x87-sse.md`](03-floating-point-x87-sse.md) | IEEE-754 review, the x87 FPU stack model in full, why it's legacy, SSE scalar float/double, rounding modes, NaN/Inf, comparison pitfalls |
| [`04-syscalls-os-interface.md`](04-syscalls-os-interface.md) | `syscall` mechanics in full, the Linux x86-64 syscall ABI, a syscall number table, `errno` convention, legacy `int 0x80`, vDSO, how libc wraps syscalls, Windows contrast |
| [`05-interrupts-exceptions-privileged-atomics.md`](05-interrupts-exceptions-privileged-atomics.md) | Hardware/software interrupts, the IDT, the x86 exception vector table, protection rings, control registers (CR0-CR4), MSRs, `lock`-prefixed atomics, memory fences, and how these map onto Rust/C++ atomic orderings |
| [`06-toolchain-nasm-gas-linking.md`](06-toolchain-nasm-gas-linking.md) | NASM vs. GAS vs. MASM syntax and directives in practice, assembling and linking a standalone binary end to end, static vs. dynamic linking hands-on, position-independent code worked example |
| [`07-writing-real-programs.md`](07-writing-real-programs.md) | Hand-written programs: raw-syscall hello world, functions with real stack frames, array/string routines, recursion, mixing NASM objects with a C `main` |
| [`08-inline-assembly-c-rust.md`](08-inline-assembly-c-rust.md) | GCC/Clang extended `asm` (constraints, clobbers), Rust's `asm!`/`global_asm!`, worked examples (`cpuid`, atomic increment, `rdtsc`), when inline asm is (and isn't) the right tool |
| [`09-debugging-disassembly-reversing.md`](09-debugging-disassembly-reversing.md) | `gdb` at the instruction level, `objdump -d` in practice, Compiler Explorer as a learning tool, a basic reverse-engineering workflow |
| [`10-performance-optimization.md`](10-performance-optimization.md) | Latency vs. throughput, µops and port pressure, dependency chains, manual loop unrolling, code/data alignment, `perf` at the instruction level |
| [`11-arm64-aarch64-primer.md`](11-arm64-aarch64-primer.md) | The second architecture: register set, load/store style, AAPCS64 calling convention, condition flags, x86-64-vs-ARM64 comparison table |
| [`12-security-exploitation-primer.md`](12-security-exploitation-primer.md) | Stack-overflow mechanics at the instruction level, how NX/canaries/ASLR/PIE actually defeat exploitation, a CTF-style reversing workflow -- educational/defensive framing throughout |

## How to Use This Library

Read the handbook's Part I first if you haven't -- everything here assumes its vocabulary (RFLAGS, the SysV ABI, PLT/GOT, PIE) without re-explaining it. After that, `01` and `06`-`07` are the core "actually know assembly" path (full instruction set, toolchain, hands-on programs); `02`-`03` fill out numeric/vector programming; `04`-`05` cover the OS/hardware boundary; `08`-`10` are the practical skills (mixing asm with real languages, reading disassembly, reasoning about performance); `11` is the second architecture; `12` ties the stack/exploit material back together for CTF and defensive-security context.
