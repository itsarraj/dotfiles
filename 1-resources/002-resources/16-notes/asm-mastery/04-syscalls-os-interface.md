# System Calls: The syscall Instruction and the Linux x86-64 ABI

Prerequisite: handbook §3.3 (the `syscall`/`int n` one-liners) and §6.2 (the SysV *function-call* ABI -- a genuinely different convention from the *syscall* ABI this file covers; don't conflate them). This file is the full treatment: exact register usage, the actual mechanism `syscall` uses to enter the kernel, a working syscall table, error handling, and how this differs on Windows.

## Why the Syscall ABI Is a Different Convention From the Function-Call ABI

It's tempting to assume "calling the kernel" works like calling any other function, but it can't: a syscall crosses a **privilege boundary** (ring 3 userspace to ring 0 kernel, §5), and the kernel is not compiled by, or linked against, your program at all -- there's no symbol resolution, no relocations, nothing from §8 applies. The interface has to be something that works identically no matter what compiled the calling code: a fixed register convention, agreed once, for the life of the kernel ABI (Linux has famously never broken this contract -- "we don't break userspace" is close to an inviolable rule of Linux kernel development, which is exactly why a syscall-number table from a decade-old kernel version is still accurate today).

## The syscall Instruction, Mechanically

`syscall` is a purpose-built fast system-call instruction (its predecessor, `sysenter`, and the legacy `int 0x80` software-interrupt mechanism handled the same job through the slower general interrupt machinery, §5):

```
 1. CPU saves RIP into RCX, and RFLAGS into R11.
 2. CPU loads RIP and CS/SS (code/stack segment) from fixed MSRs
    (Model-Specific Registers, §5) the kernel configured at boot --
    this is how the CPU knows WHERE in the kernel to jump to, without
    any lookup or indirection at the instruction level.
 3. Privilege level switches from ring 3 to ring 0.
 4. Execution resumes inside the kernel's syscall entry point.
```

`sysret` is the matching return instruction, restoring `RIP` from `RCX` and `RFLAGS` from `R11` and dropping back to ring 3 -- which is exactly why `syscall` **clobbers `RCX` and `R11`** as a side effect of its own mechanism: they're not "randomly" clobbered registers in the calling convention below, they're physically *used* by the instruction pair itself to stash the return address and flags across the privilege-level switch.

## The Linux x86-64 Syscall Calling Convention

| Register | Role |
|---|---|
| `RAX` | Syscall number on entry; return value on exit |
| `RDI` | 1st argument |
| `RSI` | 2nd argument |
| `RDX` | 3rd argument |
| `R10` | 4th argument (**not `RCX`** -- `RCX` is unusable here, since `syscall` itself clobbers it to hold the return address, §above; this is the one deliberate divergence from the ordinary SysV function-call argument order, handbook §6.2, which uses `RCX` as its 4th integer argument register) |
| `R8` | 5th argument |
| `R9` | 6th argument |
| `RCX`, `R11` | Clobbered by the `syscall`/`sysret` mechanism itself (§above) -- never usable as argument registers |

Up to six arguments, all in registers, no stack spilling for a 7th (unlike the function-call ABI) -- syscalls needing more data than that pass a pointer to a struct instead (e.g. `clone3`'s arguments are packed into a `struct clone_args` the kernel reads from a pointer).

## A Working Syscall Table

A handful of the syscalls you'll actually reach for writing raw assembly or reading disassembly, x86-64 Linux numbers (`arch/x86/entry/syscalls/syscall_64.tbl` in the kernel source is the authoritative list):

| Number (`RAX`) | Name | `RDI` | `RSI` | `RDX` |
|---|---|---|---|---|
| 0 | `read` | fd | buf ptr | count |
| 1 | `write` | fd | buf ptr | count |
| 2 | `open` | path ptr | flags | mode |
| 3 | `close` | fd | -- | -- |
| 9 | `mmap` | addr | length | prot |
| 10 | `mprotect` | addr | len | prot |
| 11 | `munmap` | addr | length | -- |
| 12 | `brk` | new break addr | -- | -- |
| 39 | `getpid` | -- | -- | -- |
| 60 | `exit` | status code | -- | -- |
| 231 | `exit_group` | status code | -- | -- |
| 57 | `fork` | -- | -- | -- |
| 59 | `execve` | path ptr | argv ptr | envp ptr |

```asm
; write("Hello\n", 6) to stdout (fd 1), then exit(0)
section .data
    msg db "Hello", 10       ; "Hello\n"
    msg_len equ $ - msg

section .text
global _start
_start:
    mov rax, 1          ; syscall number: write
    mov rdi, 1           ; fd: stdout
    mov rsi, msg          ; buffer
    mov rdx, msg_len       ; count
    syscall

    mov rax, 60          ; syscall number: exit
    mov rdi, 0            ; status 0
    syscall
```

(A fully worked, assembled-and-linked version of this -- including why `_start` rather than `main`, and why there's no libc here at all -- is in [`07`](07-writing-real-programs.md) and [`06`](06-toolchain-nasm-gas-linking.md).)

## Error Handling: The Negative-`errno` Convention

Unlike libc wrapper functions (which return `-1` and set the global `errno`), **raw Linux syscalls return their error directly as a negative value** in `RAX` -- a failed `open` doesn't return `-1` with `errno` set somewhere else, it returns e.g. `-2` (`-ENOENT`) directly. This is a clean, single-value, thread-safe encoding (no global mutable state needed at the kernel boundary at all) -- `errno` as a *separate* per-thread variable is purely a libc-level convenience layered on top, splitting the negative return into "return `-1`" plus "stash the actual code in `errno` for `strerror()` et al. to read later." Code making raw syscalls (bypassing libc entirely, as in [`07`](07-writing-real-programs.md)'s examples) must check `rax` for a value in the small negative range corresponding to `<errno.h>`'s codes directly, with no `errno` variable involved at all.

## Legacy int 0x80

Before `syscall` (introduced with x86-64/AMD64), 32-bit x86 Linux used `int 0x80` -- a software interrupt that traps through the general interrupt-descriptor-table mechanism (§5) rather than the purpose-built fast path, with syscall arguments in `EBX`/`ECX`/`EDX`/`ESI`/`EDI`/`EBP` and the number in `EAX`. It still *works* on 64-bit Linux today, for backward compatibility with 32-bit binaries, but is meaningfully slower (the general interrupt path costs more cycles to enter/exit than the dedicated `syscall`/`sysret` instruction pair) and essentially never deliberately used in new 64-bit code -- if you see it in disassembly, you're almost certainly looking at a 32-bit binary or a very old reference.

## The vDSO

Some "syscalls" that are called extremely frequently and don't strictly need a full privilege-level switch (`gettimeofday`, `clock_gettime`, `getcpu`) are implemented via the **vDSO (virtual dynamic shared object)** -- a small shared library the kernel maps into every process's address space that implements these calls as *ordinary userspace function calls*, reading data the kernel keeps updated in a shared memory page, entirely avoiding the `syscall` instruction and its ring-transition cost for the common case. This is why `clock_gettime` in a profiler trace shows up as a fast userspace call rather than a syscall-cost entry despite conceptually "asking the kernel for the time" -- it's a deliberate, load-bearing optimization for exactly the kind of call a program might make millions of times.

## How libc Wraps This

`printf`/`read`/`open`/etc. in C (and, transitively, most of what Rust's `std` does for I/O) are thin wrappers: marshal arguments into the register convention above, execute `syscall`, and translate a negative return into libc's `-1`-plus-`errno` convention. The wrapper functions themselves are ordinary functions following the *function-call* ABI (§6.2) on their way in -- it's only the last step, inside the wrapper, that switches to the syscall convention. This is why you can call `write(fd, buf, len)` from C using ordinary function-call syntax and register passing, while the *actual* kernel entry two instructions later inside that wrapper uses a different register assignment (`R10` instead of `RCX` for the 4th argument, notably) that you'd only ever see by stepping into the wrapper in a disassembler.

## Windows Contrast

Windows has **no stable, documented direct syscall ABI** for ordinary applications -- syscall numbers have changed between Windows versions and even between builds, deliberately, specifically to *discourage* bypassing the supported API surface. The documented, stable interface is the **Win32 API** (`kernel32.dll`, `user32.dll`, etc.), which itself calls into `ntdll.dll`'s `Nt*`/`Zw*` functions, which *those* eventually execute the actual `syscall`/`sysenter` instruction into the NT kernel -- but that innermost layer is explicitly unsupported and unstable across versions. This is a genuine, deliberate design difference from Linux's "the raw syscall table is itself the stable ABI, forever" stance, and it's the reason malware analysis and anti-cheat/EDR tooling on Windows cares so much about `ntdll.dll` specifically: it's the lowest stable-enough layer to hook, since going one level lower (direct `syscall` with hand-computed numbers) is exactly the technique used to *evade* hooks placed at the `ntdll` layer -- included here purely as a fact about why the two platforms' syscall interfaces differ architecturally, not as usage guidance.

## Key Takeaways

- The syscall ABI and the function-call ABI are two different, independently-designed conventions that happen to share a platform and mostly-overlapping register names -- `R10` instead of `RCX` for the 4th syscall argument is the direct, mechanical consequence of `syscall` itself clobbering `RCX`.
- Raw syscalls return errors as a negative value directly in `RAX`; the separate `errno` variable is a libc-level convenience built on top, not a kernel-level concept.
- The vDSO exists specifically to avoid the ring-transition cost for extremely hot, read-mostly kernel data (the time, the running CPU) -- a deliberate optimization visible as "this syscall doesn't actually show up as a syscall" in a trace.
- Linux's syscall table is a permanently stable ABI by policy ("don't break userspace"); Windows deliberately keeps the equivalent layer unstable and pushes stability up to the Win32 API instead -- a real platform-level design difference, not an oversight on either side.

## Interview Notes

- "Why does the Linux x86-64 syscall convention use `R10` instead of `RCX` for the 4th argument, when the ordinary function-call ABI uses `RCX`?" -- because the `syscall` instruction itself clobbers `RCX` (and `R11`) to hold the return address and flags across the ring transition, making it physically unusable as an argument register in that specific context.
- "How does a raw syscall report an error, and how is that different from what `errno` does?" -- a negative value directly in `RAX`; `errno` is a separate, later, libc-level convention that splits that into `-1` plus a stashed code, not something the kernel itself sets.
- "Why is `int 0x80` still present on 64-bit Linux if `syscall` replaced it?" -- backward compatibility for running actual 32-bit binaries, which predate the `syscall` instruction's introduction; new 64-bit code has no reason to use it.
