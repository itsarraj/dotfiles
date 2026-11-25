---
id: 20260329180000
title: SQLx CLI & cargo sqlx cheatsheet
date: 2026-03-29
type: reference
status: stable
tags: [rust, sqlx, postgres, sqlite, migrations, cli]
links:
  - https://github.com/launchbadge/sqlx
---

# SQLx CLI

SQLx’s command-line utility for managing databases, migrations, and enabling **offline** mode with `sqlx::query!()` and related macros.

## Installation (Rust toolchain)

```bash
# All databases supported by SQLx (default feature set)
cargo install sqlx-cli

# PostgreSQL only
cargo install sqlx-cli --no-default-features --features native-tls,postgres

# Vendored OpenSSL (build OpenSSL from source)
cargo install sqlx-cli --features openssl-vendored

# Rustls instead of OpenSSL — add DB features you need
cargo install sqlx-cli --no-default-features --features rustls

# SQLite only, using the system SQLite library
cargo install sqlx-cli --no-default-features --features sqlite-unbundled
```

## Usage

Every command needs a database URL:

- **`--database-url …`**, or  
- **`DATABASE_URL`** in the environment, or  
- **`.env`** in the current working directory  

```bash
sqlx <command> --help
```

### Postgres example

```bash
DATABASE_URL=postgres://postgres@localhost/my_database
```

---

## Database operations

```bash
sqlx database create   # create DB at DATABASE_URL
sqlx database drop     # drop DB at DATABASE_URL
sqlx database reset    # drop, recreate, run pending migrations
sqlx database setup    # create DB (if needed) and run pending migrations
```

---

## Migrations

### Create migration files

```bash
sqlx migrate add <migration_name>
```

Creates a new file under `migrations/` (timestamped name). Put schema changes in that file.

**Reversible migrations** (separate `.up.sql` / `.down.sql`):

```bash
sqlx migrate add -r <name>
# e.g. migrations/20211001154420_<name>.up.sql
#      migrations/20211001154420_<name>.down.sql
```

After the first `-r` migration, later `sqlx migrate add <name>` migrations are reversible too (up/down pair).

### Run / inspect

```bash
sqlx migrate run
```

Compares the DB migration history to the `migrations/` folder and applies pending scripts.

**Custom migrations directory:**

```bash
sqlx migrate run --source ../relative/migrations
sqlx migrate info --source ../relative/migrations
```

`sqlx migrate info` lists all available migrations (and how they relate to the DB).

### Revert

```bash
sqlx migrate revert
```

Reverts the latest migration that has a **down** file (from `-r` workflow).

### Other migrate commands (current CLI)

```bash
sqlx migrate build-script   # generate build.rs to recompile on new migrations
```

---

## Offline mode (`query!` / compile-time checks)

Two ideas: **save metadata** once (with DB), then **build** using that cache.

### 1. Save query metadata

Must be run as **`cargo sqlx`**, not `sqlx`:

```bash
cargo sqlx prepare
```

Writes metadata under **`.sqlx/`** in the current crate directory. Commit **`.sqlx/`** to version control so CI/other machines need no live DB for those checks.

**Workspace** (several crates use macros):

```bash
cargo sqlx prepare --workspace
```

### 2. CI: ensure `.sqlx` is up to date

```bash
cargo sqlx prepare --check
cargo sqlx prepare --check --workspace
```

Exits non-zero if `.sqlx` is stale vs current queries/schema.

### 3. Force offline builds

If **`DATABASE_URL`** is set, SQLx prefers the live DB over `.sqlx`. To avoid accidental DB access during `cargo build`:

```bash
export SQLX_OFFLINE=true
# or in .env: SQLX_OFFLINE=true
```

`cargo sqlx prepare` still connects to the DB when generating metadata.

### Queries behind features or in tests

Pass through to `cargo` so all targets/features are visible:

```bash
cargo sqlx prepare -- --all-targets --all-features
```

---

## Quick reference

| Task | Command |
|------|---------|
| Create DB | `sqlx database create` |
| Drop DB | `sqlx database drop` |
| Reset DB + migrate | `sqlx database reset` |
| Add migration | `sqlx migrate add <name>` |
| Add reversible | `sqlx migrate add -r <name>` |
| Apply migrations | `sqlx migrate run` |
| Revert last (with down) | `sqlx migrate revert` |
| Prepare offline data | `cargo sqlx prepare` |
| Check `.sqlx` fresh | `cargo sqlx prepare --check` |

---

## Log

- 2026-03-29 — Expanded install variants, reversible migrations, `cargo sqlx prepare`, `SQLX_OFFLINE`, CI `--check`; aligned `database` / `migrate` commands with current `sqlx-cli` help output.
