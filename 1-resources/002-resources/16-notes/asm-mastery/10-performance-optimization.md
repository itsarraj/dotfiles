# Performance From the Assembly Level

Prerequisite: handbook §1.5-1.7 (pipelining, branch prediction, out-of-order execution) and the original systems handbook's §37 performance chapter (cache lines, false sharing, alignment, SIMD, loop unrolling, inlining -- referenced throughout the rust-mastery library). This file is the instruction-level vocabulary underneath those concepts: what "latency" and "throughput" concretely mean per-instruction, what a µop is, and how to read `perf` output down to specific instructions.

## Latency vs. Throughput, Precisely

Every instruction has two, generally different, numbers associated with it on a given microarchitecture:

- **Latency**: cycles from when an instruction's inputs are ready to when its *result* is ready to be used by a dependent instruction.
- **Throughput** (often expressed as its reciprocal, "cycles per instruction" for a stream of independent copies): how often a *new* instance of this instruction can be issued, if instances are independent of each other (no instruction waits on a previous one's result).

A concrete illustration: on many modern x86-64 microarchitectures, scalar `imul` has a latency of ~3 cycles but a throughput of 1-per-cycle -- meaning a *chain* of dependent multiplies (`a = a * b` repeated) costs ~3 cycles each (bottlenecked on latency, since each one needs the previous result), while a *loop* of independent multiplies (`c[i] = a[i] * b[i]`, unrelated across iterations) can issue roughly one per cycle (bottlenecked on throughput instead, since the CPU can have several in flight simultaneously via pipelining, handbook §1.5). This is *why* dependency chains, not raw instruction count, are so often the actual bottleneck in scalar numeric code -- and why breaking a chain (e.g. summing into two or four separate accumulator variables and adding them together at the end, rather than one running total) is a real, common hand-optimization: it converts a latency-bound dependency chain into several independent, throughput-bound streams the CPU can overlap.

## µops and Port Pressure, Conceptually

Modern x86-64 cores don't execute the x86 instructions you write directly -- the decode stage (handbook §1.2) translates each into one or more simpler internal **micro-operations (µops)**, which a scheduler then dispatches to one of several parallel **execution ports**, each specialized for certain operation types (an ALU port, a load port, a store port, a branch port, and so on -- the exact count and specialization is microarchitecture-specific). This is why raw instruction count is a weak proxy for speed (handbook §1 Common Mistakes already flags this at a high level): two instructions competing for the *same* port serialize even if neither has a data dependency on the other, while two instructions on *different* ports genuinely run in parallel. A loop dominated by, say, memory loads can be *load-port-bound* even if it has spare ALU capacity sitting idle -- the fix isn't "fewer instructions," it's "fewer instructions competing for the specific saturated port," which is a materially different optimization target requiring you to know roughly which port each instruction in the hot loop uses (tools like Intel's `vtune` or the community-maintained [uops.info](https://uops.info) tables provide this per-microarchitecture; not something to memorize, but worth knowing exists when a loop's performance doesn't match a naive latency/throughput estimate).

## Dependency Chains in Practice

```c
// latency-bound: each iteration's result depends on the previous
float sum = 0;
for (int i = 0; i < n; i++) sum += a[i];

// throughput-bound: four INDEPENDENT chains, combined only at the end
float sum0 = 0, sum1 = 0, sum2 = 0, sum3 = 0;
for (int i = 0; i < n; i += 4) {
    sum0 += a[i];
    sum1 += a[i+1];
    sum2 += a[i+2];
    sum3 += a[i+3];
}
float sum = (sum0 + sum1) + (sum2 + sum3);
```

The first version's `addss` chain (scalar float add, [`03`](03-floating-point-x87-sse.md)) has every iteration wait for the previous one's result -- bound by `addss`'s latency (several cycles), not its throughput. The second version has four independent chains the CPU can genuinely overlap, approaching `addss`'s throughput instead -- often several times faster despite doing the *same total number* of additions, purely from breaking one long dependency chain into several short, independent ones. This is precisely the transformation an auto-vectorizer performs implicitly when it turns a reduction loop into a SIMD one ([`02`](02-simd-vector-programming.md)'s horizontal-reduction pattern): the "4 (or 8) lanes of a vector register accumulating independently, combined once at the end" shape *is* this same multiple-accumulator trick, just expressed via SIMD lanes instead of separate scalar variables.

## Manual Loop Unrolling

```asm
; rolled: one iteration per cycle-ish, PLUS loop overhead (cmp+jcc) every iteration
.loop:
    add eax, [rdi + rcx*4]
    inc rcx
    cmp rcx, rsi
    jl .loop

; unrolled x4: same total work, 1/4 the loop-overhead instructions
.loop_unrolled:
    add eax, [rdi + rcx*4]
    add eax, [rdi + rcx*4 + 4]
    add eax, [rdi + rcx*4 + 8]
    add eax, [rdi + rcx*4 + 12]
    add rcx, 4
    cmp rcx, rsi
    jl .loop_unrolled
```

Unrolling amortizes the `inc`/`cmp`/`jcc` loop-control overhead (and the associated branch-prediction pressure, handbook §1.6) across more real work per iteration -- a genuine win when that overhead is a meaningful fraction of the loop body, and a non-win (or a code-bloat loss, via larger code size hurting instruction-cache behavior, handbook §1.4) when the loop body already dominates. Compilers do this automatically under optimization (`-O2`/`-O3`) using cost models tuned per target microarchitecture -- hand-unrolling in source is mostly a *historical* technique today; it remains genuinely relevant when reading disassembly (recognizing unrolled compiler output for what it is, rather than mistaking it for four unrelated array accesses) and in performance-critical hand-written assembly where you're bypassing the compiler's model entirely.

## Alignment: Code and Data

**Code alignment**: functions and, more granularly, loop entry points are often padded (with `nop`, handbook §3.3) to start at a 16- or 32-byte boundary -- because instruction fetch happens in fixed-size aligned chunks, and a hot loop's entry straddling a fetch-chunk boundary can cost real, measurable extra fetch cycles on some microarchitectures. This is what the "why is there a run of `nop`s between functions" observation in disassembly is -- deliberate alignment padding, not dead code.

**Data alignment**: [`02`](02-simd-vector-programming.md) already covers `movaps` vs. `movups`'s alignment requirement; the broader point is that a cache-line-crossing access (any access whose address range spans two 64-byte cache lines, handbook §1.4) costs a genuine extra cache-line fetch even for an otherwise-ordinary scalar load -- naturally-aligned data (a struct's fields laid out so nothing straddles a cache-line boundary) avoids this, which is part of why struct layout/padding (handbook §10.4/§22 material) is a performance concern and not purely a size one.

## Reading perf at the Instruction Level

```bash
perf stat ./program                # high-level counters: instructions, cycles, IPC,
                                      # cache-misses, branch-misses -- the first thing to run

perf record -e cycles -g ./program    # sample which instructions cycles are spent on,
                                        # with call-graph info (-g)
perf report                             # interactive view, annotated per-function and,
                                          # drilling in, per-INSTRUCTION within a function
```

`perf annotate <function>` shows the actual disassembly (matching [`09`](09-debugging-disassembly-reversing.md)'s `objdump -d` output) with a per-instruction percentage of samples landed there -- the direct way to answer "which specific instruction in this hot loop is actually expensive," rather than guessing from source alone. A high percentage parked on a single load instruction is the classic signature of a cache miss (handbook §1.4) stalling the pipeline right there; a high percentage spread evenly across a tight arithmetic sequence more often indicates a genuine throughput/dependency-chain bottleneck (§above) rather than a memory-system one. `perf stat`'s `branch-misses` counter, cross-referenced against `perf annotate` showing where the hot conditional jumps live, is the direct instrument for handbook §1.6's branch-misprediction cost in a real, running program rather than as a theoretical concept.

**Frame-pointer caveat** (handbook §4.4, restated here because it directly determines whether `perf record -g`'s call graphs are trustworthy): a release build without `-fno-omit-frame-pointer` needs `perf record --call-graph dwarf` (or `lbr` on supported hardware) instead of the default frame-pointer-walking mode, or the call-graph output will be silently wrong/truncated.

## Key Takeaways

- Latency and throughput are genuinely different numbers per instruction, and which one bottlenecks a given loop depends on whether consecutive iterations are *dependent* on each other -- the same instruction can be latency-bound in one loop shape and throughput-bound in another.
- Breaking a long dependency chain into several independent ones (multiple accumulators, or equivalently, SIMD lanes) is one of the highest-leverage manual optimizations because it changes which hardware limit the loop is up against, not just how much work it does.
- `perf annotate`'s per-instruction sample percentages are the concrete bridge between "this loop is slow" and "this specific instruction, for this specific microarchitectural reason (cache miss vs. dependency stall vs. branch misprediction), is why."

## Interview Notes

- "Why can summing an array with four separate accumulator variables be faster than one, despite doing the exact same number of additions?" -- one accumulator creates a single dependency chain bound by the add's *latency*; four independent accumulators let the CPU issue and execute them in parallel, approaching the add's (better) *throughput* instead, with the four partial sums combined only once at the end.
- "You're looking at a `perf annotate` view and one load instruction has 40% of a hot loop's samples. What's your first hypothesis?" -- a cache miss stalling the pipeline at that specific load; the next step is checking the access pattern for that load (sequential/strided/random, handbook §1.4) and whether the data it's reading fits in a cache level appropriate for the working set size.
