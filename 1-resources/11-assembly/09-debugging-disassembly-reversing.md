# Debugging, Disassembly, and Reading Unfamiliar Assembly

Prerequisite: handbook §4.4 (frame-pointer omission, and why it breaks naive stack walking) and §38 (the handbook's own debugging-tools chapter -- `gdb`/`objdump`/`readelf`/`nm`/`perf`/sanitizers at the level of "what each tool is for"). This file is the instruction-level workflow: what you actually type, what the output means, and how to approach a piece of assembly you've never seen before.

## gdb at the Instruction Level

```bash
gdb ./hello
```

```
(gdb) break _start                  # or `break main`, or `break *0x401234` for a raw address
(gdb) run
(gdb) disassemble                    # disassemble the current function, Intel syntax by
                                       # default varies -- set with the next command
(gdb) set disassembly-flavor intel     # gdb defaults to AT&T; this switches to match NASM/
                                         # this handbook's convention (handbook §3.1)
(gdb) stepi                            # step ONE INSTRUCTION (not one source line -- "si" for short)
(gdb) nexti                            # like stepi, but steps OVER a `call` instead of into it
(gdb) info registers                    # dump all GPRs, RIP, RFLAGS
(gdb) p $rax                             # print a single register's current value
(gdb) x/4xg $rsp                          # examine memory: 4 units, hex format, giant(8-byte) size,
                                            # starting at RSP -- i.e., dump the top of the stack
(gdb) x/5i $rip                             # examine memory as 5 INSTRUCTIONS starting at RIP --
                                              # a quick disassembly window around where you are
(gdb) watch *(int*)0x404050                  # hardware watchpoint (handbook-adjacent [05]'s
                                               # debug-register mechanism) -- break on WRITE
```

`x/NFU addr` (examine) is the single most useful raw command: **N** = count, **F** = format (`x` hex, `d` decimal, `i` instruction, `s` string, `c` char), **U** = unit size (`b`/`h`/`w`/`g` = byte/halfword/word/giant = 1/2/4/8 bytes). `x/20i $rip` is the standard "show me what's about to execute" command when you land somewhere unfamiliar (a signal handler, a crash site, a `.so`'s entry point).

**Reading a raw crash**: `SIGSEGV` at an unfamiliar address, `bt` (backtrace) shows nothing useful (a stripped binary, or corrupted stack, or frame-pointer-omitted release code handbook §4.4 warns about) -- `x/i $rip` shows the actual faulting instruction; `p $rdi`/`p $rsi`/etc. shows what it was operating on; cross-referencing the faulting address against `info proc mappings` (which memory region is this address even *in* -- heap, stack, an unmapped gap) is usually the fastest way to a diagnosis (a wild pointer into unmapped space vs. a legitimate-looking address that's simply the wrong *type* of data are different bug classes with different likely causes).

## objdump -d in Practice

```bash
objdump -d -M intel ./hello       # -M intel: Intel syntax (default is AT&T, handbook §3.1)
```

```
0000000000401000 <_start>:
  401000: b8 01 00 00 00       mov    eax,0x1
  401005: bf 01 00 00 00        mov    edi,0x1
  40100a: 48 be 20 20 40 00 00 00 00 00   movabs rsi,0x402020
  401014: ba 0e 00 00 00         mov    edx,0xe
  401019: 0f 05                    syscall
```

The three columns matter: the **address** (useful for correlating with a crash address or a `gdb` breakpoint), the **raw bytes** (the actual machine code -- useful for understanding instruction length/encoding, and for the manual byte-patching technique handbook §4.1's `int3` note describes), and the **decoded mnemonic**. `objdump -d` disassembles the whole binary's `.text`; `objdump -d --start-address=0x401000 --stop-address=0x401020` narrows to a range; `objdump -dS` (with `-g`-compiled debug info present) interleaves original source lines with the disassembly -- the single best command for "what did my C/Rust code actually compile to" without leaving the terminal.

```bash
objdump -t ./hello        # symbol table (like nm, but as part of objdump's unified interface)
objdump -R ./hello          # dynamic relocations (handbook §8.2) -- what the loader will patch
readelf -d ./hello            # dynamic section: DT_NEEDED entries (handbook §8.3's dependency list)
```

## Compiler Explorer as a Learning Tool

godbolt.org (referenced already in handbook §3.3 and §9.4) is the fastest practical loop for connecting source-level code to the instructions this whole library describes: paste a small C/C++/Rust function, pick a compiler and optimization level, and see the exact generated assembly, with source-to-asm highlighting. The single most useful habit for internalizing everything in this library: **write a guess for what a piece of source code compiles to, then check it on Compiler Explorer** -- for e.g. verifying handbook §3.3's claim that `x / 4` compiles to a shift while `x / y` compiles to `idiv`, or [`02`](02-simd-vector-programming.md)'s claim that a simple sum loop auto-vectorizes at `-O3` with AVX2 enabled but not at `-O2`.

## A Basic Reverse-Engineering Workflow

Given an unfamiliar stripped-or-not binary:

1. **`file ./binary`** -- architecture, static/dynamic, stripped or not.
2. **`readelf -h`** -- ELF type (`EXEC` vs. `DYN`/PIE, handbook §8.6), entry point address.
3. **`nm ./binary`** or **`objdump -t`** -- if not stripped, symbol names are enormously more useful than raw addresses; note which symbols are `U` (undefined, imported, handbook §8.1) vs. defined locally.
4. **`ldd ./binary`** -- what shared libraries does it depend on (handbook §8.3) -- often a strong hint about what the program *does* (linked against `libssl` -> does crypto/TLS; against `libpcap` -> does packet capture).
5. **`objdump -d -M intel`** on the interesting functions (usually `main`, or whatever calls into the libraries identified in step 4) -- read it as a sequence of the instruction families from [`01`](01-instruction-reference-deep.md): find the `cmp`/`jcc` pairs (branches -- what conditions does this code check), the `call` targets (what does it invoke, and in what order), and any recognizable constant (a fixed string length, a magic number, a syscall number from [`04`](04-syscalls-os-interface.md)'s table).
6. For anything beyond a small function, a full disassembler with a graph view and cross-reference tracking (**Ghidra**, free, produces a genuinely useful pseudo-C decompilation alongside the raw disassembly; **radare2**/its `r2ghidra`-equipped GUI **Cutter**; **IDA** commercially) becomes worth the setup cost -- `objdump`/`gdb` are the right tools for "I know roughly where to look and want to confirm a detail," not for cold-reading an entire unfamiliar multi-thousand-instruction binary from scratch.

This workflow is exactly what CTF "reversing" challenges and legitimate malware/vulnerability-research triage both use as a starting point -- the skill is the same regardless of whether the goal is "understand this challenge binary" or "understand this software I have legitimate authorization to analyze" ([`12`](12-security-exploitation-primer.md) picks this up specifically in the security/CTF context).

## Reading Assembly You've Never Seen: A Checklist

When you land in the middle of an unfamiliar function in a disassembler or debugger:

- **Find the prologue/epilogue** (handbook §4.3) to establish the frame boundaries -- or confirm there isn't one (handbook §4.4, frame-pointer-omitted code), in which case track `rsp` offsets directly instead of `rbp`-relative ones.
- **Identify the calling convention position of each register** at entry (handbook §6.2) -- `rdi`/`rsi`/`rdx`/`rcx`/`r8`/`r9` at a function's very first instructions are almost certainly still holding the original arguments, before the function has done anything to them.
- **Follow the `cmp`/`test` + `jcc` pairs** ([`01`](01-instruction-reference-deep.md)'s condition table) to reconstruct the original `if`/`while`/`match` shape -- a chain of `cmp reg, N` / `je .case_N` blocks is almost always a `switch`/`match` lowered to a comparison chain (or, for a dense range of cases, a **jump table**: `jmp [table + reg*8]`, worth recognizing on sight since it looks structurally different from a comparison chain but serves the same purpose).
- **Note any `lea`** and ask whether it's a genuine address computation or just fast arithmetic (handbook §3.3) -- a `lea` feeding directly into another arithmetic instruction, with no subsequent memory access through it, is the "fast arithmetic" case.
- **Watch for the zeroing idiom** (`xor reg, reg`, handbook §3.3) so you don't misread it as "read `reg` into itself" -- it's `reg = 0`.

## Key Takeaways

- `gdb`'s `x/NFU` command family (examine memory/instructions in a chosen format and unit size) is the single highest-value raw command to be fluent in -- most other debugging workflows reduce to variations of "look at this address as instructions" or "look at this address as data."
- `objdump -dS` (interleaving source with disassembly) closes the loop between every abstract claim in this library and the literal instructions a real compiler emits for it -- it's the fastest way to verify, rather than just believe, a claim like "this compiles to a `cmov`."
- Reading unfamiliar assembly is pattern recognition over the exact vocabulary built up across this library and the handbook -- prologues, calling-convention register roles, condition-code chains, and the zeroing/lea-as-arithmetic idioms account for the large majority of what you'll see in ordinary (non-obfuscated) compiled code.

## Interview Notes

- "How would you find out what a stripped binary's `main`-equivalent function does, with no symbols to guide you?" -- start from the ELF entry point (`readelf -h`), which for a dynamically-linked binary is typically `_start` calling into libc's startup, which calls the actual `main` -- follow the `call` chain from there, or look for the function called once, early, taking `argc`/`argv`-shaped arguments (`edi`=int count, `rsi`=pointer array) as a heuristic.
- "What's the practical difference between using `objdump` and a decompiler like Ghidra?" -- `objdump` gives raw, complete, trustworthy disassembly with no interpretation; a decompiler adds a (heuristic, occasionally wrong) reconstruction of higher-level control flow and variable/type inference on top, trading some accuracy risk for dramatically faster comprehension of large, unfamiliar functions.
