# Assembly Language -- Master Index

This file is the entry point for everything on assembly in this notes tree. It deliberately does **not** duplicate what's already written in full depth elsewhere -- the table below points at existing material, and [`asm-mastery/`](asm-mastery/00-index.md) is a from-scratch deep-dive library covering everything the existing material doesn't reach: the full instruction set, SIMD/AVX, floating point, syscalls, interrupts/atomics, hands-on toolchain use, hand-written programs, inline assembly, debugging/reverse engineering, performance, ARM64, and security fundamentals.

## Already Covered in Full (Do Not Duplicate)

[`16a-rust-systems-programming.md`](16a-rust-systems-programming.md) Part I ("The Machine"), Chapters 1-9, is a genuine assembly-and-machine-model primer, language-agnostic (nothing Rust-specific until Part II):

| Chapter | What's there |
|---|---|
| Ch 1 -- CPU Architecture | Fetch-decode-execute-retire, ALU/control unit, cache hierarchy, pipelining, branch prediction, out-of-order execution, TLB/MMU/paging, page faults, copy-on-write |
| Ch 2 -- Registers | All 16 GPRs and their sub-register aliasing (RAX/EAX/AX/AH/AL), RIP, RSP, RBP, RFLAGS (ZF/SF/CF/OF/PF), XMM/YMM/ZMM SIMD registers |
| Ch 3 -- Assembly Fundamentals | Intel vs. AT&T syntax, addressing modes (immediate/register/direct/base+offset/scaled-index/RIP-relative), a curated instruction catalog (mov, lea, cmp, test, jmp/jcc, imul/idiv, xor/and/or/not, shl/shr/sar, rol/ror, cmov, nop, syscall, int) |
| Ch 4 -- The Stack | push/pop/call/ret mechanics, stack frame layout, prologue/epilogue, frame pointer omission, stack overflow, tail-call optimization |
| Ch 5 -- The Heap | How a free-list allocator works, `new`/`delete`/placement new, Rust's `GlobalAlloc`, fragmentation, arenas |
| Ch 6 -- Calling Conventions & ABI | System V AMD64 ABI in full, Windows x64 ABI in full, stack alignment, the red zone |
| Ch 7 -- Memory Layout | Process address space, .text/.data/.bss/.rodata, TLS, shared libraries, ELF/PE/Mach-O |
| Ch 8 -- Linking | Object files/symbols, relocation, static vs. dynamic linking, the loader, PLT/GOT, PIC/PIE/ASLR |
| Ch 9 -- Compiler Pipeline | Source -> tokens -> AST -> IR -> optimization -> instruction selection -> assembler -> linker; Rust's HIR/MIR/LLVM IR specifically |

If you're starting from zero, **read that Part I first** -- everything in `asm-mastery/` assumes it and cross-references it by section number rather than re-explaining it.

## This Directory -- `asm-mastery/`

See [`asm-mastery/00-index.md`](asm-mastery/00-index.md) for the full table of contents (13 files: instruction reference, SIMD, floating point, syscalls, interrupts/atomics, toolchain practice, hand-written programs, inline asm, debugging/reversing, performance, ARM64, security fundamentals).
