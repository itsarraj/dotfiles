# Systems Programming Handbook: Assembly, C, C++, and Rust

## How This Handbook Is Organized

This is a from-the-machine-up reference. **Part I** builds the actual hardware and toolchain model -- CPU architecture, registers, assembly, the stack, the heap, calling conventions, memory layout, linking, and the compiler pipeline -- with no reference to any specific high-level language. Everything after that builds *on top of* Part I: **Part II (C)**, **Part III (C++)**, and **Part IV (Rust)** each explain their language's constructs in terms of the machine model you now already have, so "what does this compile to" is never a mystery to defer -- it's already answered by Part I. **Part V** covers concerns that cut across all three languages (OS interaction, performance, debugging, build systems). **Part VI** is the applied capstone: designing and building a container runtime in Rust, which is the concrete project this handbook is ultimately in service of.

Read Part I once, fully, even the parts that feel like review -- every later chapter cites it constantly (e.g. "see §6.2" for the calling convention) rather than re-explaining it. Every chapter ends with a **Chapter Notes** block: key takeaways, common mistakes, interview-style questions, and what the compiler/CPU are doing on your behalf.

**Roadmap:**

| Part | Chapters | Question it answers |
|---|---|---|
| I -- The Machine | 1-9 | What is actually happening in silicon and in the toolchain, independent of language? |
| II -- C | 10-13 | How does the language that *is* the machine model (almost) work? |
| III -- C++ | 14-18 | What do you get by adding zero-cost abstraction on top of C? |
| IV -- Rust | 19-35 | What do you get by adding compile-time-checked safety on top of that? |
| V -- Cross-Cutting | 36-39 | OS interaction, performance, debugging, and build tooling, common to all three |
| VI -- Applied | 40-57 | Using all of the above to design and build a real container runtime |

---

# PART I -- The Machine: CPU, Assembly, ABI, Memory, and Compilation

## Chapter 1: CPU Architecture

### 1.1 Why Start Here

Every abstraction in every chapter that follows -- ownership, virtual functions, exceptions, `async fn` -- is something a compiler translates into a sequence of instructions executed by a real, physical CPU. If you don't have a model of *what the CPU actually does with an instruction*, "zero-cost abstraction" is a slogan you take on faith instead of a claim you can verify. This chapter builds that model.

### 1.2 The Fetch-Decode-Execute-Retire Cycle

A CPU core repeats one loop, billions of times a second:

```
 ┌───────────┐    ┌───────────┐    ┌───────────┐    ┌───────────┐
 │   FETCH   │───▶│  DECODE   │───▶│  EXECUTE  │───▶│  RETIRE   │
 │ read next │    │ figure out│    │  do the   │    │  commit   │
 │ instr. at │    │ what the  │    │ operation │    │ result,   │
 │    RIP    │    │ bytes mean│    │ (ALU etc.)│    │ update RIP│
 └───────────┘    └───────────┘    └───────────┘    └───────────┘
```

- **Fetch**: read the bytes at the address the instruction-pointer register (`RIP` on x86-64) points to.
- **Decode**: figure out which instruction those bytes encode (x86-64 instructions are variable-length, 1-15 bytes -- decoding is genuinely complex, which is part of why modern x86 chips translate decoded instructions into simpler internal micro-ops).
- **Execute**: perform the operation -- an integer add in the ALU, a memory load, a branch.
- **Retire**: commit the result to visible architectural state (a register, memory, flags) and advance to the next instruction.

Modern CPUs don't run this as a strict one-instruction-at-a-time loop -- they **pipeline** it (§1.5) and often execute **out of order** (§1.7), while still *retiring* results in original program order, which is what lets a single core look, from the outside, exactly like the simple four-stage loop above even though internally dozens of instructions are in flight simultaneously.

### 1.3 ALU and Control Unit

- **ALU (Arithmetic Logic Unit)**: the circuit that actually performs `add`, `sub`, `and`, `or`, `xor`, shifts, and comparisons. A modern core has *several* ALUs (and separate units for multiplication, division, and floating point/SIMD) so multiple independent instructions can execute in the same cycle.
- **Control Unit**: decodes instructions and generates the internal signals that route data between registers, the ALU, and memory -- the part of the chip that turns "the bytes mean `add rax, rbx`" into "connect these two register read ports to the ALU's add input and the result to `rax`'s write port."

### 1.4 The Cache Hierarchy

Main memory (DRAM) is roughly 100-300x slower to access than a register. Caches exist to hide that gap by keeping recently/likely-used data physically close to the core:

```
 CPU Core
   │  ~1 cycle
   ▼
 ┌─────────┐  ~32-64 KB, per-core, split I-cache/D-cache
 │   L1    │  ~4-5 cycles
 └─────────┘
   │
   ▼
 ┌─────────┐  ~256KB-1MB, per-core (usually)
 │   L2    │  ~12-15 cycles
 └─────────┘
   │
   ▼
 ┌─────────┐  several MB-tens of MB, shared across cores
 │   L3    │  ~40-70 cycles
 └─────────┘
   │
   ▼
 ┌─────────┐
 │  DRAM   │  ~200-300+ cycles
 └─────────┘
```

Caches operate in fixed-size **cache lines** (typically 64 bytes on x86-64) -- reading a single byte pulls the entire 64-byte line containing it into L1. This is the concrete mechanism behind two ideas you'll meet constantly later:

- **Cache friendliness / spatial locality**: iterating an array sequentially reuses each fetched cache line for ~16 consecutive `i32`s before needing the next one; iterating the same data via a linked list or a hash map with poor locality faults a new cache line almost every access.
- **False sharing** (§22.4 in the original systems chapters, revisited in §37): two unrelated variables that happen to sit in the *same* 64-byte cache line will bounce that line between cores' caches if different cores write to each variable, even though the variables themselves have nothing to do with each other.

### 1.5 Pipelining

Instead of waiting for one instruction to fully complete fetch→decode→execute→retire before starting the next, the CPU overlaps stages -- while instruction N is executing, instruction N+1 is decoding, and N+2 is fetching:

```
 cycle:        1    2    3    4    5    6
 instr 1:    F    D    E    R
 instr 2:         F    D    E    R
 instr 3:              F    D    E    R
 instr 4:                   F    D    E    R
```

Throughput approaches "one instruction retired per cycle" even though each individual instruction still takes multiple cycles start to finish -- this is why *instruction latency* and *instruction throughput* are different numbers you'll see in optimization manuals, and why they matter differently (§37).

A pipeline stalls (a "bubble") when a later stage needs a result the earlier stage hasn't produced yet, or when a branch is mispredicted (§1.6) and the whole pipeline behind the wrong-path instructions has to be flushed -- a real, measurable performance cost, which is the entire reason branch prediction exists as a distinct topic worth learning.

### 1.6 Branch Prediction

A conditional jump (`je`, `jne`, ...) can't be fetched-ahead-of-time correctly unless the CPU *guesses* which way it will go, because the correct target depends on a flag that isn't computed yet. Modern CPUs keep a **branch predictor** -- a hardware table keyed by instruction address, recording which way each branch went recently -- and speculatively fetch and execute down the predicted path. If the guess is right (common: >95% for well-behaved code, e.g. a loop counter comparison that goes the same way thousands of times before flipping), you paid nothing. If it's wrong, everything speculatively executed down the wrong path is discarded and the pipeline restarts from the correct target -- a penalty of roughly 10-20 cycles on modern chips.

This is why unpredictable branches (`if (data[i] > threshold)` on *random* data) are measurably slower than the same comparison on sorted data, and why branchless idioms (`cmov`, §3.3; bitwise masking) exist as an optimization technique -- they trade a data dependency for a control dependency, removing the misprediction risk entirely.

### 1.7 Out-of-Order Execution (Brief)

Beyond simple pipelining, most modern cores execute instructions **out of order** internally -- if instruction N is stalled waiting on a slow memory load, the core will execute instruction N+3 first if its inputs are ready, then reorder results back into program order at retirement. This is the hardware-level cause of the memory-reordering behavior that motivates atomics and memory ordering (covered in depth in the original §22/§34.5 material, Part VI) -- each core's *local* view of "what happened in what order" can differ from another core's view unless you use the ordering primitives that constrain it.

### 1.8 TLB, MMU, Virtual Memory, and Paging

Every memory address a program uses is a **virtual address** -- it doesn't correspond directly to a physical DRAM location. The **MMU (Memory Management Unit)**, part of the CPU, translates virtual → physical addresses on every single memory access, using a per-process table of mappings called **page tables** maintained by the OS kernel. Memory is managed in fixed-size chunks called **pages** (4 KiB is the classic x86-64 default; 2 MiB/1 GiB "huge pages" also exist to reduce translation overhead for large regions).

```
 Virtual Address                              Physical Address
 ┌──────────────────────┐   MMU walks the    ┌──────────────────────┐
 │  process A's 0x4000   │   page table for    │  actual DRAM location │
 │  process B's 0x4000   │──▶ process A ─────▶│  (different for A/B)  │
 │  (same VA, different  │   page table for    │                        │
 │   physical memory)    │   process B          │                        │
 └──────────────────────┘                      └──────────────────────┘
```

Walking the full page table on every access would be far too slow, so the CPU caches recent virtual→physical translations in the **TLB (Translation Lookaside Buffer)** -- a small, very fast cache dedicated to address translation. A **TLB miss** means the MMU has to do a full page-table walk (multiple memory accesses just to find where the *real* memory access should go) -- another concrete reason large, scattered memory access patterns are slower than compact, sequential ones (a TLB has limited entries, covering a limited *reach* of address space; a `4 KiB * TLB entries` window is roughly the region you can access without extra translation cost).

**Page faults**: if the MMU's walk finds no valid mapping (page never allocated, swapped out, or a genuine bug like a null-pointer dereference), it raises a fault, trapping into the kernel. The kernel either fixes it up transparently (a **minor fault** -- e.g. lazily allocating a page on first write, or the **copy-on-write** mechanism §36 uses for `fork()`) or delivers `SIGSEGV` to the process (a genuine invalid access -- this is the actual mechanism behind every "segmentation fault" you've ever seen).

**Copy-on-write (COW)**, briefly here (full treatment in §36): when `fork()` duplicates a process, the child's page table is set up to point at the *same* physical pages as the parent, marked read-only. The first write by either process to a shared page triggers a page fault, the kernel copies just that one page, and both processes continue with their own private copy -- `fork()` is cheap precisely because it defers the actual memory copy until (and unless) it's needed.

### Chapter 1 Notes

**Key Takeaways**
- A CPU's visible behavior (fetch→decode→execute→retire, in order) is a simplification; internally it pipelines and reorders for speed while preserving that external illusion.
- Caches exist because DRAM latency (~200+ cycles) is enormous relative to a register access (~0 cycles) -- almost every performance topic in this handbook eventually reduces to "keep the CPU fed from cache, not DRAM."
- Virtual memory means every address you see in a debugger or in Rust/C code is a lie the MMU translates on the fly -- two different processes can use the identical virtual address for completely different physical memory.

**Common Mistakes**
- Assuming instruction count is a good proxy for speed -- cache misses and branch mispredictions routinely dominate over raw instruction count on modern hardware.
- Treating `fork()` as an expensive full-memory-copy operation -- it isn't, because of copy-on-write.

**Interview Notes**
- "What happens on a cache miss?" -- walk fetch→miss at L1→check L2→check L3→DRAM access, and note the escalating latency at each level.
- "Why is branch misprediction expensive?" -- the pipeline has to discard all speculatively-executed instructions down the wrong path and restart fetch from the correct target.
- "What causes a page fault, and are all page faults bugs?" -- no; minor faults (lazy allocation, COW) are a normal, load-bearing part of how virtual memory works, distinct from a genuine invalid access (SIGSEGV).

---

## Chapter 2: Registers

Registers are the fastest storage a CPU has -- physically part of the core, accessed in essentially zero extra cycles, as opposed to even L1 cache. Every value an instruction operates on either comes from a register or has to be loaded into one first.

### 2.1 General-Purpose Registers

x86-64 has 16 general-purpose registers. The naming reflects 40+ years of backward compatibility -- each 64-bit register's lower bits are separately addressable under older names:

```
 63                                0
 ┌──────────────────────────────────┐  RAX  (64-bit, x86-64)
 └──────────────────────────────────┘
                     ┌────────────────┐  EAX  (low 32 bits)
                     └────────────────┘
                              ┌────────┐  AX   (low 16 bits)
                              └────────┘
                              ┌────┬───┐  AH │ AL  (high/low byte of AX)
                              └────┴───┘
```

Writing to `EAX` (the 32-bit name) on x86-64 zero-extends and clears the upper 32 bits of `RAX` -- a quirk that matters for exactly the kind of low-level correctness FFI code needs to get right.

| Register | Common role (by convention, not hardware-enforced) |
|---|---|
| `RAX` | Return value; accumulator for arithmetic |
| `RBX` | Callee-saved general-purpose |
| `RCX` | 4th integer argument (SysV); loop counter by convention (`rep`/`loop` instructions) |
| `RDX` | 3rd integer argument (SysV); high half of 128-bit results (`RDX:RAX`) |
| `RSI` | 2nd integer argument (SysV); traditionally "source index" for string ops |
| `RDI` | 1st integer argument (SysV); traditionally "destination index" |
| `RBP` | Frame (base) pointer -- conventionally the base of the current stack frame |
| `RSP` | Stack pointer -- always points at the top of the stack |
| `RIP` | Instruction pointer -- address of the next instruction; not directly writable except via control flow |
| `R8`-`R15` | General purpose; `R8`-`R9` are the 5th/6th integer arguments (SysV) |

None of the "common role" assignments except `RSP`/`RIP` are enforced by the hardware -- they're conventions the calling convention/ABI (§6) layers on top of otherwise-general-purpose registers. The hardware doesn't know or care that `RDI` "is" the first argument; that's purely a software agreement every compiler on a platform follows so code from different compilers/languages can call each other (this is the mechanism behind §6 and the old §35.5 material).

### 2.2 RIP, RSP, RBP in Detail

- **`RIP`** always holds the address of the *next* instruction to execute. You can't `mov` into it directly -- it's only changed by control-flow instructions (`jmp`, `call`, `ret`, conditional jumps) or by falling through to the next instruction. RIP-relative addressing (§3.2) uses this register to compute addresses relative to the current code location, which is central to how position-independent code (§8.6) works.
- **`RSP`** points at the current top of the stack (the lowest address currently in use, since the stack grows *downward* on x86-64 -- see §4). `push` decrements it and writes; `pop` reads and increments it.
- **`RBP`** conventionally marks the base of the current function's stack frame, giving a stable reference point for locals and arguments even as `RSP` moves around during the function body (from further pushes, or calling other functions). Modern optimized builds frequently omit maintaining `RBP` at all (§4.4) to free up an extra general-purpose register, using pure `RSP`-relative addressing instead.

### 2.3 RFLAGS

A register whose individual bits record the *outcome* of the most recent arithmetic/comparison instruction -- conditional jumps and `cmov` read these bits, not the actual result value.

| Flag | Set when... |
|---|---|
| `ZF` (Zero) | The result was zero |
| `SF` (Sign) | The result's high bit is set (negative, for signed interpretation) |
| `CF` (Carry) | An unsigned add overflowed / unsigned sub borrowed |
| `OF` (Overflow) | A *signed* add/sub overflowed |
| `PF` (Parity) | The low byte of the result has an even number of 1 bits (legacy, rarely used directly today) |

`cmp a, b` internally computes `a - b` and sets flags exactly as `sub` would, *without* storing the result -- it exists purely to set flags for a following conditional jump/`cmov`. `test a, b` similarly computes `a AND b` for flags only, most commonly seen as `test eax, eax` (cheaper-to-encode idiom for "is eax zero?", equivalent to `cmp eax, 0`).

### 2.4 SIMD Registers: XMM, YMM, ZMM, and AVX

Beyond the general-purpose registers, CPUs have a separate, wider register file for **SIMD (Single Instruction, Multiple Data)** -- performing the same operation on several values packed into one register simultaneously:

```
 XMM (128-bit, SSE):  [ f32 ][ f32 ][ f32 ][ f32 ]   -- 4 floats at once
 YMM (256-bit, AVX):  [ f32 ][ f32 ][ f32 ][ f32 ][ f32 ][ f32 ][ f32 ][ f32 ]  -- 8 floats
 ZMM (512-bit, AVX-512): 16 floats at once
```

A single `vaddps ymm0, ymm1, ymm2` adds eight pairs of floats in one instruction -- this is the hardware mechanism behind vectorization (§37): the compiler's auto-vectorizer looks for loops it can rewrite to use these wide instructions instead of one scalar operation per iteration. `XMM` registers double as the *default* floating-point registers on x86-64 even for ordinary scalar `f32`/`f64` math (the older x87 FPU stack is legacy and rarely used by modern compilers) -- this is also why floating-point arguments pass in `XMM0`-`XMM7` rather than the integer argument registers (§6.2).

### Chapter 2 Notes

**Key Takeaways**
- Register *names* like "argument 1" or "return value" are software convention (the ABI, §6), not hardware fact -- the same physical register is just a general-purpose 64-bit storage slot.
- `RFLAGS` is how comparisons communicate with conditional jumps -- the comparison and the branch are two separate instructions linked only through these bits.
- SIMD registers and instructions are the actual mechanism "vectorization" refers to -- it's not a metaphor, it's literally packing multiple values into one wide register operation.

**Common Mistakes**
- Assuming `RCX` is always "the fourth argument" -- that's true only under the System V AMD64 ABI (Linux/macOS); the Windows x64 ABI uses a different register assignment entirely (§6.3).
- Forgetting that writing a 32-bit register name (`EAX`) zero-extends and clobbers the full 64-bit register -- a real source of subtle bugs in hand-written or generated assembly/FFI shims.

**Interview Notes**
- "Why does `cmp` exist separately from `sub`?" -- to set flags for a subsequent branch without needing to store (and potentially waste a register on) the subtraction result itself.
- "What's the practical difference between SSE, AVX, and AVX-512?" -- register width (128/256/512 bits) and therefore how many values one instruction processes at once.

---

## Chapter 3: Assembly Language Fundamentals

### 3.1 Syntax: AT&T vs. Intel

Two different textual notations for the *same* instructions -- know both, since GNU tools (`gdb`, default `objdump`) default to AT&T, while Windows tooling, Intel's own documentation, and NASM default to Intel syntax.

| | AT&T | Intel |
|---|---|---|
| Operand order | source, dest | dest, source |
| Register prefix | `%rax` | `rax` |
| Immediate prefix | `$5` | `5` |
| Memory | `-4(%rbp)` | `[rbp - 4]` |
| Example | `movq $5, %rax` | `mov rax, 5` |

```asm
; Intel syntax (used throughout this handbook)
mov rax, 5          ; rax = 5
add rax, rbx         ; rax = rax + rbx
mov [rbp - 8], rax   ; store rax into the memory at rbp-8
```

```
# AT&T syntax (the same three instructions)
movq $5, %rax
addq %rbx, %rax
movq %rax, -8(%rbp)
```

This handbook uses **Intel syntax** throughout (matching `objdump -M intel`, NASM, and Compiler Explorer's default) since it reads left-to-right the same direction as `dest = source` in every language covered here.

### 3.2 Addressing Modes

How an instruction's operand specifies *where* a value comes from:

| Mode | Syntax (Intel) | Meaning |
|---|---|---|
| Immediate | `mov rax, 5` | The literal constant `5` |
| Register | `mov rax, rbx` | The value currently in `rbx` |
| Memory (direct) | `mov rax, [0x1000]` | The 8 bytes at absolute address `0x1000` |
| Base + offset | `mov rax, [rbp - 8]` | The 8 bytes at `rbp - 8` -- the classic "local variable" access |
| Scaled index | `mov rax, [rbx + rcx*8]` | `rbx + (rcx * 8)` -- the classic "array indexing" access (`arr[i]` for an 8-byte element type) |
| RIP-relative | `mov rax, [rip + 0x2000]` | Address computed relative to the *current instruction's* address -- used for accessing globals/string literals in position-independent code (§8.6) |

The scaled-index mode directly explains why `arr[i]` for an `i64`/`u64`/pointer array compiles to one instruction (`mov rax, [rbx + rcx*8]`) rather than a separate multiply -- the CPU has hardware support for exactly this "base + index*scale" computation as part of address generation, at no extra instruction cost, for scale factors of 1, 2, 4, or 8 (which is not a coincidence -- it covers `i8`/`i16`/`i32`/`i64` element sizes exactly).

### 3.3 Instruction Catalog

Each entry: purpose, effect on `RFLAGS`, and what typically generates it.

**`mov dst, src`** -- copy `src` into `dst`. Does *not* affect flags. Generated by essentially every variable assignment, function argument setup, and return-value placement in every language.

**`lea dst, [expr]`** ("load effective address") -- compute the *address* `expr` would evaluate to (using any addressing mode from §3.2) and store that address, without reading memory at all. Doesn't touch flags. Compilers frequently repurpose `lea` as a fast, flag-preserving arithmetic instruction: `lea rax, [rbx + rcx*4 + 12]` computes `rbx + rcx*4 + 12` in one instruction with no memory access whatsoever -- you'll see `lea` used for plain integer math constantly in optimized output, not just for actual address computation.

**`cmp a, b`** -- compute `a - b` for flags only (§2.3), discard the numeric result. Generated by every `if`/`while`/`match`/comparison operator.

**`test a, b`** -- compute `a AND b` for flags only. `test eax, eax` is the standard idiom for "is `eax` zero," cheaper to encode than `cmp eax, 0`.

**`jmp target`** -- unconditional jump, set `RIP = target`. Generated by `loop`, unconditional `goto`-shaped control flow, and tail calls.

**`je` / `jne` / `jg` / `jl`** (and the full family: `jge`, `jle`, `ja`, `jb`, ...) -- conditional jumps, taken based on the `RFLAGS` bits a preceding `cmp`/`test` set. `je`/`jne` check `ZF`; `jg`/`jl` (signed) and `ja`/`jb` (unsigned) check combinations of `SF`, `OF`, `ZF`, `CF` -- note the signed/unsigned instruction split exists *because* the same bit pattern means a different numeric value depending on signedness, and the flags alone can't disambiguate which comparison you meant.

**`imul` / `idiv`** -- signed multiply/divide (`mul`/`div` are the unsigned versions). Division is one of the genuinely slow common instructions (tens of cycles vs. ~1 for add/mov) -- this is *why* compilers aggressively replace division by a compile-time-constant with multiply-and-shift sequences (`x / 2` becomes a shift, not an `idiv`) whenever legally equivalent, an optimization you'll see immediately if you compare `x / 4` and `x / y` (variable divisor) in godbolt.org.

**`xor` / `and` / `or` / `not`** -- bitwise operations, generated directly by the corresponding operators in every language covered here. `xor rax, rax` is the idiomatic, smallest-encoding way to zero a register (faster and smaller than `mov rax, 0` on most microarchitectures, and recognized by the CPU as a "zeroing idiom" that doesn't even need the old value of `rax` as an input, breaking a false dependency).

**`shl` / `shr` / `sar`** -- logical shift left, logical shift right (zero-fills), arithmetic shift right (sign-extends, i.e. fills with copies of the sign bit -- this is what makes `sar` the correct instruction for dividing a *signed* value by a power of two, where `shr` would be wrong for negative inputs).

**`rol` / `ror`** -- rotate left/right (bits shifted off one end reappear on the other) -- less common in ordinary compiled code, but a staple of hash functions and cryptographic code.

**`cmov cc, dst, src`** ("conditional move") -- copy `src` into `dst` *only if* condition `cc` (checked against `RFLAGS`) holds, otherwise `dst` is unchanged -- crucially, with **no branch at all**. This is the branchless idiom referenced in §1.6: compilers use `cmov` to turn an unpredictable `if`/`else` assigning one of two values into straight-line code with zero misprediction risk, at the cost of always computing *both* possible values (a real tradeoff -- `cmov` loses to a well-predicted branch when one side is expensive and rarely taken).

**`nop`** -- do nothing for one cycle (multi-byte `nop` encodings exist purely for instruction alignment padding). Used by the assembler/linker to pad code for alignment, and by "hot patching" infrastructure that needs a fixed-size no-op slot to later overwrite.

**`syscall`** -- trap into kernel mode, dispatching based on the value in `RAX` (§35.6 of the original systems chapters covers this exact instruction and its argument-register convention in full, carried forward to Part VI). The single instruction every I/O operation in every userspace program, in every language, ultimately funnels through.

**`int n`** -- software interrupt (`int 0x80` was the legacy 32-bit Linux syscall mechanism, superseded by `syscall` on x86-64 because `syscall` is a purpose-built, faster instruction that avoids the general interrupt-handling machinery's overhead). You'll still see `int3` (`0xCC`) constantly, though -- it's the single-byte instruction debuggers (§38) splice into your code to implement breakpoints: replace the original byte with `0xCC`, let execution trap into the debugger, restore the original byte to single-step past it.

### Chapter 3 Notes

**Key Takeaways**
- `cmp`/`test` don't produce a usable result value -- they exist purely to set `RFLAGS` for the *next* instruction to consume.
- `lea` is frequently just "fast arithmetic," not literally "address of" -- compilers exploit its flag-free, single-cycle base+index+offset computation for ordinary integer math.
- Division is slow; multiplication and shifts are fast -- this single fact explains a large fraction of what an optimizer does to arithmetic-heavy code.

**Common Mistakes**
- Reading `mov eax, ebx` in AT&T-trained eyes as "move `eax` into `ebx`" -- operand order is reversed between the two syntaxes; always check which one you're looking at.
- Assuming `cmov` is always a win over a branch -- it removes misprediction risk but always pays the cost of computing both sides, which loses when a branch is easy to predict and one side is expensive.

**Interview Notes**
- "Why does `xor reg, reg` zero a register instead of `mov reg, 0`?" -- smaller encoding, and recognized by the CPU as a zeroing idiom that doesn't create a false data dependency on the register's previous value.
- "What's the difference between `shr` and `sar`?" -- `shr` zero-fills (logical, for unsigned values); `sar` sign-extends (arithmetic, correct for signed values).

---

## Chapter 4: The Stack

### 4.1 push / pop / call / ret

The stack is a region of memory `RSP` points into, growing **downward** (toward lower addresses) on x86-64 as things are pushed:

- **`push src`**: `RSP -= 8; [RSP] = src` -- decrement the stack pointer, then store.
- **`pop dst`**: `dst = [RSP]; RSP += 8` -- load, then increment the stack pointer.
- **`call target`**: pushes the address of the *next* instruction (the return address) onto the stack, then jumps to `target`.
- **`ret`**: pops a value off the stack into `RIP` -- i.e., returns to whatever address is currently on top of the stack. This is exactly why stack-smashing a return address (the classic buffer-overflow exploit) works: `ret` doesn't know or verify that the value it pops is a "real" return address -- it will jump anywhere an attacker can arrange for that memory to contain.

### 4.2 Stack Frame Layout

```
 higher addresses
 ┌─────────────────────────┐
 │   caller's frame...      │
 ├─────────────────────────┤
 │   argument 7, 8, ... (if │  <- args beyond the 6 register slots (§6.2)
 │   more than 6 int args)  │
 ├─────────────────────────┤
 │   return address          │  <- pushed by `call`
 ├─────────────────────────┤
 │   saved RBP               │  <- pushed by the prologue (`push rbp`)
 ├─────────────────────────┤ ◀── RBP points here
 │   local variable 1        │
 │   local variable 2        │
 │   ...                     │
 ├─────────────────────────┤ ◀── RSP points here (top of stack)
 │   (unused, available)     │
 └─────────────────────────┘
 lower addresses
```

### 4.3 Prologue and Epilogue

The standard function entry/exit sequence when a frame pointer is maintained:

```asm
my_function:
    push rbp          ; prologue: save caller's frame pointer
    mov rbp, rsp       ; establish our own frame base
    sub rsp, 32        ; reserve space for locals (32 bytes here)
    ; ... function body, locals accessed as [rbp - N] ...
    mov rsp, rbp       ; epilogue: deallocate locals
    pop rbp            ; restore caller's frame pointer
    ret                ; pop return address into RIP
```

`leave` is a single-instruction shorthand for `mov rsp, rbp; pop rbp` that compilers frequently emit instead of the two separate instructions.

### 4.4 Frame Pointer Omission

Maintaining `RBP` as a stable frame-base costs one register that could otherwise be used for general computation, and the `push rbp`/`mov rbp, rsp` pair costs two instructions per call. Optimized (release) builds very commonly omit this entirely (`-fomit-frame-pointer`, and it is **Rust's release-profile default**), addressing locals purely relative to `RSP` -- which the compiler can still track at compile time even though `RSP` itself may shift during the function body (e.g. around nested calls).

The practical consequence: a naive stack walker that assumes "follow the `RBP` chain" silently produces garbage or stops early on a frame-pointer-omitted binary. This is exactly why `perf record --call-graph dwarf` (DWARF-based unwinding, which reads debug info describing the *actual* stack layout regardless of whether `RBP` is maintained) is the correct choice for profiling optimized Rust/C/C++ binaries, rather than the default frame-pointer-walking mode -- a fact that resurfaces in §37/§38 and in the original Part VI observability material.

### 4.5 Stack Overflow

The stack is a fixed-size region (a few MB by default per thread on Linux, configurable via `ulimit -s` or, for a spawned thread, its stack-size parameter). Unbounded recursion, or a single frame with an enormous local array, exhausts it -- the next `push` or local-variable write touches unmapped guard-page memory below the stack, triggering a page fault (§1.8) the kernel turns into `SIGSEGV`, since there's no valid mapping there (deliberately, so this failure is a hard crash rather than silent corruption of whatever memory happens to be next).

### 4.6 Recursion and Tail-Call Optimization

Ordinary recursion allocates a new frame per call, bounded by stack size (§4.5). A **tail call** -- a call whose result is immediately returned with no further work in the caller -- can, in principle, reuse the *current* frame instead of allocating a new one, since the caller's own frame has nothing left to do once the callee returns. This is **tail-call optimization (TCO)**: the compiler emits a `jmp` to the callee instead of a `call`+later `ret`, turning unbounded tail recursion into a plain loop with *zero* additional stack usage.

**Neither Rust nor C/C++ guarantee TCO** -- it happens opportunistically under optimization when the compiler can prove it's safe (no destructors that need to run after the "recursive" call returns, notably -- which is a common reason Rust's `Drop`-heavy code *doesn't* get this optimization even when the recursion pattern looks tail-shaped), so relying on it for correctness (rather than as a performance nicety) is a mistake in any of these three languages -- unlike languages such as Scheme that mandate it in the spec.

### Chapter 4 Notes

**Key Takeaways**
- The stack grows downward; `push`/`pop` are just `RSP` decrement/increment paired with a memory access.
- `ret` blindly trusts whatever is on top of the stack -- the entire class of return-address-overwrite exploits follows directly from this one fact.
- Frame-pointer omission in release builds is why naive `RBP`-chain stack walking breaks on optimized binaries -- use DWARF-based unwinding instead.

**Common Mistakes**
- Assuming recursive code will always be optimized into a loop via TCO -- it's opportunistic, not guaranteed, in all three languages this handbook covers.
- Forgetting that a large local array (`let buf: [u8; 10_000_000]` inside a function) is a *stack* allocation, capable of overflowing the stack exactly like deep recursion would.

**Interview Notes**
- "Walk me through what `call`/`ret` actually do at the instruction level." -- `call` pushes the return address and jumps; `ret` pops that address back into `RIP`.
- "Why can a stack-overflow crash look identical to a null-pointer dereference?" -- both ultimately manifest as a page fault against unmapped memory, delivered to the process as `SIGSEGV`.

---

## Chapter 5: The Heap

### 5.1 How a Heap Allocator Actually Works

`malloc`, `Box::new`, and `new` all eventually ask the OS for a large region of memory (via the `brk`/`sbrk` or `mmap` syscalls) and then manage sub-allocations out of it themselves in userspace -- the OS is not involved in each individual `malloc` call, only in the comparatively rare case of growing the whole managed region.

A simplified free-list allocator: the allocator maintains a linked list of free blocks, each tagged with its size. `malloc(n)`:

```
 1. Round n up to some minimum alignment/size class.
 2. Walk the free list for a block >= the requested size
    (first-fit / best-fit / segregated free lists by size class
    are different concrete strategies real allocators use).
 3. If found: remove it from the free list (or split it, returning
    the excess back to the free list), return a pointer just past
    its size-header.
 4. If not found: ask the OS for more memory (mmap/sbrk) and retry.
```

`free(ptr)` reads the size header just before `ptr`, and adds that block back onto the free list -- typically attempting to **coalesce** it with adjacent free blocks to fight fragmentation (§5.4).

### 5.2 new / delete and Placement New (C++)

`new T(args)` in C++ is two logically separate steps compilers fuse together: (1) call `operator new(sizeof(T))` (which is, by default, just a `malloc`-family call) to get raw storage, then (2) run `T`'s constructor on that storage. `delete p` is the reverse: run the destructor, then `operator delete(p)`.

**Placement new** (`new (ptr) T(args)`) splits these apart explicitly -- construct a `T` *at an already-allocated address* `ptr`, skipping the allocation step entirely. This is the mechanism arena/pool allocators (§5.5) and low-level containers use to separate "get memory" from "initialize an object in it," a distinction C's `malloc` never makes (it only ever gives you raw, uninitialized bytes) and that Rust makes explicit via `MaybeUninit<T>` (the original §19.2 material) rather than a dedicated syntax.

### 5.3 Rust's Allocator

Every heap-allocating Rust type (`Box`, `Vec`, `String`, `Rc`, ...) goes through the `GlobalAlloc` trait, which by default forwards to the system allocator (`malloc`/`free` on Linux) -- but is swappable: a program can register its own allocator with `#[global_allocator]`, useful for e.g. a `jemalloc`/`mimalloc` swap for better multi-threaded allocation performance, or a custom bump allocator in a `no_std`/embedded context (§33) where there's no OS-provided `malloc` at all.

```rust
use std::alloc::{GlobalAlloc, Layout, System};

struct CountingAllocator;
unsafe impl GlobalAlloc for CountingAllocator {
    unsafe fn alloc(&self, layout: Layout) -> *mut u8 {
        System.alloc(layout)          // delegate, but could count/log first
    }
    unsafe fn dealloc(&self, ptr: *mut u8, layout: Layout) {
        System.dealloc(ptr, layout)
    }
}

#[global_allocator]
static ALLOC: CountingAllocator = CountingAllocator;
```

### 5.4 Fragmentation

**External fragmentation**: free memory exists in total, but scattered in pieces too small individually to satisfy a large request -- a classic consequence of many alloc/free cycles of varying sizes over a long-running process's lifetime (a long-lived daemon -- like a container runtime -- is exactly the kind of program that experiences this over its uptime). **Internal fragmentation**: the allocator rounds a request up to a fixed size class (e.g. serving a 17-byte request from a 32-byte bucket), wasting the difference -- a deliberate tradeoff most allocators make to keep free-list bookkeeping fast, trading some wasted memory for speed.

### 5.5 Memory Pools and Arenas

An **arena** (or **bump allocator**) is the simplest possible allocation strategy: hand out sequential chunks of a large pre-allocated block by just incrementing a pointer, and free the *entire arena at once* rather than tracking individual frees. This trades "can't free individual objects early" for extremely fast allocation (no free-list search at all) and *zero* fragmentation within the arena's lifetime -- a genuinely good tradeoff for objects that all share a natural lifetime scope (e.g., all the temporary allocations made while processing one request/one container's lifecycle, freed together when that scope ends). Rust's `bumpalo` crate and C++'s common "arena allocator" pattern implement exactly this; it's a technique, not a language feature, applicable in any of the three languages.

### Chapter 5 Notes

**Key Takeaways**
- `malloc`/`Box::new`/`new` are userspace bookkeeping over a much smaller number of actual OS memory-acquisition syscalls (`mmap`/`brk`) -- not a syscall per allocation.
- Fragmentation is a real, measurable cost of long-running allocate/free patterns, and arenas are the standard technique for sidestepping it when the object lifetimes allow it.
- Rust's `GlobalAlloc` makes the allocator itself swappable at the language level -- C/C++ achieve the same effect by overriding `malloc`/`operator new`, an equivalent but less structured mechanism.

**Common Mistakes**
- Assuming `free`/`drop` immediately returns memory to the OS -- in the common case it only returns the block to the allocator's own free list; the OS-visible memory footprint often doesn't shrink until much later, if ever, in that process's lifetime.
- Using an arena for objects with genuinely independent lifetimes -- if even one object needs to outlive the others, the whole arena is held alive, which can turn into an unbounded-growth leak in a long-running process.

**Interview Notes**
- "Why is `malloc` not a syscall?" -- it operates on memory the process already obtained in bulk from the OS; the syscall boundary is crossed only occasionally, to grow or shrink that bulk region.
- "When would you reach for an arena allocator?" -- a batch of allocations that all become garbage together at a well-defined point (e.g., one request's processing lifetime).

---

## Chapter 6: Calling Conventions and the ABI

### 6.1 What an ABI Is, and Why It's the Reason FFI Works at All

An **ABI (Application Binary Interface)** is the compiled-code-level contract two pieces of machine code agree to when calling each other: which registers hold arguments, which hold the return value, which registers a callee must preserve, how the stack must be aligned at a call, and more. It's the runtime-code analog of a source-level API -- except an ABI has to be followed by object code from *any* compiler, in *any* language, since by the time you're linking `.o` files together, there's no more source-level type information to lean on. This is the entire reason `extern "C"` (Rust/C++) exists: it's how you tell the compiler "emit/expect code that follows the platform's stable C ABI here," which is what makes cross-language linking possible in the first place.

### 6.2 System V AMD64 ABI (Linux, macOS, BSD)

**Integer/pointer arguments**, in order: `RDI`, `RSI`, `RDX`, `RCX`, `R8`, `R9` -- a 7th and beyond spill to the stack.

**Floating-point arguments**: `XMM0`-`XMM7`.

**Return value**: `RAX` (integer/pointer); `RAX:RDX` for values wider than 64 bits (e.g. a 128-bit integer, or a small struct returned "in registers"); `XMM0` for a float/double.

**Callee-saved** (a function must restore these to their entry value before returning, if it uses them): `RBX`, `RBP`, `RSP`, `R12`-`R15`.

**Caller-saved** (a function call may clobber these; the caller must save anything it still needs across the call): `RAX`, `RCX`, `RDX`, `RSI`, `RDI`, `R8`-`R11`.

```
 example: int add(int a, int b, int c, int d, int e, int f, int g)
 called as add(1, 2, 3, 4, 5, 6, 7)

   RDI = 1   (a)
   RSI = 2   (b)
   RDX = 3   (c)
   RCX = 4   (d)
   R8  = 5   (e)
   R9  = 6   (f)
   [RSP+0] = 7   (g -- 7th arg spills to the stack)
```

### 6.3 Windows x64 ABI

A genuinely different convention on the same x86-64 hardware -- code compiled for one is not binary-compatible with the other without an explicit shim:

**Integer/pointer arguments**, in order: `RCX`, `RDX`, `R8`, `R9` -- only four register slots (vs. SysV's six), 5th and beyond spill to the stack.

**Floating point**: `XMM0`-`XMM3` (note: argument *position*, not type, determines which register bank is used per-slot in a way that keeps integer and float argument counting in sync -- unlike SysV, which counts integer and float arguments in independent sequences).

**Shadow space**: the caller must always reserve 32 bytes of stack space (for the 4 register-passed arguments) even though the callee receives them in registers, not on the stack -- giving the callee a place to spill them if needed, and simplifying variadic-function handling. SysV has no equivalent requirement.

**Callee-saved**: `RBX`, `RBP`, `RDI`, `RSI`, `RSP`, `R12`-`R15` -- notably, `RDI`/`RSI` are callee-saved under Windows (they're caller-saved argument registers under SysV) -- a genuine, easy-to-get-wrong difference if you're hand-writing or generating assembly meant to be portable.

### 6.4 Stack Alignment

Both ABIs require `RSP` to be 16-byte aligned *at the point of a `call` instruction* (SysV: `RSP % 16 == 0` immediately before `call`, meaning `RSP % 16 == 8` immediately after, since `call` pushes an 8-byte return address). This exists because SIMD instructions (§2.4) historically required aligned memory operands for the fast-path encoding, and the ABI guarantees it so a callee never has to check. A classic, subtle FFI/hand-written-asm bug is code that leaves the stack misaligned before a call -- it can "usually" work and then crash mysteriously the one time the callee happens to use an alignment-sensitive SIMD instruction.

### 6.5 Red Zone (SysV Only)

SysV additionally guarantees the **128 bytes below `RSP`** (at a leaf function -- one that makes no further calls) will not be touched by anything else (signal handlers included), letting a leaf function use that space as scratch storage *without* adjusting `RSP` at all -- skipping the prologue/epilogue's `sub rsp, N`/`add rsp, N` entirely for small leaf functions. Windows x64 has no red zone; every function must formally reserve its stack space.

### Chapter 6 Notes

**Key Takeaways**
- An ABI is what makes it possible to link object code from different compilers and languages together at all -- `extern "C"` is a request to follow it.
- SysV and Windows x64 disagree on argument registers, shadow space, callee-saved sets, and the red zone -- "the calling convention" is not one universal thing even on identical hardware.
- Stack misalignment at a `call` is a real, historically painful bug class precisely because it "often" doesn't crash.

**Common Mistakes**
- Porting hand-written or generated x86-64 assembly from Linux to Windows (or vice versa) without re-checking argument registers and the shadow-space requirement.
- Assuming a function's callee-saved-register list is universal across ABIs -- `RDI`/`RSI` flip status between SysV and Windows.

**Interview Notes**
- "What problem does `extern \"C\"` solve?" -- it opts a function into the platform's one stable, cross-compiler ABI, rather than a given compiler's own (unstable, version-dependent) internal calling convention.
- "Why does the ABI mandate 16-byte stack alignment at `call`?" -- to guarantee alignment-sensitive SIMD instructions work in any callee without per-call runtime checks.

---

## Chapter 7: Memory Layout of a Program

### 7.1 Process Address Space

```
 high addresses
 ┌───────────────────────────┐
 │      kernel space           │  (not accessible from userspace)
 ├───────────────────────────┤
 │      stack                  │  grows DOWN
 │        │                     │
 │        ▼                     │
 │                              │
 │        ▲                     │
 │        │                     │
 │      heap                   │  grows UP
 ├───────────────────────────┤
 │      .bss                   │  zero-initialized globals/statics
 ├───────────────────────────┤
 │      .data                  │  initialized, mutable globals/statics
 ├───────────────────────────┤
 │      .rodata                │  string literals, const data
 ├───────────────────────────┤
 │      .text                  │  the actual compiled machine code
 └───────────────────────────┘
 low addresses
```

(Shared libraries, the dynamic linker's own mappings, and thread stacks for non-main threads are also present, typically mapped in the large gap between heap and stack -- omitted above for clarity.)

### 7.2 .text / .data / .bss / .rodata

- **`.text`**: the compiled machine instructions themselves. Marked read-and-execute, *not* writable -- attempting to write to `.text` (e.g. a corrupted function pointer used as a write target) faults, a deliberate hardening measure (W^X: a page is never simultaneously writable and executable) that makes a whole class of code-injection exploits harder.
- **`.data`**: global/static variables with a non-zero compile-time initial value (`static mut COUNTER: i32 = 5;` in Rust; `int counter = 5;` at file scope in C). Present in the binary file itself (the initial value has to come from *somewhere*).
- **`.bss`**: global/static variables initialized to zero (or Rust's default-zero patterns). *Not* actually stored in the binary file -- the loader just knows to zero-fill this many bytes at load time, saving disk/binary size for what would otherwise be a long run of literal zero bytes.
- **`.rodata`**: read-only data -- string literals, `const` values the compiler can't or chooses not to inline directly into instructions. Like `.text`, marked non-writable; writing to a Rust `&'static str` or a C string literal (which C, unlike Rust, technically allows you to *attempt*, via a non-const `char*`) is undefined behavior that typically manifests as a segfault.

### 7.3 Heap and Stack Placement

Heap and stack are deliberately placed at opposite ends of the large middle region of the address space and grow *toward* each other -- heap growing up from just after `.bss`, stack growing down from near the top of userspace -- so that either can grow as needed without a fixed boundary between them, until (in a genuine problem, rare in practice on 64-bit systems given the enormous address space available) they'd collide.

### 7.4 Thread-Local Storage (TLS)

A `static`/`thread_local!` variable declared with thread-local semantics gets a *separate* copy per thread, rather than one shared copy -- implemented via a dedicated TLS block per thread (commonly accessed via a segment register, `FS`/`GS` on x86-64, that the OS/runtime points at the current thread's TLS block) rather than living in the ordinary `.data`/`.bss` regions shared across all threads.

```rust
thread_local! {
    static COUNTER: std::cell::Cell<u32> = std::cell::Cell::new(0);
}
// each thread that touches COUNTER sees and mutates its OWN independent copy
```

This is the mechanism behind things like per-thread allocator caches (many high-performance allocators keep a thread-local free list specifically to avoid needing a lock on the hot allocation path) and `errno` in C (which is thread-local specifically so that one thread's failing syscall doesn't clobber another thread's error state).

### 7.5 Shared Libraries

Dynamically-linked libraries (`.so` on Linux, `.dll` on Windows, `.dylib` on macOS) are mapped into the process's address space by the dynamic linker (§8.4) at load time (or lazily, on first use), rather than being copied into the executable at build time the way static linking (§8.3) does -- multiple processes running the same program (or different programs using the same library) can share the *same physical pages* of a shared library's code, mapped read-only, which is a real, meaningful memory saving on a machine running many instances of similar software (exactly the situation on a container host running many containers built from similar base images/libraries).

### 7.6 ELF, PE, and Mach-O

The three dominant executable/object-file formats, one per major platform family -- all solve the same underlying problem (describe code, data, and how to load/link it) with different concrete layouts:

| | Linux/BSD | Windows | macOS |
|---|---|---|---|
| Format | ELF (Executable and Linkable Format) | PE (Portable Executable) | Mach-O |
| Section/segment naming | `.text`, `.data`, `.bss` | `.text`, `.data`, `.rdata` | `__TEXT`, `__DATA` |
| Dynamic linking info | `.dynamic` section, `DT_NEEDED` entries | Import Address Table (IAT) | Load commands (`LC_LOAD_DYLIB`) |
| Inspect with | `readelf`, `objdump` | `dumpbin`, `objdump` | `otool` |

An ELF file, concretely, is a header describing the file as a whole, followed by a **program header table** (describes segments -- how the OS loader should map chunks of the file into memory at load time: which parts, at what address, with what permissions) and a **section header table** (a finer-grained, link-time/debug-time view -- `.text`/.data`/`.bss`/`.symtab`/`.debug_info` and so on; not needed at runtime by the loader, which is why a stripped binary can discard sections entirely while remaining fully runnable). `readelf -l` shows the program headers (what the loader uses); `readelf -S` shows section headers (what the linker/debugger uses) -- a distinction worth having straight before reaching for either tool (§38).

### Chapter 7 Notes

**Key Takeaways**
- `.bss` existing as a *concept separate from* `.data` is purely a disk-space optimization -- "a lot of zero bytes" doesn't need to be stored literally.
- W^X (a page is never both writable and executable) is why overwriting `.text` at runtime faults -- a real, load-bearing security property, not an incidental restriction.
- Shared libraries let multiple processes physically share the same in-memory code pages -- directly relevant to any environment (like a container host) running many similar processes at once.

**Common Mistakes**
- Assuming a global variable always occupies space in the binary file on disk -- zero-initialized ones (`.bss`) don't.
- Confusing ELF program headers (loader's view) with section headers (linker/debugger's view) -- they describe overlapping data for different consumers, not the same thing twice.

**Interview Notes**
- "Where does a string literal live in memory?" -- `.rodata`, read-only, mapped once regardless of how many times the literal appears in source.
- "Why can dynamically linked libraries save memory across many processes, when statically linked ones can't?" -- the same physical pages of a shared library's `.text` can be mapped read-only into every process using it; a statically linked binary has its own private copy baked in.

---

## Chapter 8: Linking

### 8.1 Object Files and Symbols

Compiling a single source file (`.c`, `.rs` unit, `.cpp`) produces an **object file** (`.o`) -- machine code plus a **symbol table**: names (function names, global variable names, mangled names for C++/Rust) mapped to offsets within that object file's sections, plus a list of symbols the file *references* but doesn't define (an `extern` function, a call into another crate/translation unit).

```bash
nm my_object.o
# T main         <- 'T' = defined in .text (a function), globally visible
# U printf       <- 'U' = undefined here, must be resolved by the linker
# D global_var   <- 'D' = defined in .data
```

### 8.2 Relocation

When the compiler emits a reference to a symbol it doesn't yet know the final address of (a function in another object file, a global in another translation unit), it emits a placeholder plus a **relocation entry**: "at this exact byte offset, once you know the real address of symbol X, patch it in, using this specific patching formula (absolute address, or PC-relative offset, etc.)." The linker's core job is walking every object file's relocation entries and patching in real addresses once it has assigned every symbol a final location.

### 8.3 Static vs. Dynamic Linking

**Static linking**: the linker copies the actual code of every referenced library function directly into the final executable at build time -- the result is one self-contained file with no runtime dependency on that library being present on the target machine, at the cost of a larger binary and no sharing of code pages across processes/programs (§7.5).

**Dynamic linking**: the executable instead records *which* shared libraries it needs (`DT_NEEDED` entries in ELF) and leaves those symbol references unresolved until load time, when the dynamic linker (§8.4) maps the needed `.so` files in and patches the references -- smaller executable, shared code pages across processes, but a runtime dependency on the right library version being present (the classic "works on my machine," a.k.a. "DLL hell"/dependency-version-mismatch class of bug this handbook's §31 static-linking-for-container-binaries advice exists specifically to sidestep).

### 8.4 The Loader

The **loader** (`ld.so`/`ld-linux.so` on Linux) is itself a program, run by the kernel as literally the first thing that executes when you run a dynamically linked binary -- it maps the main executable and every shared library it (transitively) depends on into the address space, resolves symbol references between them, and only then jumps to the program's actual entry point. This is why a missing shared library produces an error *before* your program's own `main` ever runs -- the loader fails before handing off control at all.

### 8.5 PLT and GOT

For dynamically linked *function* calls specifically, most platforms use an extra indirection layer to support **lazy binding** (resolve each external function's real address only the first time it's actually called, not all of them up front at load time, saving startup time for functions that end up never being called):

```
  call printf@plt         ; your code calls into the Procedure Linkage Table
       │
       ▼
  PLT stub for printf:
    jmp [GOT entry for printf]   ; jumps through the Global Offset Table
       │
       ▼ (first call: GOT entry still points back into the PLT's resolver stub)
  dynamic linker resolves printf's real address,
  PATCHES the GOT entry to point directly at it
       │
       ▼ (every subsequent call jumps straight through the now-patched GOT)
  actual printf() code
```

The **GOT (Global Offset Table)** holds the actual resolved addresses (patched in once, lazily); the **PLT (Procedure Linkage Table)** is the small stub code your call sites actually target, which either triggers first-time resolution or, once resolved, just jumps straight through the GOT with effectively no overhead beyond the one indirection.

### 8.6 PIC and PIE

**PIC (Position-Independent Code)**: machine code that works correctly no matter what address it's loaded at -- required for shared libraries, since the same `.so` file might be mapped at a different base address in every process that loads it (and, with ASLR, even in different runs of the *same* program). Achieved by never hard-coding absolute addresses for globals/functions, instead computing them relative to the current instruction pointer -- exactly the RIP-relative addressing mode from §3.2, which exists on x86-64 largely *for* this purpose.

**PIE (Position-Independent Executable)**: applying that same property to the *main executable*, not just shared libraries -- letting the loader place the whole program at a randomized base address each run. This is the mechanism behind **ASLR (Address Space Layout Randomization)**, a security hardening feature (making memory-corruption exploits that rely on hard-coded addresses far less reliable) that is now the default build mode on virtually all modern Linux distributions, macOS, and Windows.

### Chapter 8 Notes

**Key Takeaways**
- Linking is fundamentally "patch in real addresses once you know them" -- relocations are the placeholders, symbol tables are the lookup, and the linker is the program that connects the two.
- The PLT/GOT indirection exists specifically to make lazy symbol resolution possible for dynamically linked function calls, at the cost of one extra jump per call site (negligible after the first resolution).
- PIE/ASLR is why you can't rely on a function living at the "same address" across runs of the same program anymore -- a real, deliberate security property, not an accident.

**Common Mistakes**
- Assuming a "missing symbol" linker error and a "missing shared library at runtime" loader error are the same failure -- one happens at build time (static linking, or an unresolved symbol dynamic linking can't defer), the other at process-start time, and they're diagnosed differently.
- Forgetting that static linking trades away shared-page memory savings across processes -- relevant when deciding how to ship a container-runtime binary (§31's musl/static-linking discussion, Part VI).

**Interview Notes**
- "What's the difference between the PLT and the GOT?" -- the PLT is the stub code your calls jump to; the GOT is the data table holding the actual resolved addresses that the PLT stub reads through.
- "Why does PIE matter for security?" -- it randomizes the executable's own load address, defeating exploits that hard-code addresses of useful code/data (return-oriented programming gadgets, known function addresses, etc.).

---

## Chapter 9: The Compiler Pipeline

### 9.1 The General Shape: Source → Machine Code

```
 Source Code
     │
     ▼
 ┌─────────┐   tokens (identifiers, keywords, literals, punctuation)
 │  Lexer   │
 └─────────┘
     │
     ▼
 ┌─────────┐   Abstract Syntax Tree -- the grammatical structure of the program
 │ Parser   │
 └─────────┘
     │
     ▼
 ┌───────────────────────┐   one or more Intermediate Representations (IR) --
 │  IR generation/lowering │   simpler, more uniform than source syntax, easier
 │  (+ type checking,       │   for the compiler to analyze and transform
 │   borrow checking, etc.) │
 └───────────────────────┘
     │
     ▼
 ┌─────────────┐   dozens of independent transformation passes: inlining,
 │ Optimization │   dead code elimination, constant folding, vectorization,
 │    passes     │   loop unrolling...
 └─────────────┘
     │
     ▼
 ┌──────────────────┐   choosing actual machine instructions for the target
 │ Instruction        │   CPU (this is where "IR add" becomes "x86-64 add"
 │ selection & sched.  │   specifically, register-allocated, scheduled)
 └──────────────────┘
     │
     ▼
 ┌─────────┐   .o file: machine code + symbol table + relocations (§8.1-8.2)
 │Assembler │
 └─────────┘
     │
     ▼
 ┌─────────┐   resolves symbols across object files/libraries (§8)
 │ Linker   │
 └─────────┘
     │
     ▼
 Executable / Shared Library
```

### 9.2 Rust's Specific Pipeline: HIR → MIR → LLVM IR

Rust's front end (`rustc`) lowers through several of its *own* intermediate representations before ever reaching LLVM:

- **AST**: close to source syntax, produced by parsing.
- **HIR (High-level IR)**: a desugared AST -- `for` loops rewritten in terms of the `Iterator` trait's actual method calls, `?` expanded to its match-and-early-return form, and so on. This is roughly the level at which type inference and trait resolution happen.
- **MIR (Mid-level IR)**: a much simpler, explicitly control-flow-graph-shaped representation -- this is where **borrow checking actually runs**. By this stage, all the high-level syntax is gone; MIR looks like a simplified, typed assembly-adjacent language of basic blocks and explicit moves/borrows, which is precisely the representation the borrow checker's dataflow analysis needs (it can literally follow the CFG and track, block by block, where a value's borrow is or isn't currently live). This is also the stage where the compile-time cost of ownership/lifetime checking is fully paid -- and, matching §34.2's point, fully *finished* here: nothing downstream from MIR carries any trace of it.
- **LLVM IR**: MIR is lowered into LLVM's intermediate representation, at which point `rustc` hands off to the same optimizer and code generator LLVM-based C/C++ compilers (`clang`) use -- this is precisely *why* Rust and C/C++ (via clang) can produce comparably optimized machine code for equivalent logic: past this point, it's the same optimization pipeline working on a similar IR, regardless of source language.

### 9.3 C/C++: AST → LLVM IR or GCC's GIMPLE

`clang` follows an analogous path (AST → LLVM IR → the same LLVM optimizer/backend Rust uses). `gcc` uses its own intermediate representations (**GENERIC**, then **GIMPLE** for most optimization, then **RTL** just before final code generation) instead of LLVM IR, but the *shape* of the pipeline -- successive lowering through IRs of decreasing abstraction, with optimization passes running primarily on a middle-tier IR -- is the same idea implemented independently.

### 9.4 Optimization Passes

Dozens of largely independent transformations run over the IR, commonly including: **inlining** (replacing a call with the callee's body, enabling further optimization across the former call boundary -- the actual mechanism behind zero-cost abstraction claims, §35.4/§37), **dead code elimination** (removing computations whose results are never used), **constant folding/propagation** (computing compile-time-known values ahead of time), **common subexpression elimination**, **loop-invariant code motion** (hoisting a computation that doesn't change between iterations out of the loop), **loop unrolling** and **auto-vectorization** (§37), and many more, run in a carefully tuned order (some passes create opportunities for others -- inlining routinely unlocks further constant folding and dead-code elimination that wouldn't have been legal to do across a real function-call boundary).

### 9.5 Instruction Selection and Scheduling

Once optimization on the IR is essentially done, the backend has to choose *actual machine instructions* implementing each IR operation for the *specific target* CPU (a decision informed by what instructions that target even has -- AVX-512 availability, for instance), assign real physical registers to IR values (**register allocation** -- a genuinely hard combinatorial problem, since there are far more live values in typical code than physical registers, requiring some to "spill" to stack slots), and **schedule** the resulting instructions in an order that keeps the target CPU's pipeline (§1.5) as full as possible, given known instruction latencies for that specific microarchitecture.

### 9.6 Assembler, Object File, and Linker

The chosen instructions, in textual/IR form, are turned into actual encoded machine-code bytes by the **assembler**, packaged into an object file with its symbol table and relocations (§8.1-8.2), and finally combined with every other object file and needed library by the **linker** (§8) into the executable or shared library that actually ships.

### Chapter 9 Notes

**Key Takeaways**
- Rust's borrow checker runs on MIR, a dedicated intermediate representation built specifically to make that dataflow analysis tractable -- and nothing past MIR carries any trace of it, which is the concrete compiler-internals confirmation of §34.2's "ownership is 100% compile-time, fully erased" claim.
- Rust (via LLVM) and C/C++ (via clang, also LLVM-based) share the *same* optimizer and code generator for a large fraction of real-world toolchains -- a major reason comparable Rust and C/C++ code can produce comparable machine code: the last two-thirds of the pipeline is often literally the same code.
- Optimization is not one pass but dozens, run in a specific, tuned order, because many passes only become *legal or profitable* after another pass has already run (inlining unlocking further dead-code elimination being the paradigm example).

**Common Mistakes**
- Assuming "Rust is fast because the borrow checker prevents bugs" -- the borrow checker affects what compiles, not the *speed* of what does compile; the speed comes from the same LLVM backend/optimizer C/C++ also use.
- Assuming a debug build's assembly is representative of what ships -- optimization passes (§9.4) are largely disabled in debug builds specifically to keep compile times and debuggability high, so debug-build codegen and release-build codegen can look almost unrelated for the same source.

**Interview Notes**
- "Why does Rust use its own MIR instead of running borrow-checking directly on LLVM IR?" -- LLVM IR has already lost Rust-specific structure (moves, borrows, lifetimes) that the borrow-checking dataflow analysis needs; MIR is deliberately kept close enough to source semantics to make that analysis both possible and comparatively simple.
- "Explain why an optimizer might run dead-code elimination more than once in the same compilation." -- because a later pass (e.g. inlining, constant folding) can create *new* dead code that the earlier DCE pass had no way to see yet.

---

# PART II -- C: The Machine, Barely Abstracted

C's entire design philosophy is "a thin, portable veneer over what Part I already described." Nearly every C construct maps to a small, predictable, almost mechanical translation into the instructions and memory model from Part I -- which is exactly why C remains the *lingua franca* of systems programming and the ABI (§6) that every other language interoperates through.

## Chapter 10: C Fundamentals, Mapped to the Machine

### 10.1 Variables and Types

A C variable is nothing more than a name the compiler associates with a storage location -- a register (while live and small enough), a stack slot (`[rbp - N]`, §4.2), or a fixed address (`.data`/`.bss`, §7.2) for globals/statics. There is no runtime concept of "a variable" at all; by the time you're looking at emitted assembly, only addresses and register names remain -- the variable name existed purely for the compiler's and your own benefit.

```c
int x = 5;          // likely a register while live, or [rbp-4] if it must live in memory
static int y = 10;   // a fixed address in .data -- exists for the whole program's lifetime
```

### 10.2 Pointers: The Core Idea

A pointer is a variable whose value is interpreted as a memory address -- literally just an integer, sized to match the platform's address width (8 bytes on x86-64), with the compiler tracking a *type* for what's supposedly at that address purely for its own type-checking purposes; the hardware has no concept of pointer "type" at all.

```c
int x = 42;
int *p = &x;      // p's value = the address of x  (lea rax, [x's location]; mov [p], rax)
int y = *p;        // dereference: read the int-sized value AT the address p holds
                    //   (mov rax, [p]; mov eax, [rax])
```

```
   p (a variable, holds an address)          x (a variable, holds a value)
 ┌───────────────┐                       ┌───────────────┐
 │  0x7ffee4a0    │──────points to──────▶│      42        │
 └───────────────┘                       └───────────────┘
   address: 0x7ffee498                     address: 0x7ffee4a0
```

`&x` is `lea` (§3.3) -- compute an address, don't read memory. `*p` is a `mov` that *reads* memory at the address held in `p`. Pointer arithmetic (`p + 1`) is automatically scaled by `sizeof(*p)` -- `p + 1` on an `int*` advances by 4 bytes, not 1, which is exactly the scaled-index addressing mode from §3.2 doing the scaling for you at the instruction level when indexing (`p[i]` compiles to the same `[base + index*scale]` form as an array access).

### 10.3 Arrays and Array-to-Pointer Decay

A C array is a contiguous block of `N` elements with *no* separate stored length or capacity anywhere -- `sizeof(arr)` only works because the compiler still statically knows the type `int[10]`; the moment that array is passed to a function or otherwise "decays," all that's left is a plain pointer to its first element, and the size information is gone for good:

```c
void f(int arr[10]) { }     // deceptive syntax -- this is IDENTICAL to:
void f(int *arr) { }         // arr has decayed to a pointer; sizeof(arr) inside f is 8, not 40!

int arr[10];
int *p = arr;                 // decay happens here too -- arr "becomes" &arr[0]
```

This single fact -- arrays silently decaying to pointers, losing length information -- is the direct root cause of an enormous fraction of classic C bugs (buffer overflows from a function that can't know how big the array actually is unless told separately, `sizeof` mistakes when a caller assumes an array parameter still "is" an array). It's also precisely the gap `Vec<T>`/`&[T]` (which carry their length explicitly, always, §7.1/§3.4) and `std::vector`/`std::span` close.

### 10.4 Struct Layout, Padding, and Alignment

The compiler doesn't pack struct fields as tightly as possible -- each field must sit at an address that's a multiple of its own **alignment requirement** (typically equal to its size, up to some platform maximum), and the compiler inserts **padding** bytes wherever needed to satisfy that:

```c
struct Example {
    char a;      // 1 byte,  offset 0
    // 3 bytes of padding here -- next field needs 4-byte alignment
    int b;        // 4 bytes, offset 4
    char c;       // 1 byte,  offset 8
    // 3 bytes of padding here -- struct's overall size must be a
    // multiple of its largest member's alignment (4), so it can be
    // correctly aligned inside an array of these structs
};
// sizeof(struct Example) == 12, not 6!
```

```
 offset:  0    1    2    3    4    5    6    7    8    9   10   11
        ┌────┬─────────────────┬───────────────────┬────┬─────────────────┐
        │ a  │   padding (3)    │        b            │ c  │  padding (3)     │
        └────┴─────────────────┴───────────────────┴────┴─────────────────┘
```

Reordering fields largest-to-smallest often eliminates padding entirely (`int b; char a; char c;` needs only 2 bytes of trailing padding instead of 6 total) -- a real, common manual optimization in C, and precisely why Rust's *default* struct layout (§4's original material) is allowed to reorder your fields for you automatically, unless you opt out with `#[repr(C)]` to match C's guaranteed declared-order layout for FFI purposes.

### 10.5 Multi-Dimensional Arrays and Pointer Arithmetic

`int matrix[3][4]` is one contiguous block of 12 `int`s, row-major (each row's 4 elements contiguous, rows one after another) -- `matrix[i][j]` compiles to address `base + i*4*sizeof(int) + j*sizeof(int)`, i.e. exactly the scaled-index addressing mode again, just with the row stride baked in as an additional multiply. This row-major layout (shared by C, C++, and Rust arrays-of-arrays) is why iterating the *inner* index fastest is dramatically more cache-friendly (§1.4/§37) than iterating the outer index fastest -- the inner loop touches consecutive memory (and consecutive cache lines), the outer-first version jumps a whole row's width on every access.

### Chapter 10 Notes

**Key Takeaways**
- A pointer is just an address-sized integer with compile-time-only type information layered on top -- the hardware doesn't know or enforce pointer types.
- Array-to-pointer decay is the single fact that explains most classic C buffer bugs, and directly motivates every "fat pointer" (length-carrying reference) design in C++ (`std::span`) and Rust (`&[T]`).
- Struct padding exists because of per-field alignment requirements, not compiler laziness -- and field reordering is a legitimate, common manual size optimization.

**Common Mistakes**
- Believing `sizeof(arr)` inside a function that received `arr` as a parameter gives the array's true size -- it gives the size of a pointer (8), because the array already decayed at the call boundary.
- Assuming struct field declaration order doesn't affect memory footprint -- it very much does, via padding, unless the compiler is explicitly allowed to reorder (as Rust's default `repr` does, and C/C++ do not).

**Interview Notes**
- "What is array decay, and why does it matter?" -- an array used as a function argument (or in most other expression contexts) is implicitly converted to a pointer to its first element, permanently losing length information at that boundary.
- "Why might reordering struct fields change `sizeof` the struct?" -- alignment-driven padding between/after fields depends on the specific ordering; grouping same/larger-alignment fields together minimizes the padding needed.

---

## Chapter 11: Storage Duration, Linkage, Translation Units, and the Preprocessor

### 11.1 Storage Duration

Every C object has one of four storage durations, each corresponding directly to a Part I memory region:

| Storage duration | Lives in | Lifetime |
|---|---|---|
| Automatic | Stack (§4) | From declaration until the enclosing block exits |
| Static | `.data`/`.bss` (§7.2) | Entire program run |
| Thread | TLS (§7.4) | Entire thread's run |
| Allocated | Heap (§5) | From `malloc` until `free` |

`static` inside a function is the notable case worth calling out explicitly: it gives a *local-looking* variable *static* storage duration -- it's initialized once, and retains its value across calls, unlike an ordinary automatic local that's re-created (garbage, until assigned) on every call:

```c
int counter() {
    static int n = 0;   // lives in .data, NOT on the stack -- initialized once, ever
    return ++n;          // each call sees the previous call's value
}
```

### 11.2 Linkage

Linkage determines whether the *same name* in different translation units (§11.3) refers to the *same* object/function or independent ones:

- **External linkage** (the default for file-scope functions/variables): the name is visible to, and shared with, other translation units at link time -- exactly what makes calling a function defined in another `.c` file work.
- **Internal linkage** (`static` at file scope): the name is visible *only* within its own translation unit -- the linker never even sees it as a candidate for cross-file symbol resolution. This is C's closest approximation of Rust's module-privacy (§6.4's original comparison) -- a real, load-bearing mechanism, just coarser-grained (whole-file, not per-item) and linker-enforced rather than compiler-enforced.
- **No linkage**: block-scope (local) variables -- the name simply doesn't exist outside its own block; there's no cross-file question to even ask.

### 11.3 Translation Units and Separate Compilation

A **translation unit** is one `.c` file *after* preprocessing (§11.4) -- i.e., with every `#include` textually expanded in place. Each translation unit is compiled to an object file (§8.1) completely independently of every other one; the compiler processing `a.c` has zero knowledge of `b.c`'s contents beyond whatever got declared (not defined) via headers. This is precisely why header files exist: a `.h` file's job is to give every translation unit that includes it the *declarations* it needs to correctly generate calls into code that will be *defined* in some other translation unit and stitched together later, at link time (§8), by symbol name.

### 11.4 The Preprocessor

A distinct, purely textual pass that runs *before* the compiler proper ever parses anything -- it has no concept of C syntax, types, or scope, only text substitution and conditional inclusion:

```c
#define SQUARE(x) ((x) * (x))     // pure textual substitution
#define MAX_SIZE 100

#include "myheader.h"              // textually pastes the named file's contents here

#ifdef DEBUG
    printf("debug info\n");
#endif
```

`SQUARE(x)` being pure text substitution (not a real function) is the source of the classic macro-argument-parenthesization bug: `SQUARE(a + b)` without the inner parens in the definition would expand to `a + b * a + b`, not `(a+b)*(a+b)` -- and even correctly parenthesized, `SQUARE(i++)` evaluates `i++` *twice*, a side-effect-duplication bug no amount of careful parenthesization can fix, because the preprocessor genuinely does not know or care that `x` appears twice in the expansion. This is precisely the macro-hygiene problem the original §16.6 comparison material contrasts against Rust's token-tree-based `macro_rules!`, which doesn't have this failure mode because it isn't operating on raw text at all.

### Chapter 11 Notes

**Key Takeaways**
- Every C storage duration maps directly onto a specific Part I memory region -- there's no C-specific memory model beyond what Chapters 4, 5, and 7 already established.
- `static` at file scope (internal linkage) and `static` inside a function (static storage duration for a local-looking variable) are two genuinely different uses of the same keyword -- don't conflate them.
- The preprocessor runs before the compiler even sees C syntax -- macro bugs are text-substitution bugs, categorically different from ordinary C bugs.

**Common Mistakes**
- Expecting a `static` local variable to reset between calls -- it explicitly does not; that's the entire point of static storage duration.
- Writing a macro argument that has side effects (`SQUARE(i++)`) without realizing the argument text is duplicated verbatim wherever it appears in the macro body.

**Interview Notes**
- "What's the difference between a declaration and a definition in C, and why does it matter for translation units?" -- a declaration promises a symbol exists somewhere with a given type/signature (enough for the compiler to generate calls to it); a definition actually allocates storage/provides a function body. Headers hold declarations so each translation unit can be compiled independently; the linker later matches declarations to the one translation unit holding the real definition.
- "Why can't the preprocessor be fixed to avoid macro-hygiene bugs while staying a preprocessor?" -- because "staying a preprocessor" means operating on raw tokens/text without full grammatical/semantic understanding; fixing hygiene properly requires exactly the AST/token-tree awareness that turns it into something more like Rust's `macro_rules!` (§16.6) or a C++ template -- i.e., stops being "just" a preprocessor.

---

## Chapter 12: Function Pointers, volatile, const, inline, and restrict

### 12.1 Function Pointers

A function, once compiled, lives at a fixed address in `.text` (§7.2) -- a function pointer is simply a variable holding that address, callable via an indirect `call` instruction (`call [rax]` rather than `call known_address`):

```c
int add(int a, int b) { return a + b; }
int (*op)(int, int) = add;   // op now holds add's address
int result = op(3, 4);        // compiles to an indirect call through op
```

This is the exact mechanism the original §14.3 comparison material described as what C hand-rolls to fake dynamic dispatch (a struct of function pointers standing in for a vtable) -- and it is, quite literally, what a compiled C++ vtable *is*: an array of function pointers, indexed and called indirectly, generated by the compiler instead of by hand.

### 12.2 volatile

`volatile` tells the compiler: **do not assume this memory behaves like ordinary memory -- its value may change for reasons outside this thread of control, and every read/write in the source must actually happen, in the order written, with no caching in a register across accesses.** Without it, the optimizer is free to assume a value that's never (visibly, to it) written between two reads is unchanged, and cache it in a register instead of re-reading memory -- which is exactly wrong for memory-mapped hardware registers (where reading the same address twice can return genuinely different values, e.g. a hardware status register) or a variable a signal handler can modify asynchronously.

```c
volatile uint32_t *status_reg = (volatile uint32_t *)0x40000000;
while (*status_reg == 0) { }   // WITHOUT volatile: the optimizer might hoist
                                 // the read out of the loop entirely, assuming
                                 // it can't change -- an infinite loop in
                                 // practice even though the hardware register
                                 // genuinely does change
```

**`volatile` is not a threading/concurrency primitive** -- a very common misconception. It says nothing about atomicity, and nothing about memory ordering *between cores* (§1.7/§34.5) -- it only constrains the compiler's own reordering/caching of accesses within one thread of execution, for the benefit of hardware or signal-handler interaction. Using `volatile` where you actually need thread-safety (instead of an atomic type, §22) is a real, historically common bug -- it happens to "often work" on x86 (whose strong native memory ordering hides many multi-core reordering bugs) while being genuinely, formally insufficient.

### 12.3 const

`const` is a compile-time-only promise to the type system that *this code path* won't modify the value through *this particular reference* -- it is not a hardware-level write-protection (that's what `.rodata`, §7.2, provides for genuinely immutable data) and, critically, it can be **cast away**:

```c
void modify(const int *p) {
    int *mutable_p = (int *)p;   // legal C -- compiles fine
    *mutable_p = 99;              // UB if the ORIGINAL object was actually const
                                    // (e.g. lived in .rodata); fine if it wasn't
}
```

Whether removing `const` and writing is actually safe depends on the *original* object's real storage -- a compile-time-only annotation offering no runtime guarantee is precisely why Rust's default immutability (§34.1's original comparison) is a stronger property: there is no `mut_cast` equivalent in safe Rust at all.

### 12.4 inline

`inline` is a *hint*, not a command -- the compiler is free to ignore it and not inline the function, or to inline a function that isn't marked `inline` at all, purely based on its own cost/benefit heuristics (§9.4's inlining pass). Its actual *required* effect in C is narrower and more subtle than "please inline this": it changes the linkage rules to permit the function to be defined identically in multiple translation units without an ODR (One Definition Rule) violation at link time -- solving a real header-file problem (a small function defined in a widely-`#include`d header) that has nothing to do with whether the compiler literally inlines the call.

### 12.5 restrict

`restrict` on a pointer parameter is a promise from the *programmer* to the compiler: "for the duration this pointer is valid, no other pointer will be used to access the same memory." The compiler cannot verify this -- it's taken on faith, and violating it is undefined behavior -- but *given* that promise, the optimizer is freed from having to conservatively assume two pointer parameters might alias (overlap), which otherwise blocks a large class of optimizations (e.g., reordering loads/stores, keeping a value in a register across a store through a *different* pointer that "might" be the same memory):

```c
void add_arrays(int *restrict a, int *restrict b, int *restrict out, int n) {
    for (int i = 0; i < n; i++) out[i] = a[i] + b[i];
    // WITHOUT restrict: the compiler must assume `out` might overlap `a`
    // or `b`, and can't safely vectorize/reorder the loop as aggressively
}
```

This is precisely the promise Rust's `&mut T`/`&T` borrow rules (§34.1) make *automatically and compiler-checked*, for every function, all the time -- `restrict` is C manually opting in, per pointer, to an aliasing guarantee Rust's type system enforces globally by construction. It's a strong hint of exactly what problem the borrow checker was actually built to solve at the optimizer level, not just the safety level: unrestricted aliasing is a genuine, measurable optimization blocker in C, and Rust's references simply never have the ambiguity `restrict` exists to resolve.

### Chapter 12 Notes

**Key Takeaways**
- `volatile` constrains compiler reordering/caching for one thread's interaction with hardware or a signal handler -- it is not a substitute for atomics or locks in multi-threaded code.
- `const` is a compile-time-only, castable-away promise -- unlike Rust's default immutability, it offers no runtime guarantee about the underlying object.
- `restrict` is C's opt-in, per-pointer, programmer-promised version of the no-aliasing guarantee Rust's borrow checker enforces automatically and universally -- and it exists specifically because unrestricted pointer aliasing is a real optimization blocker.

**Common Mistakes**
- Using `volatile` where an atomic type or a mutex was actually needed -- a classic, easy-to-write, hard-to-diagnose concurrency bug.
- Assuming `const` prevents a determined caller from mutating the data -- it only prevents *accidental* mutation through that specific reference, at compile time.

**Interview Notes**
- "Why is `volatile` insufficient for thread synchronization?" -- it says nothing about atomicity or cross-core memory ordering (§1.7); it only stops the *compiler* from caching/reordering accesses within one thread, which is a different problem than what happens between cores at the hardware level.
- "What class of optimization does `restrict` unlock, concretely?" -- it lets the compiler avoid conservatively re-reading memory after every store through a possibly-aliasing pointer, and enables more aggressive instruction reordering and vectorization (§37) by removing the "but what if these pointers overlap" case it would otherwise have to handle correctly.

---

## Chapter 13: Undefined Behavior, Sequence Points, and Strict Aliasing

### 13.1 What Undefined Behavior Actually Is

Restated precisely, building on §34.2's original framing but now grounded in Part I's compiler-pipeline model (§9): the C standard defines certain constructs as having **no defined behavior whatsoever** -- and every optimization pass in §9.4 is written under the explicit assumption that the code it's optimizing never triggers UB. When it does anyway, the optimizer's transformations remain "valid" *by the standard's own rules* even though the resulting behavior has no connection to what the source appears to say -- because the standard placed no constraint on what's allowed to happen once UB occurs. This is not a defect in the optimizer; it is a design tradeoff that gives C's compilers wide latitude to generate fast code by *not* having to insert defensive checks for cases the standard says can't legally arise.

### 13.2 Sequence Points and Sequenced-Before

Before a value written in one part of an expression can be *read* elsewhere in the same expression (or the next one), the standard needs to define an order -- and for a long stretch of any given expression's evaluation, **no such order is guaranteed at all**. The classic example:

```c
int i = 1;
int result = i++ + i++;   // UNDEFINED BEHAVIOR -- not "implementation defined",
                            // not "some order or another" -- literally undefined.
                            // i is modified twice with no sequence point between
                            // the two modifications and their uses.
```

The compiler is free to evaluate this however it likes -- including in ways that produce a result matching *neither* intuitive reading order, because the standard imposes no requirement here at all. (C11 replaced the older "sequence point" terminology with a more precise "sequenced before" relation between evaluations, but the practical upshot for code like the example above is identical.) The lesson generalizes: **modifying a value more than once, or modifying and reading it, within the same unsequenced expression, is UB** -- not a matter of "which compiler you use" or "which order it happens to pick."

### 13.3 Strict Aliasing

The **strict aliasing rule**: the compiler is permitted to assume that pointers of *unrelated* types never point to the same memory (with specific, narrow exceptions -- `char*` may alias anything, for instance). This licenses a real optimization: if the compiler sees a write through an `int*` and later a read through an unrelated `float*`, it can assume they're different memory and reorder/cache accordingly, *without* re-checking after every write whether some other differently-typed pointer might have touched that address.

```c
float f = 3.14f;
int *p = (int *)&f;
*p = 0;                 // UB: writing through an int* to memory that's
                          // "really" a float violates strict aliasing --
                          // the compiler may not observe this write at all
                          // when it later reads `f` as a float
```

This exact pattern -- reinterpreting the bits of one type as another -- is called **type punning**, and doing it via a raw pointer cast (as above) is the classic strict-aliasing violation. The standard-legal ways to achieve the same *intent* are `memcpy` (the compiler recognizes and optimizes away a `memcpy` of a known, fixed, small size into an ordinary bit-reinterpreting move -- so this costs nothing at `-O2`+ despite "copying") or a `union` (C, unlike C++, explicitly permits reading a different union member than was last written, specifically for this type-punning use case):

```c
float f = 3.14f;
int bits;
memcpy(&bits, &f, sizeof(bits));   // standard-legal, and free once optimized
```

Compiling with `-fno-strict-aliasing` disables this optimization license entirely, making raw-pointer type punning well-defined again at the cost of some optimization opportunities -- a real, sometimes-used escape hatch for older codebases that predate wide awareness of this rule, but not something to reach for as a first response instead of just using `memcpy`/a union correctly. Rust sidesteps this entire failure mode: `std::mem::transmute` (§19.4's original material) is `unsafe`, explicit about programmer responsibility at the call site, and the compiler's aliasing assumptions for ordinary safe-Rust references are instead governed by the borrow checker's own, differently-shaped rules (§34.1) rather than a type-based aliasing rule you can silently violate with a cast.

### Chapter 13 Notes

**Key Takeaways**
- UB is a design tradeoff, not a bug in the optimizer: the standard's silence on certain constructs is exactly what licenses aggressive, non-defensive code generation for the (overwhelming majority of) constructs that *aren't* UB.
- "Multiple unsequenced modifications to the same value" (`i++ + i++`) and "aliasing violations via mismatched pointer types" are two structurally different UB categories -- one about evaluation order, one about the optimizer's aliasing assumptions -- both genuinely undefined, not "implementation-specific."
- `memcpy` of a fixed, known size is free after optimization and is the standard-legal way to type-pun -- there's no real performance argument for reaching for a raw pointer cast instead.

**Common Mistakes**
- Writing an expression that both modifies and reads the same variable more than once without an intervening sequence point, and assuming "well it worked when I tried it" means it's actually defined.
- Reaching for `-fno-strict-aliasing` as a first fix for a type-punning bug, rather than switching to `memcpy`/a union, which is both correct *and* just as fast after optimization.

**Interview Notes**
- "Why is `i = i++ + i++` undefined rather than just 'compiler-dependent'?" -- because the standard places literally no requirement on the outcome when a value is modified more than once without a sequencing relationship between the modifications, as opposed to leaving *one specific, bounded* choice up to the implementation (which would be "unspecified" or "implementation-defined" behavior, a different, weaker category than UB).
- "What does the strict aliasing rule let the optimizer assume, concretely?" -- that two pointers of unrelated types never refer to overlapping memory, letting it skip re-checking/re-reading memory after a write through a pointer of a different type than the one it's currently using to read.

---

# PART III -- C++: Zero-Cost Abstraction Over C

C++'s founding design goal is "everything C already gives you, plus higher-level abstractions that cost nothing you wouldn't have paid writing the equivalent C by hand." Every chapter here is best read as "what does this abstraction lower to, in terms of the C-level/Part-I model already built" -- the abstraction is only "zero-cost" to the extent that lowering is faithful.

## Chapter 14: Classes, Inheritance, Vtables, and RTTI

### 14.1 Classes vs. C Structs

A C++ `class`/`struct` with no virtual functions has *identical* memory layout and cost to the equivalent C struct (§10.4) -- `public`/`private` access control is a **compile-time-only** check with zero runtime representation, exactly like Rust's `pub` (§6.4's original comparison). Member functions are, at the ABI level, ordinary functions taking an implicit `this` pointer as their first argument (§4.4's original comparison) -- `obj.method()` compiles to essentially `method(&obj)`.

### 14.2 Inheritance Layout

Single inheritance simply concatenates the base class's layout at the start of the derived class's layout:

```
 class Base { int x; };
 class Derived : public Base { int y; };

 Derived object layout:
 ┌─────────────┬─────────────┐
 │   Base::x    │  Derived::y  │
 │  (offset 0)  │  (offset 4)  │
 └─────────────┴─────────────┘
```

A `Derived*` can be implicitly converted to a `Base*` with **zero runtime cost** in the single-inheritance case above, because a `Base` subobject starts at offset 0 -- the pointer value doesn't even need to change. **Multiple inheritance** breaks this: if `Derived` inherits from two unrelated bases, only one of them can start at offset 0, so converting to the *other* base's pointer type requires the compiler to silently adjust the pointer value by a fixed offset -- a genuine (if tiny) runtime cost single inheritance doesn't have, and the root cause of the notorious "diamond problem" (two base classes that both inherit from a common further-base, ambiguous which copy `Derived` should see) that `virtual` inheritance exists to resolve, at the cost of yet more indirection (a diamond's shared base's location becomes something that has to be looked up rather than known at a fixed offset).

### 14.3 Virtual Functions and Vtables, in Full

Adding even one `virtual` method to a class adds a hidden pointer field (the **vptr**), typically the very first field, pointing at a **vtable**: a per-*class* (not per-object) static array of function pointers, one slot per virtual method:

```
  object of type Derived:              Derived's vtable (one shared instance,
 ┌───────────────┐                       not per-object):
 │  vptr           │────────────────▶  ┌─────────────────────┐
 ├───────────────┤                    │  &Derived::~Derived()  │  slot 0
 │  Base::x        │                    ├─────────────────────┤
 ├───────────────┤                    │  &Derived::foo()        │  slot 1
 │  Derived::y     │                    ├─────────────────────┤
 └───────────────┘                    │  &Derived::bar()        │  slot 2
                                        └─────────────────────┘
```

Calling `obj->foo()` through a `Base*` when `foo` is virtual compiles to: load `obj`'s vptr, index into the vtable at `foo`'s known slot, call through that function pointer -- two extra memory loads plus an indirect call versus a direct `call` for a non-virtual method. This is the exact mechanism §14.3's original comparison identified as identical to Rust's `dyn Trait` (§35.4) -- not an analogy, the same technique, independently converged on by both languages' implementations.

### 14.4 RTTI

**RTTI (Run-Time Type Information)** lets code query an object's *actual* dynamic type at runtime, even when only accessed through a base-class pointer -- implemented by storing a pointer to a `std::type_info` object as an extra vtable entry (so it's only available for polymorphic types, i.e. types with at least one virtual function -- there's no dynamic type to recover for a type with no vtable in the first place).

```cpp
class Animal { public: virtual ~Animal() = default; };
class Dog : public Animal {};

Animal *a = new Dog();
std::cout << typeid(*a).name();          // queries RTTI -- prints Dog's mangled name
if (Dog *d = dynamic_cast<Dog*>(a)) {    // safe downcast: checks RTTI at runtime,
    // ...                                 // returns nullptr if a isn't actually a Dog
}
```

`dynamic_cast` is genuinely expensive relative to a `static_cast` (which does no runtime check at all) -- it walks the RTTI-described class hierarchy at runtime to verify the cast is legal, which is why performance-sensitive code either avoids downcasting entirely (favoring virtual dispatch itself, or a variant/tagged-union redesign) or disables RTTI project-wide (`-fno-rtti`) when it's provably unused, trading away `dynamic_cast`/`typeid` for a smaller binary and marginally faster virtual-class construction. Rust has no direct equivalent -- `dyn Any` (`std::any::Any`) provides a narrower, opt-in form of the same idea (runtime type identification via `downcast_ref`), but ordinary `dyn Trait` objects carry no built-in "what concrete type is this" query the way every polymorphic C++ object does by default.

### Chapter 14 Notes

**Key Takeaways**
- A non-virtual C++ class costs exactly what the equivalent C struct costs -- the vtable/vptr overhead is opt-in, triggered specifically by declaring at least one virtual method.
- Multiple inheritance can require runtime pointer adjustment on upcasts that single inheritance does for free -- not all inheritance is equally cheap.
- RTTI/`dynamic_cast` are real, non-negligible runtime costs (a hierarchy walk), unlike `static_cast`, which is purely compile-time and free.

**Common Mistakes**
- Assuming all C++ base-to-derived pointer conversions are free -- true only for the first base in single/simple inheritance; false in general under multiple inheritance.
- Reaching for `dynamic_cast` as a routine control-flow tool rather than recognizing it as a real runtime cost that a `match`/visitor-pattern-shaped redesign often avoids entirely.

**Interview Notes**
- "What's the actual memory-layout cost of adding one virtual method to a previously-plain class?" -- one pointer-sized field (the vptr) added to every instance, plus one static vtable per class (not per instance).
- "Why is `dynamic_cast` slower than `static_cast`?" -- `static_cast` is resolved entirely at compile time with no runtime check; `dynamic_cast` walks RTTI metadata at runtime to verify the actual dynamic type supports the target type.

---

## Chapter 15: Templates, constexpr, and Concepts

### 15.1 Templates

A C++ template is a *pattern* for generating code, instantiated once per distinct set of template arguments actually used in the program -- mechanically the same **monomorphization** process as Rust generics (§9.4's original comparison, §35.4), performed by the C++ front end rather than a separate MIR-level pass, but with an important historical difference in *when errors surface*: template bodies are type-checked only *after* substitution, against the specific types used at each instantiation site (**two-phase lookup**, roughly) -- so a constraint violation deep inside a heavily-used template can produce error output blamed on the instantiating call site, cascading through every intermediate template layer, rather than being caught once against the template's own declared requirements.

```cpp
template <typename T>
T max_val(T a, T b) { return a > b ? a : b; }

max_val(3, 4);        // instantiates max_val<int>
max_val(3.0, 4.0);     // instantiates max_val<double> -- a SEPARATE compiled function
```

### 15.2 constexpr

`constexpr` marks a function or variable as *evaluable at compile time*, when its inputs are themselves compile-time constants -- a genuinely different property from `const` (§12.3): `const` is about *not being mutated*; `constexpr` is about *when* the computation happens (compile time, baking the result directly into the binary as if it had been written as a literal, versus computed at every run).

```cpp
constexpr int square(int x) { return x * x; }
constexpr int result = square(5);   // computed AT COMPILE TIME -- literally becomes `25`
                                      // in the generated code, no runtime multiply at all

int n = get_user_input();
int result2 = square(n);              // n isn't compile-time-known -- square() runs
                                        // as an ordinary function call at runtime instead
```

The same function can be evaluated at compile time *or* runtime depending on whether its actual arguments are compile-time-known -- `constexpr` is a *permission*, not a mandate, for compile-time evaluation. Rust's `const fn` (used throughout the original §16.3-adjacent material for compile-time-evaluable constants) is the direct structural analog, with a narrower historically-allowed-operations set that has been steadily widening release over release, converging toward roughly the same capability C++'s `constexpr` has had for longer.

### 15.3 Concepts (C++20)

**Concepts** let a template *declare its actual requirements* on a type parameter, checked *before* instantiation rather than discovered mid-substitution -- directly closing the "errors surface deep inside the instantiated body" gap from §15.1, and the direct structural analog of Rust's trait bounds (§9's `T: Summary`, checked at the generic function's own definition rather than at each call site):

```cpp
template <typename T>
concept Addable = requires(T a, T b) { { a + b } -> std::same_as<T>; };

template <Addable T>              // constrained -- a type failing the concept is
T sum(T a, T b) { return a + b; }  // rejected with an error pointing AT sum's own
                                     // declaration, not deep inside its body
```

This is a genuinely late addition to C++ (2020, versus templates existing since the early 1990s) specifically because unconstrained templates' error-locality problem was a decades-long, widely-felt pain point -- concepts are C++ converging toward the same "checked at the generic's own boundary" property Rust's trait system had from its first stable release.

### Chapter 15 Notes

**Key Takeaways**
- Templates and Rust generics share the exact same *cost* model (monomorphization) but historically differed sharply in *error-locality* -- concepts close most of that gap.
- `constexpr` and `const` answer different questions (*when* computed vs. *whether* mutable) -- conflating them is a common beginner mistake in both C++ and, by the const/immutable-by-default distinction, in reasoning about Rust's `const`/`let` split too.

**Common Mistakes**
- Assuming `constexpr` guarantees compile-time evaluation -- it only *permits* it, for compile-time-known inputs; the same function silently falls back to ordinary runtime execution for non-constant inputs.
- Diagnosing an unconstrained-template error by reading the *innermost* error message first -- the actual mistake is usually at the outermost call site; concepts exist specifically to fix this diagnostic ordering.

**Interview Notes**
- "Why did C++ add concepts in C++20 when templates already existed since C++98?" -- to move constraint checking from instantiation time (deep, cascading, hard-to-read errors) to definition time (one clear error at the template's own declaration), matching the ergonomics trait-bound generics had already demonstrated in other languages.
- "Give an example of something `constexpr` can compute that would otherwise cost a runtime instruction." -- a lookup table or hash computed from compile-time-known literals, baked directly into `.rodata` (§7.2) instead of being recomputed on every program run.

---

## Chapter 16: RAII, Smart Pointers, Move Semantics, and Copy Elision

### 16.1 RAII, Formally

**RAII (Resource Acquisition Is Initialization)**: tie a resource's lifetime to an object's scope by acquiring it in the constructor and releasing it in the destructor -- so the resource is *guaranteed* released when the object goes out of scope, including via an exception unwinding through it (§17.1), with no explicit cleanup call required at every exit path. This is C++'s original version of the idea Rust's `Drop` trait (§12.4's original material) formalizes as a language-checked mechanism rather than a class-author convention -- the *idea* is C++'s; Rust's contribution is making "did you actually implement RAII correctly, everywhere" a compiler-enforced property rather than a code-review concern.

### 16.2 Smart Pointer Internals

```cpp
std::unique_ptr<T>    // one raw T* field, deletes it in its destructor -- move-only
std::shared_ptr<T>     // a raw T* PLUS a pointer to a heap-allocated "control block"
                        // holding the atomic strong/weak reference counts
std::weak_ptr<T>       // holds a pointer to the SAME control block, without
                        // incrementing the strong count -- breaks Rc/shared_ptr cycles
```

`shared_ptr`'s control block is why `std::make_shared<T>(...)` is preferred over `shared_ptr<T>(new T(...))`: the former allocates the object *and* its control block in a single heap allocation; the latter requires two separate allocations (one from `new T`, one for the control block `shared_ptr`'s constructor allocates itself) -- a real, measurable difference in allocator pressure for shared_ptr-heavy code, directly analogous to why `Rc::new`/`Arc::new` in Rust allocate the value and its refcount together in one block by design, with no equivalent "two-allocation" footgun to avoid in the first place.

### 16.3 Move Semantics

**Rvalue references** (`T&&`) let a function overload distinguish "this argument is a temporary/explicitly-moved-from value I can safely cannibalize" from "this argument is a named, possibly-still-used object I must not destructively modify":

```cpp
class Buffer {
    char *data;
    size_t size;
public:
    // move constructor: STEAL the other object's resources
    Buffer(Buffer&& other) noexcept : data(other.data), size(other.size) {
        other.data = nullptr;   // leave `other` in a valid, destructible,
        other.size = 0;          // but unspecified state -- NOT undefined,
    }                             // just "don't assume anything about its value"
};

Buffer a = std::move(b);   // std::move doesn't move anything itself -- it's purely
                             // a cast to Buffer&&, SELECTING the move-constructor
                             // overload instead of the copy-constructor one
```

The crucial, easy-to-miss difference from Rust's move (§3.5's original comparison): **`std::move` does not make using `b` afterward a compile error.** It's legal C++ to keep using `b` after moving from it -- the object is in a "valid but unspecified" state (destructible, assignable, but its *value* shouldn't be relied upon) rather than inaccessible. This is a real, live footgun class C++ has that Rust's compiler-enforced move (§3.2's original material) structurally cannot have: using a moved-from Rust value is caught at compile time; using a moved-from C++ value silently compiles and reads whatever the move constructor happened to leave behind.

### 16.4 Copy Elision

The compiler is permitted -- and since C++17, for specific cases, *required* -- to skip a copy/move entirely and construct the result object *directly* in its final destination, even where the language's ordinary as-if rule would otherwise mandate an observable copy/move constructor call:

```cpp
Buffer make_buffer() {
    return Buffer(1024);   // C++17+: GUARANTEED elision -- Buffer(1024) is
}                            // constructed directly in the caller's storage;
                              // NO move constructor call happens at all, not
                              // even an elided-but-notionally-present one

Buffer b = make_buffer();    // b IS that same object, not a moved-into copy of it
```

This specific case -- returning a prvalue (a genuine temporary, not a named local) directly -- became a *mandatory* part of the C++17 standard's semantics rather than a mere permitted optimization; the temporary conceptually never exists as a separate object at all. **NRVO (Named Return Value Optimization)** -- eliding the copy/move when returning a *named* local variable -- remains merely *permitted*, not guaranteed, meaning a move constructor call can still legally happen there depending on the compiler, which is why (unlike the guaranteed prvalue case) a type intended for NRVO still needs a correct, working move constructor as a fallback. Rust has no equivalent optimization to reason about at all here: returning a value from a function is *always* just a move (or a `Copy`, for `Copy` types) with no separate "was this actually elided" question, because Rust never had C++'s copy-constructor-call-as-observable-side-effect semantics to elide away from in the first place.

### Chapter 16 Notes

**Key Takeaways**
- RAII is C++'s original contribution; Rust's `Drop`/ownership makes the same idea *compiler-verified* rather than convention-based -- the concepts are historically linked, not independently invented.
- `std::move` is just a cast selecting an overload -- it performs no action itself, and (unlike Rust) leaves the source object legally usable afterward, just in an unspecified-value state.
- Guaranteed copy elision (C++17, for prvalues) means a `return SomeType(...)` in modern C++ genuinely never calls a copy or move constructor at all -- not "elides an actual call," but was never going to make one under the current standard's rules.

**Common Mistakes**
- Using a C++ object after `std::move`-ing it and assuming it retains its old value -- it's legal to do, but the value is unspecified, and relying on it is a real bug even though it compiles.
- Assuming NRVO is guaranteed the way prvalue elision is -- it's compiler-dependent, which is exactly why a move-constructor fallback still has to be correct even in code that "usually" benefits from NRVO in practice.

**Interview Notes**
- "What does `std::move` actually do, mechanically?" -- nothing at runtime; it's a compile-time cast to an rvalue reference, which changes overload resolution to prefer a move constructor/assignment over a copy one.
- "Why can C++ have a 'moved-from but still usable' bug class that Rust structurally can't?" -- Rust's compiler tracks moves and makes using a moved-from binding a compile error; C++'s move leaves the source object as an ordinary, still-accessible variable whose value is merely unspecified, with no compiler-enforced restriction on touching it again.

---

## Chapter 17: Exceptions and the C++ Memory Model

### 17.1 Exceptions, Stack Unwinding, and Cost

`throw` transfers control to the nearest enclosing matching `catch`, running the destructor of every stack-allocated object between the throw site and the catch site along the way (**stack unwinding**) -- which is precisely why RAII (§16.1) and exceptions were co-designed: unwinding is only safe/correct because every resource-holding object on the unwound stack cleans itself up automatically via its destructor, with no manually-written cleanup code needed at every possible throw point.

Mechanically, modern C++ implementations use **zero-cost exceptions**: the non-throwing path carries *no* per-call runtime overhead at all (unlike, say, C's manual `if (err) return err;` chains, which cost a branch on every single call whether or not an error actually occurs) -- instead, a separate, statically-generated table (parallel to the DWARF unwind tables debuggers/profilers already use, §38) maps each possible instruction-pointer range to what cleanup is needed if an exception passes through it. The *cost* is entirely deferred to the throw path itself: walking that table at throw time to find the right handler and run the right destructors is genuinely expensive -- routinely cited as one to two orders of magnitude slower than a normal function return, which is exactly why exceptions are considered appropriate for truly exceptional, rare-path errors and not for routine control flow (a `Result`-shaped design, as Rust and increasingly modern C++ style guides both favor, has no equivalent "cheap when not used, expensive when used" asymmetry -- every path costs the same small, predictable amount).

### 17.2 The C++11 Memory Model

Before C++11, the language standard itself said nothing about multi-threading at all -- `std::thread`, `std::atomic`, and a formal memory model (defining exactly what reordering is and isn't legal across threads) were all introduced together, because you cannot specify correct concurrent behavior without *also* specifying the memory model constraining what "happens before what" even means across cores.

```cpp
#include <atomic>
std::atomic<int> counter{0};
counter.fetch_add(1, std::memory_order_relaxed);
counter.store(1, std::memory_order_release);
int v = counter.load(std::memory_order_acquire);
```

This is, ordering-name for ordering-name, the *same* model Rust's `std::sync::atomic` (§22, the original material) exposes -- both languages adopted essentially the same C++11-originated memory-ordering vocabulary (`relaxed`/`acquire`/`release`/`acq_rel`/`seq_cst`), for the same underlying hardware reason (§1.7/§34.5: cores genuinely reorder memory operations, and something has to formally constrain that). The practical difference isn't the ordering model itself but what surrounds it: C++ atomics can be used correctly or incorrectly with no compiler assistance distinguishing the two (an ordinary, non-atomic `int` shared across threads without synchronization is a silent data race, UB, and the compiler will not stop you), where Rust's `Send`/`Sync` traits (§19.3/§34.1) make *accidentally* sharing non-thread-safe data across threads a compile error in the first place -- the atomics themselves are borrowed almost directly from C++11's design, but the surrounding guardrail is Rust's own addition.

### Chapter 17 Notes

**Key Takeaways**
- Zero-cost exceptions genuinely cost nothing on the non-throwing path -- the cost is concentrated entirely on the throw path itself, which is real and substantial.
- RAII and exceptions are co-designed: unwinding safety depends on every stack object's destructor running automatically, with no manual per-throw-site cleanup code.
- Rust's atomics and C++11's atomics share essentially the same memory-ordering vocabulary and hardware justification -- the difference is Rust additionally makes *unsynchronized* sharing a compile error via `Send`/`Sync`.

**Common Mistakes**
- Using exceptions for routine, expected error conditions (a missing config key, a parse failure on ordinary untrusted input) rather than reserving them for genuinely exceptional, rare-path failures -- a performance and, in many style guides, a readability mistake.
- Sharing a plain (non-atomic) variable across C++ threads without synchronization and having it "usually" work on a given platform/compiler -- it's a data race and UB regardless of how reliably it happens to behave in practice.

**Interview Notes**
- "Why are C++ exceptions called 'zero-cost' if the throw path is clearly expensive?" -- "zero-cost" specifically means the *non-throwing* path pays nothing extra; it's a claim about the common case, not about the exceptional path.
- "What has to be true for stack unwinding to safely release resources?" -- every object with a resource to release must do so in its destructor (RAII), since unwinding runs destructors automatically but does not run arbitrary manually-placed cleanup code that isn't tied to an object's lifetime.

---

## Chapter 18: Coroutines, Lambdas, and Modules

### 18.1 Lambdas, Formally

A C++ lambda desugars to a compiler-generated anonymous class (a "closure type") with the captured variables as data members and an `operator()` implementing the body -- capture-by-value copies into a member field at lambda-creation time; capture-by-reference stores a reference member instead:

```cpp
int x = 10;
auto by_value = [x](int n) { return n + x; };        // roughly:
// struct Anon1 { int x; int operator()(int n) const { return n + x; } };

auto by_ref = [&x](int n) { return n + x; };            // roughly:
// struct Anon2 { int &x; int operator()(int n) const { return n + x; } };
```

This is exactly the "closure is just a struct with a call method" mechanism described in §11.3's original comparison for Rust closures -- both languages implement the same desugaring independently, which is *why* capturing large data by value has a real, measurable size/copy cost in both: you're materializing a genuine struct field, not a free abstraction.

### 18.2 Coroutines in Full

A C++20 coroutine (any function using `co_await`, `co_yield`, or `co_return`) is transformed by the compiler into a state machine object, driven by a **promise type** that defines what happens at each suspend/resume point -- the direct structural analog of Rust's `async fn` → `Future`/`Waker` transformation (§23.1/§17.2's original comparison), arrived at independently for the same reason: cheap suspension/resumption without a dedicated OS thread and stack per coroutine.

```cpp
generator<int> counter(int start) {
    for (int i = start; ; i++) {
        co_yield i;         // suspend here, produce a value, resume on next request
    }
}
```

Every `co_await`/`co_yield`/`co_return` in a function forces the compiler to generate a full state-machine transformation of that function -- locals that must survive across a suspend point become fields of the generated coroutine-frame object (conceptually identical to how a Rust `async fn`'s live-across-`.await` locals become enum-variant fields, §23.1) -- and, as the original §17.2 comparison notes, that frame is typically heap-allocated per invocation in C++ (unless the compiler can prove the allocation elidable), where Rust leaves the placement decision to the caller.

### 18.3 Modules (C++20)

C++20 modules are a genuine departure from the `#include`-based translation-unit model described in §11.3-11.4: instead of textually re-parsing an entire header's contents in *every* translation unit that includes it (real, measurable compile-time cost at scale -- a widely-included header can be re-lexed and re-parsed thousands of times across a large build), a module is compiled *once* into a binary interface file that importing translation units consume directly:

```cpp
// math.ixx -- a module interface file
export module math;
export int square(int x) { return x * x; }
```

```cpp
import math;               // no textual re-parsing -- consumes the precompiled interface
int r = square(5);
```

This is the C++ ecosystem converging, decades later, toward something structurally closer to how Rust's crate/module system (§6.3's original material) and its incremental-compilation model already worked from the start -- module boundaries are true compilation boundaries, not textual-inclusion boundaries, which is exactly the property `#include` never had.

### Chapter 18 Notes

**Key Takeaways**
- A C++ lambda and a Rust closure are the *same* compiler trick (anonymous struct + call operator/trait impl) implemented independently in both languages -- capture cost is real in both for the same underlying reason.
- C++20 coroutines and Rust's `async fn` solve the same problem (cheap, OS-thread-free suspension) with structurally analogous compiler transformations, differing mainly in where the resulting state machine gets allocated by default.
- C++20 modules exist specifically to fix `#include`'s textual-reparsing compile-time cost -- a problem Rust's module system, designed later and without needing C-header backward compatibility, never had in the first place.

**Common Mistakes**
- Assuming a C++ coroutine's frame allocation is always elided the way Rust's `Future` placement is caller-controlled by default -- it's an optimization the compiler *may* perform, not a guarantee, unlike Rust where you're always explicitly choosing stack-value vs. `Box::pin`.
- Underestimating how much large-scale C/C++ build time historically came from repeatedly re-parsing the same widely-`#include`d headers -- modules are a direct, structural answer to a real, quantifiable cost, not a stylistic preference.

**Interview Notes**
- "What does a lambda capture list actually produce, under the hood?" -- data members of a compiler-generated anonymous class, populated at the point the lambda expression is evaluated (by copy or by reference, per the capture specifier).
- "Why do C++20 modules improve build times over `#include`?" -- a module is compiled once into a reusable interface representation; `#include` instead re-lexes and re-parses the full header text in every translation unit that includes it, however many times that is across the whole build.

---

# PART IV -- Rust: Compile-Time Safety Without Runtime Cost

Everything in this Part builds directly on Parts I-III: you already know what a stack frame, a vtable, a heap allocator, and an ABI are, and you already know what C and C++ do when faced with the same problem. Rust's story, chapter after chapter, is the same shape: take a problem C handles with zero enforcement (§10-13) or C++ handles with convention/RAII (§14-18), and make the *compiler* enforce the invariant instead -- at the cost of upfront restriction, for the benefit of zero added runtime cost. §9.2 already showed you *where* in the compiler pipeline that enforcement happens (MIR) and *that* nothing downstream of it carries any trace of the checking -- keep that firmly in mind through this entire Part.

## Chapter 19: Toolchain and Compilation Model

`cargo` unifies build, dependency management, testing, and documentation behind one config file (`Cargo.toml`) -- contrast with C/C++'s fragmented make/CMake-plus-external-package-manager landscape (§39 compares all of these directly). `cargo build` invokes `rustc`, which follows the AST → HIR → MIR → LLVM IR pipeline detailed in §9.2 -- worth re-reading now that you also have Chapters 14-15's C++ template/monomorphization comparison fresh, since Rust generics (§26) go through the same MIR stage, monomorphized, before ever reaching the LLVM backend Rust shares with `clang`.

```bash
cargo new project_name    # scaffold a new package
cargo build                # compile (debug profile: -O0-ish, fast compile, slow runtime)
cargo build --release      # compile (release profile: full optimization, §9.4's passes)
cargo check                 # run the front end + borrow checker WITHOUT codegen -- much faster
                             # feedback loop, since instruction selection/codegen (§9.5-9.6)
                             # is skipped entirely
cargo run
cargo test
```

## Chapter 20: Core Language Concepts

Variables, types, functions, and control flow -- covered in full, with direct C/C++/assembly-level comparison, in the original material now folded into this handbook's Chapter 2 (C) framing: immutability-by-default (§2.1's original discussion) costs *nothing* at runtime (it's erased identically to `const`, per §12.3, except non-castable-away); fixed-width types (`i32`/`u64`) map 1:1 onto C's `<stdint.h>` types (§10.1); expression-oriented tail returns and `loop { break value; }` desugar to the same `cmp`/`jmp`-shaped assembly as their C equivalents (§3.3). Nothing here costs more than the equivalent hand-written C -- this chapter is a thin layer of ergonomics, not a new execution model.

## Chapter 21: Ownership, Borrowing, and Lifetimes -- The Central Idea

### 21.1 The Problem This Solves

Restated once more, now with the full weight of Parts I-III behind it: C gives you §10.2's pointers with *zero* enforcement of who's allowed to read or write through them, and the historical result (§10.3's array decay, §12.5's `restrict` existing at all as a manual escape hatch, §13's entire undefined-behavior chapter) is that a huge fraction of C's most serious bugs and security vulnerabilities are aliasing/lifetime bugs the language simply never tried to prevent. C++ layers RAII (§16.1) on top, formalizing *cleanup* but never *access* -- a `unique_ptr` stops a double-free, but nothing stops you from also holding a raw `T*` alias to the same object with no relationship the compiler tracks (§16.1's original framing).

Rust's ownership model answers the question Part II/III's languages leave to programmer discipline: **at every point in the program, is there exactly one live mutable path to this data, or any number of live read-only paths, and never both?** -- checked once, in MIR (§9.2), for free at runtime.

### 21.2 Ownership Rules and the Compiler's View

```
 Rules:                                    What this looks like on MIR's CFG (§9.2):
 1. Each value has one owner
 2. Only one owner at a time              basic_block_0:
 3. Owner leaving scope drops the value      _1 = String::from("hello")   // s owns this
                                              _2 = move _1                 // moved into s2
                                              // _1 is now "dead" -- using it here
                                              // is what the borrow checker's
                                              // dataflow analysis rejects
```

```rust
let s1 = String::from("hello");
let s2 = s1;                       // MOVE -- MIR marks _1 dead from here on
// println!("{s1}");                // compile error: value borrowed after move
```

The borrow checker is a **dataflow analysis** over exactly this kind of CFG -- for every point in the program, it tracks which borrows are currently live, and rejects any path where a conflicting access (two live mutable borrows, or a mutable borrow alongside a live immutable one, or a use after the owner's move) would occur. This is mechanically the same *category* of static analysis a C++ static analyzer *tries* to approximate after the fact (§9.4's optimizer's own aliasing assumptions, §12.5's `restrict`) -- Rust's version is sound and mandatory, not best-effort and opt-in.

### 21.3 References and Borrowing

```rust
fn calculate_length(s: &String) -> usize { s.len() }   // immutable borrow
fn change(s: &mut String) { s.push_str(", world"); }   // mutable borrow
```

At the machine level (§6.2), `&String`/`&mut String` are both just a pointer passed in a register -- there is *no* runtime representation distinguishing a mutable borrow from an immutable one; the distinction is 100% erased after MIR, exactly like §13.1/§34.2's UB discussion establishes for C's unchecked pointers, except here the checking actually happened, upstream, and succeeded. The rule enforced -- one mutable XOR many immutable, at any point in time -- is precisely the aliasing guarantee C's `restrict` (§12.5) asks the *programmer* to manually promise, per pointer, on a case-by-case basis. Rust's references make that guarantee true *by construction*, for every reference, all the time -- which is also why an ordinary Rust reference gets a real, measurable optimization benefit analogous to a `restrict`-annotated C pointer: LLVM's optimizer, seeing Rust's noalias metadata (emitted based on the borrow checker's own guarantees), can make the same non-aliasing assumptions `restrict` licenses in C, without a single `restrict` keyword anywhere in the Rust source.

### 21.4 Lifetimes

```rust
fn longest<'a>(x: &'a str, y: &'a str) -> &'a str {
    if x.len() > y.len() { x } else { y }
}
```

A lifetime annotation is a *constraint the compiler checks*, not a value that exists at runtime -- `'a` never appears in emitted code. It answers a question C/C++ leave entirely to the programmer (or, at best, to external tools like ASan/Valgrind catching the violation *after* it ships, §38): "is it possible for this reference to outlive the data it points to?" If the answer is yes, the program is rejected before it compiles; if no, the lifetime parameters vanish completely by the time you're looking at LLVM IR, let alone assembly.

### Chapter 21 Notes

**Key Takeaways**
- Ownership/borrowing is a MIR-stage, compile-time-only dataflow analysis (§9.2) -- it costs compile time, never runtime, and produces code indistinguishable at the assembly level from the equivalent (correctly-written) C.
- Rust references give LLVM the same noalias optimization opportunity C's `restrict` (§12.5) gives it -- but automatically, for every reference, rather than as an opt-in, unenforced, per-pointer promise.
- Lifetimes are purely a rejection mechanism -- an accepted program's generated code carries zero trace of lifetime checking having occurred.

**Common Mistakes**
- Assuming borrow-checking has a runtime cost because it's "extra checking" -- it is checking, but it happens entirely before code generation, not instead of or in addition to it.
- Expecting lifetime syntax to appear anywhere in `cargo asm`/godbolt.org output -- it never does; if you're looking for it there, you've misunderstood what stage it operates at.

**Interview Notes**
- "In one sentence, what invariant does the borrow checker enforce?" -- at any point in the program, either one live mutable reference to a value, or any number of live immutable references, never both, and never a reference to a value that has already been moved from or dropped.
- "Why can a Rust reference be optimized as aggressively as a `restrict`-qualified C pointer, with no explicit annotation?" -- because the borrow checker already proved the same no-aliasing property `restrict` merely promises in C, so the compiler can safely emit the same noalias metadata for the optimizer to exploit.

## Chapter 22: Structs, Enums, and Memory Layout

`#[repr(Rust)]` (the default) permits field reordering for padding minimization -- unlike C's declared-order-guaranteed layout (§10.4); `#[repr(C)]` opts back into that C-compatible guarantee specifically for FFI (§31.4). Enums are tagged unions (§5.5's original comparison to a hand-rolled C `struct { tag; union {...}; }`), with **niche optimization** -- `Option<&T>` uses the impossible null-pointer bit pattern as its own discriminant, so it's exactly pointer-sized, no separate tag byte at all, something neither a naive C tagged union nor `std::variant` gets automatically.

```
 Option<&T> layout (niche-optimized):        A hand-rolled C tagged union:
 ┌─────────────────────┐                    ┌─────┬─────────────────────┐
 │   the pointer itself   │  8 bytes          │ tag  │   payload             │  9+ bytes
 │  (0 == None, else Some)│                   │(1 B) │  (padded to align)     │  (with padding)
 └─────────────────────┘                    └─────┴─────────────────────┘
```

## Chapter 23: Modules and Crates

Rust modules (§6, original material) are a pure compile-time namespacing/privacy construct, zero runtime cost -- structurally closer to C++ namespaces than to C's `#include`-based translation units (§11.3), but crucially, crate compilation is a genuine, incremental compilation boundary the way C++20 modules (§18.3) were specifically introduced to *become* -- Rust never had `#include`'s textual-reparse cost to begin with, since it was designed after that problem was already well understood.

## Chapter 24: Collections and Memory Layout

`Vec<T>` (§7.1, original material) is `{ptr, len, cap}` -- the compiler-managed version of the growable-array pattern §5.1's manual `malloc`/`realloc` heap-allocator discussion already walked through by hand; `.get()`/`[]` bounds-checking is the direct answer to §10.3's array-decay-driven buffer-overflow bug class. `HashMap`'s `hashbrown`/SwissTable implementation (open addressing, SIMD-accelerated probing) is a genuinely different *implementation strategy* than `std::unordered_map`'s typical separate-chaining, not just an API-surface difference -- worth remembering the SIMD-register material from §2.4 here: SwissTable's probing loop is precisely the kind of short, fixed-width, parallel byte-comparison operation `XMM`-register instructions are built for.

## Chapter 25: Error Handling

`Result<T, E>` (§8, original material) compiles to an ordinary tagged-union return value -- a conditional branch and early return via `?`, no unwind tables involved, unlike C++ exceptions' throw-path machinery (§17.1). `panic!`'s *default* behavior (`unwind`) does use the same unwind-table mechanism C++ exceptions rely on -- which is exactly why `panic = "abort"` (skipping that machinery for a plain process-terminate, closer to C's `abort()`) is a real, meaningful Cargo.toml profile choice, not a cosmetic one, when binary size or unwind-table overhead matters (relevant again in Part VI, where a container runtime's panic strategy is a real design decision).

## Chapter 26: Generics, Traits, and Dispatch

Monomorphization (§9.1, §35.4's original material) -- direct structural match for C++ template instantiation (§15.1), with the same code-size-for-zero-indirection tradeoff. `impl Trait`/generic bounds are Rust's *static* dispatch (inlines like any direct call, §35.4); `dyn Trait` is Rust's *dynamic* dispatch, compiling to literally the same vtable-plus-indirect-call mechanism as a C++ virtual function (§14.3) -- not an analogy, the same technique. Trait bounds are checked once, at the generic's own definition (§9.4's original comparison, and the exact gap C++20 concepts, §15.3, closed decades later).

```
 impl Trait / generic<T: Trait>:        dyn Trait:
   direct call, often inlined            vptr load + vtable index + indirect call
   (§3.3's `call` to a known address)     (identical to §14.3's C++ vtable dispatch)
```

## Chapter 27: Testing

`#[test]`/`cargo test` (§10, original material) bake testing into the toolchain the same way `cargo` itself unifies build/package management (§19) -- versus C's no-built-in-framework status quo (Check/CUnit) and C++'s strong-convention-but-still-third-party status quo (GoogleTest/Catch2, §15's original comparison).

## Chapter 28: Closures and Iterators

A Rust closure desugars to an anonymous struct (captured variables as fields) implementing `Fn`/`FnMut`/`FnOnce` -- **the identical mechanism** to a C++ lambda's anonymous class with `operator()` (§18.1) -- both languages converged on the same technique independently. Iterator adaptor chains (`map`/`filter`/`fold`) are verifiably zero-cost the same way C++'s `<algorithm>`/ranges are (§11.3's original comparison, §35.4's godbolt.org methodology) -- paste both a hand-written loop and an iterator chain into Compiler Explorer and diff the output; for well-optimized cases they're identical.

## Chapter 29: Smart Pointers and Interior Mutability

`Box<T>` ~ `unique_ptr<T>`; `Rc<T>`/`Arc<T>` ~ `shared_ptr<T>`, with one real difference: `shared_ptr`'s refcount is *always* atomic in standard C++, where Rust makes the atomic-vs-not choice explicit and separate (`Rc` non-atomic single-threaded-only, `Arc` atomic) (§12.5's original comparison). `RefCell<T>`'s runtime-checked borrow rules have no real C/C++ standard-library analog -- it's Rust choosing a *third* point on the spectrum between C's "no check at all" and the borrow checker's "fully static check," specifically for the cases (like a graph structure with shared, mutable nodes) where full static checking is too restrictive to express the pattern at all. `Deref`/`Drop` (§12.4, original material) are what make `Box`/`Rc` *feel* like ordinary references/RAII objects -- the same operator-overloading-for-ergonomics idea as C++'s own smart pointers, and `Drop`'s guarantee is exactly RAII (§16.1) made compiler-checked.

## Chapter 30: Concurrency -- Send, Sync, Threads, Mutex, RwLock, Atomics

`std::thread`/`Mutex<T>` (§13, original material) share `std::thread`/`std::mutex`'s API shape (§13.4's original comparison) but close the gap C++ leaves open: `Mutex<T>` *wraps* the data rather than sitting beside it, so obtaining `&mut T` at all requires `.lock()` -- "forgot to lock" becomes a type you can't construct rather than a ThreadSanitizer finding. `Send`/`Sync` (§19.3, original material) are the compile-time enforcement mechanism: a type is `Send` if it's safe to transfer across threads, `Sync` if `&T` is safe to share across threads, both auto-derived structurally and both checkable by the compiler at every thread-boundary API (`thread::spawn`'s bound on its closure, for instance) -- turning "did you accidentally share unsynchronized state" from a runtime race (C++'s status quo, §17.2) into a compile error. Rust's atomic types and `Ordering` enum (`Relaxed`/`Acquire`/`Release`/`AcqRel`/`SeqCst`) are, ordering-name for ordering-name, the same vocabulary C++11 introduced (§17.2) -- for the same hardware reason (§1.7's out-of-order execution, §34.5's cache-coherence discussion). `RwLock<T>` extends the same wrapped-data pattern to the reader-writer case: many concurrent `.read()` guards, or one exclusive `.write()` guard, mechanically enforced the same way `Mutex`'s single-guard rule is.

## Chapter 31: Unsafe Rust, Pin, and FFI

### 31.1 Unsafe, Restated Against the Full Machine Model

`unsafe` (§16.1/§19, original material) unlocks exactly five abilities -- and every one of them is something C/C++ code does *by default, everywhere*, with no opt-in (§16.6's original comparison, restated now with Part I's full machine model behind it): raw pointer dereference is §10.2's ordinary C pointer; calling an unsafe function is calling any C function at all, since C has no safety-checked function category to contrast against; mutable statics are C's ordinary non-`const` globals (§7.2); unsafe traits are a Rust-specific bookkeeping mechanism with no C/C++ analog (C/C++ have no `Send`/`Sync` to manually assert in the first place); union field access is C's `union` (§13.3's type-punning discussion), unchecked in both languages identically.

### 31.2 Pin, in Full

`Pin<P>` guarantees the pointee will not move in memory after being pinned -- necessary because an `async fn`'s generated state machine (§33) can be *self-referential*: a local borrowed across an `.await` point becomes a reference stored in a later field, pointing at an earlier field of the *same* struct. Moving such a struct (an ordinary `memcpy`, which is what a ordinary Rust move compiles to, §21.2) would leave that internal reference pointing at the *old* location -- a dangling-pointer bug the type system would otherwise miss entirely. `Pin` closes this specific gap by making "this value's address is now fixed" a type-level, checked property, enforced at exactly the boundary (constructing/polling a `Future`) where it matters.

```
 A self-referential state machine BEFORE Pin existed as a concept:
 ┌─────────────────┐
 │  local: String     │◀───┐
 │  reference: &String │────┘   (points at the SAME struct's own field)
 └─────────────────┘
      moving this struct (ordinary memcpy) would leave `reference`
      pointing at the OLD memory location -- Pin prevents the move
      from being legally expressible in the first place
```

### 31.3 MaybeUninit, Raw Pointers, and transmute

Covered in full in the original §19.1-19.4 material -- provenance and pointer arithmetic (mapped directly onto §3.2's addressing modes and §10.2's C pointer model, just now requiring an explicit `unsafe` block to invoke), `MaybeUninit<T>` (the type-level answer to "I have raw bytes from a syscall/`read()` that aren't a valid `T` yet," a distinction C's `malloc` never bothers to make since it only ever returns uninitialized bytes with no type attached at all), and `transmute` (Rust's explicit, `unsafe`, call-site-visible version of §13.3's C type-punning -- `memcpy`/a checked cast is almost always the better tool, exactly as in C).

### 31.4 FFI, libc, and bindgen

`extern "C"` (§20, original material) opts a function into the System V/Windows ABI (§6) specifically so object code from `rustc` and object code from `gcc`/`clang`/MSVC can call each other at all -- `extern "Rust"` (the implicit default) makes no such cross-compiler promise. `#[repr(C)]` (§22) is the struct-layout half of the same promise. The `libc` crate is pre-declared `extern "C"` bindings for the POSIX/Linux surface; `bindgen` automates generating the same for an arbitrary C header.

### Chapter 31 Notes

**Key Takeaways**
- Every `unsafe` ability corresponds to something C/C++ does unconditionally -- `unsafe` is Rust's opt-in gate on C's default state, not a separate, more dangerous mode.
- `Pin` exists to solve one specific problem (self-referential state machines from `async fn`, §33) that C/C++ never had to solve because neither language generates that kind of compiler-transformed self-referential struct in the first place.
- FFI correctness is entirely a matter of matching the ABI (§6) and layout (§10.4/§22) conventions Parts I-III already built -- there's no additional Rust-specific FFI theory beyond "does this actually match what a C/C++ compiler would produce for the equivalent declaration."

**Common Mistakes**
- Treating `unsafe` as "turn off the borrow checker" broadly -- it doesn't; ordinary borrow-checking still applies inside an unsafe block for everything except the five specific unlocked abilities.
- Forgetting `#[repr(C)]` on a struct crossing an FFI boundary -- without it, Rust's default field-reordering (§22) can silently produce a layout mismatch against the C side's expectations.

**Interview Notes**
- "Why does async Rust need `Pin` but synchronous Rust doesn't?" -- only the compiler-generated `async fn` state machine can end up self-referential across suspend points; ordinary synchronous code never generates that shape of struct.
- "What's the minimum needed to safely call a C function from Rust?" -- an accurate `extern "C"` signature (matching the C header's actual types/ABI expectations) and, for any struct crossing the boundary, `#[repr(C)]` to guarantee matching layout.

## Chapter 32: Macros

`macro_rules!` (§16.5/§16.6, original material) operates on the parsed token tree, not raw text -- structurally closer to a restricted form of C++ template metaprogramming (§15.1) than to C's preprocessor (§11.4), and immune to C's classic macro-hygiene bugs (accidental variable capture, missing-parens precedence errors, silent multiple evaluation of a side-effecting argument) precisely *because* it isn't text substitution. Procedural macros go further still, operating on and generating real AST nodes with full type-system awareness -- closer in raw power to C++ template metaprogramming, safer in practice because the input is always a well-formed token stream, never arbitrary text.

## Chapter 33: Async/Await and Tokio

`async fn` (§23/§29, original material) compiles to a compiler-generated state machine implementing `Future`, structurally identical to a C++20 coroutine's compiler-generated frame (§18.2) -- both exist to make suspension/resumption cheap (a poll is a plain function call, no OS context switch) without one OS thread per concurrent task. `tokio`'s executor/reactor split (§23.3) is the concrete runtime driving that state machine: the executor polls tasks when woken, the reactor (backed by `epoll` on Linux) watches OS-level readiness and calls the right `Waker`. Blocking work inside an async task starves the whole worker thread's other tasks -- a correctness bug, not just a performance one, since scheduling is cooperative (§23.4/§34.6's original framing), requiring `spawn_blocking` for anything that can't yield promptly.

## Chapter 34: no_std, Embedded, and Custom Allocators

`#![no_std]` opts a crate out of the standard library's OS-dependent parts (`std::fs`, `std::thread`, `std::net`, all of which assume a real OS underneath) while keeping `core` (the OS-independent subset: `Option`, `Result`, slices, the ownership/trait system itself) -- the correct starting point for firmware, kernels, or any environment without an underlying OS to make syscalls (§35, Part V/VI) into at all. Without `std`, there's no default global allocator either -- a `no_std` binary that still wants `Box`/`Vec` (heap-allocating types, which live in the separate `alloc` crate, one layer above bare `core`) must supply its own via `#[global_allocator]` (§5.3's original material), commonly a bump allocator (§5.5) over a fixed, statically-reserved memory region, since there's no OS-provided `malloc`/`mmap` to delegate to in the first place. `panic = "abort"` (§25) is the near-universal choice here too -- unwind tables (§17.1's mechanism) assume runtime support that frequently doesn't exist in a bare-metal target.

## Chapter 35: Zero-Cost Abstractions -- Verifying the Claim

The capstone question for all of Part IV: is "zero-cost abstraction" actually true, or marketing? The honest answer, now that you have the full machine model: **verifiably true for the abstractions that are true monomorphization/static-dispatch/compile-time-erasure mechanisms** (generics, ownership, iterators, closures -- all shown, chapter by chapter above, to produce assembly indistinguishable from the hand-written C/C++ equivalent), **and genuinely not zero-cost where the abstraction requires runtime machinery** (`dyn Trait`'s vtable indirection, §26; `Rc`/`Arc`'s refcount operations, §29; a `HashMap`'s probing sequence, §24) -- exactly as true, and for exactly the same reasons, of C++'s equivalent constructs (virtual functions, `shared_ptr`, `unordered_map`). "Zero-cost" was never a claim that *everything* is free -- it's Bjarne Stroustrup's original C++ formulation, which Rust inherited near-verbatim: *what you don't use, you don't pay for, and what you do use, you couldn't hand-code any better.* The verification method is always the same one introduced in §35.4 of the original material: paste both versions into godbolt.org, diff the assembly, and stop taking the claim on faith.

### Chapter 35 Notes

**Key Takeaways**
- "Zero-cost" is a claim about *unused* features costing nothing and *used* features costing no more than a hand-written equivalent -- not a claim that every abstraction is literally free.
- Every genuinely zero-cost Rust abstraction in this Part has a hand-verifiable C/C++ equivalent producing comparable assembly -- that's the actual empirical content of the claim, not a slogan to accept unexamined.
- Where Rust *does* have runtime cost (`dyn Trait`, `Rc`/`Arc`, hash maps), C++ has the *same* cost for the *same* reason (virtual dispatch, `shared_ptr`, `unordered_map`) -- this isn't a Rust weakness, it's a shared, structural cost of the underlying technique in any language.

**Common Mistakes**
- Treating "zero-cost abstraction" as a universal property of the whole language rather than a per-construct claim that holds for some Rust features and not others.
- Never actually checking a zero-cost claim against real generated assembly -- the entire value of §35.4's godbolt.org methodology is turning a slogan into a checkable fact.

**Interview Notes**
- "Name a Rust abstraction that is NOT zero-cost, and explain why." -- `dyn Trait`: it requires a vtable lookup and indirect call at every virtual method invocation, exactly like a C++ virtual function (§14.3) -- the cost is real, just optional (you choose it over `impl Trait`/generics when you specifically need runtime polymorphism).
- "How would you actually verify a zero-cost claim rather than take it on faith?" -- compile both the abstracted and hand-written versions with optimizations on, and diff the emitted assembly (godbolt.org, or `cargo asm`/`objdump` locally, §38) -- if they match, the claim holds for that specific case.

---

# PART V -- Cross-Cutting Systems Concerns

The concerns in this Part apply identically no matter which of C, C++, or Rust generated the code in question -- they live at the OS/hardware boundary (Chapter 36), the hardware-performance boundary (Chapter 37), the tooling layer that inspects any compiled binary regardless of source language (Chapter 38), and the build-orchestration layer (Chapter 39).

## Chapter 36: Operating System Concepts

### 36.1 Processes and Threads

A **process** is an OS-managed unit of isolation: its own virtual address space (§1.8), its own file descriptor table, its own set of OS resources -- created via `fork()` (which duplicates the calling process, using copy-on-write, §1.8, to make that duplication cheap) or, more commonly today, `posix_spawn`/`clone`-with-full-isolation-flags. A **thread** is a unit of *execution* within a process -- threads in the same process share the address space, file descriptors, and most other resources, but each has its *own* stack (§4) and register state (§2), which is exactly the minimum a CPU needs to context-switch between them independently.

### 36.2 Context Switching

Switching the CPU from running one thread to running another means: save the current thread's full register state (including `RIP`/`RSP`, §2.2) somewhere the kernel can find it again, load the next thread's saved register state, and (if switching to a thread in a *different* process) update the MMU's active page-table root so virtual addresses now resolve against the new process's mappings (§1.8) -- that page-table switch is specifically why a cross-process context switch is measurably more expensive than a same-process thread switch, which needs no such TLB-invalidating page-table change.

### 36.3 System Calls

The single mechanism (§3.3's `syscall` instruction, §35.6 of the original Part-VI-bound material) by which userspace code requests kernel services -- file I/O, memory mapping, process/thread creation, networking, and everything else that touches shared or privileged system state. Every I/O call in every language covered in this handbook (`read()`/`fs::read`/`ifstream`) funnels through the same handful of syscalls at the bottom.

### 36.4 Signals

Asynchronous notifications delivered to a process/thread -- `SIGSEGV` (invalid memory access, §1.8's page-fault-to-signal path), `SIGTERM`/`SIGINT` (requested/interactive termination), `SIGCHLD` (a child process changed state), and dozens more. A signal handler runs essentially as an unplanned interruption of whatever the thread was doing, which is precisely why only a narrow set of **async-signal-safe** functions are legal to call from inside one -- and exactly the reason `volatile` (§12.2) is the correct (if limited) tool for a variable a signal handler touches, while a full mutex is not (locking inside a signal handler risks deadlocking against the very thread it interrupted, if that thread already held the lock).

### 36.5 Virtual Memory, Page Faults, and Copy-on-Write

Already built in full in §1.8 -- restated in OS terms here: the kernel maintains each process's page tables; a page fault traps into the kernel, which either satisfies it transparently (lazy allocation, copy-on-write's first-write-triggers-a-real-copy behavior, swapping a page back in from disk) or delivers `SIGSEGV` for a genuinely invalid access. `fork()`'s practical cheapness is a direct, load-bearing consequence of copy-on-write, not an implementation detail you can ignore when reasoning about process-creation cost.

### 36.6 ELF, the Loader, Kernel, and Userspace

ELF's structure (§7.6) and the dynamic linker/loader's job (§8.4) are already covered in full -- restated in OS terms: **kernel space** runs with full hardware privilege (able to execute privileged instructions, touch any physical memory, program the MMU) and hosts the code that services syscalls, manages processes/memory/scheduling, and talks to hardware; **userspace** is everything else, running with the CPU's lower privilege ring, unable to do any of that directly -- which is exactly *why* a syscall (a deliberate, controlled transition into kernel mode) is the only door between the two, rather than userspace code being able to just reach in.

### 36.7 The Scheduler

The kernel component deciding which of the (usually far more numerous) runnable threads actually gets the CPU at any given moment, and for how long, before a **timer interrupt** forces a context switch (§36.2) to give another thread a turn -- this preemptive scheduling is exactly what Chapter 34.6's "cooperative async scheduling" was contrasted against: OS threads *don't* need to voluntarily yield, because the scheduler can and will preempt them regardless, where an async task genuinely must `.await` to ever give another task a turn.

### Chapter 36 Notes

**Key Takeaways**
- A cross-process context switch costs more than a same-process thread switch specifically because of the page-table/TLB invalidation the former requires and the latter doesn't.
- Signal handlers run as an unplanned interruption of arbitrary code -- async-signal-safety constraints (and `volatile`'s role, §12.2) follow directly from that fact.
- The kernel/userspace privilege boundary is *why* syscalls exist as a distinct, deliberate transition mechanism rather than an ordinary function call.

**Common Mistakes**
- Believing `fork()` is inherently expensive because it "copies the whole process" -- copy-on-write (§1.8) makes the actual initial cost small; the cost, if any, shows up later, spread across whichever pages actually get written to by either process.
- Calling non-async-signal-safe functions (`malloc`, most of `printf`) from inside a signal handler -- a classic source of rare, hard-to-reproduce deadlocks/corruption when the interrupted code happened to be inside that same non-reentrant function already.

**Interview Notes**
- "Why is a thread switch within the same process cheaper than a switch between processes?" -- both threads share the same address space/page tables, so no MMU page-table-root change (and the associated TLB implications) is needed, only register-state save/restore.
- "What OS mechanism is responsible for `fork()` being fast despite duplicating a process's entire address space?" -- copy-on-write: pages are shared (marked read-only) until either process writes to one, at which point only that single page is actually copied.

---

## Chapter 37: Performance Engineering

### 37.1 Cache Friendliness

Restated from §1.4, now as an actionable principle: **access memory sequentially wherever possible.** A `Vec<T>`/`std::vector<T>`/C array iterated in order reuses each fetched 64-byte cache line for every element inside it; a linked list, a `HashMap` with a poor hash distribution, or a "chase a pointer" data structure in general faults a new, likely-uncached line on nearly every step -- this single difference frequently dominates over big-O complexity for real-world data sizes that fit comfortably in cache, which is exactly why "just use a `Vec` and linear-scan it" regularly outperforms a theoretically-better-complexity tree/hash structure for genuinely small collections.

### 37.2 Branch Prediction (Practical Application)

Restated from §1.6: sort or partition data before a data-dependent branch inside a hot loop, if you can, to make the branch predictable; where you can't, prefer a branchless idiom (§3.3's `cmov`, or bitwise masking) *specifically* when the branch is genuinely unpredictable *and* both sides are cheap to compute unconditionally -- `cmov` loses to a well-predicted branch, so this is a targeted fix, not a universal one.

### 37.3 False Sharing

Restated from §1.4 and the original §22.4 material: two logically-unrelated variables that happen to share one 64-byte cache line will bounce that line between cores' private caches if different cores write to each variable concurrently -- indistinguishable, performance-wise, from genuine contention over the *same* data, even though there's no actual logical relationship. `#[repr(align(64))]` (Rust) / `alignas(64)` (C++) / manual padding (C) on hot, independently-written fields is the fix, trading memory for eliminating the false dependency.

### 37.4 Memory Bandwidth, Instruction Latency, and Throughput

**Latency**: how many cycles from an instruction starting to its result being available. **Throughput**: how many *independent* instances of that instruction the pipeline (§1.5) can have in flight/complete per cycle, which can be far better than `1/latency` when there are no dependencies between successive instances (superscalar execution). **Memory bandwidth**: the aggregate rate (bytes/second) data can move between DRAM and the CPU -- a genuinely separate ceiling from cache/latency concerns, which becomes the binding constraint for large, sequential, low-arithmetic-intensity workloads (streaming through gigabytes of data doing little computation per byte) rather than any single instruction's cost.

### 37.5 SIMD, Vectorization, and Loop Unrolling

SIMD (§2.4) processes multiple values per instruction; **auto-vectorization** is the compiler's own optimization pass (§9.4) that rewrites a suitable scalar loop into SIMD instructions automatically, when it can prove the iterations are independent (this is exactly where `restrict`, §12.5, and Rust's automatic noalias guarantee, §21.3, matter in practice -- unproven aliasing is one of the most common reasons a loop that *looks* vectorizable doesn't actually get vectorized). **Loop unrolling** -- replicating a loop body several times per iteration of the driving counter -- reduces per-iteration branch/counter overhead and gives the scheduler (§9.5) more independent instructions to overlap; compilers do this automatically under optimization, though it can also be written by hand for cases the compiler's heuristics miss.

### 37.6 Prefetching and Alignment

**Prefetching**: issuing a hint (`prefetcht0` and friends, or the compiler inserting one automatically for a predictable striding access pattern) to start pulling a cache line into L1 *before* it's actually needed, hiding memory latency behind other useful work. **Alignment**: many SIMD load/store instructions have (or historically had) a faster encoding for naturally-aligned addresses (an address that's a multiple of the access width) -- part of why the ABI (§6.4) mandates 16-byte stack alignment at calls, and why allocators commonly over-align larger allocations by default.

### Chapter 37 Notes

**Key Takeaways**
- Cache-friendliness (sequential access) routinely dominates algorithmic complexity for real, cache-sized data -- know both, but check the constant factor before assuming asymptotic complexity settles a performance question.
- False sharing is invisible in source code -- it only shows up in a profiler as unexplained contention between threads touching "unrelated" data, making it one of the harder performance bugs to diagnose without knowing to look for it.
- Aliasing (or the compiler's inability to prove its absence) is one of the most common real-world blockers to auto-vectorization -- this is the direct, practical payoff of `restrict` (§12.5) and Rust's automatic reference-noalias guarantee (§21.3).

**Common Mistakes**
- Optimizing algorithmic complexity while ignoring memory-access pattern -- a worse-complexity, cache-friendly algorithm frequently wins in practice for realistic data sizes.
- Padding every struct field defensively against false sharing "just in case" -- it's a targeted fix for genuinely hot, concurrently-written fields, not a default hygiene practice; over-applied, it just wastes memory and hurts cache-friendliness (§37.1) elsewhere.

**Interview Notes**
- "What's the practical difference between instruction latency and throughput, and when does it matter?" -- latency is the cost of one instruction's dependency chain; throughput matters when you have many *independent* instances that can overlap in the pipeline -- code with long dependency chains is latency-bound, code with lots of independent work is throughput-bound, and they call for different optimization approaches.
- "How would you diagnose false sharing in a profiler?" -- unexplained contention/stalling between threads touching data that has no actual logical relationship, often resolved by checking whether the touched fields share a cache line and padding/aligning them apart if so.

---

## Chapter 38: Debugging and Tooling

A curated reference -- every tool here works identically regardless of whether the binary came from `rustc`, `gcc`, `clang`, or MSVC, because they all operate on the compiled artifact (ELF/PE/Mach-O, §7.6) and/or its debug info, not on the source language.

| Tool | Purpose |
|---|---|
| `gdb` / `rust-gdb` | Interactive debugger -- breakpoints (via `int3`, §3.3), stepping, register/memory inspection, backtraces |
| `lldb` | The macOS/LLVM-ecosystem equivalent of `gdb`, same core capabilities |
| `objdump -d` | Disassemble a binary -- see the actual emitted instructions (§35.7's original methodology) |
| `readelf -l` / `-S` | Inspect ELF program headers (loader's view) / section headers (linker/debugger's view), §7.6 |
| `nm` | List a binary/object file's symbol table (§8.1) -- what's defined, what's still undefined and needs linking |
| `strings` | Dump printable text found in a binary -- a fast, crude way to spot embedded string literals, version info, or (in a security context) hardcoded secrets/URLs |
| `cargo asm` (`cargo-show-asm`) | Rust-specific: view the actual assembly for one function of your own crate, at your actual optimization settings (§35.7) |
| `cargo expand` | Rust-specific: view source *after* macro expansion (§32) -- essential for understanding what a `derive`/procedural macro actually generates |
| `perf` | Linux profiler -- sampling-based CPU profiling, cache-miss/branch-misprediction hardware-counter access, flame-graph generation (`perf record --call-graph dwarf` for correctness on frame-pointer-omitted release builds, §4.4) |
| `valgrind` (`memcheck`) | Dynamic binary instrumentation -- catches memory errors (use-after-free, uninitialized reads, leaks) by running the actual binary under heavy instrumentation; correct but slow (10-50x slowdown), most relevant for C/C++ (Rust's ownership model prevents most of what memcheck exists to catch, though `unsafe` code can still benefit) |
| Sanitizers (`ASan`/`TSan`/`UBSan`/`MSan`) | Compile-time-inserted instrumentation (`-fsanitize=address` etc., or `RUSTFLAGS=-Zsanitizer=address` on nightly Rust) -- catches memory errors (ASan), data races (TSan), UB (UBSan), uninitialized reads (MSan) with far less overhead than Valgrind (2-3x rather than 10-50x), because the checks are compiled in rather than emulated |

### Chapter 38 Notes

**Key Takeaways**
- Every tool in this chapter is language-agnostic at its core -- they inspect compiled artifacts and debug info, which is why a `gdb` session on a Rust binary and a C binary looks the same at the instruction/register level.
- Sanitizers and Valgrind solve overlapping problems at very different performance costs -- sanitizers' compiled-in instrumentation is far cheaper than Valgrind's full emulation, which is why sanitizers are the default choice for CI-integrated checking today.
- `cargo expand` and `cargo asm` are the two tools that make Rust's two biggest "what did the compiler actually do" questions (macro expansion, §32; final codegen, §35) empirically checkable rather than a matter of reading documentation and hoping.

**Common Mistakes**
- Reaching for Valgrind by default on Rust code, when the ownership model already prevents most of the bug classes it exists to catch outside of `unsafe` blocks -- a sanitizer (and Miri, §19.5's original material, for pure UB-in-unsafe-code detection) is usually the better-targeted tool.
- Debugging a release build's confusing backtrace without realizing frame-pointer omission (§4.4) is the cause, and reaching for `perf record --call-graph dwarf` (or rebuilding with frame pointers) instead of assuming the debugger is broken.

**Interview Notes**
- "Why are compiler sanitizers generally preferred over Valgrind for routine CI use?" -- sanitizers instrument at compile time (2-3x slowdown), where Valgrind emulates the entire binary in a virtual CPU (10-50x slowdown) -- both catch real bugs, but sanitizers are cheap enough to run on every CI build.
- "What would you reach for to see what a `#[derive(...)]` macro actually generates?" -- `cargo expand`, which shows the fully macro-expanded source, the direct Rust analog of manually tracing through a C preprocessor's `-E` output.

---

## Chapter 39: Build Systems Compared

| Tool | Category | Role |
|---|---|---|
| `gcc` | Compiler | Compiles C/C++ (and others via frontends) using its own GENERIC/GIMPLE/RTL pipeline (§9.3) |
| `clang` | Compiler | Compiles C/C++ using the LLVM pipeline (§9.2-9.3) -- the same backend Rust uses |
| MSVC (`cl.exe`) | Compiler | Microsoft's own C/C++ compiler and toolchain, primarily Windows-targeted, its own independent pipeline |
| `cargo` | Build tool + package manager + more | Rust's unified tool (§19/§39.1 below) -- invokes `rustc` under the hood |
| `make` | Build tool | Generic, language-agnostic dependency-graph task runner -- executes shell commands based on file-timestamp dependency rules you write yourself |
| `CMake` | Build system *generator* | Doesn't build directly -- generates `make`/`ninja`/MSVC-project files from a higher-level, more portable description |
| `ninja` | Build tool | A deliberately minimal, very fast build-execution engine, usually used as CMake's *generated* backend rather than hand-written directly |
| `meson` | Build system generator | A higher-level, more opinionated alternative to CMake, commonly paired with `ninja` as its backend |

### 39.1 Why Cargo Is Different in Kind, Not Just Degree

Every tool above the `cargo` row is a *compiler* -- it turns source into object code/executables, full stop. Everything from `make` down is purely a *build orchestrator* -- it has no idea what a "crate" or a "package" is; it just runs commands based on file dependencies you specify. `cargo` sits across both roles *and* adds a third (package management/dependency resolution, resolving version constraints across a whole dependency graph, fetching packages from a registry) that C/C++'s ecosystem splits across entirely separate, non-standardized tools (`vcpkg`, `conan`, or simply vendoring source and hoping) -- which is the concrete, mechanical reason "just run `cargo build`" works uniformly across virtually every Rust project's README, where an equivalent C/C++ project's build instructions vary project to project, build-system to build-system.

### Chapter 39 Notes

**Key Takeaways**
- Compilers (gcc/clang/MSVC/rustc) and build orchestrators (make/ninja) solve different problems -- CMake/Meson sit in between, generating orchestrator input from a higher-level description.
- Cargo's uniqueness isn't "a better make" -- it's compiler-invocation, build orchestration, and package management unified in one tool with one standard project layout, a combination C/C++ tooling has never standardized on.

**Common Mistakes**
- Comparing `cargo` to `make` as if they were peers solving the same problem -- `cargo` subsumes what `make`+`CMake`+a package manager together provide in the C/C++ world.
- Assuming CMake *builds* anything itself -- it generates input for an actual build tool (commonly `make` or `ninja`); the actual compilation is always delegated further down the chain.

**Interview Notes**
- "Why does C++ have both CMake and Ninja, doing seemingly similar jobs?" -- they operate at different layers: CMake generates portable build descriptions from a higher-level spec, Ninja is a fast low-level executor of the already-generated concrete build graph.
- "What does Cargo do that make/CMake don't?" -- dependency resolution and fetching (a real package manager's job), a standardized project layout/test/doc convention, and unified invocation of the actual compiler (`rustc`) -- three roles C/C++ tooling keeps as separate, independently-chosen tools.

---

# PART VI -- Applied: Building a Container Runtime in Rust

Everything in Parts I-V is now in service of one concrete project -- the goal named in [systems-engineering.md](../../systems-engineering.md): a container runtime in the spirit of `youki`/`runc`. This Part stops comparing languages and starts building, using Linux syscalls (grounded in §36's OS model and §31's FFI chapter), namespaces, and cgroups as the actual mechanism, with Rust's safety properties (Part IV) applied to code that is, underneath, doing exactly what §21's raw-C mental model already described.

## Chapter 40: Why This Is the Right Capstone

A container runtime touches nearly everything this handbook built: the calling convention and `syscall` instruction (§3.3, §6) at its lowest level; memory layout and FFI (§7, §31.4) for talking to the kernel and to C libraries; process/signal/scheduler OS concepts (§36) as its actual subject matter; concurrency (§30) for the control-plane/API layer; and performance/observability (§37-38) once it's real enough to profile. It is also, deliberately, a project where getting the *safety* story right matters in a way a toy CLI tool's wouldn't: a container-runtime bug is a container-escape vulnerability, which is exactly the CVE-2019-5736 class of bug §14.3/§21's original framing already flagged as the concrete motivation for choosing Rust's ownership model (Part IV) over unmanaged C/C++ for this specific kind of software.

## Chapter 41: Linux Namespaces

### 41.1 What a Namespace Actually Is

Restated from the original conceptual material, now fully grounded in §36's process model: not virtualization in the hardware sense -- no hypervisor, no second kernel. For each of ~8 namespace-able kinds of kernel state (mount table, PID tree, network stack, UTS/hostname, IPC objects, UID/GID mapping, cgroup view, time), the kernel maintains *N* independent instances instead of one global instance; every process carries a namespace ID per kind, and syscalls resolve against whichever instance the calling process is tagged with. This is why containers start in milliseconds where VMs take seconds (§40) -- no second kernel to boot, no page-table-level isolation of an entire address space (§1.8) -- and also why a kernel exploit breaks out of every container on the host at once, unlike a VM escape: the isolation is real but the kernel underneath is still exactly one, shared kernel.

### 41.2 clone/unshare, in Rust via nix

```toml
[dependencies]
nix = { version = "0.28", features = ["sched", "mount", "process", "signal"] }
```

```rust
use nix::sched::{clone, unshare, CloneFlags};
use nix::sys::signal::Signal;

// unshare -- move the CALLING process into new namespaces
unshare(CloneFlags::CLONE_NEWNS      // mount namespace
      | CloneFlags::CLONE_NEWUTS     // hostname
      | CloneFlags::CLONE_NEWPID     // pid namespace (affects children, not self)
      | CloneFlags::CLONE_NEWNET     // network namespace
).expect("unshare failed");

// clone -- create a CHILD directly into new namespaces (what a runtime actually uses,
// since CLONE_NEWPID only takes effect for processes created AFTER the call)
let mut stack = [0u8; 1024 * 1024];
let child_pid = unsafe {
    clone(
        Box::new(child_fn),
        &mut stack,
        CloneFlags::CLONE_NEWPID | CloneFlags::CLONE_NEWNS | CloneFlags::CLONE_NEWUTS,
        Some(Signal::SIGCHLD as i32),
    )
}.expect("clone failed");
```

Every field here is exactly what §6.2's SysV ABI and §31.4's FFI chapter told you to expect: `clone` is an ordinary `extern "C"` function underneath (`nix` is a safe wrapper over `libc`, which is a thin wrapper over the raw `syscall` instruction, §3.3), the `unsafe` block is required because `clone`'s child-runs-a-closure-on-a-manually-provided-stack contract is exactly the kind of invariant §31.1 flagged as unverifiable by the compiler.

### 41.3 setns -- Joining an Existing Namespace

```rust
use nix::sched::{setns, CloneFlags};
use std::fs::File;
use std::os::unix::io::AsRawFd;

let ns_file = File::open("/proc/1234/ns/net").unwrap();
setns(ns_file.as_raw_fd(), CloneFlags::CLONE_NEWNET).unwrap();
// used by `docker exec`-style tooling to run a new process inside a running container
```

### 41.4 Mount Namespace, chroot, and pivot_root

```rust
use nix::mount::{mount, MsFlags};
use nix::unistd::{chdir, pivot_root};

// make mount propagation private first, or changes leak to the host
mount::<str, str, str, str>(None, "/", None, MsFlags::MS_REC | MsFlags::MS_PRIVATE, None).unwrap();

mount(Some(rootfs), rootfs, None::<&str>, MsFlags::MS_BIND | MsFlags::MS_REC, None::<&str>).unwrap();
chdir(rootfs).unwrap();
pivot_root(".", "old_root").unwrap();   // preferred over chroot() -- properly changes the mount tree root
chdir("/").unwrap();
```

`chroot` only changes where root-relative path lookups resolve -- it was never a security boundary, since a privileged process can escape it via well-known fd tricks. `pivot_root` actually detaches the old root from the process's mount tree entirely (a genuinely different, stronger operation, not just a stricter `chroot`), which is why every real container runtime uses it.

### Chapter 41 Notes

**Key Takeaways**
- A namespace is per-resource-type kernel state replication, not hardware virtualization -- cheap, but sharing one underlying kernel with every other namespace on the host.
- `clone` with namespace flags, not `unshare` followed by `fork`, is the correct tool when you need `CLONE_NEWPID` to actually take effect for the new process, since PID-namespace changes only apply going forward to newly created processes.
- `pivot_root` is not "a safer `chroot`" -- it's a structurally different operation (detaching the old mount-tree root entirely) that `chroot` never performed.

**Interview Notes**
- "Why does a container start faster than a VM?" -- no second kernel boot, no hardware-level address-space virtualization -- just per-resource-type kernel bookkeeping being redirected to a new instance for the calling process.
- "Why is `chroot` insufficient as a container security boundary?" -- it only changes path resolution, not the actual mount namespace; a privileged process retains well-known ways to escape it that `pivot_root` closes off.

## Chapter 42: cgroups v2

### 42.1 Accounting vs. Limiting

cgroups do two genuinely different jobs, restated from the original conceptual material and now tied to §36's OS model: **accounting** -- the kernel counts resource usage per cgroup as a side effect of normal operation, exposed as plain files (`memory.current`, `cpu.stat`), one `read()` syscall (§36.3) away, no polling overhead on the kernel's side; **limiting** -- the kernel actively enforces a ceiling (`memory.max` triggers the OOM-killer scoped to that cgroup; `cpu.max` throttles via the CFS bandwidth controller, the same CFS scheduler §36.7 already introduced), the mechanism that makes "this container has 512MB" an *enforced* fact.

### 42.2 The Unified Hierarchy

cgroups v1's flaw: each controller (cpu, memory, blkio) had its own independent hierarchy, so one process could sit at unrelated tree positions depending on which resource you asked about. v2 collapses this to one hierarchy -- every process sits at exactly one path, controllers attach to nodes within that single tree.

### 42.3 Plain File I/O

```rust
use std::fs;

let cg = "/sys/fs/cgroup/mycontainer";
fs::create_dir_all(cg).unwrap();
fs::write(format!("{cg}/cgroup.procs"), pid.to_string()).unwrap();     // move pid in
fs::write(format!("{cg}/memory.max"), "512M").unwrap();                // set memory limit
fs::write(format!("{cg}/cpu.max"), "100000 100000").unwrap();          // 1 CPU worth
```

No special crate needed -- cgroups v2 is a filesystem interface. `cgroups-rs` wraps this in a typed API once the raw mechanics (above) feel automatic.

### Chapter 42 Notes

**Key Takeaways**
- Accounting and limiting are separate cgroup capabilities that happen to share the same filesystem interface -- don't conflate "I can read usage" with "usage is being enforced."
- cgroups v2's single unified hierarchy is a direct simplification over v1's per-controller-hierarchy chaos -- one path uniquely identifies a container's full resource-limit state.

**Interview Notes**
- "What actually enforces a container's memory limit?" -- the kernel's OOM-killer, scoped to fire within the cgroup specifically, triggered by `memory.max` being exceeded -- not a userspace monitoring loop.
- "Why did cgroups v2 move to a single hierarchy?" -- v1 let a process occupy inconsistent positions across independent per-controller trees; v2 makes one path the single source of truth for all of a process's resource-controller memberships.

## Chapter 43: Capabilities and Seccomp

```rust
use caps::{Capability, CapSet};
caps::drop(None, CapSet::Bounding, Capability::CAP_SYS_ADMIN).unwrap();   // drop before exec
```

Linux capabilities split root's traditionally all-or-nothing privilege into ~40 independent bits (`CAP_SYS_ADMIN`, `CAP_NET_ADMIN`, `CAP_SYS_PTRACE`, ...) -- a runtime drops everything a container doesn't need *before* the container's actual process runs, following the same least-privilege principle behind every access-control system. Seccomp (via `seccomp-rs`/`libseccomp-rs`) goes a level deeper, filtering *which syscalls* (§36.3) a process may invoke at all, independent of capabilities -- mirroring `runc`'s default seccomp profile, which blocks dozens of rarely-needed, historically-exploited syscalls outright.

## Chapter 44: Minimal Container Skeleton

```rust
fn create_container(rootfs: &str, cmd: &[&str]) -> nix::Result<Pid> {
    let mut stack = vec![0u8; 1024 * 1024];
    let flags = CloneFlags::CLONE_NEWPID
        | CloneFlags::CLONE_NEWNS
        | CloneFlags::CLONE_NEWUTS
        | CloneFlags::CLONE_NEWNET
        | CloneFlags::CLONE_NEWIPC;

    unsafe {
        clone(
            Box::new(|| {
                pivot_root_into(rootfs);
                setup_cgroup_limits();
                drop_capabilities();
                let prog = CString::new(cmd[0]).unwrap();
                let args: Vec<CString> = cmd.iter().map(|s| CString::new(*s).unwrap()).collect();
                execvp(&prog, &args).unwrap();   // replaces this process image entirely
                0
            }),
            &mut stack,
            flags,
            Some(Signal::SIGCHLD as i32),
        )
    }
}
```

`execvp` is the syscall that *replaces* the current process's image entirely (§36.6's ELF loading, run again, in place, for the new program) -- everything before it in the closure (pivot_root, cgroup setup, capability drop) had to happen *first*, in the still-privileged, still-runtime-controlled process, because there's no "come back and lock things down" after `execvp` succeeds -- it doesn't return. This mirrors the exact lifecycle `youki`/`runc` implement for OCI `create`/`start` (§48). Read `youki`'s `libcontainer` crate next to this section.

## Chapter 45: Process Supervision and Signals -- Being PID 1

### 45.1 Why This Matters

A container's init process inherits PID 1's kernel responsibilities inside its own PID namespace (§41): default signal disposition changes (unhandled signals are ignored rather than fatal, unless a handler is installed), and orphaned grandchildren get reparented to it. A runtime that ignores this leaks zombies (§36.1-36.2's process model) until the container is killed.

### 45.2 Reaping Zombies

```rust
use nix::sys::wait::{waitpid, WaitPidFlag, WaitStatus};
use nix::unistd::Pid;

fn reap_zombies() {
    loop {
        match waitpid(Pid::from_raw(-1), Some(WaitPidFlag::WNOHANG)) {
            Ok(WaitStatus::StillAlive) => break,
            Ok(WaitStatus::Exited(pid, code)) => { tracing::info!(?pid, code, "reaped child"); }
            Ok(_) => continue,
            Err(nix::errno::Errno::ECHILD) => break,
            Err(e) => { tracing::error!(?e, "waitpid failed"); break; }
        }
    }
}
```

### 45.3 signalfd -- Signals Inside an Event Loop

Traditional signal handlers can't safely call most functions (async-signal-safety, §36.4). `signalfd` turns signal delivery into a readable fd, composing with `epoll`/`tokio` (§33's reactor model) instead of a handwritten handler.

```rust
use nix::sys::signalfd::{SignalFd, SfdFlags};
use nix::sys::signal::{SigSet, Signal};

let mut mask = SigSet::empty();
mask.add(Signal::SIGCHLD);
mask.add(Signal::SIGTERM);
mask.thread_block().unwrap();

let mut sfd = SignalFd::with_flags(&mask, SfdFlags::SFD_NONBLOCK).unwrap();
if let Ok(siginfo) = sfd.read_signal() {
    // siginfo.ssi_signo tells you which signal fired; SIGCHLD -> reap_zombies()
}
```

### 45.4 Signal Forwarding

```rust
use nix::sys::signal::{kill, Signal};
use nix::unistd::Pid;

fn forward(container_init_pid: Pid, sig: Signal) -> nix::Result<()> {
    kill(Pid::from_raw(-container_init_pid.as_raw()), sig)   // negative pid == signal the whole process group
}
```

A runtime must forward signals it receives (e.g. `docker stop` sending SIGTERM) into the container's namespace, targeting the process group so the container's own init gets a chance to shut down cleanly before an eventual SIGKILL.

## Chapter 46: Container Networking

### 46.1 Netlink

`ip link`/`ip addr`/`ip route` are thin wrappers over netlink sockets -- `rtnetlink` gives programmatic access to the same kernel interface.

```toml
rtnetlink = "0.14"
tokio = { version = "1", features = ["rt", "macros"] }
```

```rust
use rtnetlink::new_connection;

#[tokio::main]
async fn main() -> Result<(), rtnetlink::Error> {
    let (connection, handle, _) = new_connection().unwrap();
    tokio::spawn(connection);

    handle.link().add().veth("veth-host".into(), "veth-ctr".into()).execute().await?;

    let mut links = handle.link().get().match_name("veth-ctr".into()).execute();
    if let Some(link) = links.try_next().await? {
        handle.link().set(link.header.index).setns_by_pid(container_pid).execute().await?;
    }
    Ok(())
}
```

### 46.2 Configuring the Interface Inside the Namespace

```rust
handle.address().add(veth_ctr_index, "172.17.0.2".parse().unwrap(), 24).execute().await?;
handle.link().set(veth_ctr_index).up().execute().await?;
handle.route().add().v4()
    .destination_prefix("0.0.0.0".parse().unwrap(), 0)
    .gateway("172.17.0.1".parse().unwrap())
    .execute().await?;
```

### 46.3 Bridge and NAT

```rust
handle.link().add().bridge("cbr0".into()).execute().await?;
handle.link().set(veth_host_index).master(bridge_index).execute().await?;
```

Outbound NAT typically still goes through `iptables`/`nftables` rules (shell out, or the `rustables` crate) -- most runtimes delegate this specific piece to CNI plugins rather than reimplementing it.

## Chapter 47: eBPF for Observability and Security

```toml
aya = "0.13"
aya-log = "0.2"
```

```rust
// eBPF side, compiled to a BPF target and loaded into the kernel
#[kprobe]
pub fn trace_execve(ctx: ProbeContext) -> u32 {
    match try_trace_execve(ctx) { Ok(ret) => ret, Err(ret) => ret }
}
```

```rust
// userspace side -- loads and attaches the compiled BPF program
use aya::programs::KProbe;
let mut bpf = aya::Bpf::load(include_bytes_aligned!("../target/bpfel/trace_execve"))?;
let program: &mut KProbe = bpf.program_mut("trace_execve").unwrap().try_into()?;
program.load()?;
program.attach("sys_execve", 0)?;
```

Two payoffs for a container runtime: **observability** -- trace every syscall (§36.3) a container makes without modifying the workload, feeding directly into §37's performance-analysis toolkit; **security** -- an eBPF-based syscall filter enforces policy at a finer grain than the static seccomp profiles of §43. Treat this as an optional, later-stage addition -- get the core runtime (§41-45) working first.

## Chapter 48: OCI Runtime Design Patterns

### 48.1 The create/start Split

```rust
enum ContainerState { Creating, Created, Running, Stopped }

trait Runtime {
    fn create(&mut self, id: &str, bundle: &Path) -> Result<()>;
    fn start(&mut self, id: &str) -> Result<()>;
    fn kill(&mut self, id: &str, sig: Signal) -> Result<()>;
    fn delete(&mut self, id: &str) -> Result<()>;
    fn state(&self, id: &str) -> Result<ContainerState>;
}
```

`create` and `start` are split because OCI requires the container process to *exist* (so its pid is known, hooks/cgroup setup can happen) before the user's actual command starts running -- exactly why §44's clone'd child blocks on a pipe/socket read before its `execvp`, rather than exec'ing immediately.

### 48.2 Error Handling Shape

```rust
#[derive(thiserror::Error, Debug)]
enum RuntimeError {
    #[error("namespace setup failed: {0}")]
    Namespace(#[from] nix::Error),
    #[error("cgroup write failed: {0}")]
    Cgroup(#[from] std::io::Error),
}

fn run() -> anyhow::Result<()> {
    let bundle = load_bundle(path).context("failed to load OCI bundle")?;
    Ok(())
}
```

`thiserror` for library code callers need to match on (variant-shaped errors, §25's Result model); `anyhow` for binary/CLI-level code that just needs ergonomic `?`-propagation with context, not a variant for every leaf error.

### 48.3 Key Crates

| Crate | Purpose |
|---|---|
| `nix` | Safe(r) wrappers over syscalls: clone, mount, setns, signals |
| `libc` | Raw FFI bindings (§31.4) when `nix` doesn't cover something |
| `oci-spec` | Typed (de)serialization of `config.json` / the OCI runtime spec |
| `caps` | Linux capabilities get/set/drop (§43) |
| `cgroups-rs` | Typed cgroups v1/v2 management (§42) |
| `thiserror` / `anyhow` | Error types -- library vs. binary, respectively |
| `tokio` | Async runtime (§33) for the control-plane/API side |
| `tracing` | Structured logging/spans (§51) for a long-running daemon |

## Chapter 49: Testing and Fuzzing Syscall-Heavy Code

### 49.1 Fuzzing the Config Parser

```toml
libfuzzer-sys = "0.4"
```

```rust
#![no_main]
use libfuzzer_sys::fuzz_target;

fuzz_target!(|data: &[u8]| {
    if let Ok(s) = std::str::from_utf8(data) {
        let _ = serde_json::from_str::<oci_spec::runtime::Spec>(s);
    }
});
```

The `config.json` parsing path takes untrusted input and needs no privileges to fuzz -- unlike the syscall path itself, making it the natural first fuzz target.

### 49.2 Integration-Testing Namespace Code

```rust
// rootless testing via a user namespace first -- CLONE_NEWUSER lets an
// unprivileged process gain the other namespace capabilities inside it
unshare(CloneFlags::CLONE_NEWUSER | CloneFlags::CLONE_NEWNS | CloneFlags::CLONE_NEWPID)?;

#[test]
#[cfg_attr(not(feature = "integration"), ignore)]
fn pivot_root_into_minimal_rootfs() { /* ... */ }
```

Build one tiny static busybox-based rootfs fixture, checked into the repo or fetched in CI, rather than a full distro image -- keeps privileged/namespace tests fast and hermetic.

## Chapter 50: Static Linking and Cross-Compilation

```bash
rustup target add x86_64-unknown-linux-musl
cargo build --release --target x86_64-unknown-linux-musl
```

```toml
# .cargo/config.toml
[target.x86_64-unknown-linux-musl]
linker = "musl-gcc"
```

A fully static binary avoids a dynamic-glibc-version mismatch (§8.3's static-vs-dynamic-linking tradeoff, now applied concretely) when the runtime binary needs to run against arbitrary/minimal root filesystems. Caveats: `getaddrinfo`/NSS-based DNS resolution behaves differently under musl -- rarely relevant for the runtime binary itself, which isn't doing DNS lookups.

## Chapter 51: Observability -- Structured Tracing

```toml
tracing = "0.1"
tracing-subscriber = { version = "0.3", features = ["json", "env-filter"] }
```

```rust
use tracing::{info, instrument};

#[instrument(skip(spec), fields(container_id = %id))]
fn create(id: &str, spec: &Spec) -> anyhow::Result<()> {
    info!("setting up namespaces");
    setup_namespaces()?;
    info!("applying cgroup limits");
    apply_cgroups()?;
    Ok(())
}

fn main() {
    tracing_subscriber::fmt()
        .json()
        .with_env_filter(tracing_subscriber::EnvFilter::from_default_env())
        .init();
}
```

`#[instrument]` creates a span per call with entry/exit timing automatically -- across `create`/`start`/`kill`/`delete` this gives per-operation latency for free, feeding directly into §37's performance-analysis toolkit with no hand-rolled timing code.

## Chapter 52: End-to-End Skeleton

A condensed shape of one `create` call, annotated with exactly which prior chapter each line's material comes from:

```rust
fn create_container(id: &str, spec: &Spec) -> anyhow::Result<Pid> {
    let rootfs = &spec.root.path;

    // §41: clone into new namespaces; child blocks on a pipe read
    // until `start` is called, per §48.1's create/start split
    let (sync_r, sync_w) = nix::unistd::pipe()?;
    let child = unsafe {
        clone(Box::new(move || {
            nix::unistd::read(sync_r, &mut [0u8; 1]).unwrap();   // wait for `start`

            pivot_root_into(rootfs).unwrap();                     // §41.4
            drop_capabilities(&spec.linux.capabilities).unwrap(); // §43
            configure_loopback_and_iface().unwrap();               // §46.2

            let prog = CString::new(spec.process.args[0].clone()).unwrap();
            execvp(&prog, &to_cstrings(&spec.process.args)).unwrap();
            unreachable!("execvp replaces this process or returns Err above");
        }),
        &mut stack, namespace_flags(&spec), Some(Signal::SIGCHLD as i32),
    )}?;

    apply_cgroup_limits(id, child, &spec.linux.resources)?;   // §42, from the PARENT
    register_supervised_child(child);                           // §45.2/45.4

    Ok(child)   // `start` later writes to sync_w, unblocking the child's execve
}
```

## Chapter 53: A Staged Learning Path

Maps this handbook's Parts, plus the book list in [systems-engineering.md](../../systems-engineering.md), into a build order that keeps theory and hands-on Rust close together rather than front-loading all theory first.

**Phase 0 -- The full machine model.** Parts I-III of this handbook, cover to cover, even the parts that feel like review of things you already knew from C/C++ -- everything downstream cites this constantly, and having it genuinely automatic (not just "recognized when explained") pays off immediately once you're reading kernel C or debugging a segfault at the instruction level.

**Phase 1 -- Syscalls, in Rust, immediately.** Read TLPI's chapters on processes/fork/exec/namespaces *alongside* Chapter 41 above -- for each syscall TLPI covers in C, write the Rust (`nix`) equivalent yourself before moving to the next chapter, rather than reading the whole book first and translating later.

**Phase 2 -- Unsafe, FFI, and the Rust-specific books.** *Rust for Rustaceans* + *Programming Rust*, read against Chapter 31 above. Do this before namespaces/cgroups get serious -- you'll be writing plenty of `unsafe`, and want the invariants internalized before you're mid-debug.

**Phase 3 -- Build a minimal container by hand.** Chapter 44 as a skeleton: fork/clone into new namespaces, `pivot_root` into a rootfs, apply a cgroup memory limit, `execve` a shell. Read *Container Security* (Liz Rice) and *Linux Kernel Programming*'s cgroup chapters in parallel -- they explain the *why* behind what you just made work.

**Phase 4 -- Study youki/runc source in parallel.** Once your toy container works, read youki's `libcontainer` crate end to end. Every difference between your version and theirs is a concrete question to chase down.

**Phase 5 -- Concurrency and the control plane.** *Rust Atomics and Locks* against Chapter 30, then build the async API/event-watching layer (Chapter 33) on top of the synchronous container-launch core from Phases 3-4. *C++ Concurrency in Action* pays off here too, by contrast -- the same problems, solved without the borrow checker.

**Phase 6 -- Performance and production concerns.** *Systems Performance* + *BPF Performance Tools* once something real exists to profile -- flame-graph your own runtime's container-start latency (Chapter 37/38), not a toy benchmark.

Keep §48.3's crate table as the running reference for what to reach for at each phase instead of hand-rolling syscall wrappers from scratch.

