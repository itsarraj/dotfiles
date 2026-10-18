# The Rust Ecosystem: tokio, hyper, axum, tonic, tower, serde, and the Rest

Prerequisite: §07 (async runtime internals), handbook §30 (concurrency). This file is a map of what each major crate actually is and where it fits, not a tutorial on using any one of them.

## The Async/Networking Stack

**`tokio`** -- the async runtime (§07): scheduler, reactor, timers, and the async-flavored equivalents of `std`'s threading/sync primitives (`tokio::sync::Mutex`, channels). Nearly everything else in this section is built *on top of* tokio rather than being an alternative to it.

**`hyper`** -- a low-level HTTP/1 and HTTP/2 implementation, deliberately *not* a full "framework" -- it handles connection management, request/response parsing, and protocol correctness, but leaves routing, middleware conventions, and application structure entirely to whatever's built on top of it (axum, below, being the dominant example).

**`axum`** -- a web framework built on `hyper` + `tower` (below), oriented around **extractors** (function parameters that pull typed data out of a request -- a JSON body, a path parameter, request headers -- via a trait, `FromRequest`, rather than a framework-specific "context" object you manually query) and ordinary `async fn` handlers. Its routing and middleware are expressed as `tower::Service`s, which is *why* axum interoperates so cleanly with the broader `tower` middleware ecosystem (rate limiting, tracing, timeouts, load shedding written once against `tower`'s `Service` trait work unmodified across axum, tonic, and any other `tower`-based server).

**`tower`** -- not a framework at all, but a single trait (`Service<Request> -> Future<Output = Result<Response, Error>>`) plus a set of composable **middleware** (`Layer`s) implementing cross-cutting concerns (timeouts, retries, load shedding, rate limiting, tracing) against that one trait, regardless of whether the underlying request is HTTP, gRPC, or something else entirely. This is the same idea as middleware/interceptor chains in other web ecosystems, but genuinely protocol-agnostic -- a `tower::Layer` written for rate limiting works unmodified whether the `Service` underneath is serving HTTP (via axum) or gRPC (via tonic).

**`tonic`** -- a gRPC implementation built on `hyper` (specifically its HTTP/2 support, since gRPC is defined as running over HTTP/2, handbook §10) and `tower` (for the same middleware-composability reason axum uses it) -- generates Rust client/server code directly from `.proto` service definitions via a build-time code generator (`prost`, below, handles the message-type side; `tonic-build` handles the service/RPC side).

**`reqwest`** -- the dominant HTTP *client* library (as opposed to hyper/axum/tonic, which are primarily server-side-oriented, though hyper itself does have client capabilities reqwest builds on) -- higher-level, batteries-included (connection pooling, redirect following, JSON body helpers via `serde`) versus hyper's deliberately low-level client API.

## Serialization

**`serde`** -- not a serialization format itself, but a **generic serialization framework**: a type implements `Serialize`/`Deserialize` once (commonly via `#[derive(Serialize, Deserialize)]`), and that single implementation works with *any* format that provides a serde backend (`serde_json`, `bincode`, `postcard`, `serde_yaml`, `toml`, ...) without the type's own code knowing or caring which format is actually in use. This is achieved through a **visitor pattern**: `Serialize`'s implementation calls generic methods (`serialize_struct`, `serialize_field`, ...) on whatever `Serializer` it's given, and each format crate provides a `Serializer` implementation translating those generic calls into its own concrete wire format -- the same "one generic interface, many concrete backends" idea `tower::Service` applies to networking, applied here to data encoding.

**`bytes`** -- provides `Bytes`/`BytesMut`, a **reference-counted, cheaply-cloneable byte buffer** designed specifically for networking code: cloning a `Bytes` is `O(1)` (an `Arc`-like refcount bump over a shared underlying buffer, §05's `Arc` material) rather than copying the underlying data, and slicing a `Bytes` produces a new `Bytes` sharing the same backing allocation rather than copying -- exactly the property a network stack passing the same buffer through multiple protocol layers (TCP → TLS → HTTP → application) wants, avoiding a copy at every layer boundary.

**`futures`** -- the crate that existed *before* `async`/`await` was stabilized in the language, and today primarily provides the extended combinator ecosystem (`FuturesUnordered`, `select!`, `join!` outside of a specific runtime, `Stream` -- the async analog of `Iterator`) that complements, rather than replaces, `std::future::Future` and a runtime like tokio.

## Concurrency and Parallelism

**`parking_lot`** -- covered in §05/§06: smaller, faster, non-poisoning-by-default `Mutex`/`RwLock` alternatives to `std::sync`'s.

**`crossbeam`** -- covered in §06: `crossbeam-epoch` (epoch-based reclamation), `crossbeam-channel` (a widely-used MPMC channel implementation, often preferred over `std::sync::mpsc` for its performance and additional features like `select!`), and ready-made lock-free structures (`SegQueue`, `SkipMap`).

**`rayon`** -- **data-parallelism**, not async concurrency: turns an ordinary iterator chain into a parallel one (`vec.iter().map(...)` → `vec.par_iter().map(...)`) using a work-stealing thread pool under the hood (the same work-stealing idea §07 described for tokio's *task* scheduler, applied here to *data-parallel* CPU-bound work instead of I/O-bound async tasks) -- the right tool for "I have a CPU-bound computation over a collection and want to use all cores," which is a different problem than tokio's "I have many concurrent, mostly-I/O-waiting tasks."

## Caching and Concurrent Data Structures

**`dashmap`** -- a concurrent `HashMap` alternative to wrapping `std::collections::HashMap` in a `Mutex`/`RwLock`: internally **shards** the map into many independent sub-maps, each with its own lock, so operations on keys that happen to hash into different shards can proceed fully in parallel with no contention at all -- a real, measurable win over a single global lock for read/write-heavy concurrent access patterns, at the cost of some operations that need a *global* view (like `len()`, or iterating the whole map) being more expensive than they'd be with one simple lock.

**`moka`** -- a caching library providing bounded, concurrent caches with configurable eviction policies (including **TinyLFU**-based admission, a more sophisticated policy than plain LRU that tracks a compact frequency sketch of recently-seen keys to make smarter admit/evict decisions than pure recency alone would) and time-based expiration -- the Rust ecosystem's answer to the same caching-layer role Caffeine (Java) or a Redis-fronted layer plays in other stacks, but in-process rather than requiring a separate service.

## Databases

**`sqlx`** -- an *async*, **compile-time-checked** SQL query interface: `sqlx`'s macros connect to a real database at *compile time* (or against a saved query-metadata cache) to verify a given SQL string actually type-checks against the real schema, catching a class of bug (a typo'd column name, a type mismatch) at build time that would otherwise only surface at runtime -- without requiring a full ORM's abstraction layer, since queries remain plain SQL strings.

**`diesel`** -- a more traditional, synchronous **ORM** with its own query-builder DSL (Rust code that constructs a query, rather than embedding raw SQL strings) and a `#[derive(Queryable)]`-style mapping between Rust structs and table rows -- trading `sqlx`'s "write real SQL, get it checked" model for a more abstracted, Rust-native query construction API, at the cost of the DSL itself being another thing to learn on top of SQL.

## Observability

**`tracing`** -- covered in the handbook's observability chapter: structured, span-based logging (`#[instrument]` auto-generating entry/exit spans with timing) that composes naturally with async code specifically because a `tracing` span can be entered/exited across `.await` points correctly (ordinary sequential logging libraries built around a simple "current context" global often get this wrong across an executor interleaving multiple tasks on one thread) -- the de facto standard for anything beyond the simplest async Rust service's logging needs.

## Key Takeaways

- `tower`'s single `Service` trait is why the same middleware (rate limiting, retries, tracing) works unmodified across axum (HTTP) and tonic (gRPC) -- it's the actual unifying abstraction underneath "the Rust web ecosystem," not axum or hyper themselves.
- `serde`'s visitor-pattern design is what lets one `#[derive(Serialize)]` work against JSON, bincode, YAML, and any other format with a serde backend, without the derived code knowing which format is in use.
- `rayon` (data parallelism, CPU-bound) and `tokio` (async concurrency, I/O-bound) solve genuinely different problems that are easy to conflate under the umbrella term "concurrency" -- picking the wrong one for a given workload is a common early mistake.

## Interview Notes

- "Why do axum and tonic middleware compose so cleanly despite being HTTP and gRPC respectively?" -- both are built on `tower::Service`, a single protocol-agnostic trait; middleware written against that trait doesn't know or care what protocol is actually running underneath.
- "When would you reach for `rayon` instead of `tokio`?" -- when the work is CPU-bound and parallelizable across cores (e.g., processing every element of a large in-memory collection), rather than I/O-bound and concurrency-bound (waiting on many sockets/files at once), which is tokio's actual sweet spot.
