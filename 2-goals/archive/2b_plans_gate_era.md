# Plans : When & How

One 10-year focus to eliminate drift. Pivot only after 10000+ deep work hours on this path.

## The One Thing

Low-level systems and high-performance compute infrastructure.
Modern computer architecture (x86-64, ARM, RISC-V), SIMD and matrix extensions (AVX-512, NEON, AMX, SME), GPU compute architectures (CUDA, PTX, Tensor Cores), ASM, C, C++, Rust, and Linux internals.
Applied to high-throughput compute kernels, AI inference runtimes, and distributed infrastructure.
Pivoting is locked until 10000+ deep work hours are logged on this single path.

## Milestone
January 25, 2027: All GATE CSE and GATE DA subjects completed with chapter-wise PYQs done in each stage. GATE exam ready.

---

## Phases

### Phase 1: Foundations, Funding, and Relocation (2026-2027)
- Complete all core CSE subjects (COA, OS, Data Structures, Algorithms, Digital Logic, Networks, DBMS, Compilers, TOC, Discrete Maths) to build the CS foundations missed during ECE degree and prepare for GATE CSE.
- Master low-level systems engineering: Assembly (x86-64, ARM, RISC-V), SIMD/vector units (AVX-512, NEON), GPU compute architectures (CUDA, PTX), C, C++, Rust, and Linux internals (CS:APP, OSTEP, TLPI).
- Learn AI from first principles: understand tensors, neural network math, and model architectures using Python as a mathematical prototyping scratchpad, then implement high-performance execution kernels and inference runtimes in C, C++, SIMD, and CUDA.
- Build and benchmark high-performance compute kernels (CPU SIMD GEMM, GPU tensor kernels), AI inference runtimes, and distributed infrastructure.
- Build financial reserves (save 80% of income per month).
- Complete English IELTS, clear APS verification, leverage 3-year industry software engineering experience, and secure 100% English-taught European MS admission for Fall 2027 with zero language blockers.

### Phase 2: European MS and Applied Research (2027-2029)
- Complete MS in Computer Engineering
- Specialize in hardware-aware runtimes, compiler optimizations, and accelerator kernels (matrix units, GPUs, RISC-V, custom silicon).
- High-impact industry internships and research at systems infrastructure labs.
- Master thesis on low-latency or distributed inference infrastructure with direct commercial application.

### Phase 3: Deep-Tech Founder and Systems Infrastructure (2029 onwards)
- Build deep-tech B2B systems company directly out of MS or applied research.
- Commercialize proprietary high-throughput inference runtimes, compute kernels, or distributed engines.
- Exploit zero marginal cost software leverage to build enterprise equity and contracts.
- Convert enterprise revenues into compounding global assets and complete financial sovereignty.
- Trajectory changes drastically beyond this point based on venture outcome; future phases planned only after Phase 3 milestones are unlocked.

---

## Daily Standing Block: Rust 1hr (Oct 17, 2026 - Feb 5, 2027)

Every single day, alongside GATE study, 1 hour of Rust language work is executed as a non-negotiable daily block.
This is not P1 project execution — it is foundational language exposure that runs in parallel with GATE.
Source: The Rust Programming Language (The Book) → Rustlings exercises → small systems-flavored programs.
This keeps the language warm so Phase 1 systems work post-Feb 2027 starts from a position of fluency, not zero.

---

## Phase 1 Study Curriculum: Order of Execution (Oct 10, 2026 - Feb 5, 2027)

Condensed 15-week sprint ending January 25, 2027. Core CS subjects and mathematics are front-loaded to align directly with low-level systems engineering, computer architecture, and high-performance compute kernels.

### Stage 1: Hardware and Mathematical Foundations (Oct 10 - Oct 31, 2026 | 3 weeks)
- Digital Logic: Digital Design (Morris Mano & Ciletti)
  Window: Oct 10 - Oct 20 (1.5 weeks)
  Focus: Boolean algebra, logic minimization, combinational circuits (adders, multiplexers), sequential circuits (flip-flops, counters, FSMs). Hardware foundation for CPU datapaths.
  Daily Schedule (Oct 10 - Oct 20):
  - Oct 10: Chapter 1 — Binary systems, conversions, signed binary numbers, complements.
  - Oct 11: Chapter 2 — Boolean algebra, basic theorems, canonical SOP and POS forms.
  - Oct 12: Chapter 2 — Logic gates, digital IC families, universal NAND/NOR logic.
  - Oct 13: Chapter 3 — Gate-level minimization, 2/3/4-variable K-maps, prime implicants, essential prime implicants.
  - Oct 14: Chapter 3 — Don't-care conditions, POS simplification, XOR/XNOR parity generation.
  - Oct 15: Chapter 4 — Combinational circuits, half/full adders, ripple carry adders, carry-lookahead adders, magnitude comparators.
  - Oct 16: Chapter 4 — Multiplexers, demultiplexers, decoders, encoders, Boolean function implementation using MUX.
  - Oct 17: Chapter 5 — Synchronous sequential logic, latches, flip-flops (SR, JK, D, T), master-slave, setup and hold times.
  - Oct 18: Chapter 5 — Sequential circuit analysis, state equations, state reduction, Mealy and Moore models.
  - Oct 19: Chapter 6 — Registers and counters, shift registers, ripple counters, synchronous counters, ring and Johnson counters.
  - Oct 20: Digital Logic revision, comprehensive summary, and GATE CSE/DA previous year questions (PYQs) sprint.
- Engineering Mathematics & Discrete Mathematics: Higher Engineering Mathematics (Grewal) + Discrete Mathematics (Rosen) + Introduction to Linear Algebra (Strang)
  Window: Oct 21 - Oct 31 (1.5 weeks)
  Focus: Linear algebra (matrices, determinants, eigenvalues, eigenvectors - critical for tensor kernels), calculus, probability, propositional logic, sets, relations, combinatorics, graph theory.
  DA Focus (Sections 1, 2, 3): Probability and Statistics: counting (permutations, combinations), probability axioms, sample space, events, independent events, mutually exclusive events, marginal, conditional and joint probability, Bayes theorem, conditional expectation and variance, mean, median, mode, standard deviation, correlation, covariance, random variables, discrete random variables and PMF (uniform, Bernoulli, binomial), continuous random variables and PDF (uniform, exponential, Poisson, normal, standard normal, t-distribution, chi-squared distributions), CDF, conditional PDF, central limit theorem, confidence interval, z-test, t-test, chi-squared test. Linear Algebra: vector space, subspaces, linear dependence and independence of vectors, matrices, projection matrix, orthogonal matrix, idempotent matrix, partition matrix and properties, quadratic forms, systems of linear equations and solutions, Gaussian elimination, eigenvalues and eigenvectors, determinant, rank, nullity, projections, LU decomposition, singular value decomposition. Calculus and Optimization: functions of a single variable, limit, continuity, differentiability, Taylor series, maxima and minima, optimization involving a single variable.
  Daily Schedule (Oct 21 - Oct 31):
  - Oct 21: Linear Algebra Part 1 — Vector spaces, subspaces, linear independence, basis, dimension, systems of linear equations, Gaussian elimination (Strang Chapter 1 & 2 / Grewal).
  - Oct 22: Linear Algebra Part 2 — Projections, projection matrices, orthogonal matrices, idempotent and partition matrices, quadratic forms (Strang Chapter 3 & 4).
  - Oct 23: Linear Algebra Part 3 — Determinants, eigenvalues, eigenvectors, LU decomposition, singular value decomposition SVD (Strang Chapter 5 & 6).
  - Oct 24: Calculus & Optimization Part 1 — Functions of single variable, limits, continuity, differentiability, mean value theorems (Grewal / Thomas).
  - Oct 25: Calculus & Optimization Part 2 — Taylor series, Maclaurin series, maxima and minima, single-variable optimization (Grewal).
  - Oct 26: Probability Foundations — Counting, permutations, combinations, probability axioms, sample space, conditional and joint probability, Bayes theorem (Bertsekas / Ross).
  - Oct 27: Random Variables & Distributions — Discrete PMF, continuous PDF, expectation, variance, conditional expectation, binomial, Poisson, normal, t, chi-squared distributions (Bertsekas / Grewal).
  - Oct 28: Mathematical Statistics — Correlation, covariance, Central Limit Theorem (CLT), confidence intervals, hypothesis testing: z-test, t-test, chi-squared test (Grewal).
  - Oct 29: Discrete Mathematics Part 1 — Propositional and predicate logic, truth tables, logical equivalences, sets, relations, partial orders, lattices (Rosen Chapter 1 & 2).
  - Oct 30: Discrete Mathematics Part 2 — Combinatorics, recurrence relations, graph theory: paths, cycles, Eulerian/Hamiltonian graphs, planar graphs, trees (Rosen Chapter 6 & 10).
  - Oct 31: Stage 1 Revision & PYQs — Full review of Engineering Mathematics & Discrete Mathematics, formula consolidation, and GATE CSE/DA PYQs sprint.

### Stage 2: Systems Programming, Architecture & DSA (Nov 1 - Nov 28, 2026 | 4 weeks)
- C Programming & Data Structures: The C Programming Language (Kernighan & Ritchie) + Data Structures Made Easy (Karumanchi) + DSA in Python (Goodrich & Tamassia)
  Window: Nov 1 - Nov 11 (1.5 weeks)
  Focus: Pointers, memory allocation, structs, bitwise operations, linked lists, stacks, queues, trees, heaps, hashing.
  DA Focus (Section 4): Programming in Python, basic data structures: stacks, queues, linked lists, trees, hash tables; search algorithms: linear search and binary search.
  Daily Schedule (Nov 1 - Nov 11):
  - Nov 1: C Fundamentals & Memory Model — Data types, operators, precedence, bitwise operators, control flow (K&R Chapters 1 & 2).
  - Nov 2: Functions, Scope & Recursion — Call stack, activation records, parameter passing, recursive function analysis (K&R Chapter 4).
  - Nov 3: Pointers & Dynamic Memory in C — Pointer arithmetic, arrays vs pointers, malloc, calloc, realloc, free (K&R Chapter 5).
  - Nov 4: Structs, Unions & Memory Layout — Struct alignment, padding, bit fields, self-referential structures (K&R Chapter 6).
  - Nov 5: Python Programming for DA — Python built-in types, lists, dicts, tuples, sets, list comprehensions, lambda, file I/O (Goodrich Chapters 1 & 2).
  - Nov 6: Linear Data Structures — Singly linked list, doubly linked list, circular list, cycle detection, list reversal (Karumanchi).
  - Nov 7: Stacks & Applications — Array and list implementation, infix to postfix conversion, postfix evaluation, balanced parentheses.
  - Nov 8: Queues & Deques — Circular queue, deque, queue using stacks, priority queue fundamentals.
  - Nov 9: Trees & Binary Trees — Properties of binary trees, inorder, preorder, postorder, level-order traversals, reconstructing trees.
  - Nov 10: Binary Search Trees & Heaps — BST insertion, deletion, searching, LCA; Binary heaps (min/max heap), heapify, build-heap, heapsort.
  - Nov 11: Hash Tables & Search Algorithms — Hash functions, collision resolution (chaining, linear/quadratic probing, double hashing), linear and binary search variations.
- Computer Organization and Architecture (COA) & Systems Core: Computer System Architecture (Morris Mano) + CS:APP Computer Systems: A Programmer's Perspective (Bryant & O'Hallaron)
  Window: Nov 12 - Nov 28 (2.5 weeks)
  Focus: Instruction set architectures, datapath, pipelining, hazards, cache hierarchy, virtual memory, x86-64 assembly, linking, memory performance. Directly links hardware design with low-level software execution.
  Daily Schedule (Nov 12 - Nov 28):
  - Nov 12: Machine Instructions & Addressing Modes — Instruction formats (0, 1, 2, 3-address), immediate, direct, indirect, register, indexed, relative addressing modes.
  - Nov 13: CPU Datapath & Control Unit — Datapath components, register transfers, micro-operations, hardwired vs microprogrammed control units.
  - Nov 14: Computer Arithmetic & ALU Design — Fixed-point arithmetic, unsigned and 2's complement addition/subtraction, Booth's multiplication algorithm, division.
  - Nov 15: Floating-Point Representation — IEEE 754 single precision (32-bit) and double precision (64-bit) standards, normalization, NaN, infinity, arithmetic.
  - Nov 16: Instruction Pipelining Core — 5-stage pipeline (IF, ID, EX, MEM, WB), clock cycle time, pipeline speedup, throughput, efficiency.
  - Nov 17: Pipeline Hazards & Forwarding — Structural hazards, data hazards (RAW, WAR, WAW), operand forwarding, hardware interlocks, load-use delays.
  - Nov 18: Branch Hazards & Prediction — Control hazards, branch penalty, static prediction, 2-bit dynamic branch prediction, Branch Target Buffer (BTB).
  - Nov 19: Memory Hierarchy & Cache Fundamentals — SRAM vs DRAM, temporal and spatial locality, cache line size, hit ratio, miss penalty, AMAT calculations.
  - Nov 20: Cache Mapping Techniques — Direct mapped, fully associative, and set-associative caches, tag/index/offset calculations.
  - Nov 21: Cache Write Policies & Replacement — Write-through vs write-back, write-allocate vs no-write-allocate, cache replacement (LRU, FIFO, Optimal, Random).
  - Nov 22: Multilevel Caches & Memory Performance — L1, L2, L3 caches, inclusive vs exclusive policies, memory stall cycles calculations.
  - Nov 23: Virtual Memory & Address Translation — Paging, page tables, page size, multi-level paging, page table entries, virtual to physical address translation.
  - Nov 24: TLB & Page Replacement — Translation Lookaside Buffer (TLB), TLB hit/miss, effective memory access time (EMAT), page fault handling, FIFO, LRU, Optimal.
  - Nov 25: I/O Interface: Interrupts & DMA — Programmed I/O, interrupt-driven I/O, priority interrupts, Direct Memory Access (DMA: burst mode, cycle stealing).
  - Nov 26: Systems Core: x86-64 Assembly (CS:APP) — Registers, operands, mov, arithmetic logic instructions, condition codes, control flow in assembly.
  - Nov 27: Systems Core: Linking & Cache Performance (CS:APP) — Object files, symbol resolution, relocation, static/dynamic linking, writing cache-friendly code.
  - Nov 28: Stage 2 Revision & PYQs — Full review of C, DSA, COA, and solving GATE CSE previous year questions (2012-2024).

### Stage 3: Algorithms, Operating Systems & Linux Internals (Nov 29 - Dec 26, 2026 | 4 weeks)
- Algorithms: Introduction to Algorithms (CLRS) + Karumanchi
  Window: Nov 29 - Dec 12 (2 weeks)
  Focus: Asymptotic analysis, divide and conquer, greedy methods, dynamic programming, graph algorithms (BFS, DFS, Dijkstra, Prim/Kruskal).
  DA Focus (Section 4): Basic sorting algorithms: selection sort, bubble sort, insertion sort; divide and conquer: mergesort, quicksort; introduction to graph theory; basic graph algorithms: traversals and shortest path.
  Daily Schedule (Nov 29 - Dec 12):
  - Nov 29: Asymptotic Analysis & Recurrences — Big-O, Big-Omega, Big-Theta, small-o, small-omega; substitution method, recursion tree, Master Theorem.
  - Nov 30: Sorting: Comparison-Based — Selection, bubble, insertion sort; Merge Sort, Quick Sort (partition algorithms, randomized quicksort, worst case O(n^2), average O(n log n)).
  - Dec 1: Linear Time Sorting & Heapsort — Counting sort, Radix sort, Bucket sort, lower bound of comparison sorting Omega(n log n); Heapsort analysis.
  - Dec 2: Divide and Conquer Paradigm — Binary search variations, finding median, finding min-max with minimum comparisons, Strassen's matrix multiplication.
  - Dec 3: Greedy Algorithms Part 1 — Greedy choice property, optimal substructure; Fractional Knapsack, Activity selection, Job sequencing with deadlines.
  - Dec 4: Greedy Algorithms Part 2: Minimum Spanning Trees — Cut property, cycle property; Kruskal's algorithm (Disjoint Set Union DSU), Prim's algorithm.
  - Dec 5: Greedy Algorithms Part 3: Shortest Path & Huffman — Optimal merge patterns, Huffman coding; Dijkstra's single-source shortest path algorithm.
  - Dec 6: Dynamic Programming Part 1 — Overlapping subproblems, optimal substructure, memoization vs tabulation; 0/1 Knapsack problem.
  - Dec 7: Dynamic Programming Part 2 — Longest Common Subsequence (LCS), Longest Increasing Subsequence (LIS), Matrix Chain Multiplication (MCM).
  - Dec 8: Dynamic Programming Part 3: Graph DP — Bellman-Ford algorithm (negative weight cycles), Floyd-Warshall all-pairs shortest path, Traveling Salesperson Problem (TSP) DP.
  - Dec 9: Graph Traversals & Properties — Graph representations (matrix vs list), Breadth-First Search (BFS), Depth-First Search (DFS), edge classification.
  - Dec 10: Advanced Graph Algorithms — Topological sorting (Kahn's and DFS), Strongly Connected Components (Kosaraju, Tarjan), Bipartite testing, cycle detection.
  - Dec 11: Hashing & String Matching — Hash tables analysis, load factor, string matching basics (Naive, KMP prefix function).
  - Dec 12: Algorithms Sprint & GATE PYQ Solving — Complete revision of asymptotic analysis, divide and conquer, greedy, DP, graphs; solve 15 years of GATE CSE/DA algorithms PYQs.
- Operating Systems and Linux Internals: Operating Systems: Three Easy Pieces (OSTEP) + Operating System Concepts (Silberschatz) + The Linux Programming Interface (TLPI)
  Window: Dec 13 - Dec 26 (2 weeks)
  Focus: Processes, CPU scheduling, thread synchronization, deadlocks, virtual memory, paging, page replacement, file systems, POSIX system calls.
  Daily Schedule (Dec 13 - Dec 26):
  - Dec 13: OS Architecture & System Calls — Dual-mode operation (user vs kernel), trap, interrupt, context switch, POSIX calls (fork, exec, wait, exit).
  - Dec 14: Process Management & Lifecycle — Process states, Process Control Block (PCB), process creation hierarchy, zombie and orphan processes.
  - Dec 15: CPU Scheduling Algorithms — Preemptive vs non-preemptive; FCFS, SJF, SRTF, Priority scheduling, Round Robin, Multi-Level Feedback Queue (MLFQ).
  - Dec 16: Inter-Process Communication & Threads — User vs kernel threads, multithreading models; IPC via pipes, shared memory, message queues.
  - Dec 17: Process Synchronization Foundations — Race conditions, critical section problem, mutual exclusion, progress, bounded waiting, Peterson's algorithm, hardware atomic instructions.
  - Dec 18: Semaphores & Classical Sync Problems — Counting and binary semaphores; Producer-Consumer, Readers-Writers, Dining Philosophers problems.
  - Dec 19: Deadlocks: Detection & Prevention — 4 Coffman conditions, Resource Allocation Graph (RAG), deadlock prevention strategies.
  - Dec 20: Deadlock Avoidance & Recovery — Banker's Algorithm (safety and request algorithms, safe state calculations), deadlock detection and recovery.
  - Dec 21: Memory Management: Paging & Segmentation — Contiguous allocation, internal/external fragmentation, paging hardware, page tables, segmentation.
  - Dec 22: Virtual Memory & Page Replacement — Demand paging, page fault service, Belady's anomaly; Page replacement: FIFO, Optimal (OPT), Least Recently Used (LRU), Clock algorithm.
  - Dec 23: Thrashing & Working Set Model — Causes of thrashing, page fault frequency, Working Set Model, local vs global page allocation.
  - Dec 24: File Systems & Storage Management — File access methods, directory structures; allocation: contiguous, linked, indexed (inode structure, direct and indirect blocks).
  - Dec 25: Disk Scheduling & Linux Internals (TLPI) — Seek time, rotational latency; FCFS, SSTF, SCAN, C-SCAN, LOOK, C-LOOK; Linux epoll and POSIX threads introduction.
  - Dec 26: Operating Systems Sprint & GATE PYQ Solving — Full OS formula and concept consolidation; solve 15 years of GATE CSE OS previous year questions.

### Stage 4: Compilers and Distributed Networks (Dec 27, 2026 - Jan 9, 2027 | 2 weeks)
- Compiler Design: Compilers: Principles, Techniques, and Tools (Aho, Lam, Sethi, Ullman)
  Window: Dec 27 - Jan 2 (1 week)
  Focus: Lexing, LL and LR parsing, syntax directed translation, intermediate representations, basic blocks, register allocation, compiler optimizations.
  Daily Schedule (Dec 27 - Jan 2):
  - Dec 27: Compiler Architecture & Lexical Analysis — Compiler phases, front-end vs back-end; Regular expressions to DFA, lexer implementation, tokens, patterns, lexemes.
  - Dec 28: Syntax Analysis & Grammar Basics — Context-Free Grammars (CFG), derivations, parse trees, grammar ambiguity, elimination of left recursion, left factoring.
  - Dec 29: Top-Down Parsing — Recursive descent parsing, LL(1) grammars, FIRST and FOLLOW set computations, LL(1) parse table construction, error handling.
  - Dec 30: Bottom-Up Parsing (LR Parsing) — Shift-reduce parsing, handles, viable prefixes; LR(0) items and automaton; SLR(1) parsing table construction and conflicts.
  - Dec 31: Advanced LR Parsing & SDT — CLR(1) and LALR(1) parse tables; Syntax-Directed Translation (SDT), synthesized attributes (S-attributed), inherited attributes (L-attributed).
  - Jan 1: Intermediate Code Generation & Runtime — Three-address code (quadruples, triples, indirect triples), DAG representation; Runtime memory layout, activation records, heap management.
  - Jan 2: Code Optimization & Data Flow Analysis — Basic blocks, control flow graphs (CFG); Local optimizations (common subexpression elimination, dead code elimination); Data flow: liveness analysis, reaching definitions, constant propagation.
- Computer Networks: Computer Networks (Tanenbaum & Wetherall)
  Window: Jan 3 - Jan 9 (1 week)
  Focus: OSI and TCP/IP stack, packet switching, routing algorithms, transport layer (TCP state machine, congestion control, UDP), network latency, socket API.
  Daily Schedule (Jan 3 - Jan 9):
  - Jan 3: Network Architecture & Physical Layer — OSI model vs TCP/IP stack; packet switching vs circuit switching; performance metrics: bandwidth, latency, propagation delay, transmission delay, throughput.
  - Jan 4: Data Link Layer & MAC — Framing, error detection (parity, checksum, CRC); flow control: Stop-and-Wait, Go-Back-N, Selective Repeat (window sizes, channel efficiency).
  - Jan 5: Medium Access Control & Ethernet — Multiple access: ALOHA, CSMA, CSMA/CD (minimum frame size calculations), CSMA/CA; Ethernet frame format.
  - Jan 6: Network Layer & IPv4 — IPv4 header, fragmentation and reassembly (offset calculations); classful addressing, CIDR subnetting, supernetting, Network Address Translation (NAT).
  - Jan 7: Routing Algorithms — Distance Vector Routing (Bellman-Ford, count-to-infinity), Link State Routing (Dijkstra, OSPF), routing table lookups (longest prefix match).
  - Jan 8: Transport Layer: TCP & UDP — UDP header; TCP header, 3-way handshake, connection teardown; TCP flow control; TCP congestion control (slow start, congestion avoidance, fast retransmit, fast recovery).
  - Jan 9: Application Layer Protocols & Socket API — DNS, HTTP/HTTPS, FTP, SMTP; Socket API: socket, bind, listen, accept, connect, send, recv; Computer Networks GATE PYQs sprint.

### Stage 5: Secondary Foundations, DBMS, Warehousing & Aptitude (Jan 10 - Jan 25, 2027 | 2 weeks)
- Theory of Computation (TOC): Introduction to Automata Theory (Ullman)
  Window: Jan 10 - Jan 16 (1 week)
  Focus: Finite automata (DFA, NFA), regular expressions, context-free grammars, pushdown automata, Turing machines, decidability, halting problem.
  Daily Schedule (Jan 10 - Jan 16):
  - Jan 10: Finite Automata (DFA & NFA) — Deterministic Finite Automata (DFA), Non-deterministic Finite Automata (NFA), NFA to DFA subset construction, epsilon-NFA conversion.
  - Jan 11: DFA Minimization & Regular Expressions — State minimization using table-filling (Myhill-Nerode) algorithm; regular expressions, Arden's theorem, FA to regex conversion.
  - Jan 12: Regular Languages & Pumping Lemma — Closure properties of regular languages (union, intersection, complement, concatenation, star); Pumping Lemma for regular languages.
  - Jan 13: Context-Free Grammars & Pushdown Automata — CFG simplification (null, unit, useless productions), Chomsky Normal Form (CNF); Pushdown Automata (PDA), DPDA vs NPDA.
  - Jan 14: Context-Free Languages & Properties — Closure properties of CFLs and DCFLs; Pumping Lemma for CFLs; ambiguity in context-free languages.
  - Jan 15: Turing Machines & Chomsky Hierarchy — Standard Turing Machine model, multi-tape TM; Chomsky hierarchy (Type 0, Type 1, Type 2, Type 3), recursively enumerable (RE) vs recursive (REC) languages.
  - Jan 16: Decidability & Undecidability — Halting problem, reduction proofs, Rice's theorem, Post Correspondence Problem (PCP), decidability summary table.
- Database Management Systems (DBMS) & Warehousing: Database System Concepts (Silberschatz) + Data Mining: Concepts and Techniques (Han & Kamber)
  Window: Jan 17 - Jan 23 (1 week)
  Focus: Relational model, relational algebra, SQL, normalization, transactions, ACID properties, concurrency control, B/B+ trees, storage engines.
  DA Focus (Section 5): ER-model, relational model: relational algebra, tuple calculus, SQL, integrity constraints, normal form, file organization, indexing, data types, data transformation: normalization, discretization, sampling, compression; data warehouse modelling: schema for multidimensional data models, concept hierarchies, measures: categorization and computations.
  Daily Schedule (Jan 17 - Jan 23):
  - Jan 17: ER Model & Relational Model — Entity-Relationship model, entities, relationships, cardinalities, weak entity sets, converting ER diagrams to relational tables.
  - Jan 18: Relational Algebra & Tuple Calculus — Relational algebra operators: select, project, Cartesian product, set operations, rename, joins (natural, inner, outer); Tuple and Domain Relational Calculus.
  - Jan 19: SQL Queries & Constraints — DDL, DML, integrity constraints, nested subqueries, correlated queries, aggregate functions, GROUP BY, HAVING, joins in SQL.
  - Jan 20: Normalization & Functional Dependencies — Functional dependencies, closure of attributes, minimal cover, candidate keys; Normal forms: 1NF, 2NF, 3NF, BCNF; lossless join decomposition, dependency preservation.
  - Jan 21: Transactions & Concurrency Control — ACID properties, transaction states; serializability (conflict and view serializability, precedence graphs); Recoverability; Two-Phase Locking (2PL), strict 2PL.
  - Jan 22: Storage & Indexing — File organization, records in blocks; primary index, secondary index, clustering index; B-trees and B+ trees (search, insertion, node splitting, height calculations).
  - Jan 23: Data Warehousing & Transformation (DA Section 5) — Multidimensional data models: star schema, snowflake schema, fact constellation; concept hierarchies; measures: additive, semi-additive, non-additive; OLAP operations: roll-up, drill-down, slice, dice, pivot; Data transformation: min-max and z-score normalization, discretization, sampling, data compression.
- General Aptitude & Final Sprint: MadeEasy Reasoning & Aptitude
  Window: Jan 24 - Jan 25 (2 days)
  Focus: Quantitative aptitude, spatial reasoning, verbal reasoning drills, rapid PYQ problem-solving.
  Daily Schedule (Jan 24 - Jan 25):
  - Jan 24: Quantitative & Analytical Aptitude — Number systems, percentages, ratios, speed-time-distance, work-time, permutations, combinations, probability, data interpretation (graphs, tables).
  - Jan 25: Spatial & Verbal Aptitude & Grand Final Milestone — Spatial reasoning (folding, mirroring, rotation, 2D/3D shapes), verbal reasoning, critical reading; Final Stage 1-5 Milestone Check. All GATE core CSE and GATE DA subjects 100% completed.

### Stage 6: GATE DA Delta Track — Machine Learning & AI (Oct 10, 2026 - Jan 25, 2027)
- Machine Learning: Pattern Recognition and Machine Learning (Bishop) + Hands-On Machine Learning (Geron)
  Focus (Section 6): Supervised Learning: simple linear regression, multiple linear regression, ridge regression, logistic regression, k-nearest neighbour, naive Bayes classifier, linear discriminant analysis, support vector machine, decision trees, bias-variance trade-off, cross-validation methods (leave-one-out cross-validation, k-folds cross-validation), multi-layer perceptron, feed-forward neural network. Unsupervised Learning: clustering algorithms (k-means, k-medoid, hierarchical clustering: top-down, bottom-up, single-linkage, multiple-linkage), dimensionality reduction (principal component analysis).
- Artificial Intelligence: Artificial Intelligence: A Modern Approach (Russell & Norvig)
  Focus (Section 7): Search: informed, uninformed, adversarial; logic: propositional, predicate; reasoning under uncertainty: conditional independence representation, exact inference through variable elimination, approximate inference through sampling.
  Module Execution Roadmap (Integrated with Stages 1 to 5):
  - Module 1 (Nov 1 - Nov 14 | Supervised Regression & Classification Math): Simple and multiple linear regression, closed-form ordinary least squares, ridge regression, logistic regression (sigmoid, log-loss, gradient descent), k-nearest neighbors (distance metrics, k selection).
  - Module 2 (Nov 15 - Nov 28 | Discriminant Models & Trees): Linear Discriminant Analysis (LDA derivation, Fisher projection), Naive Bayes classifier (prior, likelihood, posterior, Laplace smoothing), Support Vector Machines (hyperplane, margin, primal and dual formulations, soft margin, kernel trick intro), Decision Trees (entropy, information gain, Gini impurity, tree pruning).
  - Module 3 (Nov 29 - Dec 12 | Generalization & Neural Networks): Bias-variance tradeoff, cross-validation (Leave-One-Out LOO, k-folds cross-validation), Multi-Layer Perceptron (MLP), forward pass, backpropagation, activation functions (ReLU, Sigmoid, Tanh, Softmax).
  - Module 4 (Dec 13 - Dec 26 | Unsupervised Learning & Dimensionality Reduction): Clustering algorithms: k-means (convergence, inertia), k-medoids; Hierarchical clustering (agglomerative, divisive, single-linkage, complete-linkage, average-linkage, dendrograms); Principal Component Analysis (PCA: covariance matrix, eigenvectors, eigenvalues, variance explained).
  - Module 5 (Dec 27 - Jan 9 | Artificial Intelligence: Search): Uninformed search (BFS, DFS, Uniform Cost Search UCS, Depth-Limited Search, Iterative Deepening); Informed heuristic search (Greedy Best-First, A-star algorithm, admissibility and consistency of heuristics); Adversarial search (Minimax algorithm, game trees, Alpha-Beta pruning).
  - Module 6 (Jan 10 - Jan 23 | Artificial Intelligence: Logic & Uncertainty): Propositional logic and First-Order Predicate Logic (syntax, semantics, inference rules, resolution); Reasoning under uncertainty: conditional independence representations, Bayesian Networks (DAG, conditional probability tables CPT); Exact inference via variable elimination; Approximate inference via sampling (prior sampling, rejection sampling, likelihood weighting).
  - Module 7 (Jan 24 - Jan 25 | DA Grand Revision & PYQ Sprint): Full consolidation of ML and AI algorithms, formulas, and solving 2024-2026 GATE DA previous year questions.

### Mock Test and Exam Readiness Block (Jan 26 - Feb 5, 2027 | 10 days)
- Full-length timed GATE CSE and GATE DA mock tests under exam conditions.
- One full mock per day: 3-hour paper, strict time discipline, no pausing.
- Post-mock analysis: identify weak topics, targeted 1-hour drilling session after each mock.
- Final 2 days: no new learning, only light revision of formulas, PYQs, and exam logistics.
- Exam logistics: admit card download, exam center visit, material and calculator check.
- GATE exam: February 6-21, 2027 (exact slot on admit card).

---

## Reference Book Inventory

### GATE Curriculum
- C Programming: The C Programming Language (Kernighan & Ritchie)
- Digital Logic: Digital Design (Morris Mano & Ciletti)
- Discrete Mathematics: Discrete Mathematics and Its Applications (Rosen)
- Data Structures: Data Structures and Algorithms Made Easy (Karumanchi)
- COA: Computer System Architecture (Morris Mano)
- Algorithms: Introduction to Algorithms (CLRS)
- TOC: Introduction to Automata Theory (Ullman)
- OS: Operating System Concepts (Silberschatz)
- DBMS: Database System Concepts (Elmasri & Navathe / Silberschatz)
- Computer Networks: Computer Networks (Tanenbaum & Wetherall)
- Compiler Design: Compilers: Principles, Techniques, and Tools (Aho, Lam, Sethi, Ullman)
- Engineering Mathematics: Higher Engineering Mathematics (Grewal)
- Aptitude: MadeEasy Reasoning & Aptitude

### GATE DA Curriculum (7 Sections Complete Inventory)
- Section 1 (Probability & Statistics): Introduction to Probability (Bertsekas & Tsitsiklis) / Higher Engineering Mathematics (Grewal)
- Section 2 (Linear Algebra): Introduction to Linear Algebra (Gilbert Strang)
- Section 3 (Calculus & Optimization): Higher Engineering Mathematics (Grewal)
- Section 4 (Python, DSA): Data Structures and Algorithms in Python (Goodrich, Tamassia, Goldwasser) / CLRS
- Section 5 (DBMS & Warehousing): Database System Concepts (Silberschatz) + Data Mining: Concepts and Techniques (Han & Kamber)
- Section 6 (Machine Learning): Pattern Recognition and Machine Learning (Bishop) + Hands-On Machine Learning (Geron)
- Section 7 (Artificial Intelligence): Artificial Intelligence: A Modern Approach (Russell & Norvig)

### Systems Core (ECE to CSE Bridge)
- CS:APP: Computer Systems: A Programmer's Perspective (Bryant & O'Hallaron)
  Bridge covering data representation, x86-64 assembly, processor architecture, cache memories, virtual memory, linking, and system I/O.
- OSTEP: Operating Systems: Three Easy Pieces (Remzi & Andrea Arpaci-Dusseau)
  Virtualization (CPU, memory), concurrency (threads, locks, semaphores), persistence (file systems, I/O).
- TLPI: The Linux Programming Interface (Michael Kerrisk)
  Linux kernel interfaces, POSIX system calls, process management, signals, IPC, and network sockets.

### Rust (Systems Language — Post-GATE Phase 2)
- ✅ COMPLETED: The Rust Programming Language (Steve Klabnik & Carol Nichols) — "The Rust Book"
  Ownership, borrowing, lifetimes, traits, generics, error handling, closures, iterators, smart pointers, concurrency primitives.
  Status: Completed during 2025 hyperfocus sprint. Build phase begins post-GATE Feb 2027.
- QUEUED (Post-GATE): Rust for Rustaceans (Jon Gjengset)
  Advanced Rust internals: unsafe, FFI, async runtimes, lock-free data structures, macro systems, performance tuning.
  Start: After GATE exam window closes (Feb 21, 2027).