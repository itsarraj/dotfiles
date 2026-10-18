# Floating Point: IEEE-754, the x87 Stack, and Modern SSE Scalar Math

Prerequisite: handbook §2.4 (XMM registers are the default float registers on x86-64) and [`02`](02-simd-vector-programming.md) (packed vs. scalar suffixes: `ss`/`sd`). This file covers the actual float instruction sets -- the legacy x87 stack model (still worth understanding: it's what you'll meet in 32-bit code, `long double`, and old disassembly) and the modern SSE scalar instructions every current compiler actually emits.

## IEEE-754, Briefly

A 32-bit `float` (`f32`) and 64-bit `double` (`f64`) both encode a sign bit, a biased exponent, and a mantissa (fraction):

```
 f32:  [S][ 8-bit exponent ][      23-bit mantissa       ]
 f64:  [S][ 11-bit exponent ][       52-bit mantissa            ]
```

Two values are reserved as special: an all-1s exponent with a zero mantissa means **±infinity**; an all-1s exponent with a nonzero mantissa means **NaN** (Not a Number) -- and there are *many* distinct bit patterns that are all "a NaN," which is exactly why `NaN != NaN` is true under IEEE-754 (comparing bit patterns isn't what float equality means) and why every language's float type has a dedicated `is_nan()` check rather than relying on `==`. An all-zero exponent with a nonzero mantissa is a **subnormal** (denormal) number -- representing values too small to have a full-precision normalized representation, at the cost of some hardware implementations handling subnormal arithmetic via a slow microcode path (a real, sometimes-surprising performance cliff: code that unexpectedly produces subnormal intermediate values, e.g. in an audio DSP loop approaching silence, can suddenly run an order of magnitude slower for no visible algorithmic reason -- `-ffast-math`/flush-to-zero mode exists partly to sidestep exactly this).

## The x87 FPU Stack Model

Long before SSE, x86 floating point ran entirely on the **x87 FPU**, a genuinely different architecture bolted onto the side of the integer instruction set: instead of addressable registers, it's an 8-deep **register stack** (`ST(0)`-`ST(7)`), where every instruction operates on the top of the stack, implicitly, like an RPN calculator.

```asm
fld  qword [a]      ; push a onto the FPU stack -> ST(0) = a
fld  qword [b]      ; push b -> ST(0) = b, ST(1) = a
fadd                 ; ST(1) = ST(1) + ST(0), pop -> ST(0) = a + b
fstp qword [result]   ; pop ST(0) into result
```

- **`fld`** pushes a value (from memory or another `ST(i)`) onto the stack.
- **`fst`/`fstp`** stores the top of stack to memory (`fstp` additionally pops it off).
- **`fadd`/`fsub`/`fmul`/`fdiv`** and their reversed (`fsubr`/`fdivr`) and popping (`faddp`/etc.) variants operate on `ST(0)` and either memory or another stack register, in various operand-order combinations that exist specifically to avoid needing an explicit "swap operands" step for non-commutative operations.
- **`fcom`/`fcomp`/`fcomi`** compare, with `fcomi` (a later addition) being the version that sets ordinary `RFLAGS` bits directly instead of the separate x87 status-word flags older comparisons used -- `fcomi` exists specifically to let a comparison feed directly into an ordinary `jcc`, without an intermediate flag-transfer step.

**Internally, x87 registers are 80 bits wide** (extended precision: 64-bit mantissa, 15-bit exponent) regardless of whether you loaded a 32-bit or 64-bit value -- every x87 computation happens at this extended precision, then gets truncated back to 32/64 bits only when stored to memory. This was, historically, a genuine correctness *and* portability headache: a value kept live in an x87 register across several operations could produce a subtly different result than the same computation with each intermediate step rounded to 64-bit `double` precision (the classic "this floating-point code gives different answers in debug vs. release, or on different compilers" bug class from the 32-bit era) -- because whether a compiler kept a value in a register or spilled it to memory between operations was itself a compiler-internal decision that changed the effective precision. This exact unpredictability is the concrete reason SSE2 scalar math (§below), with its fixed 32-/64-bit precision on every single operation, replaced x87 as the default for ordinary float/double arithmetic on every mainstream 64-bit compiler.

**The x87 control word** configures rounding mode (round-to-nearest, toward zero, toward +/-infinity) and precision -- `fldcw`/`fstcw` load/store it. Rust and C on 64-bit targets essentially never touch it directly; it's still relevant if you're reading disassembly of `long double` arithmetic (the one place x87 remains the *only* way to get genuine 80-bit extended precision on x86-64, since SSE/AVX have no 80-bit format) or genuinely old 32-bit code.

## SSE Scalar Float/Double

On x86-64, ordinary `f32`/`f64` arithmetic uses the **scalar** forms of the SSE instructions from [`02`](02-simd-vector-programming.md) -- same registers, same instruction families, just operating on only the low lane of an XMM register while leaving the upper lanes untouched:

```asm
movss xmm0, [a]       ; load one f32 into the low lane of xmm0
movss xmm1, [b]
addss xmm0, xmm1        ; xmm0[0] = a + b, other lanes of xmm0 unaffected
movss [result], xmm0
```

`movsd`/`addsd`/`subsd`/`mulsd`/`divsd`/`sqrtsd` are the `f64` equivalents. Because these operate on fixed 32-/64-bit precision every single instruction (no hidden 80-bit intermediate the way x87 has), the result is fully deterministic given the instruction sequence -- the exact property x87 lacked, and the reason this is the default everywhere on 64-bit targets today.

**Conversions**: `cvtsi2ss`/`cvtsi2sd` convert an integer to float/double; `cvttss2si`/`cvttsd2si` convert float/double to integer with truncation (`tt` = "truncating," the C/Rust `as i32` cast's rounding behavior); `cvtss2sd`/`cvtsd2ss` convert between float and double precision.

## Rounding Modes

IEEE-754 defines four rounding modes, selectable via the SSE control/status register (`MXCSR`, read/written with `ldmxcsr`/`stmxcsr`) or, for x87, the FPU control word above: round-to-nearest-even (the default nearly everywhere, and the one that avoids systematic bias by rounding exact ties to whichever neighbor has an even last bit), round toward zero (truncation), round toward `+∞`, round toward `-∞`. Code that needs a *specific* mode other than the default (some numerical algorithms verify correctness bounds by deliberately running the same computation in round-up and round-down mode and checking the results bracket the true answer) manipulates `MXCSR` directly; ordinary application code essentially never touches this.

## Comparing Floats Correctly

`ucomiss`/`ucomisd` (unordered compare) and `comiss`/`comisd` (ordered compare) are the scalar-float analogs of `cmp` -- setting ordinary `RFLAGS` bits (`ZF`/`PF`/`CF`) so an ordinary `jcc` can follow, exactly like `fcomi` does for x87. The "unordered" in `ucomiss` refers to how a `NaN` operand is handled: comparing against `NaN` sets the parity flag (`PF=1`) to signal "this comparison result is meaningless," which is the hardware-level reason `NaN < x`, `NaN > x`, and `NaN == x` are all false while `NaN != x` is true -- every ordinary comparison against `NaN` is defined to fail except not-equal, matching IEEE-754's semantics exactly, and it's implemented by checking `PF` alongside the ordinary flag in the generated code for `<`/`>`/`==` on floats.

The classic mistake this instruction-level behavior explains: writing `if (x == x)` to check for `NaN` (relying on `NaN != NaN`) *works correctly* precisely because of this hardware behavior, but comparing two floats for exact equality after independent computation paths that are mathematically equal but numerically different (due to intermediate rounding, operation order, or historically, differing x87-vs-SSE precision) is a separate, much more common bug -- the standard fix is comparing `(a - b).abs() < epsilon` rather than `a == b`, which is a numerical-methods concern layered on top of, not caused by, anything at the instruction level.

## Key Takeaways

- x87's 80-bit-internal, stack-based model made floating-point results depend on compiler register-allocation decisions in a way that was a genuine source of non-reproducible bugs -- SSE2 scalar math's fixed-precision-per-instruction design is why that entire bug class disappeared on 64-bit targets.
- `long double` on x86-64 Linux is still the one place 80-bit extended precision survives, and it's still implemented via the legacy x87 stack for exactly that reason.
- Float comparison instructions set ordinary `RFLAGS` bits, with `PF` specifically carrying "this comparison involved a NaN and is meaningless" -- the hardware-level source of every "why does `NaN == NaN` evaluate to false" fact.

## Interview Notes

- "Why did x86-64 compilers stop using the x87 FPU for ordinary float math?" -- x87's 80-bit-wide internal stack made results depend on where the compiler happened to spill values to memory (truncating precision) versus keep them in registers (full 80-bit), a source of non-reproducible, compiler-decision-dependent results that SSE2's fixed-width-per-instruction scalar math eliminated entirely.
- "What does it mean for a float comparison to be 'unordered'?" -- one or both operands is NaN, which IEEE-754 defines as incomparable to anything (including itself) under `<`/`>`/`==`; the CPU signals this via the parity flag so generated code can special-case it.
- "Why can `x == x` correctly detect NaN?" -- IEEE-754 defines NaN as unequal to everything, itself included, and the comparison instructions implement exactly that at the hardware level.
