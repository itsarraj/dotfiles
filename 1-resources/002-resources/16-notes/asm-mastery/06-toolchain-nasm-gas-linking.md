# Toolchain in Practice: NASM, GAS, and Linking a Real Binary

Prerequisite: handbook §3.1 (Intel vs. AT&T syntax) and §8 (linking concepts: object files, relocation, static/dynamic, the loader, PLT/GOT, PIC/PIE). This file is the hands-on counterpart -- actual assembler syntax, actual directives, actual commands to go from a `.asm` file to a running binary.

## The Three Assemblers

| Assembler | Default syntax | Typical use |
|---|---|---|
| **NASM** (Netwide Assembler) | Intel | The most common choice for hand-written standalone assembly on Linux/macOS/Windows -- clean syntax, good documentation, this file's primary tool |
| **GAS** (GNU Assembler, `as`) | AT&T (supports `.intel_syntax noprefix` to switch) | What `gcc`/`clang` emit internally when compiling C/C++/Rust to assembly (`-S` flag) -- you'll meet GAS syntax constantly when reading compiler output even if you never hand-write it |
| **MASM** (Microsoft Macro Assembler) | Intel | Windows-specific, tied to Visual Studio's toolchain -- relevant if you're targeting Windows specifically; not covered in depth here since this handbook's toolchain focus is Linux |

## NASM Syntax and Directives

```asm
section .data                 ; initialized data (-> ELF .data, handbook §7.2)
    greeting db "Hello, world!", 10, 0   ; db = define byte(s); 10 = '\n', 0 = null terminator
    count    dd 42                        ; dd = define doubleword (32-bit)
    big_num  dq 0x1122334455667788        ; dq = define quadword (64-bit)

section .bss                  ; uninitialized data (-> ELF .bss, handbook §7.2)
    buffer resb 256             ; resb = reserve N bytes, uninitialized

section .rodata                ; read-only data (-> ELF .rodata, handbook §7.2)
    pi dq 3.14159265358979

section .text                  ; code (-> ELF .text, handbook §7.2)
global _start                    ; export this symbol (visible to the linker, handbook §8.1)
extern printf                     ; declare a symbol defined elsewhere, to be resolved at link time

_start:
    mov rax, 1
    mov rdi, 1
    mov rsi, greeting
    mov rdx, 14
    syscall
    mov rax, 60
    xor rdi, rdi
    syscall
```

- **`section`** (or `segment`) switches which output section subsequent bytes go into -- directly the ELF sections from handbook §7.2, one-to-one.
- **`global name`** marks `name` as an exported symbol (an ELF `T`/`D`-type entry visible to the linker, handbook §8.1) -- without it, a label is local to the object file and the linker can't resolve external references to it.
- **`extern name`** declares that `name` is defined *elsewhere* and should be left as an unresolved reference (a relocation entry, handbook §8.2) for the linker to patch in.
- **`db`/`dw`/`dd`/`dq`** define byte/word(16-bit)/doubleword(32-bit)/quadword(64-bit) data.
- **`resb`/`resw`/`resd`/`resq`** reserve (uninitialized) space of the same widths -- these go in `.bss` specifically because reserved-but-unspecified bytes are exactly what `.bss` is for (handbook §7.2's "not actually stored in the file" point).
- **`equ`** defines a compile-time constant: `msg_len equ $ - msg` computes "current address minus `msg`'s address," the standard NASM idiom for "the length of the string literal I just wrote," entirely resolved by the assembler with no runtime cost.
- **`times N instr`** repeats `instr` N times -- commonly used for padding/alignment (`times 16-($-$$) db 0`, aligning to a 16-byte boundary by computing how many zero bytes are needed to get there).

### NASM Macros

```asm
%macro syscall3 4
    mov rax, %1
    mov rdi, %2
    mov rsi, %3
    mov rdx, %4
    syscall
%endmacro

; usage:
syscall3 1, 1, greeting, 14      ; expands to the four-instruction write() sequence above
```

`%macro name argcount` / `%endmacro` defines a textual-substitution macro (`%1`-`%9` reference positional arguments) -- purely an assembler-time convenience, expanded before assembly proper begins, with zero runtime overhead; the assembled output is identical to having written the expansion by hand. NASM also supports `%define` (simple text/constant substitution, C-preprocessor-`#define`-equivalent) and conditional assembly (`%ifdef`/`%endif`) for the same "compile-time configuration" purposes the C preprocessor serves (handbook §11.4).

## GAS (AT&T) Syntax

The same program's data/text sections in GAS, since this is what you'll actually see reading `gcc -S` output:

```gas
    .section .data
greeting:
    .asciz "Hello, world!\n"    # .asciz = null-terminated string (like NASM's db ..., 0)

    .section .text
    .globl _start                # note: .globl, not NASM's "global"
_start:
    movq $1, %rax
    movq $1, %rdi
    leaq greeting(%rip), %rsi     # RIP-relative addressing (handbook §3.2), GAS syntax
    movq $14, %rdx
    syscall

    movq $60, %rax
    xorq %rdi, %rdi
    syscall
```

Directive-name differences to expect: `.globl` (not `global`), `.section`, `.byte`/`.word`/`.long`/`.quad` (not `db`/`dw`/`dd`/`dq`), `.asciz`/`.ascii` (null-terminated vs. not), `.equ` (not `equ`), `.align`. GAS also accepts `.intel_syntax noprefix` at the top of a file to write Intel-syntax operands while keeping GAS's directive names -- a genuinely useful middle ground when you want Intel operand order without switching assemblers entirely.

## Assembling and Linking, End to End

```bash
# NASM: assemble to an object file (ELF64 format)
nasm -f elf64 hello.asm -o hello.o

# Link with ld directly (no libc at all -- _start is the literal entry point,
# handbook §8.4's loader jumps straight here, no libc startup code runs first)
ld hello.o -o hello

./hello
```

`nasm -f elf64` produces a genuine object file (handbook §8.1) -- inspect it exactly like compiler output:

```bash
nm hello.o          # symbol table: greeting, count, _start, etc.
objdump -d hello.o     # disassembly, confirming the assembled bytes match intent
readelf -S hello.o      # section headers -- .text, .data, .bss all present
```

Linking with **`gcc` instead of raw `ld`** is the more common real-world path once you're mixing hand-written assembly with C or want libc available (`printf`, `malloc`, ...):

```bash
gcc hello.o -o hello        # gcc acts as a driver: invokes ld with the right default
                                # flags, libc paths, and CRT startup objects automatically
```

Using `gcc` as the linker driver pulls in the C runtime startup objects (`crt1.o`/`crti.o`/`crtn.o`) that set up the environment `main` expects (argc/argv, `__libc_start_main`) -- which is exactly why a hand-written assembly file linked this way needs a `main` symbol, not `_start`, if it wants libc's setup to have already run before it gets control (`_start` is the *true*, libc-free entry point; `main` is a libc convention layered on top, handbook §8.4-adjacent).

## Static vs. Dynamic Linking, Hands-On

```bash
# Dynamic (default): the binary records a dependency on libc.so.6,
# resolved by the dynamic linker (handbook §8.4) at process start
gcc hello.c -o hello_dynamic
ldd hello_dynamic          # shows libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6

# Static: libc's actual code is copied into the executable at link time
gcc -static hello.c -o hello_static
ldd hello_static            # "not a dynamic executable" -- no runtime dependency at all
file hello_static           # noticeably larger; genuinely self-contained
```

The static build is meaningfully larger on disk and forgoes the shared-page memory savings from handbook §7.5, but produces a binary with zero runtime dependency on the target machine's libc version -- the practical tradeoff behind, e.g., statically-linked Go/Rust-with-musl binaries shipped in minimal container images, where "no libc mismatch possible" outweighs the size cost.

## A Worked PIC/PIE Example

Handbook §8.6 explains *why* position-independent code uses RIP-relative addressing; here's the concrete before/after:

```asm
; NOT position-independent: hard-codes an absolute address, requires
; relocation at load time (or fails outright in a PIE binary loaded
; at a randomized base, since this address was computed at LINK time
; against an assumed fixed base)
mov rax, [0x404050]

; position-independent: computed relative to RIP, correct no matter
; where the loader actually places this code in memory
lea rax, [rel my_var]      ; NASM's `rel` keyword forces RIP-relative addressing
mov rax, [rax]
```

```bash
nasm -f elf64 pic_example.asm -o pic_example.o
gcc -pie pic_example.o -o pic_example    # -pie: build a Position-Independent Executable
gcc -no-pie pic_example.o -o pic_fixed    # contrast: a traditional fixed-base executable
```

Compare `readelf -h` on both: the PIE binary's `Type` field reads `DYN` (shared-object-shaped, loaded at a runtime-chosen base, exactly like a `.so`) while the non-PIE binary reads `EXEC` (a fixed load address baked in) -- a directly observable confirmation of handbook §8.6's ASLR mechanism.

## Key Takeaways

- NASM directives map almost one-to-one onto ELF sections (handbook §7.2) -- `section .data`/`.bss`/`.rodata`/`.text` in the source *are* the sections in the output object file, not an abstraction over them.
- `global`/`extern` in NASM are the source-level spelling of exactly the symbol-table entries and relocations handbook §8.1-8.2 describe -- an unresolved `extern` symbol is a relocation entry the linker must satisfy or it fails with "undefined reference."
- Linking via `gcc` instead of raw `ld` isn't just convenience -- it changes which entry point and startup machinery your code needs to cooperate with (`_start` vs. `main`), because it pulls in libc's CRT startup objects.
- `readelf -h`'s `Type: DYN` vs. `Type: EXEC` is the direct, inspectable evidence of whether a binary is PIE (ASLR-eligible) or not.

## Interview Notes

- "What's the practical difference between assembling with NASM directly vs. compiling C with `-S` and looking at GAS output?" -- different syntax (Intel vs. AT&T) and different directive names for the same underlying ELF concepts; the object-file-level result (sections, symbols, relocations) is equivalent.
- "Why would a hand-written `_start`-based assembly program fail if you tried to call libc's `printf` from it directly?" -- libc's own initialization (`__libc_start_main`, run as part of the CRT startup objects `gcc` normally links in ahead of `main`) hasn't executed, so libc's internal state isn't set up; `_start` bypasses that whole layer by design.
- "How do you tell from a built binary whether it's PIE?" -- `readelf -h`'s ELF type: `DYN` means PIE (position-independent, loadable at any base), `EXEC` means a traditional fixed-base executable.
