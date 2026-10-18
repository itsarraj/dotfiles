# Database Internals: Buffer Pool, MVCC, Transaction/Lock Managers, Recovery, Query Optimization

Prerequisite: §11 (storage engines -- B-trees/LSM-trees/WAL are the on-disk foundation this file builds the transactional/query layer on top of).

## The Buffer Pool

A database's own, application-managed page cache -- deliberately separate from (and, per §11's `O_DIRECT` discussion, often used *instead of* relying on) the OS's general-purpose page cache, because the database has semantic information the kernel doesn't (which pages are index roots vs. leaves, which pages are part of a currently-running transaction's working set, access patterns specific to its own query workload). An **eviction policy** (classic LRU, or a **clock algorithm** -- a cheaper approximation that cycles through pages with a reference bit rather than maintaining a precise access-order list) decides which page to evict when the pool is full and a new page needs to be read in; pages are **pinned** while a transaction is actively using them, preventing eviction out from under in-flight work, and **dirty** once modified, requiring writeback (coordinated with the WAL, §11) before that page's memory can actually be reused for something else.

## MVCC (Multi-Version Concurrency Control)

Instead of readers blocking behind writers (or vice versa) via locks, MVCC keeps **multiple versions** of a row, each tagged with the transaction (or timestamp) that created it and, once superseded, the one that invalidated it:

```
 Row "id=1" version history:
 ┌─────────────┬─────────────┬──────────────┬──────────────┐
 │ value          │ created_by    │ created_ts     │ deleted_by/ts  │
 ├─────────────┼─────────────┼──────────────┼──────────────┤
 │ "Alice"        │ txn 10          │ t=1              │ txn 15 / t=5     │
 │ "Alicia"       │ txn 15          │ t=5              │ (still live)      │
 └─────────────┴─────────────┴──────────────┴──────────────┘
```

A transaction reading "id=1" sees whichever version was live *as of its own snapshot* -- a transaction that started before `t=5` sees "Alice"; one that started after sees "Alicia" -- without ever needing to acquire a read lock that would block transaction 15's write. **Snapshot isolation** (each transaction sees a consistent snapshot as of its start time) is what MVCC gives you nearly for free; achieving the *stronger* **serializable** isolation level (equivalent to some serial execution of all transactions, ruling out certain anomalies snapshot isolation alone permits, like write skew) on top of MVCC typically requires additional machinery (tracking read/write dependencies between concurrent transactions and aborting one if a cycle would result -- **Serializable Snapshot Isolation**, the approach PostgreSQL uses).

## Transaction Manager and Isolation Levels

The **ACID** properties (**A**tomicity: a transaction's writes all happen or none do; **C**onsistency: application-defined invariants hold before and after; **I**solation: concurrent transactions don't observe each other's uncommitted intermediate states, to a degree depending on the isolation level; **D**urability: once committed, survives a crash -- guaranteed via the WAL, §11) are the contract the transaction manager enforces. The standard isolation-level hierarchy, from weakest to strongest:

| Level | Prevents |
|---|---|
| Read Uncommitted | Nothing -- can see another transaction's uncommitted writes ("dirty reads") |
| Read Committed | Dirty reads -- but a repeated read within the same transaction can see a *different* value if another transaction committed in between ("non-repeatable reads") |
| Repeatable Read | Non-repeatable reads -- but new rows matching a repeated query's condition can still appear ("phantom reads") in some implementations |
| Serializable | Every anomaly -- equivalent to *some* serial (one-at-a-time) execution order of all transactions |

Weaker isolation levels are chosen deliberately, not out of laziness -- they permit more concurrency (fewer conflicts force blocking/aborting), which is a genuine, measurable throughput tradeoff against correctness guarantees an application may or may not actually need for a given workload.

## Lock Manager

For engines that use locking (rather than -- or in addition to -- MVCC) for isolation: locks are typically hierarchical, with modes like **S** (shared, for reads), **X** (exclusive, for writes), and **intention locks** (**IS**/**IX** -- a coarser-grained "I intend to take a finer-grained S/X lock somewhere below this level" marker, letting a lock manager quickly detect a conflict between a transaction wanting a table-level X lock and another transaction that already holds a row-level lock somewhere inside that table, without having to scan every row-level lock individually). **Deadlock detection** maintains a **wait-for graph** (transaction A waits for a lock held by B, B waits for one held by C, ...) and periodically checks for cycles -- a detected cycle means those transactions can never all proceed, so the lock manager picks one as a **victim**, aborting and rolling it back to break the cycle and let the others proceed.

## Write-Ahead Logging and ARIES Recovery

Building on §11's WAL foundation, the classic **ARIES** recovery protocol runs recovery in three phases after a crash:

1. **Analysis**: scan the WAL forward from the last checkpoint to determine which transactions were active and which pages were dirty at the moment of the crash.
2. **Redo**: replay *every* logged change (even for transactions that never committed) from the appropriate point forward, restoring the data pages to exactly the state they were in immediately before the crash -- including the effects of transactions that will be undone in the next phase. This "redo everything, then undo the losers" ordering (rather than only redoing committed transactions) is a deliberate ARIES design choice that keeps the redo phase simple (a pure, order-independent replay) at the cost of doing some work in phase 2 that phase 3 then reverses.
3. **Undo**: roll back the changes of transactions that were still active (uncommitted) at crash time, using the WAL's undo information, restoring the database to a state reflecting only committed transactions.

## Checkpointing

As in §11, checkpoints bound recovery time by recording a point past which the analysis phase doesn't need to scan -- a database-specific checkpoint additionally records exactly which transactions were active and which pages were dirty *at* the checkpoint, giving the analysis phase a starting point rather than requiring it to reconstruct that state by scanning from the beginning of the log.

## Query Planning and Optimization

A SQL query is first translated into a **logical plan** (an abstract tree of relational operations -- select, project, join, aggregate -- with no commitment yet to *how* each operation is executed), then the **optimizer** searches for the cheapest **physical plan** (a concrete choice of algorithm and access path for each logical operation -- index scan vs. full table scan, nested-loop vs. hash vs. merge join, and in what order to join multiple tables) using a **cost model** that estimates each candidate plan's resource cost from statistics (table sizes, column value distributions/histograms, index selectivity estimates) gathered ahead of time.

**Join ordering** is the single most consequential decision a query optimizer makes for a multi-table query -- the same logical join can cost orders of magnitude more or less depending on which table is joined to which first (joining two large tables before filtering down to a small result, versus filtering first and joining small intermediate results, can differ enormously in the amount of intermediate data produced and processed) -- and it's a genuinely hard combinatorial search problem (the number of possible join orders grows factorially with the number of tables), which is why real optimizers use dynamic-programming-based search with pruning for reasonably-sized queries, and fall back to heuristics or the query's own written order for very large joins where exhaustive search becomes impractical. **Index selection** -- deciding whether using a given index is actually cheaper than a full table scan for a specific predicate -- depends heavily on estimated **selectivity** (what fraction of rows the predicate is expected to match): a highly selective predicate (matches a small fraction of rows) benefits enormously from an index; a predicate matching most of the table is often *cheaper* to satisfy via a sequential full scan than via the random I/O pattern (§11's B-tree random-access cost) that following an index into scattered table pages would incur -- a real, non-obvious crossover point every cost-based optimizer has to estimate correctly to avoid choosing an index that actually performs worse than not using one.

## Key Takeaways

- MVCC trades locking-based read/write conflict avoidance for keeping multiple row versions -- it gives snapshot isolation nearly for free, but serializability on top of MVCC needs extra dependency-tracking machinery.
- ARIES's "redo everything, then undo the losers" design keeps the redo phase a simple, order-independent replay, deliberately pushing the complexity of correctly reverting uncommitted work entirely into the separate undo phase.
- Join ordering and index-vs-scan selection are both fundamentally *cost estimation under uncertainty* problems -- the optimizer's decisions are only as good as its statistics, which is why stale statistics are a classic, real-world cause of a suddenly-terrible query plan with no change to the query itself.

## Interview Notes

- "How does MVCC let a long-running read transaction avoid blocking concurrent writers?" -- the reader is given a consistent snapshot as of its start time and reads whichever row versions were live then, regardless of writes committed by other transactions afterward -- no read lock is needed because the reader and writer are operating on logically different versions of the data.
- "Why might a query optimizer choose a full table scan over using an available index?" -- when the predicate's estimated selectivity is low (matches a large fraction of the table), the random I/O cost of following the index into scattered table pages can exceed the cost of one sequential scan over the whole table -- the optimizer's cost model is meant to catch exactly this crossover.
