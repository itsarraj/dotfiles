# Next 18 Hours

Date: 2026-10-18
Mode: One thing at a time. Finish it. Then next.

---

## Current Focus

Rust for Rustaceans -- Ch 1: Types
Topic: memory layout, sized vs unsized, ZST, PhantomData, variance, lifetime variance rules.

---

### 2026-10-18

- [ ] (p1)(est: 2h) RfR Ch 1 -- read the chapter, understand every concept
  > Start: ___ | End: ___

- [ ] (p1)(est: 1h) Build: typed newtype wrapper for file descriptors (struct Fd(RawFd))
  > Make it compile. Handle open/close. Use thiserror or plain io::Error.

- [ ] (p2)(est: 30m) Dissect: what does the newtype cost in ASM?
  > cargo rustc --release -- --emit=asm  OR  paste on godbolt.org
  > Confirm: struct Fd(i32) generates identical ASM to bare i32. Zero overhead. See it.
  > Write 5 lines of C equivalent. Compare. Read: 1-resources/12-rust/08-mir-llvm-deep.md §drop-elaboration if drop behavior is unclear.

→ Done. Pull next from queue below.

---

## Queue (pull from here when current is done)

1. RfR Ch 2 -- Traits & Generics: dyn dispatch, vtables, monomorphization
2. RfR Ch 2 -- Build: trait-based Read/Write abstraction
3. RfR Ch 2 -- Dissect: dyn vs impl in ASM -- see the vtable call vs direct call on godbolt
4. RfR Ch 3 -- Designing Interfaces: type-state, builder, sealed traits
5. RfR Ch 3 -- Build: type-state file descriptor (FileOpen / FileClosed)
6. RfR Ch 3 -- Dissect: does PhantomData appear in ASM? It should not. Verify.
7. RfR Ch 4 -- Error Handling: thiserror, anyhow, context chains
8. RfR Ch 4 -- Build: syscall wrapper with typed errno error enum
9. RfR Ch 4 -- Dissect: what does Result<i32, Errno> look like in memory vs C int+errno
10. RfR Ch 5 -- Project Structure: workspaces, feature flags, cfg
11. RfR Ch 5 -- Build: multi-crate workspace (syscall-raw, syscall-safe, CLI)
12. RfR Ch 6 -- Testing: proptest, cargo-fuzz
13. RfR Ch 6 -- Build: fuzz a byte-level parser (/proc/self/status)
14. RfR Ch 7 -- Macros: macro_rules!, tt-muncher
15. RfR Ch 7 -- Build: macro-generated typed syscall wrappers
16. RfR Ch 8 -- Async: Future, Waker, Pin, state machine
17. RfR Ch 8 -- Build: minimal single-threaded async executor
18. RfR Ch 9 -- Unsafe: raw pointers, invariants, soundness
19. RfR Ch 9 -- Build: arena allocator (bump, no_std)
20. RfR Ch 10 -- Concurrency: atomics, memory ordering, lock-free
21. RfR Ch 10 -- Build: lock-free stack with AtomicPtr + compare_exchange
22. RfR Ch 10 -- Dissect: what does compare_exchange compile to? Find the lock cmpxchg.
