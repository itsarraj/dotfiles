# Plans

**Updated**: 2026-11-24

---

## Mission

Move to Bangalore. Execute day job well. Build real systems Rust on own time.  
Find the right founder or become one. Eventually exit India.

---

## Reality: What I Have and What I Need

| Have | Need |
|---|---|
| Rust job (ITC/SAP, remote) | Bangalore move done |
| Rust iced + AI tooling experience | Low-level systems Rust portfolio |
| Full ownership on current project | Founder network in Bangalore |
| Resume credibility starting | Savings buffer |

The day job is application-layer Rust. Real systems depth comes from own projects.  
Both tracks run in parallel. Neither waits for the other.

---

## Track 1: Bangalore Move

**Do this first. Everything else is easier from there.**

- Find PG or room share — HSR Layout, Koramangala, Indiranagar, Whitefield
- Budget: 3k–6k/month rent + food — easily covered on current salary
- Target: moved within 4-6 weeks

**Once there:**
- Nasscom 10000 Startups hub — free coworking, founder events
- HasGeek events — Bangalore's best tech community, systems/infra people here
- Rust India community — Telegram + meetups
- Dukaan, Setu, Hasura, Obvious — Bangalore startups worth watching
- IndieBio, Antler, Surge — accelerators running cohorts

---

## Track 2: Day Job — Execute Well

**Project**: Screen recording + AI demo tool for SAP clients  
**Stack**: Rust iced (GUI), LangChain/LangGraph (AI backend)  
**Position**: Solo dev, full ownership, SAP seniors as stakeholders

How to extract maximum value from this:

- Ship clean, documented Rust — it's your portfolio code
- Push to a private or public GitHub repo (check NDA carefully)
- If public isn't possible, write about it — blog post, tweet thread, LinkedIn post
- Ask SAP seniors for intro to anyone doing systems/infra work
- Treat every deliverable as a demo of what you can build solo

---

## Track 3: Low-Level Rust Portfolio (own time)

**The gap**: Day job is app-layer Rust. Systems jobs and serious startups want low-level.  
**The fix**: Build the gap closed on your own time. 1-2 hours daily minimum.

### Phase A: Rust for Rustaceans (finish this)

One chapter, one build project, one ASM dissection. In order.

| # | Chapter | Build | Dissect |
|---|---|---|---|
| 1 | Types — layout, variance, PhantomData | typed newtype fd wrappers | struct Fd(i32) vs i32 in ASM — zero cost |
| 2 | Traits & Generics — dyn, vtables, monomorphization | trait Read/Write on custom types | dyn dispatch vs impl Trait in ASM |
| 3 | Designing Interfaces — type-state, builder, sealed | type-state Fd (Open/Closed) | PhantomData in ASM — verify zero bytes |
| 4 | Error Handling — thiserror, anyhow, context | syscall wrapper + typed errno enum | Result<i32,Errno> layout vs C int+errno |
| 5 | Project Structure — workspaces, features, cfg | multi-crate: syscall-raw / syscall-safe / CLI | nm + readelf on final binary |
| 6 | Testing — proptest, cargo-fuzz | /proc/self/status parser + fuzzer | compare to handwritten C parser output |
| 7 | Macros — macro_rules!, tt-muncher | macro-generated syscall wrappers | do macro fns inline? cargo-asm |
| 8 | Async — Future, Waker, Pin, state machine | minimal single-threaded async executor | Poll::Pending state machine in ASM |
| 9 | Unsafe — raw pointers, invariants, soundness | arena/bump allocator, no_std | compare to C bump allocator — near-identical ASM |
| 10 | Concurrency — atomics, ordering, lock-free | lock-free stack, AtomicPtr + compare_exchange | lock cmpxchg instruction directly |

### Phase B: Tokio (non-negotiable for jobs)

After RfR. Every Bangalore systems job uses it.

- Tokio book — tasks, channels, select!, timeouts
- Build: async TCP server, multiple clients
- Build: async file watcher with inotify + Tokio

### Phase C: Portfolio Projects (the proof)

These go on GitHub with clean READMEs. This is what gets you interviews and founder attention.

| Project | What it shows |
|---|---|
| `fd-safe` — type-safe Linux syscall wrappers | unsafe Rust, Linux API, type design |
| `bump-alloc` — arena allocator, no_std | unsafe Rust, memory model |
| `lockfree-stack` — AtomicPtr, compare_exchange | concurrency, atomics |
| `mini-executor` — hand-rolled async executor | Future/Waker internals |
| `proc-parser` — /proc/self/maps parser + fuzzer | byte parsing, cargo-fuzz, Linux knowledge |

**What makes a project hireable:**
- Error cases handled explicitly — no unwrap() everywhere
- Tests — unit at minimum, fuzz or property ideally
- README explains *why*, not just *what*
- Clean commits — tell a story

---

## Track 4: Founder Network + Startup Path

**The play**: Get to Bangalore → go to events → find what's being built → find the bet.

You don't need to know the idea yet. You need to be in the room.

**What to look for in a co-founder or early team:**
- Building something in infra, AI infra, developer tools, or data
- Technical, early-stage, ideally pre-seed or just raised seed
- Needs someone who can own engineering solo

**When to make the move:**
- If you find something worth betting on → join part-time first, then full
- If nothing fits → build your own, once you have savings + depth
- If a systems role abroad opens up → take it, startup follows later

---

## Job Search (keep this warm, don't stop)

Even with current job, keep one eye on the market.

**Titles to search:**
- Rust Engineer / Rust Developer
- Systems Engineer — Rust
- Infrastructure Engineer
- Platform Engineer
- Storage Engineer

**Companies (Bangalore priority):**
- Zscaler, Fortanix — security/networking, real low-level Rust
- Nutanix, Commvault, Druva, Aerospike — storage/infra
- MongoDB, Databricks — database internals
- Startups on Wellfound, Cutshort, Instahyre

**Boards:**
- RustJobs.dev, LinkedIn, Cutshort, Instahyre, Wellfound, Hirist

---

## Daily Execution

One thing at a time. No context switching mid-session.

```
Morning     → Day job (ship, build, document)
Evening     → Rust portfolio work (RfR chapter or build project)
Weekends    → Events, meetups, founder conversations
```

---

## What's Parked

- GATE — not relevant right now
- MS Europe/USA — revisit after 1-2 years in Bangalore with savings
- CUDA, SIMD, AVX-512, Assembly deep work — after Tokio + portfolio done
- Digital Logic, COA — not relevant right now

Not abandoned. Sequenced. Exit India first. Then go deep on the technical north star.
