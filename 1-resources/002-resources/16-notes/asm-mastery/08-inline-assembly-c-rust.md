# Inline Assembly: GCC/Clang Extended asm and Rust's asm!

Prerequisite: [`07`](07-writing-real-programs.md) (standalone hand-written functions), handbook §6.2 (SysV ABI -- inline asm is where you most often need to know it precisely, since you're manually declaring the interface between your asm fragment and the surrounding compiled code). This file covers embedding small assembly fragments *inside* a C/Rust function, rather than writing a whole standalone function in a `.asm` file.

## When Inline Asm Is (and Isn't) the Right Tool

Reach for it only when: an instruction has no compiler intrinsic ([`02`](02-simd-vector-programming.md) covers the far more common intrinsics path for SIMD specifically), you need precise control over exact instruction sequencing the optimizer isn't allowed to disturb (some cryptographic constant-time code), or you're doing something the type system/compiler model can't express directly (a raw `cpuid` query, a context switch's register save/restore in a kernel or embedded context). It is **not** the right tool for "I want this loop to be fast" -- the compiler's own instruction scheduler and register allocator (handbook §9.5) will almost always beat hand-scheduled inline asm for anything beyond a handful of instructions, and inline asm actively *defeats* several optimizations (the compiler can't see through it to reorder, inline, or constant-fold across it) unless you describe its effects to the compiler with complete accuracy via constraints -- getting the constraints wrong is a correctness bug, not a missed-optimization one.

## GCC/Clang Extended asm

```c
int result;
asm volatile (
    "addl %2, %0"          // template: assembly text, %N refers to the Nth operand below
    : "=r" (result)          // output operands: "=r" means "write to a register, then treat as C variable `result`"
    : "0" (a), "r" (b)         // input operands: "0" ties this input to output #0 (same register)
    :                           // clobbers: none beyond the declared operands
);
```

The four colon-separated sections are the entire interface: **template** (the actual instruction text, with `%0`/`%1`/... placeholders the compiler substitutes with whatever register/memory location it assigned each operand), **outputs**, **inputs**, and **clobbers** (registers/memory the asm fragment modifies that aren't already covered by an output operand -- omitting a real clobber is a genuine, hard-to-diagnose bug class, since the compiler will keep using a register's old value in surrounding code, believing your asm didn't touch it).

### Constraint Letters

| Constraint | Meaning |
|---|---|
| `r` | Any general-purpose register |
| `m` | A memory operand |
| `i` | An immediate integer constant |
| `0`-`9` | "Same location as operand N" -- ties an input to a specific output, common for read-modify-write patterns |
| `a`, `b`, `c`, `d`, `S`, `D` | A *specific* register (`RAX`/`RBX`/`RCX`/`RDX`/`RSI`/`RDI`) -- needed when an instruction hardwires a particular register (e.g. `cpuid`'s fixed `EAX`/`EBX`/`ECX`/`EDX` outputs, or `div`'s implicit `RDX:RAX`, handbook-adjacent [`01`](01-instruction-reference-deep.md)) |
| `=` prefix | Write-only (output) |
| `+` prefix | Both read and written (in-out operand) |

`volatile` on the `asm` statement tells the compiler this fragment has effects beyond its declared outputs (an I/O port write, a syscall-adjacent instruction) and must not be optimized away or reordered relative to other volatile operations even if its outputs appear unused -- the inline-asm analog of handbook §12.2's `volatile` on a variable.

### Worked Example: cpuid

```c
#include <stdint.h>

void cpuid(uint32_t leaf, uint32_t *eax, uint32_t *ebx, uint32_t *ecx, uint32_t *edx) {
    asm volatile (
        "cpuid"
        : "=a" (*eax), "=b" (*ebx), "=c" (*ecx), "=d" (*edx)   // fixed-register outputs
        : "a" (leaf)                                             // fixed-register input: EAX = leaf
    );
}
```

This is a direct, literal translation of [`01`](01-instruction-reference-deep.md)'s `cpuid` description into a callable C function -- the `"a"`/`"b"`/`"c"`/`"d"` constraints exist specifically because `cpuid` (unlike most instructions) has *fixed* register operands, not ones the compiler is free to choose.

### Worked Example: Atomic Increment (Pre-Intrinsic Style)

```c
static inline void atomic_increment(volatile int *counter) {
    asm volatile (
        "lock incl %0"
        : "+m" (*counter)      // "+m": read-modify-write directly on the memory operand
        :
        : "memory"                // clobber: this instruction has a side effect the compiler
                                    // can't otherwise see -- prevents reordering memory
                                    // accesses across this asm statement (a compiler-level
                                    // fence, distinct from the CPU-level fences in [05])
    );
}
```

This is the literal instruction ([`01`](01-instruction-reference-deep.md)'s `lock`-prefixed increment) behind what `std::atomic<int>::fetch_add` compiles to -- included here purely as a worked example of the pattern, since real code should always prefer the language's actual atomic types (`<atomic>`/`std::sync::atomic`) over hand-rolled inline asm, which get this exactly right without the risk of a missed clobber.

## Rust's asm! Macro

```rust
use std::arch::asm;

let a: u64 = 5;
let b: u64 = 10;
let result: u64;

unsafe {
    asm!(
        "add {0}, {1}",
        inout(reg) a => result,   // a is read in, result is the same register read back out
        in(reg) b,
    );
}
```

Rust's syntax is deliberately more structured than GCC's colon-separated sections: operands are named inline (`in(reg)`, `out(reg)`, `inout(reg)`, `lateout(reg)`), removing the "which colon section, which position" bookkeeping GCC's syntax requires, at the cost of needing `unsafe` explicitly (inline asm is one of the operations Rust's safety model has no way to check at all -- it's trusted exactly as much as an `unsafe` block anywhere else, handbook §2 of the systems handbook's unsafe material).

### Worked Example: rdtsc in Rust

```rust
use std::arch::asm;

unsafe fn rdtsc() -> u64 {
    let hi: u32;
    let lo: u32;
    asm!(
        "rdtsc",
        out("eax") lo,
        out("edx") hi,
        options(nomem, nostack)
    );
    ((hi as u64) << 32) | (lo as u64)
}
```

`out("eax")`/`out("edx")` pin operands to *specific* registers (matching `rdtsc`'s hardwired `EDX:EAX` output, [`01`](01-instruction-reference-deep.md)), the same fixed-register need `cpuid`'s C example above had. `options(nomem, nostack)` is Rust's equivalent of GCC's clobber list, but expressed as *properties* the compiler can trust (`nomem`: doesn't access memory; `nostack`: doesn't touch the stack) rather than an exhaustive list of what's touched -- letting the compiler optimize more aggressively around the block than it safely could with no information at all, while still being honest about what the asm fragment does.

### global_asm!

`global_asm!` (Rust) / a plain top-level `asm(...)` block (some C compilers) emits assembly **outside** any function -- for writing an entire standalone function, a raw `_start` entry point (the [`07`](07-writing-real-programs.md) `_start` pattern, but embedded directly in a Rust/C source file instead of a separate `.asm` file), or hand-placed data. Unlike the in-function `asm!`/`asm volatile`, there's no operand/constraint machinery at all here -- it's genuinely equivalent to what a separate `.asm` file assembled and linked in would produce, just textually inline in the source for convenience (common in `no_std`/embedded/kernel code, [`14-embedded.md`](../rust-mastery/14-embedded.md), for the reset vector or panic handler's absolute minimum bootstrap).

## Comparing the Two

| | GCC/Clang extended asm | Rust `asm!` |
|---|---|---|
| Operand binding | Positional (`%0`, `%1`, ...), matched against colon-separated sections | Named inline (`in(reg) x`, `out("eax") y`) |
| Safety | No language-level marking beyond the statement itself | Requires `unsafe`, explicit about it |
| Effect declaration | Explicit clobber list (easy to under-declare, a real bug source) | `options()` flags (`nomem`/`nostack`/`pure`/...) describing properties, checked more structurally |
| Register pinning | Single-letter constraints (`"a"` for `RAX`, etc.) | Named registers directly (`out("eax")`) |

Both ultimately compile down to the exact same embedded instruction bytes with compiler-managed operand placement around them -- the differences are entirely in how precisely and safely you describe the fragment's interface to the surrounding optimizer, not in what's possible.

## Key Takeaways

- Inline asm's entire correctness burden is in accurately describing the fragment's *interface* (inputs, outputs, clobbers) to the compiler -- the instructions themselves are the easy part; an incomplete clobber list or missing `volatile`/`options()` flag is the actual, common bug class.
- Fixed-register instructions (`cpuid`, `rdtsc`, `div`) are the paradigm case for needing specific-register constraints (`"a"`/`"d"` in GCC syntax, `out("eax")` in Rust) rather than the generic `"r"`/`reg` -- the instruction itself, not a stylistic choice, dictates this.
- Prefer language-level intrinsics (SIMD, [`02`](02-simd-vector-programming.md)) or standard-library atomics over hand-rolled inline asm whenever an equivalent exists -- they encode the correct interface description for you, which is exactly the part inline asm makes you get right by hand.

## Interview Notes

- "Why does inline asm need an explicit clobber list at all -- doesn't the compiler know what the instruction does?" -- no; the compiler treats the asm template as opaque text it doesn't parse or understand at the instruction level, so it relies entirely on what you *declare* (outputs, inputs, clobbers/options) to know what's safe to assume unchanged around the fragment.
- "Why does Rust require `unsafe` for `asm!` specifically, beyond the general unsafe-operations list?" -- inline asm can violate literally any invariant the rest of the type/borrow system relies on (corrupt the stack, invalidate a reference, break aliasing assumptions) with no way for the compiler to check any of it -- it's the maximal escape hatch, matching how much trust it requires.
