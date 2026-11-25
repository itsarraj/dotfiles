---
id: 20250930001555
title: Rust Actix r2d2 diesel dotenvy
date: 2025-09-30 00:16
tags: []
links: []
---

## Previous Project Notes

I was working on my  rust project of insiderlist.
and there are two rate limiters that I can use:

actie-extensible-rate-limit vs actix governor
actix-governor is a high-performance, simple middleware designed for fast in-memory rate limiting using atomic counters, ideal for single-instance apps. 
actix-extensible-rate-limit offers better scalability with pluggable backends (e.g., Redis), making it suitable for distributed deployments. 

// Summary:
// - actix-governor: fastest, simplest setup, great for single-instance apps.
// - actix-extensible-rate-limit: scalable via Redis/backends, suited for distributed setups.
// Recommendation: use governor for local/small apps; extensible for distributed/multi-server scenarios.


Key Comparisons:
Performance: actix-governor is faster due to its reliance on in-memory atomic counters.
Scalability: actix-extensible-rate-limit supports shared backends (Redis), allowing rate limiting across multiple server instances.
Ease of Use: actix-governor is often considered easier to set up for basic needs, while actix-extensible-rate-limit requires backend configuration.
Flexibility: actix-extensible-rate-limit provides greater flexibility in choosing how to store rate-limit data. 
Reddit
Reddit
 +4
Recommendation:
Use actix-governor for simple projects needing high speed. Use actix-extensible-rate-limit if your application is distributed and requires a shared, consistent rate-limit state across instances. 

---

- []() - Add link context: why notes are connected
- []() - Add link context: why notes are connected

---

# Journey from 0 

Diesel handles ORM and query building but doesn't pool connections; r2d2 is a generic connection pool. Use Diesel + Diesel's r2d2 integration for async-safe, reusable DB connections in web apps. Avoid r2d2_postgres unless running raw SQL outside Diesel.

Use dotenvy over dotenv for new Rust projects—actively maintained, safer, and drop-in compatible.
