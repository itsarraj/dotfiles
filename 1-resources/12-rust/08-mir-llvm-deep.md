# MIR and LLVM, In Depth: Drop Elaboration, Move Analysis, SSA, and Optimization Passes

Prerequisite: handbook §9.2 (why borrow-checking runs on MIR specifically). This file covers the two MIR-stage analyses that make ownership actually work in the presence of conditional control flow, then goes one level deeper into the LLVM machinery both `rustc` and `clang` share.

## The Problem: Conditional Moves

```rust
fn f(cond: bool) {
    let s = String::from("hello");
    if cond {
        drop(s);            // s is moved (and dropped) HERE, on this branch only
    }
    // s must be dropped again at the end of the function scope --
    // but ONLY if we did NOT take the `if` branch above. How does the
    // compiler generate correct cleanup code for both possible paths?
}
```

A value might be moved-from on *some* control-flow paths through a function but not others -- the compiler needs to generate a drop at scope exit that runs *conditionally*, based on which path was actually taken, without that condition existing anywhere in the original source.

## Move Analysis (MIR Dataflow)

Before drop elaboration can run, the compiler performs a **dataflow analysis over MIR** tracking, for every local variable at every point in the control-flow graph, whether it is **definitely initialized**, **definitely moved-out/uninitialized**, or **maybe** either (on some incoming paths but not others) -- exactly the kind of backward/forward dataflow analysis §01's NLL material already introduced, applied here to initialization state rather than borrow liveness. This is also the actual mechanism enforcing the "use of moved value" compile error: at any program point where a local is used, the analysis checks whether it's provably still initialized on *every* path reaching that point -- if any path could have already moved it out, that's the error, computed directly from this dataflow result rather than from a simpler syntactic rule.

## Drop Elaboration

For every local whose initialization state is only "maybe" at some scope-exit point (as in the `cond` example above), the compiler introduces a **drop flag** -- a hidden, compiler-generated boolean local, invisible in source, set to `true` when the value is initialized and `false` when it's moved out -- and elaborates the implicit end-of-scope drop into an explicit conditional:

```
 Roughly, the generated MIR shape for the example above:
 bb0: s = String::from("hello"); drop_flag_s = true; goto bb1 if cond else bb3
 bb1: drop(s); drop_flag_s = false; goto bb2
 bb2: goto bb4
 bb3: goto bb4
 bb4: if drop_flag_s { drop(s) }     // the SAME implicit end-of-scope drop, now
                                        // conditioned on the flag drop-elaboration
                                        // introduced -- correct on every path,
                                        // with zero flag overhead on paths where
                                        // the analysis could prove initialization
                                        // state statically (the common case --
                                        // most locals never need a runtime flag at all)
```

The crucial efficiency property: drop flags are only introduced where the move-analysis dataflow result is genuinely ambiguous ("maybe" moved) -- for the overwhelming majority of ordinary, straight-line code, the analysis proves initialization state precisely, and the corresponding drop compiles to an unconditional call with **no runtime flag check at all**. This is the concrete mechanism behind the broader claim (handbook §21, §34.2) that ownership/`Drop` correctness is a compile-time property with no *inherent* runtime cost -- the rare cases that *do* need a runtime flag are a narrow, specific consequence of conditional control flow interacting with moves, not a general tax every `Drop` implementation pays.

## LLVM: SSA Form

By the time Rust's MIR is lowered to LLVM IR (handbook §9.2), it's converted into **Static Single Assignment (SSA)** form -- every variable is assigned exactly once, and control-flow merge points use explicit **phi nodes** to select which prior definition is live:

```llvm
; roughly: let x = if cond { 1 } else { 2 };
%x1 = 1
br label %merge
%x2 = 2
br label %merge
merge:
  %x = phi i32 [ %x1, %then_block ], [ %x2, %else_block ]
```

SSA exists because it makes a huge class of optimizations dramatically simpler to implement correctly: since each SSA value has exactly one definition, "does this optimization change what value X refers to" becomes a local, syntactic question instead of requiring a separate reaching-definitions analysis for ordinary mutable-variable code -- nearly every optimization pass below is easier to write, and provably correct, specifically because it operates on SSA.

## Key LLVM Passes

- **mem2reg**: promotes stack-allocated (`alloca`'d) values that are never address-taken into pure SSA registers -- this is the pass that turns naive, straightforward-but-verbose initial IR (every local gets a stack slot) into the tight, register-based form actual optimization operates on; almost every other pass benefits from running after this one.
- **Inlining**: replaces a call site with the callee's body (handbook §9.4/§35.4) -- the single highest-leverage pass for enabling *further* optimization across what used to be a function-call boundary (constant folding, dead-code elimination, and vectorization routinely only become legal/visible once inlining has exposed the combined code to the optimizer as one unit), which is exactly why "zero-cost abstraction" claims depend so heavily on inlining actually happening -- an abstraction whose thin wrapper function *doesn't* get inlined pays a real, non-zero call overhead.
- **GVN (Global Value Numbering)**: identifies computations that produce provably identical results (even across different textual expressions) and eliminates the redundant ones -- a more powerful generalization of local common-subexpression elimination.
- **LICM (Loop-Invariant Code Motion)**: hoists a computation that doesn't change across loop iterations out of the loop entirely, computing it once instead of on every iteration.
- **SROA (Scalar Replacement of Aggregates)**: breaks a struct/aggregate stored in one stack slot into independent scalar values when possible, unlocking further per-field optimization (constant propagation, register allocation) that treating the whole struct as one opaque memory blob would block.
- **Vectorization passes** (`loop-vectorize`, `slp-vectorize`): the auto-vectorization mechanism referenced in handbook §37.5 -- `loop-vectorize` rewrites suitable scalar loops into SIMD instructions (handbook §2.4); `slp-vectorize` (Superword-Level Parallelism) finds *non-loop* straight-line code performing the same scalar operation on adjacent memory and packs it into SIMD instructions instead, a genuinely different pattern than loop vectorization targets.

## Instruction Selection (Brief)

Once optimization on LLVM IR is essentially finished, the backend maps IR operations onto the *actual* target instruction set (handbook §9.5) via one of two internal frameworks: the older, pattern-matching-based **SelectionDAG** (builds a per-basic-block directed acyclic graph of IR operations and matches it against known instruction patterns for the target, historically LLVM's primary mechanism) or the newer **GlobalISel** (designed to scale better across basic-block boundaries and to be easier to extend for new targets, gradually replacing SelectionDAG for some targets though not a universal replacement as of this writing). Either way, this is the stage where "IR add" becomes "x86-64 `add`" *specifically*, informed by what instructions the actual target CPU has (AVX-512 availability and similar target-feature questions are resolved here) -- the last stage before register allocation and final instruction scheduling (handbook §9.5) produce the assembly this whole handbook has been building toward understanding.

## Key Takeaways

- Move analysis is a MIR dataflow computation, and drop elaboration's runtime flags are only introduced where that analysis is genuinely ambiguous -- most `Drop` calls in ordinary code compile unconditionally, with zero flag-check overhead.
- SSA form (one definition per value, phi nodes at merges) is what makes most LLVM optimization passes tractable to implement correctly -- it's an internal representation choice, not something you write directly, but it's why the optimizer can do what it does.
- Inlining is the highest-leverage single pass for "zero-cost abstraction" claims to actually hold -- most other optimizations only see across a former call boundary once inlining has erased it.

## Interview Notes

- "Why doesn't every `Drop` call in Rust carry a hidden runtime flag check?" -- drop elaboration only introduces a flag where the compiler's move-analysis dataflow result is ambiguous (a value's initialization state depends on which control-flow path was taken); for statically-provable cases (the overwhelming majority of real code) the drop is unconditional, with no flag at all.
- "Why is SSA form useful for a compiler's optimizer, concretely?" -- because each value has exactly one definition, "what value does this reference refer to" is a purely local, syntactic fact rather than something requiring a separate reaching-definitions analysis -- which is what lets passes like constant propagation and dead-code elimination be implemented as comparatively simple, local transformations.
