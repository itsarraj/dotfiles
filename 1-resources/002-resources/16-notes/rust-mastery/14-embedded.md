# Embedded Rust: no_std, embedded-hal, RTIC, Interrupts, DMA, and Bare Metal

Prerequisite: handbook §34 (`#![no_std]`, the `alloc` crate, custom global allocators). This file covers what's above and below that: the hardware-abstraction ecosystem, real-time scheduling, and what actually runs before `main` on bare metal.

## The no_std/alloc/std Layering, Restated for Embedded

```
 core   -- always available: Option, Result, slices, the trait/ownership system itself,
            NO heap, NO OS assumptions whatsoever (works on a microcontroller with no
            allocator and no operating system underneath at all)
 alloc  -- Box, Vec, String, etc. -- requires a #[global_allocator] to be registered
            (handbook §5.3/§34), but STILL makes no OS assumptions otherwise
 std    -- filesystem, threads, networking, environment variables -- assumes a real OS
            underneath providing syscalls for all of this; NOT available on bare metal
```

Most embedded Rust code is `#![no_std]` with `alloc` (if the target has enough RAM to justify a heap at all -- many microcontroller projects avoid heap allocation entirely, preferring fixed-capacity, stack- or static-allocated data structures specifically to make memory usage fully predictable and avoid fragmentation, handbook §5.4, on a device with only kilobytes of RAM and no swap to fall back on).

## embedded-hal: The Hardware Abstraction Layer

`embedded-hal` defines a set of **traits** (not implementations) for common peripheral interfaces -- `SpiBus`, `I2c`, `DigitalOutputPin`, `PwmPin`, and similar -- so that a driver crate (say, for a specific temperature sensor communicating over I2C) can be written **once**, generically over `impl embedded_hal::i2c::I2c`, and work unmodified across any microcontroller whose vendor-specific HAL crate implements that same trait for its actual hardware I2C peripheral. This is the exact same "one generic trait, many concrete backends" pattern §12's `tower::Service`/`serde` material describes for networking/serialization, applied here to hardware peripherals -- a sensor driver crate depends only on `embedded-hal`'s traits, never on any specific chip's register layout, which is what lets the embedded Rust ecosystem have genuinely portable driver crates instead of needing a rewrite per supported microcontroller.

## Interrupts

A microcontroller's CPU, on receiving a hardware interrupt (a timer expiring, a byte arriving on a UART, a GPIO pin's level changing), immediately suspends whatever it was executing and jumps to a registered **interrupt service routine (ISR)** -- the bare-metal analog of handbook §36.4's OS-level signal handling, but with no OS underneath to mediate it: the ISR *is* directly what the CPU jumps to, at the hardware level, with none of an OS's signal-delivery machinery in between. Rust embedded code registers ISRs via attributes the target's HAL/PAC (Peripheral Access Crate, below) provides (`#[interrupt]` in many Cortex-M HALs), and -- exactly like signal handlers in the OS-hosted case -- an ISR interrupting arbitrary "normal" code means sharing any state between the two requires the same careful discipline `volatile`/atomics provide at the OS level (handbook §12.2/§30), just with even less runtime infrastructure available to lean on (no OS-provided synchronization primitives to fall back on if the target has no OS at all).

## RTIC (Real-Time Interrupt-driven Concurrency)

A framework specifically for structuring interrupt-driven embedded applications *safely*, without a general-purpose OS's scheduler: RTIC uses the target's own hardware **interrupt priority levels** as its scheduling mechanism directly (a higher-priority interrupt preempts a lower-priority one, with no separate software scheduler needed at all) and, critically, uses Rust's type system and a compile-time-computed **resource priority ceiling** analysis to guarantee **data-race freedom between tasks sharing resources, without runtime locks** -- if RTIC's analysis proves two tasks that share a resource can never actually preempt each other in a way that would race (based on their configured priorities), no lock is needed at all, and the compiler generates direct, lock-free access; where preemption genuinely could cause a race, RTIC requires (and enforces, at compile time) that access go through its resource-management API instead. This is a genuinely different *mechanism* than the OS-level `Mutex`/atomics in Part IV/§06 (no runtime lock, no OS scheduler at all) achieving an analogous *goal* (no data races) via static, compile-time-provable priority analysis specific to interrupt-driven hardware scheduling.

## DMA (Direct Memory Access)

Ordinarily, moving data between a peripheral (a UART, an ADC, a network controller) and memory requires the CPU to execute an instruction per unit of data transferred -- **DMA** lets a dedicated hardware controller move data directly between a peripheral and memory *without* CPU involvement for each individual transfer, freeing the CPU to do other work while a bulk transfer (say, filling a buffer from an ADC sampling continuously) proceeds in the background, and issuing an interrupt (above) only once the whole transfer completes. This is the embedded-hardware-level analog of the completion-based I/O model (§07/§10's IOCP/io_uring material) -- "submit an operation, get notified when the whole thing is done, no per-unit involvement required" is the same underlying idea, implemented in hardware silicon here rather than in an OS kernel.

## Memory-Mapped I/O and Peripheral Registers

On nearly all microcontrollers, hardware peripherals are controlled by reading and writing specific, fixed memory addresses -- a peripheral's control/status registers are simply mapped into the same address space ordinary RAM occupies, so "configure the UART's baud rate" is, at the instruction level, an ordinary store instruction to a specific address, and "check if a byte has arrived" is an ordinary load from another specific address. This is exactly the scenario handbook §12.2's `volatile` chapter was built for: **every** access to a memory-mapped peripheral register must be `volatile` (reads must actually happen every time, since the "same" address can return a genuinely different value on each read as hardware state changes; writes must actually happen and in program order, since writing the same value twice can have real hardware side effects the compiler mustn't elide as "redundant") -- embedded Rust's **PAC (Peripheral Access Crate)**, typically auto-generated from the chip vendor's machine-readable register description (an SVD file), wraps every register access in the correct `volatile` read/write automatically, so application code interacts with typed, safe-feeling register accessors rather than hand-writing raw `volatile` pointer dereferences throughout.

## Bare Metal and the Bootloader

On a microcontroller with no OS at all, there is no `main` in the ordinary hosted sense to jump to automatically -- the very first thing that runs after reset is a **reset handler**, at an address the hardware's boot sequence is wired to jump to unconditionally, whose job is to perform the minimum setup an ordinary hosted program's runtime would otherwise do invisibly for you: initialize the stack pointer, copy `.data`'s initial values from flash into RAM (handbook §7.2 -- on a microcontroller, `.data`'s initializers live in flash, not RAM, and must be explicitly copied at startup since flash and RAM are physically distinct memories, unlike a conventional OS's unified virtual address space), zero-fill `.bss`, and only then call into the actual `fn main() -> !` (the `!` return type, handbook §16.3's "never type," reflecting that on bare metal there genuinely is nowhere for `main` to return *to* -- there's no OS to hand control back to). The `cortex-m-rt` crate (for ARM Cortex-M targets) provides exactly this reset-handler-and-startup-sequence boilerplate, so application code can simply write an ordinary-looking `#[entry] fn main() -> ! { loop { /* ... */ } }` without hand-writing the assembly-level startup sequence every project would otherwise need to duplicate.

## Key Takeaways

- `embedded-hal`'s trait-based abstraction is the same "one generic interface, many backends" idea as `tower`/`serde` (§12), applied to hardware peripherals -- it's what makes driver crates portable across microcontroller vendors.
- RTIC achieves data-race freedom without runtime locks by using compile-time priority-ceiling analysis over the hardware's own interrupt priority levels -- a genuinely different mechanism than OS-level `Mutex`/atomics for the same underlying goal.
- Every memory-mapped peripheral register access must be `volatile`, and PACs exist specifically to wrap that correctly and automatically rather than requiring hand-written raw volatile pointer code throughout an application.
- The reset handler does, explicitly and by hand (via `cortex-m-rt` or equivalent), everything a hosted OS's process-startup sequence does invisibly: set up the stack, initialize `.data`, zero `.bss`, then call `main`.

## Interview Notes

- "Why must every access to a memory-mapped peripheral register be `volatile`?" -- because the same address can return different values on successive reads as hardware state changes, and writes can have real side effects even when writing an "unchanged" value -- without `volatile`, the compiler could legally cache a stale read in a register or eliminate a "redundant" write, both of which would be actual functional bugs against real hardware.
- "How does RTIC guarantee no data races between interrupt handlers without using locks?" -- it computes, at compile time, whether tasks sharing a resource could ever actually preempt each other in a racing way given their configured hardware interrupt priorities; where the analysis proves that's impossible, direct lock-free access is generated, and where it isn't, access is required to go through RTIC's resource API, which the type system enforces.
