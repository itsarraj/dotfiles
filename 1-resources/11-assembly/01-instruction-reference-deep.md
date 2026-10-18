# The Full Instruction Set: Data Movement, Arithmetic, Bit Manipulation, Strings, Condition Codes

Prerequisite: handbook §3.3's curated catalog (`mov`, `lea`, `cmp`, `test`, `jmp`/`jcc`, `imul`/`idiv`, `xor`/`and`/`or`/`not`, `shl`/`shr`/`sar`, `rol`/`ror`, `cmov`, `nop`, `syscall`, `int`). This file fills in everything that catalog left out: the rest of data movement, the flags each instruction actually sets, the full 16-condition table, bit manipulation up through BMI2, string instructions, and the small set of "you'll see this eventually" misc instructions. All examples in Intel syntax (handbook §3.1).

## Data Movement, the Rest

**`movzx dst, src`** ("move with zero-extend") -- copy a smaller register/memory operand into a larger one, filling the extra high bits with zero. `movzx eax, byte [rbx]` reads one byte and zero-extends it into all 32 bits of `eax`. Generated whenever you widen an unsigned smaller type (`u8` -> `u32`, `unsigned char` -> `int`).

**`movsx dst, src`** / **`movsxd dst, src`** -- same idea, but sign-extending: the smaller value's top bit is replicated into every new high bit. `movsx eax, byte [rbx]` treats the byte as signed and extends its sign. `movsxd` specifically handles the 32-to-64-bit sign-extend case (there's no plain `movsx` encoding for that width pair; `movsxd` exists separately for it). This is the instruction behind widening a signed smaller type (`i8` -> `i32`, `int` -> `int64_t`).

Why two separate instructions instead of one "extend" instruction with a signedness flag: the *value itself* is ambiguous without knowing whether it's signed, and the CPU doesn't track that -- it's purely a compile-time fact the compiler has to have picked the right instruction for.

**`xchg dst, src`** -- atomically swap two operands' values. When one operand is memory, `xchg` has an *implicit* `lock` prefix (handbook-adjacent, full atomics treatment in [`05`](05-interrupts-exceptions-privileged-atomics.md)) -- it's one of a small handful of instructions that are atomic by default without needing `lock` spelled out, a historical quirk worth knowing so you don't add a redundant (harmless, but pointless) explicit `lock xchg`.

**`cmpxchg dst, src`** -- "compare and exchange": compare `RAX` against `dst`; if equal, write `src` into `dst` and set `ZF`; if not equal, load `dst`'s actual value into `RAX` and clear `ZF`. This single instruction is the hardware primitive behind essentially every lock-free algorithm and every language's `compare_and_swap`/`compare_exchange` (Rust's `AtomicUsize::compare_exchange`, C++'s `std::atomic::compare_exchange_strong` both compile straight down to this, `lock`-prefixed). `cmpxchg16b` is the 128-bit variant, operating on two adjacent 64-bit registers/memory locations -- the mechanism behind lock-free structures that need to update a pointer-plus-generation-counter pair atomically (defeating the ABA problem, covered from the Rust side in the concurrency mastery file).

**`xadd dst, src`** -- "exchange and add": add `src` to `dst`, but store `dst`'s *original* (pre-add) value into `src`. `lock xadd` is the standard way to implement an atomic fetch-and-increment (`AtomicUsize::fetch_add`) -- it's the one instruction that both mutates memory atomically *and* returns the pre-mutation value in a single indivisible step.

**`push`/`pop` variants**: `pushf`/`popf` push/pop the entire `RFLAGS` register; `pusha`/`popa` (32-bit-only, removed in 64-bit mode) used to push/pop all general registers at once -- x86-64 code does this manually with individual `push`es when it needs to save a whole register set (e.g. around a signal handler or a context switch).

## Arithmetic, With Flags

Every arithmetic instruction updates a specific subset of `RFLAGS` (handbook §2.3) -- knowing exactly which flags matters because later code (a conditional jump, an `adc`) depends on them being set correctly.

| Instruction | Effect | Flags set |
|---|---|---|
| `add dst, src` | `dst += src` | `CF ZF SF OF PF AF` -- full arithmetic flag set |
| `sub dst, src` | `dst -= src` | Same full set (`cmp` is `sub` without the store, same flags) |
| `adc dst, src` | `dst += src + CF` | Full set -- "add with carry," chains a multi-word add across the carry from a lower-order `add` |
| `sbb dst, src` | `dst -= src + CF` | Full set -- "subtract with borrow," the subtraction counterpart |
| `inc dst` / `dec dst` | `dst += 1` / `dst -= 1` | `ZF SF OF PF AF` -- **not `CF`** (deliberately, so a loop counter's `inc` doesn't disturb a carry flag a surrounding multi-word add/sub sequence is still using) |
| `neg dst` | `dst = -dst` (two's complement negation) | Full set; `CF` is set unless the input was zero |
| `mul src` | unsigned `RDX:RAX = RAX * src` | `CF OF` (set if the result overflowed the lower half); `SF ZF AF PF` undefined |
| `imul src` (1-operand) | signed `RDX:RAX = RAX * src` | Same `CF`/`OF` pattern |
| `imul dst, src` / `imul dst, src, imm` (2-/3-operand forms) | signed `dst = dst*src` / `dst = src*imm`, truncated to `dst`'s width | `CF OF` set if the truncated result lost information |
| `div src` | unsigned `RAX = RDX:RAX / src`, `RDX = RDX:RAX % src` | All flags undefined; **traps `#DE` (divide error) on divide-by-zero or a quotient too large to fit** |
| `idiv src` | signed version of the same | Same undefined-flags/`#DE` behavior |

**Multi-word arithmetic** is the concrete reason `adc`/`sbb` exist: adding two 128-bit numbers stored as register pairs is `add rax, rcx` (low halves, sets `CF` on overflow) followed by `adc rdx, r8` (high halves, folds in the carry from the low-half add) -- exactly the "carry the 1" grade-school algorithm, implemented in hardware via the flag chain.

**Why `mul`/`imul`/`div`/`idiv` widen into `RDX:RAX`**: multiplying two 64-bit numbers can produce a result up to 128 bits wide (`0xFFFFFFFFFFFFFFFF * 0xFFFFFFFFFFFFFFFF` doesn't fit in 64 bits), and division needs a 128-bit dividend to support the common "divide a 128-bit value by a 64-bit divisor" pattern -- this is why you `cqo`/`cdq` (sign-extend `RAX` into `RDX:RAX`) immediately before a signed `idiv`: without it, `RDX` holds garbage from whatever used it last, corrupting the dividend's high half.

## The Full Condition Code Table

Every conditional jump (`jcc`), `cmov`, and byte-set instruction (`setcc`) is parameterized by one of 16 conditions, each testing a specific combination of `RFLAGS` bits. Many conditions have multiple valid mnemonics for the *same* underlying encoding -- purely for readability at the call site (a compiler picks whichever name matches the comparison's intent).

| Condition | Mnemonics | Flags tested | Meaning (after `cmp a, b`) |
|---|---|---|---|
| Equal / zero | `je` / `jz` | `ZF=1` | `a == b` |
| Not equal / not zero | `jne` / `jnz` | `ZF=0` | `a != b` |
| Above (unsigned >) | `ja` / `jnbe` | `CF=0 AND ZF=0` | `a > b`, unsigned |
| Above or equal (unsigned >=) | `jae` / `jnb` / `jnc` | `CF=0` | `a >= b`, unsigned |
| Below (unsigned <) | `jb` / `jnae` / `jc` | `CF=1` | `a < b`, unsigned |
| Below or equal (unsigned <=) | `jbe` / `jna` | `CF=1 OR ZF=1` | `a <= b`, unsigned |
| Greater (signed >) | `jg` / `jnle` | `ZF=0 AND SF=OF` | `a > b`, signed |
| Greater or equal (signed >=) | `jge` / `jnl` | `SF=OF` | `a >= b`, signed |
| Less (signed <) | `jl` / `jnge` | `SF != OF` | `a < b`, signed |
| Less or equal (signed <=) | `jle` / `jng` | `ZF=1 OR SF!=OF` | `a <= b`, signed |
| Sign set | `js` | `SF=1` | Result negative |
| Sign clear | `jns` | `SF=0` | Result non-negative |
| Overflow | `jo` | `OF=1` | Signed overflow occurred |
| No overflow | `jno` | `OF=0` | No signed overflow |
| Parity even | `jp` / `jpe` | `PF=1` | Low byte of result has even popcount (rare in modern code) |
| Parity odd | `jnp` / `jpo` | `PF=0` | Low byte of result has odd popcount |

`SF != OF` (signed less-than) is the one that trips people up: it's *not* just `SF=1`. Consider `cmp` on two `i8` values `-1` and `2` computing `-1 - 2 = -3`: no signed overflow occurred (`OF=0`), and the result is negative (`SF=1`), so `SF != OF` is true -- correctly, `-1 < 2`. Now consider values near the signed range boundary where the subtraction itself overflows (e.g. comparing `INT_MIN` against a positive number): the raw subtraction's sign bit alone would give the *wrong* answer, which is exactly why the signed comparisons XOR in `OF` -- it corrects for the case where the subtraction used to compute the flags itself overflowed.

`setcc dst` (e.g. `sete al`, `setg al`) writes `0` or `1` into a byte operand based on the same condition table -- the instruction compilers use to implement `bool result = (a > b);` without a branch at all, paired with `movzx` to widen the byte result into a full register.

## Bit Manipulation

**`bt`/`bts`/`btr`/`btc`** (bit test / test-and-set / test-and-reset / test-and-complement) -- test a single bit (by index) of an operand into `CF`, then optionally set/clear/flip it. `bts` in particular, `lock`-prefixed, is a standalone atomic "set this bit and tell me its previous value" primitive, used by some bitmap-based allocators and lock implementations.

**`bsf`/`bsr`** (bit scan forward/reverse) -- find the index of the lowest/highest set bit. `bsf` on zero is undefined (leaves the destination unmodified pre-modern-CPUs, and sets `ZF=1` either way, which is why correct code always checks `ZF` before trusting the result).

**`popcnt dst, src`** -- count the number of set bits. A single instruction (requires the `POPCNT` CPU feature flag, universal on anything from the last ~15 years) behind `u32::count_ones`/`__builtin_popcount` -- without it, counting bits is a multi-instruction bit-trick sequence.

**`lzcnt`/`tzcnt`** -- count leading/trailing zero bits, the modern BMI1 replacements for `bsr`/`bsf` with well-defined behavior on a zero input (`lzcnt`/`tzcnt` of zero returns the operand width, not undefined) -- the actual instructions behind `u32::leading_zeros`/`trailing_zeros`.

**BMI1/BMI2** (Bit Manipulation Instruction sets, near-universal on modern x86-64): `andn dst, s1, s2` computes `(~s1) & s2` in one instruction (useful for clearing bits by mask without a separate `not`); `blsi dst, src` isolates the lowest set bit (`src & -src`); `blsr dst, src` clears the lowest set bit (`src & (src-1)`, the classic "Brian Kernighan popcount loop" body, now a single instruction); `bextr dst, src, ctrl` extracts a contiguous bit field given a start/length packed into `ctrl`; `pdep`/`pext` (BMI2) scatter/gather bits according to a mask -- `pext` compresses the bits selected by a mask into a contiguous low-order run, `pdep` does the reverse, both frequently used in bit-packing serialization formats and some hash-table/Bloom-filter implementations where they turn what would be a bit-by-bit loop into one instruction.

## String Instructions and `rep` Prefixes

A legacy-named but still-relevant family operating implicitly on `RSI` (source), `RDI` (destination), and `RCX` (count), advancing `RSI`/`RDI` automatically based on the `DF` (direction flag) in `RFLAGS`:

| Instruction | Effect (byte form; `w`/`d`/`q` suffixes exist for 16/32/64-bit) |
|---|---|
| `movsb` | `[RDI] = [RSI]; RSI += 1; RDI += 1` (or `-= 1` if `DF=1`) -- memory-to-memory copy |
| `cmpsb` | Compare `[RSI]` and `[RDI]`, set flags, advance both |
| `scasb` | Compare `AL` against `[RDI]`, set flags, advance `RDI` -- the primitive behind `strlen`/`memchr`-style scanning |
| `lodsb` | `AL = [RSI]`, advance `RSI` |
| `stosb` | `[RDI] = AL`, advance `RDI` -- the primitive behind `memset` |

The `rep` prefix family turns a single string instruction into an implicit loop, decrementing `RCX` each iteration: `rep movsb` repeats `movsb` until `RCX == 0` (a whole-buffer `memcpy` in one prefixed instruction); `repe`/`repz` and `repne`/`repnz` additionally stop early if `ZF` disagrees with the prefix (used with `cmpsb`/`scasb` for "repeat while equal/not equal," the mechanism behind a hand-rolled `strcmp`/`memchr`).

In practice: modern glibc's `memcpy`/`memset`/`strlen` are hand-tuned SIMD routines (handbook-adjacent, see [`02`](02-simd-vector-programming.md)), **not** `rep movsb` loops, for most sizes -- but `rep movsb` specifically has had a resurgence on recent Intel/AMD chips implementing "Enhanced REP MOVSB" (`ERMSB`), where the microcode-level implementation is competitive with or faster than a hand-written AVX loop for large copies, precisely *because* the CPU can implement it with knowledge (cache-line-aware batching, no per-iteration instruction decode overhead) a generic instruction sequence can't express. This is a good concrete example of "don't assume an old-looking instruction is slow" -- microarchitectural investment can and does flow back into legacy encodings when it's worth it to hardware vendors.

## Miscellaneous

**`cpuid`** -- queries CPU feature/identification information. Input: a "leaf" number in `EAX` (and sometimes a sub-leaf in `ECX`); output: feature bits packed into `EAX`/`EBX`/`ECX`/`EDX`, whose meaning depends entirely on which leaf you asked for. This is how every "does this CPU support AVX2/AVX-512/BMI2" runtime check works -- both hand-written and inside `std::is_x86_feature_detected!`/`__builtin_cpu_supports`.

**`rdtsc`/`rdtscp`** -- read the CPU's Time-Stamp Counter, a free-running cycle counter, into `EDX:EAX`. `rdtscp` additionally returns a processor ID in `ECX` and, critically, is a *serializing* read (it can't be reordered relative to surrounding instructions the way plain `rdtsc` can be) -- the difference matters for microbenchmarking, where an unserialized `rdtsc` can be executed out of order relative to the code you're actually trying to time, silently corrupting the measurement (full context in [`10`](10-performance-optimization.md)).

**`xlat`** -- `AL = [RBX + AL]`, a byte-table-lookup-by-value instruction, a holdover from an era when a dedicated single-byte-encoding lookup instruction was worth having; essentially never emitted by modern compilers, included here only because you'll occasionally meet it reading old assembly.

**`ud2`** -- guaranteed-undefined instruction, deliberately trapping `#UD` (invalid opcode). Compilers emit it as a deliberate "this path is unreachable" trap (Rust's `unreachable_unchecked()` in debug-adjacent builds, or as a hard-stop after a detected-at-compile-time abort) -- a controlled crash is the intended behavior, not a bug.

## Key Takeaways

- `movzx`/`movsx` exist as two separate instructions because zero- vs. sign-extension is a compile-time fact about the *type*, not something the raw bit pattern encodes -- the CPU can't infer it.
- `lock cmpxchg`/`lock xadd` are the actual hardware instructions every language's atomic compare-and-swap/fetch-and-add compiles down to -- there's no deeper primitive underneath them.
- The signed condition codes (`jg`/`jl`/etc.) test `SF != OF`-style combinations, not just `SF`, specifically to stay correct when the comparison subtraction itself overflows.
- BMI1/BMI2 turn several classic "bit-trick loop" idioms (isolate lowest bit, clear lowest bit, popcount, leading/trailing zero count) into single instructions -- worth checking for before hand-rolling the loop version.

## Interview Notes

- "Why does `inc` not affect `CF` when `add ..., 1` does?" -- so a loop counter increment doesn't clobber a carry flag a surrounding multi-word arithmetic sequence (built from `add`/`adc`) is still relying on.
- "What's the difference between `ja` and `jg`?" -- `ja` ("above") is the unsigned greater-than condition (tests `CF`/`ZF`); `jg` ("greater") is the signed one (tests `SF`/`OF`/`ZF`) -- picking the wrong one is a classic signed/unsigned comparison bug at the instruction level.
- "How would you implement `memcpy` in raw assembly, and would you actually want to?" -- `rep movsb` is a one-instruction correct implementation; whether it's the *fast* implementation depends entirely on the target microarchitecture's ERMSB support and the copy size, which is why real libc implementations dispatch between several strategies at runtime via `ifunc` resolvers.
