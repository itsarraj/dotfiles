# ARM64 (AArch64): The Second Architecture

Prerequisite: everything x86-64-specific in this library and the handbook -- this file exists specifically to show which of those facts are x86-64 quirks vs. genuinely universal ideas, by contrast with a real second ISA. ARM64 is what you're actually running assembly on if you're on Apple Silicon, most phones, and an increasing share of cloud instances (AWS Graviton) -- not an exotic/legacy architecture, a mainstream second target.

## RISC vs. CISC, Concretely

x86-64 is **CISC** (Complex Instruction Set Computer): instructions can read memory, compute, and write memory all in one instruction (`add [rbx], eax` reads memory, adds, and writes memory), and instruction encoding is variable-length (1-15 bytes, handbook §1.2). ARM64 is **RISC** (Reduced Instruction Set Computer, though modern ARM64 is more accurately "a very well-designed load/store architecture" than "minimal" in any literal sense): **only** dedicated load/store instructions touch memory; every ALU operation (`add`, `sub`, `and`, ...) operates strictly register-to-register, and every instruction is a fixed 4 bytes. This single design choice cascades into most of the concrete differences below.

## Register Set

| ARM64 | Role |
|---|---|
| `X0`-`X30` (64-bit) / `W0`-`W30` (low 32 bits of the same registers) | General purpose -- note the naming pattern is the *opposite* direction of x86-64's (handbook §2.1's `RAX`/`EAX`/`AX`/`AL` nesting): here, `W0` is simply "the low 32 bits of `X0`," a cleaner, uniform relationship across all 31 registers rather than x86-64's historically-accumulated, inconsistent sub-register naming |
| `X0`-`X7` | First 8 integer/pointer arguments (AAPCS64, §below) -- more register-passed arguments than x86-64's SysV 6, again a RISC-lineage choice reflecting more general-purpose registers overall |
| `X0` | Return value (`X0`/`X1` for a 128-bit return) |
| `X19`-`X28` | Callee-saved |
| `X29` (`FP`) | Frame pointer -- conventionally maintained far more consistently than x86-64's `RBP` (handbook §4.4's frame-pointer-omission optimization is much rarer on ARM64 in practice, partly because ARM64 has enough spare registers that giving one up for `FP` is a smaller relative cost) |
| `X30` (`LR`) | **Link register** -- holds the return address directly, set automatically by `bl` (branch-and-link, ARM64's `call` equivalent) -- a fundamentally different mechanism from x86-64's `call`, which pushes the return address to the *stack* (handbook §4.1). ARM64's `ret` reads `LR`, not the stack, by default |
| `SP` | Stack pointer -- unlike x86-64's `RSP`, `SP` is *not* a general-purpose register usable as an arbitrary operand in most instructions; it has restricted addressing-mode roles |
| `PC` | Instruction pointer, not directly addressable as a GPR (similar restriction to x86-64's `RIP`) |
| `XZR`/`WZR` | The **zero register** -- reads as 0, writes are discarded. No dedicated `xor reg, reg` zeroing idiom (handbook §3.3) is needed on ARM64; `mov x0, xzr` (or, more precisely, an add/move-from-zero-register encoding) is the direct, unambiguous way to zero a register, and `XZR` doubles as a way to *discard* a result (e.g. a compare that doesn't need to keep the subtraction result, ARM64's `cmp` is literally `subs xzr, ...` under the hood -- a subtract that writes flags and discards the result into the zero register, rather than `cmp` being a conceptually distinct instruction the way it more clearly is on x86-64) |

## Load/Store Architecture in Practice

```asm
; x86-64: one instruction reads memory, adds, done
add eax, [rbx]

; ARM64: memory access and arithmetic are ALWAYS separate instructions
ldr w0, [x1]        ; load
add w0, w0, w2        ; then compute
```

This is the direct, mechanical consequence of "RISC" above -- there is no ARM64 instruction that both reads memory and performs arithmetic in one step. This generally means *more* instructions for equivalent work compared to x86-64, traded for uniform, easy-to-pipeline, fixed-length encoding and (not coincidentally) real power-efficiency advantages that are a large part of why ARM64 dominates mobile and is increasingly competitive in servers.

## Instruction Style, Side by Side

| Operation | x86-64 (Intel syntax) | ARM64 |
|---|---|---|
| Move immediate | `mov rax, 5` | `mov x0, #5` |
| Register move | `mov rax, rbx` | `mov x0, x1` |
| Add | `add rax, rbx` | `add x0, x0, x1` (3-operand -- like AVX's VEX encoding, [`02`](02-simd-vector-programming.md), ARM64's ALU ops are non-destructive by default, not an exception the way VEX was for x86) |
| Load from memory | `mov rax, [rbx]` | `ldr x0, [x1]` |
| Store to memory | `mov [rbx], rax` | `str x0, [x1]` |
| Compare | `cmp rax, rbx` | `cmp x0, x1` (= `subs xzr, x0, x1` under the hood, §above) |
| Unconditional jump | `jmp label` | `b label` |
| Conditional jump | `je label` | `b.eq label` |
| Function call | `call func` | `bl func` (sets `LR` = `X30`, no stack push) |
| Return | `ret` (pops the stack) | `ret` (reads `LR`) |

## Addressing Modes

ARM64's load/store instructions support base+offset (`[x1, #16]`), **pre-indexed** (`[x1, #16]!` -- computes the address, uses it, *and* writes the incremented address back into `x1`, in one instruction), and **post-indexed** (`[x1], #16` -- uses the current value of `x1` as the address, *then* increments `x1` afterward) forms -- the pre/post-indexed forms are ARM64's answer to the kind of "compute an address and advance a pointer" pattern x86-64 needs a separate `add`/`lea` instruction for; a tight pointer-walking loop (e.g. array iteration, or the prologue/epilogue's paired-register save shown below) genuinely benefits from folding the pointer advance into the memory instruction itself. A **literal** pool/PC-relative form (`ldr x0, =symbol` as an assembler pseudo-instruction, or `adrp`+`add` for position-independent addressing, ARM64's RIP-relative equivalent from handbook §3.2/§8.6) rounds out the set -- ARM64 instructions being fixed-4-byte-width means a full 64-bit immediate/address literally cannot fit in one instruction the way x86-64's variable-length encoding sometimes allows, which is exactly why loading a large constant or a symbol's address on ARM64 routinely takes 2-4 instructions (`adrp`+`add` for a PC-relative symbol address, or a sequence of `movz`/`movk` -- move-with-zero / move-with-keep -- each loading 16 bits of a 64-bit constant) where x86-64 might do it in one.

## AAPCS64 Calling Convention

The ARM64 equivalent of handbook §6's SysV/Windows ABI treatment -- the **ARM Architecture Procedure Call Standard**, 64-bit variant:

- **Integer/pointer arguments**: `X0`-`X7` (eight registers, vs. SysV's six) -- a 9th and beyond spill to the stack.
- **Floating-point arguments**: `V0`-`V7` (ARM64's SIMD/FP register file, the rough analog of `XMM0`-`XMM7`).
- **Return value**: `X0` (`X0`/`X1` for wide results); `V0` for float/double.
- **Callee-saved**: `X19`-`X28`, and `X29`/`X30` (frame pointer/link register) if the function itself calls further functions (a "leaf" function that calls nothing else, handbook §6.5-adjacent, has no obligation to preserve `LR` beyond its own use of it).
- **Stack alignment**: `SP` must be 16-byte aligned at a public interface boundary (a function call) -- the same *requirement*, for the same underlying SIMD-operand reason, as SysV's stack alignment rule (handbook §6.4), just restated for a different ISA.
- **No red zone**: unlike SysV (handbook §6.5), AAPCS64 has no guaranteed-untouched region below `SP` -- every function must formally adjust `SP` for any stack space it needs, matching Windows x64's stance (handbook §6.3) rather than SysV's.

```asm
; typical ARM64 prologue/epilogue, using pre/post-indexed addressing (§above)
; to combine the stack-pointer adjustment with the register save in one instruction:
my_function:
    stp x29, x30, [sp, #-16]!      ; store PAIR (fp, lr), pre-indexed: sp -= 16, then store
    mov x29, sp                     ; establish frame pointer
    ; ... body ...
    ldp x29, x30, [sp], #16           ; load pair, post-indexed: load, THEN sp += 16
    ret
```

`stp`/`ldp` (store/load **pair**) save or restore two registers in a single instruction -- a genuinely different capability from x86-64's `push`/`pop` (which handle exactly one register at a time), and the reason ARM64 function prologues/epilogues are often *shorter*, instruction-count-wise, than the equivalent x86-64 sequence despite RISC's general "more instructions for the same work" tendency -- the register-pair instructions specifically claw some of that back for the extremely common save-frame-pointer-and-link-register pattern.

## Condition Flags (NZCV)

ARM64's flags register segment is `NZCV` -- **N**egative, **Z**ero, **C**arry, o**V**erflow -- directly analogous to x86-64's `SF`/`ZF`/`CF`/`OF` (handbook §2.3), with the same underlying meanings. The genuine difference is that on ARM64, *most* ALU instructions have an explicit flag-setting variant chosen by an `s` suffix (`adds`, `subs`, `ands` set flags; plain `add`/`sub`/`and` do not) -- flag-setting is opt-in per instruction, whereas on x86-64 essentially every arithmetic/logic instruction always updates flags as a side effect (handbook §2.3/§3.3), with `lea` as the deliberate flag-preserving exception. This ARM64 design gives the compiler (and a hand-optimizer) more freedom to interleave flag-affecting and flag-preserving computation without an instruction accidentally clobbering flags a later branch still needs -- a genuine ergonomic/scheduling advantage traded for one extra letter of mnemonic verbosity.

## x86-64 vs. ARM64: Summary Table

| | x86-64 | ARM64 |
|---|---|---|
| Design philosophy | CISC -- memory operands allowed directly in ALU ops | RISC/load-store -- memory access always separate from computation |
| Instruction length | Variable, 1-15 bytes | Fixed, 4 bytes |
| GPR count | 16 | 31 |
| Return address | Pushed to the stack by `call`, popped by `ret` | Held in a dedicated link register (`X30`/`LR`) by `bl`, read by `ret` |
| Zeroing idiom | `xor reg, reg` (handbook §3.3) | Zero register (`XZR`) available directly, no idiom needed |
| Flag setting | Automatic on almost every arithmetic instruction | Opt-in via an `s` suffix (`adds` vs. `add`) |
| Non-destructive 3-operand ALU ops | Only via VEX-encoded AVX ([`02`](02-simd-vector-programming.md)) | The default for every ordinary ALU instruction |
| Memory model | Strong (loads/stores mostly stay in program order by default, [`05`](05-interrupts-exceptions-privileged-atomics.md)) | Weak -- the compiler must emit explicit barrier instructions (`dmb`, `dsb`, load-acquire/store-release instruction *forms*) far more often to get the same ordering guarantees, directly affecting how much extra code the same atomics-heavy Rust/C++ program generates on each target |
| Function-call arg registers | 6 integer (`RDI`/`RSI`/`RDX`/`RCX`/`R8`/`R9`) | 8 integer (`X0`-`X7`) |

## Key Takeaways

- Nearly every concrete difference between x86-64 and ARM64 traces back to one root decision -- CISC-with-memory-operands vs. strict load/store -- rather than being a grab-bag of unrelated design choices.
- ARM64's dedicated link register (rather than a stack-pushed return address) and zero register (rather than an `xor`-based idiom) both remove a small instruction or a subtle idiom x86-64 needs, at the cost of `LR` needing explicit preservation (via `stp`) in any non-leaf function.
- ARM64's weaker default memory-ordering model is the concrete, mechanical reason identical high-level atomics code can compile to visibly more instructions on ARM64 than on x86-64 -- not a compiler-quality gap, a genuine ISA-level guarantee difference (already flagged in [`05`](05-interrupts-exceptions-privileged-atomics.md), restated here from the ARM side).

## Interview Notes

- "Why does ARM64 assembly often have more instructions than the equivalent x86-64 code for the same task, despite ARM64 chips often being competitive or faster in practice?" -- the load/store architecture forbids combining memory access and computation in one instruction, genuinely increasing instruction count for memory-touching code; the efficiency comes from elsewhere (simpler, more uniform, more power-efficient decode and execution per instruction, not from doing more per instruction).
- "How does ARM64 handle a function's return address differently from x86-64, and what's the consequence for a non-leaf function?" -- ARM64 stores it in the link register (`X30`) via `bl`, not on the stack; a non-leaf function (one that calls further functions, which will overwrite `LR` with their own return address) must explicitly save `LR` to the stack itself (typically via `stp x29, x30, [sp, #-16]!`) before making any further calls, and restore it before its own `ret`.
