# Writing Real Programs by Hand

Prerequisite: [`06`](06-toolchain-nasm-gas-linking.md) (assembling/linking), [`04`](04-syscalls-os-interface.md) (syscalls), handbook §4 (stack frames), §6.2 (SysV function-call ABI). This file works through progressively more realistic hand-written programs -- the actual exercise that turns "I've read about the stack" into "I can write a function." All NASM/Intel syntax, assembled per [`06`](06-toolchain-nasm-gas-linking.md).

## A Function With a Real Stack Frame

Implementing `int32_t sum_to_n(int32_t n)` -- `1 + 2 + ... + n` -- with an explicit prologue/epilogue matching handbook §4.3 exactly:

```asm
; int32_t sum_to_n(int32_t n)  -- SysV ABI: n in EDI, return in EAX
sum_to_n:
    push rbp                ; prologue (handbook §4.3)
    mov rbp, rsp
    sub rsp, 16               ; local storage: [rbp-4]=total, [rbp-8]=i

    mov dword [rbp-4], 0        ; total = 0
    mov dword [rbp-8], 1         ; i = 1

.loop:
    mov eax, [rbp-8]
    cmp eax, edi                ; i vs n
    jg .done                     ; if i > n, exit loop

    mov eax, [rbp-4]
    add eax, [rbp-8]              ; total += i
    mov [rbp-4], eax

    add dword [rbp-8], 1           ; i += 1
    jmp .loop

.done:
    mov eax, [rbp-4]              ; return value in EAX (handbook §6.2)
    mov rsp, rbp                    ; epilogue (handbook §4.3)
    pop rbp
    ret
```

Every piece here is a direct instance of a rule from earlier files: `edi` holding the argument is handbook §6.2's SysV convention; `[rbp-4]`/`[rbp-8]` are base+offset addressing (handbook §3.2) into the frame handbook §4.2 diagrams; the loop condition is exactly the `cmp`+`jg` pattern from [`01`](01-instruction-reference-deep.md)'s condition-code table (signed greater-than, since `n`/`i` are `int32_t`).

## Arrays and the Scaled-Index Addressing Mode

Summing an array of `int32_t` -- the direct hand-written version of handbook §3.2's "`arr[i]` compiles to one instruction via scaled-index addressing" claim:

```asm
; int32_t sum_array(const int32_t *arr, size_t len)  -- arr in RDI, len in RSI
sum_array:
    xor eax, eax           ; accumulator = 0 (handbook §3.3's xor-zero idiom)
    xor rcx, rcx             ; i = 0
.loop:
    cmp rcx, rsi
    jge .done
    add eax, [rdi + rcx*4]     ; arr[i] -- base(rdi) + index(rcx)*scale(4), one instruction
    inc rcx
    jmp .loop
.done:
    ret
```

No stack frame at all here -- this is a **leaf function** (calls nothing else) using only caller-saved registers it's free to clobber, so there's nothing to save/restore and no need to even touch `rsp` (handbook §6.5's red zone would apply if it needed scratch stack space, which it doesn't).

## A Hand-Written String Routine

`size_t my_strlen(const char *s)`, using the `scasb`/`repne` pattern from [`01`](01-instruction-reference-deep.md):

```asm
my_strlen:
    mov rdi, rdi          ; s is already in rdi (SysV 1st arg) -- scasb's implicit operand
    mov rcx, -1             ; "unbounded" count (repne stops on match, not count exhaustion)
    xor al, al               ; scan for the byte 0 (null terminator)
    cld                       ; clear direction flag: scasb advances RDI forward
    repne scasb                ; repeat scasb while NOT equal to AL, decrementing RCX

    ; RDI now points ONE PAST the null terminator; RCX = -1 - (chars scanned) - 1
    mov rax, rdi
    sub rax, rdi_start          ; (pseudocode: subtract the original rdi to get the length)
    dec rax                      ; correct for RDI having advanced one past the terminator
    ret
```

(A fully correct version needs to save the original `rdi` before `scasb` advances it -- shown slightly simplified here to keep the `repne scasb` mechanism visible; the point is seeing the string-instruction family from [`01`](01-instruction-reference-deep.md) actually driving a real loop instead of a bare description.) In practice, real `strlen` implementations use SIMD ([`02`](02-simd-vector-programming.md)) for performance, but this `repne scasb` version is the direct, literal translation of "scan bytes until you find the null" and is exactly what compilers emitted for `strlen` for decades before SIMD versions became standard in libc.

## Recursion in Pure Assembly

`int32_t factorial(int32_t n)`, showing an actual `call` to itself, real stack growth, and the caller-saved-register discipline handbook §6.2 requires:

```asm
factorial:
    push rbp
    mov rbp, rsp
    push rdi              ; save n across the recursive call (RDI is caller-saved --
                             ; the recursive call is free to clobber it, so WE must save
                             ; the value we still need after it returns)

    cmp edi, 1
    jg .recurse
    mov eax, 1               ; base case: factorial(0) = factorial(1) = 1
    jmp .done

.recurse:
    dec edi
    call factorial              ; factorial(n-1), result in EAX
    pop rdi                       ; restore our n (this ALSO pops the stack slot we pushed)
    imul eax, edi                  ; eax = factorial(n-1) * n
    jmp .epilogue

.done:
    add rsp, 8                     ; discard the pushed rdi (base case never popped it)
.epilogue:
    mov rsp, rbp
    pop rbp
    ret
```

Watching `rsp` here across a few levels of recursion is the concrete version of handbook §4.5/§4.6: each call pushes a return address (`call`) plus a saved `rbp` plus the saved `rdi` -- a real, bounded-by-stack-size amount of memory per level, and `factorial` as written has no tail-call shape the compiler could collapse (the `imul` happens *after* the recursive call returns, so it's not a tail call at all -- matching handbook §4.6's point that TCO only applies when there's genuinely nothing left to do after the call).

## Mixing a NASM Object With a C main

The realistic way hand-written assembly gets used: as a callable function from a higher-level language, following the SysV ABI as the contract (handbook §6.1) that makes this possible with zero glue code.

```c
// main.c
#include <stdio.h>
extern int32_t sum_to_n(int32_t n);   // implemented in sum.asm, ABI-compatible

int main(void) {
    printf("%d\n", sum_to_n(10));      // prints 55
    return 0;
}
```

```bash
nasm -f elf64 sum.asm -o sum.o
gcc main.c sum.o -o combined       # gcc links C's compiled main.o and the hand-assembled sum.o
                                     # together -- neither knows or cares the other exists
                                     # as anything other than an ABI-compatible symbol
./combined                            # 55
```

Nothing here requires the assembler and compiler to know about each other -- `extern`/`global` (NASM, [`06`](06-toolchain-nasm-gas-linking.md)) plus `extern` (C) plus the shared SysV calling convention (handbook §6.2) is the entire mechanism, exactly as handbook §6.1 describes an ABI's purpose. The same `sum.o` links identically against a Rust binary declaring `extern "C" { fn sum_to_n(n: i32) -> i32; }` -- the ABI is the actual contract, not the source language on either side.

## Key Takeaways

- Writing a function by hand forces every abstract fact from the handbook (calling convention, stack frame layout, addressing modes, condition codes) to become a concrete, checkable line of code -- this is the fastest way to convert "I've read this" into "I actually know this."
- A leaf function that touches no memory it didn't receive as arguments needs no prologue/epilogue at all -- `sum_array` above is a real example of handbook §6.5's red-zone-eligible, frame-pointer-free code, not a simplification for teaching purposes.
- Recursion in hand-written assembly makes the caller-saved/callee-saved distinction (handbook §6.2) unavoidable to get right: `factorial`'s explicit `push rdi`/`pop rdi` around the recursive call exists *because* `RDI` is caller-saved and the call is free to clobber it.
- Mixing hand-written assembly with C/Rust needs nothing beyond `extern`/`global` symbol declarations on both sides and agreement on the ABI -- there's no special interop layer because the ABI *is* the interop layer.

## Interview Notes

- "Why does `factorial` need to save `n` across its own recursive call, but `sum_array` doesn't need to save anything across its loop?" -- `sum_array`'s loop never calls another function, so nothing it's using can be clobbered by anyone else; `factorial`'s recursive call is a real function call, free under the ABI to clobber any caller-saved register (including `RDI`, which still holds a value `factorial` needs after the call returns).
- "What makes two object files from different languages/compilers linkable into one binary?" -- agreement on the ABI (handbook §6) for anything crossing the boundary: register/stack argument conventions, name mangling (or the lack of it, via `extern "C"`), and nothing else -- the linker just matches symbol names and patches relocations (handbook §8.1-8.2), with no language-awareness at all.
