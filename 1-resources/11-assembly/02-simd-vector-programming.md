# SIMD and Vector Programming: MMX, SSE, AVX, AVX-512

Prerequisite: handbook §2.4 (XMM/YMM/ZMM registers exist, and `vaddps` packs 8 floats into one add). This file covers the actual instruction families, data types, naming conventions, and hand-written patterns behind that one-line summary.

## The Lineage

| Extension | Year | Register width | Notes |
|---|---|---|---|
| MMX | 1997 | 64-bit (`MM0`-`MM7`, aliased onto the x87 FPU registers) | Integer-only; obsolete, but explains why mixing x87 and MMX code was historically forbidden (they physically shared registers) |
| SSE | 1999 | 128-bit (`XMM0`-`XMM15`) | Adds dedicated float registers, separate from x87/MMX |
| SSE2 | 2001 | 128-bit | Adds packed integer and double-precision float ops to the SSE register file -- the first "do everything in XMM" generation |
| SSE3 / SSSE3 / SSE4.1 / SSE4.2 | 2004-2008 | 128-bit | Incremental instruction additions: horizontal ops, shuffles, blend, string/text instructions (`PCMPESTRI` etc., used by some regex/JSON-parsing SIMD tricks) |
| AVX | 2011 | 256-bit (`YMM0`-`YMM15`) | New three-operand (non-destructive) encoding via the VEX prefix -- `vaddps ymm0, ymm1, ymm2` instead of the old two-operand `addps xmm0, xmm1` that clobbers one input |
| AVX2 | 2013 | 256-bit | Extends integer operations to the full 256-bit width (AVX itself was mostly float/double at 256-bit; integer ops were still 128-bit until AVX2) |
| AVX-512 | 2016+ | 512-bit (`ZMM0`-`ZMM31`) | New EVEX encoding, mask registers (`K0`-`K7`) for per-lane predication, up to 32 vector registers. Multiple independent sub-extensions (`AVX-512F`, `-VL`, `-BW`, `-DQ`, ...) -- "AVX-512" is not one monolithic feature, and support is genuinely fragmented across CPU generations, which is the main practical headache using it in portable code |

Each generation is a superset in *capability* but not automatically in *availability* -- a CPU can support AVX2 without AVX-512, and code has to runtime-detect (via `cpuid`, handbook-adjacent §1 of [`01`](01-instruction-reference-deep.md)) which level it can safely use, or ship multiple compiled variants selected at startup (the same `ifunc`/multiversioning mechanism mentioned for `memcpy` there).

## Packed Data Types and Naming Conventions

An XMM/YMM/ZMM register has no inherent "type" -- it's just bits, and the instruction determines how those bits are interpreted:

```
 XMM (128 bits) interpreted as:
   4x  packed 32-bit float   (ps = "packed single")
   2x  packed 64-bit double  (pd = "packed double")
   16x packed 8-bit int      (the integer suffixes below)
   8x  packed 16-bit int
   4x  packed 32-bit int
   2x  packed 64-bit int
   1x  scalar 32-bit float in the low lane, rest untouched (ss = "scalar single")
   1x  scalar 64-bit double in the low lane (sd = "scalar double")
```

Instruction mnemonics encode both the operation and this interpretation as a suffix: `addps` (add, packed single), `addss` (add, scalar single), `addpd`/`addsd` (packed/scalar double), `paddd` (packed add, doubleword integers -- the `p` prefix on integer ops marks "packed," since there's no scalar-integer SIMD equivalent worth naming separately; ordinary GPR instructions already cover scalar integers). Once you know this pattern, most of the instruction set is decodable on sight: `mulps`, `subpd`, `pand`, `pcmpeqb` (packed compare-equal, bytes) all follow the same `{op}{p|s}{s|d|type}` shape.

## Alignment: Aligned vs. Unaligned Moves

| Instruction | Requires 16/32/64-byte alignment? | Notes |
|---|---|---|
| `movaps`/`movapd`/`movdqa` | Yes | Faults (`#GP`) on a misaligned address; historically the *fast* path |
| `movups`/`movupd`/`movdqu` | No | Handles any alignment; historically slower, but on modern Intel/AMD cores the aligned/unaligned performance gap for in-cache data has mostly closed -- `movups` on a naturally-aligned address today typically costs the same as `movaps` |

The practical rule: use the aligned form when you can *guarantee* alignment (e.g. a buffer allocated with `posix_memalign`/`std::alloc::Layout::from_size_align`) to get a hard fault-on-bug instead of silent slow-path behavior; use the unaligned form for anything whose alignment isn't statically known, which is what most compiler-generated auto-vectorized code defaults to for safety.

## Common Patterns

**Horizontal reduction** (summing all lanes of a vector into one scalar) is the classic "SIMD isn't a free lunch" example -- there's no single instruction that sums N lanes into 1 for arbitrary N, so it's done via a `log2(N)`-step shuffle-and-add tree:

```asm
; sum the 4 floats in xmm0 into the low lane
movshdup xmm1, xmm0      ; xmm1 = [x1, x1, x3, x3]  (duplicate odd elements)
addps    xmm0, xmm1       ; xmm0 = [x0+x1, ..., x2+x3, ...]
movhlps  xmm1, xmm0        ; xmm1 = high 64 bits of xmm0 moved to low 64
addss    xmm0, xmm1        ; xmm0[0] = final sum
```

This pattern (`SSE3`'s `haddps`/horizontal-add exists too, but is frequently *slower* on real hardware than the shuffle-and-add sequence above -- another "the obviously-named instruction isn't always the fast one" case) is why auto-vectorized reduction loops (`sum += arr[i]`) show noticeably more instructions in the loop's epilogue than the main vectorized body: the epilogue is doing this reduction plus handling any remainder elements that don't fill a full vector.

**Shuffles and permutes** (`shufps`, `pshufb`, `vpermilps`, `vpermd`) rearrange lanes within (or, for the `perm` family, across) a vector according to an immediate or register-supplied control mask -- the building block for transposes, de-interleaving struct-of-arrays data, and byte-order swaps done in bulk.

**Masking / predication**: pre-AVX-512, "conditionally do this per-lane" is done by computing a compare (`cmpps` produces an all-1s or all-0s mask per lane) and blending (`blendvps`, or plain `and`/`andn`/`or` bit tricks) -- effectively `cmov`'s SIMD equivalent, same branchless tradeoff (always compute both sides, no misprediction risk). AVX-512's dedicated mask registers (`K0`-`K7`) make this a first-class feature: `vaddps zmm0 {k1}, zmm1, zmm2` adds only the lanes selected by `k1`, leaving the others untouched (or zeroed, depending on the merging/zeroing form) -- genuinely cheaper than the blend-based pre-AVX-512 idiom because it doesn't need to compute-then-discard the masked-off lanes' work in the same way.

## VEX and EVEX Encoding, Briefly

Legacy SSE instructions use the traditional two-operand x86 encoding (`addps xmm0, xmm1` computes `xmm0 = xmm0 + xmm1`, clobbering `xmm0`). AVX introduced the **VEX prefix**, giving instructions a genuine three-operand non-destructive form (`vaddps xmm0, xmm1, xmm2` computes `xmm0 = xmm1 + xmm2`, leaving both inputs intact) -- this alone reduces register pressure and the extra `mov`s needed to preserve an input you still need after the operation, independent of the width increase to 256 bits. AVX-512's **EVEX prefix** extends this further: access to registers `XMM16`-`XMM31`/`YMM16`-`YMM31`/`ZMM16`-`ZMM31`, the mask-register operand slot, and a compressed-displacement addressing mode that keeps instruction encoding compact despite the wider operands.

One practical consequence: **mixing legacy SSE and VEX-encoded AVX instructions in the same code without an explicit transition** (`vzeroupper`) can incur a real, measurable penalty on some microarchitectures, because the CPU has to preserve the upper bits of YMM registers across the legacy SSE instruction (which only knows about the lower 128 bits) via extra internal state-saving. Compilers handle this correctly automatically; it's a real hazard for hand-written mixed-mode assembly.

## Intrinsics vs. Hand-Written Assembly

In practice, almost nobody hand-writes raw SIMD assembly directly -- **intrinsics** (C/C++'s `<immintrin.h>` `_mm_add_ps`/`_mm256_add_ps`/etc., Rust's `std::arch::x86_64` module) give a one-to-one mapping to the actual instructions while staying inside the compiler's register allocator and instruction scheduler, which is genuinely hard to beat by hand for anything beyond a handful of instructions:

```rust
use std::arch::x86_64::*;

// SAFETY: caller must ensure the AVX2 target feature is available
#[target_feature(enable = "avx2")]
unsafe fn sum_f32x8(a: __m256, b: __m256) -> __m256 {
    _mm256_add_ps(a, b)   // compiles to a single vaddps ymm, ymm, ymm
}
```

Reaching for raw inline assembly (§8) instead of intrinsics is rare and mostly limited to instructions with no intrinsic mapping at all, or cases needing precise control over instruction scheduling/register allocation that intrinsics don't expose. The realistic learning path is: understand the instruction families and data model from this file, then write intrinsics (or let the compiler auto-vectorize and read the disassembly per [`09`](09-debugging-disassembly-reversing.md) to check it did what you wanted) rather than hand-assembling SIMD loops from scratch.

## Key Takeaways

- The instruction mnemonic's suffix (`ps`/`pd`/`ss`/`sd`/`p<int-type>`) tells you exactly how the same physical register's bits are being interpreted -- there's no hidden type tag on the register itself.
- VEX's three-operand non-destructive form is a real ergonomic and register-pressure win independent of AVX's wider registers -- it's why compilers prefer emitting `vaddps` over `addps` even for 128-bit operations on AVX-capable targets.
- Horizontal reductions are the standard "SIMD has a tax" example: summing a vector's lanes into a scalar needs a shuffle-and-add tree, not one instruction, and that tax shows up as extra epilogue code in every auto-vectorized reduction loop.
- Runtime feature detection (`cpuid`) is mandatory for portable SIMD code -- AVX2 and AVX-512 support is genuinely non-uniform across still-common CPUs, unlike, say, SSE2, which has been a safe universal-baseline assumption on x86-64 for well over a decade (it's part of the baseline x86-64 spec itself).

## Interview Notes

- "Why might `movups` and `movaps` perform identically on modern hardware despite one requiring alignment and the other not?" -- modern Intel/AMD cores largely closed the aligned/unaligned load performance gap for in-cache data; the alignment *requirement* on `movaps` is now mostly about correctness (a deliberate fault on misuse) rather than a performance feature.
- "Why does summing a SIMD vector's lanes need multiple instructions instead of one?" -- there's no hardware "add all N lanes together" instruction for general N; it's built from a `log2(N)`-depth tree of shuffle+add steps.
- "What's the actual benefit of AVX's VEX encoding beyond wider registers?" -- non-destructive three-operand instructions, reducing the extra `mov`s needed to preserve an input across an operation that would otherwise overwrite it.
