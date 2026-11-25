---
id: 20250513130632
title: Career Paths Quant Finance Crypto ZK Systems Distributed Compilers
date: 2025-05-13 13:06
type: reference # note | concept | snippet | bug | journal | reference
status: stable # draft | stable | evergreen
tags: [career-paths, quant-finance, crypto, zk-systems, distributed-systems, compilers, cpp, rust]
links: []
---
# Log
- 2025-05-13 13:06 - Created note.

# Notes

Quant finance (C++/Rust with math)
Crypto/ZK systems (Rust/math/heavy engineering)
Distributed systems & compilers (Rust/C++/math combo)
For these how to show my competency and how to achieve it 

`ans`
Perfect — you've zeroed in on **three of the most elite technical fields** that reward deep skills and passion for low-level systems and math. Here's **how to become competitive** for each and **prove you're ready**, even if you're starting solo or from a regular dev job.

---

## 🎯 1. QUANT FINANCE (C++/Rust + Math + Speed)

### ✅ Skills You Need

* **C++17+ or Rust**: Low-latency programming, zero-cost abstractions
* **DSA**: Priority queues, hash maps, graphs, segment trees
* **Numerical math**: Linear algebra, optimization, probability, calculus
* **Concurrency**: Lock-free data structures, memory models
* **Markets**: Understand order books, latency arbitrage, trading mechanics

### 📈 How to Show Competency

* ✅ **Build a basic matching engine** (e.g., limit order book in C++/Rust)
* ✅ Write blog posts / GitHub repos explaining market microstructure
* ✅ Leetcode *only helps partially* — use **Project Euler**, **Kaggle finance problems**, or **Quantopian-style notebooks**
* ✅ Contribute to OSS in trading systems (e.g., [Hummingbot](https://github.com/hummingbot/hummingbot), [Backtrader](https://github.com/mementum/backtrader))
* ✅ Publish a fast backtesting system in Rust

### 🧠 Resources

* Book: *"Designing Stock Market Trading Systems"* by Bruce Vanstone
* Book: *"Programming in C++ for Quant Finance"* by Daniel J. Duffy
* Book: *"A Primer for the Mathematics of Financial Engineering"*
* Tool: [QuantLib](https://www.quantlib.org/) (C++)
* Course: Hudson River Trading open courses, Jane Street puzzles

---

## 🔐 2. CRYPTO / ZK SYSTEMS (Rust + Math + Engineering)

### ✅ Skills You Need

* **Rust**: Memory safety, generics, trait-based programming
* **Cryptography**: Modular arithmetic, ECC, pairing-based crypto, SHA
* **ZKP math**: Finite fields, SNARKs/STARKs, polynomials
* **Protocols**: L2 scaling, rollups, VM design

### 📈 How to Show Competency

* ✅ Build your own zk-SNARK or implement one from scratch (e.g., [Bulletproofs](https://github.com/dalek-cryptography/bulletproofs))
* ✅ Contribute to [zkSync](https://github.com/matter-labs), [snarkOS](https://github.com/AleoHQ/snarkOS), [Arkworks](https://github.com/arkworks-rs)
* ✅ Write blog posts: "ZKPs in Rust", "How SNARKs Work", "Proof systems comparison"
* ✅ Build toy blockchain, implement merkle trees, Poseidon hash
* ✅ Attend hackathons (ETHGlobal) — **good hiring path**

### 🧠 Resources

* Book: *"Zero Knowledge Proofs: Primer"* by Vitalik Buterin
* Rust Crypto libs: [Arkworks](https://github.com/arkworks-rs), [Zexe](https://github.com/scipr-lab/zexe)
* Courses:

  * [Cryptography I - Stanford (Coursera)](https://www.coursera.org/learn/crypto)
  * [Applied ZKP course](https://zk-learning.org/)
* Videos: Justin Thaler’s lectures on ZK

---

## ⚙️ 3. DISTRIBUTED SYSTEMS / COMPILERS (Rust/C++ + Math + Design)

### ✅ Skills You Need

* **Rust/C++ internals**: Ownership, lifetimes, memory layout
* **DSA**: Trees, graphs, skip lists, bloom filters, consistent hashing
* **Distributed concepts**: Raft, Paxos, CAP, CRDTs
* **Compilers**: Lexing, parsing, IR, optimization passes

### 📈 How to Show Competency

* ✅ Build your own:

  * 🗃️ Key-value store (like Redis clone in Rust)
  * 🖥️ Toy compiler (turn source into bytecode or LLVM IR)
  * 📡 Raft-based consensus system (see [raft-rs](https://github.com/tikv/raft-rs))
* ✅ Contribute to: [TiKV](https://github.com/tikv/tikv), [Cranelift](https://github.com/bytecodealliance/wasmtime/tree/main/cranelift), \[Zig compiler], [Rust Analyzer](https://github.com/rust-lang/rust-analyzer)
* ✅ Blog: “Building Raft from Scratch”, “Memory Layout in Rust”, “How Compilers Optimize Code”
* ✅ Write benchmarks comparing Rust vs C++ implementations

### 🧠 Resources

* Book: *"Designing Data-Intensive Applications"* by Martin Kleppmann
* Book: *"Compilers: Principles, Techniques, and Tools"* (Dragon Book)
* Site: [Rust Embedded Book](https://docs.rust-embedded.org/book/)
* Tools: LLVM, Cranelift, Zig, WebAssembly

---

## 🛠️ Common Strategy for All

### 🔨 Build + Write + Open Source

| Action                                     | Why                                |
| ------------------------------------------ | ---------------------------------- |
| 🚀 **Build toy projects**                  | Demonstrates systems understanding |
| ✍️ **Write articles explaining internals** | Shows depth + helps others learn   |
| 📦 **Contribute to OSS**                   | Build resume + network             |
| 📄 **Resume: show 1–2 deep projects**      | Better than 10 shallow ones        |

---

## 📁 GitHub Project Ideas (One per field)

| Field       | Project                                                              |
| ----------- | -------------------------------------------------------------------- |
| Quant       | `libmatch`: A C++ limit order book engine with nanosecond benchmarks |
| ZK          | `rust-zkp`: Bulletproof/ZK-STARK implementation using Arkworks       |
| DS/Compiler | `rafsim`: Rust Raft consensus simulator + distributed KV store       |
| Compiler    | `tinycc`: A Rust toy compiler that compiles to LLVM IR               |
| Bonus       | Blog: “Why Rust is Eating C++ in Systems Engineering”                |

---

## 🚧 What to Avoid

* ❌ “Full-stack” overload when aiming for deep systems
* ❌ Too many half-finished projects
* ❌ Avoid bootcamp-style projects (they look shallow)
* ❌ Tutorials without original work

---

## 🧭 Next Steps

1. Choose **one project per category** and begin now
2. Write **1 article/blog** per project (even a simple README guide counts)
3. Contribute to one **real OSS project**
4. Use that as leverage to apply to:

   * Internships at Quant firms or crypto startups
   * Rust-based infra companies (like Fly.io, Redpanda, etc.)
   * Grants from ZK foundations (some even fund you to learn/build!)

---

Would you like a **learning + project roadmap** for one of these (like ZK, Quant, or Compiler) in weekly steps? I can make it personalized to your current skill level.




