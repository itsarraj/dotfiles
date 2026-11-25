# Redis & Valkey Complete Learning Guide: From Start to Finish

> **Target Environment**: Arch Linux | **Goal**: Complete mastery for Rust + PostgreSQL + Redis applications

## Table of Contents
1. [Introduction & Overview](#1-introduction--overview)
2. [Installation on Arch Linux](#2-installation-on-arch-linux)
3. [Redis Fundamentals](#3-redis-fundamentals)
4. [Data Structures Deep Dive](#4-data-structures-deep-dive)
5. [Configuration & Persistence](#5-configuration--persistence)
6. [Redis Commands & Operations](#6-redis-commands--operations)
7. [Clustering & High Availability](#7-clustering--high-availability)
8. [Rust Integration](#8-rust-integration)
9. [PostgreSQL + Redis Hybrid Patterns](#9-postgresql--redis-hybrid-patterns)
10. [Performance & Monitoring](#10-performance--monitoring)
11. [Production Deployment](#11-production-deployment)
12. [Troubleshooting & Best Practices](#12-troubleshooting--best-practices)

---

## 1. Introduction & Overview

### What is Redis?
Redis (Remote Dictionary Server) is an open-source, in-memory data structure store used as a database, cache, and message broker. It's known for its exceptional performance and versatility.

### What is Valkey?
Valkey is a Redis fork created by Linux Foundation after Redis changed its license. It maintains full compatibility with Redis while being community-driven.

### Why Redis for Your Rust Stack?
- **Caching Layer**: Speed up PostgreSQL queries
- **Session Storage**: Store user sessions, JWT tokens
- **Real-time Features**: Pub/Sub for live updates
- **Rate Limiting**: API rate limiting
- **Data Structures**: Sets, sorted sets, hashes for complex data models

---

## 2. Installation on Arch Linux

### Option 1: Install Redis (Official)
```bash
sudo pacman -S redis
```

### Option 2: Install Valkey (Community Fork)
```bash
# Add chaotic-aur repository for pre-built packages
sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
sudo pacman-key --lsign-key 3056513887B78AEB
sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

# Add to pacman.conf
echo "[chaotic-aur]" >> /etc/pacman.conf
echo "Include = /etc/pacman.d/chaotic-mirrorlist" >> /etc/pacman.conf

sudo pacman -Syyu valkey
```

### Basic Service Management
```bash
# Start service
sudo systemctl start redis  # or valkey

# Enable auto-start
sudo systemctl enable redis  # or valkey

# Check status
sudo systemctl status redis  # or valkey

# View logs
sudo journalctl -u redis -f
```

### Verify Installation
```bash
redis-cli ping
# Should return: PONG
```

---

## 3. Redis Fundamentals

### Architecture Overview
```
┌─────────────────┐    ┌─────────────────┐
│   Application   │────│     Redis       │
│   (Rust/Node)   │    │  In-Memory DB   │
└─────────────────┘    └─────────────────┘
                              │
                              ▼
                       ┌─────────────────┐
                       │   Persistence   │
                       │   (Optional)    │
                       └─────────────────┘
```

### Key Concepts
- **In-Memory**: All data stored in RAM for lightning-fast access
- **Key-Value Store**: But supports complex data structures
- **Single-Threaded**: No concurrency issues, predictable performance
- **Persistence**: Optional disk storage (RDB snapshots, AOF logs)
- **Pub/Sub**: Built-in message broker
- **Lua Scripting**: Server-side scripting

### Redis vs PostgreSQL Comparison

| Feature | Redis | PostgreSQL |
|---------|-------|------------|
| Data Persistence | Optional | Always |
| Performance | ~100k ops/sec | ~10k ops/sec |
| Data Structures | Rich (lists, sets, etc.) | Tables only |
| ACID Compliance | No | Yes |
| Scalability | Horizontal/Vertical | Vertical |
| Use Case | Cache, Sessions, RT data | Primary storage, complex queries |

---

## 4. Data Structures Deep Dive

### 1. Strings (Most Common)
```bash
# Basic operations
SET user:123:name "John Doe"
GET user:123:name
# Returns: "John Doe"

# Numeric operations
SET counter 0
INCR counter
INCRBY counter 5
GET counter
# Returns: 6

# Bit operations
SETBIT user:permissions 0 1  # Admin
SETBIT user:permissions 1 1  # Read
SETBIT user:permissions 2 1  # Write
GETBIT user:permissions 0    # Returns: 1
```

### 2. Lists (Linked Lists)
```bash
# Queue operations
LPUSH notifications "New message"
LPUSH notifications "Friend request"
LRANGE notifications 0 -1
# Returns: ["Friend request", "New message"]

# Stack operations
RPUSH stack "item1"
RPUSH stack "item2"
RPOP stack  # Returns: "item2"
```

### 3. Sets (Unique Values)
```bash
# User interests
SADD user:123:interests "rust" "linux" "redis"
SADD user:456:interests "python" "docker" "redis"

# Find common interests
SINTER user:123:interests user:456:interests
# Returns: ["redis"]

# Union of interests
SUNION user:123:interests user:456:interests
# Returns: ["rust", "linux", "redis", "python", "docker"]
```

### 4. Sorted Sets (Ordered Sets)
```bash
# Leaderboard
ZADD leaderboard 100 "user1"
ZADD leaderboard 150 "user2"
ZADD leaderboard 120 "user3"

# Get top players
ZREVRANGE leaderboard 0 2 WITHSCORES
# Returns: ["user2", "150", "user3", "120", "user1", "100"]
```

### 5. Hashes (Objects)
```bash
# User profile
HSET user:123 name "John" email "john@example.com" age "30"
HGET user:123 name
# Returns: "John"

HGETALL user:123
# Returns: ["name", "John", "email", "john@example.com", "age", "30"]

# Increment age
HINCRBY user:123 age 1
```

### 6. Bitmaps & HyperLogLog
```bash
# User activity tracking (bitmap)
SETBIT daily:active:2024-01-01 12345 1  # User 12345 was active

# Count active users
BITCOUNT daily:active:2024-01-01

# Unique visitor counting (HyperLogLog)
PFADD page:visitors "user1" "user2" "user1"  # Only counts unique
PFCOUNT page:visitors  # Returns: 2
```

---

## 5. Configuration & Persistence

### Configuration File Location
```bash
# Redis
/etc/redis.conf

# Valkey
/etc/valkey.conf
```

### Essential Configuration Settings
```conf
# Network
bind 127.0.0.1  # Listen only on localhost
port 6379       # Default port

# Memory Management
maxmemory 256mb                    # Limit memory usage
maxmemory-policy allkeys-lru      # Eviction policy

# Persistence
save 900 1      # Save after 900 seconds if 1 key changed
save 300 10     # Save after 300 seconds if 10 keys changed
save 60 10000   # Save after 60 seconds if 10000 keys changed

appendonly yes  # Enable AOF persistence
appendfilename "appendonly.aof"

# Security
requirepass your_password_here    # Set password
```

### Persistence Strategies

#### 1. RDB Snapshots (Point-in-time backups)
- **Pros**: Compact, fast loading, good for backups
- **Cons**: Potential data loss between snapshots
- **Use Case**: When you can afford some data loss

#### 2. AOF (Append Only File) (Every operation logged)
- **Pros**: Minimal data loss, human-readable
- **Cons**: Larger files, slower startup
- **Use Case**: When durability is critical

#### 3. Hybrid (Both)
- Best of both worlds
- Recommended for production

---

## 6. Redis Commands & Operations

### Connection Commands
```bash
# Connect to Redis
redis-cli

# Authenticate
AUTH your_password

# Select database (0-15 available)
SELECT 1

# Get info
INFO
INFO memory
INFO stats
```

### Key Management
```bash
# Check if key exists
EXISTS user:123

# Set expiration
SET session:abc123 "data" EX 3600  # Expires in 1 hour
EXPIRE user:123 86400              # Expire in 24 hours

# Get TTL
TTL user:123

# Delete keys
DEL user:123
UNLINK user:123  # Async delete

# Pattern matching
KEYS user:*      # Get all user keys (SLOW!)
SCAN 0 MATCH user:* COUNT 100  # Cursor-based iteration
```

### Transactions
```bash
# Multi-exec transaction
MULTI
SET balance:123 100
INCR balance:123
EXEC

# Watch for changes
WATCH balance:123
MULTI
INCR balance:123
EXEC  # Only succeeds if balance:123 wasn't modified
```

---

## 7. Clustering & High Availability

### Redis Cluster
```bash
# Start cluster-enabled Redis instances
redis-server /etc/redis.conf --cluster-enabled yes --cluster-config-file nodes.conf

# Create cluster
redis-cli --cluster create 127.0.0.1:7001 127.0.0.1:7002 127.0.0.1:7003 \
  127.0.0.1:7004 127.0.0.1:7005 127.0.0.1:7006 \
  --cluster-replicas 1
```

### Sentinel (Automatic Failover)
```yaml
# sentinel.conf
sentinel monitor mymaster 127.0.0.1 6379 2
sentinel down-after-milliseconds mymaster 5000
sentinel failover-timeout mymaster 60000
sentinel parallel-syncs mymaster 1
```

### Replication Setup
```bash
# On slave Redis instances
SLAVEOF master_ip master_port
# or in config: slaveof master_ip master_port
```

---

## 8. Rust Integration

### Popular Rust Redis Crates

#### 1. `redis` (Official Redis crate)
```toml
[dependencies]
redis = "0.23"
tokio = { version = "1.0", features = ["full"] }
```

#### 2. `deadpool-redis` (Connection Pooling)
```toml
[dependencies]
deadpool-redis = "0.12"
```

### Basic Connection
```rust
use redis::Commands;
use std::collections::HashMap;

#[tokio::main]
async fn main() -> redis::RedisResult<()> {
    // Connect to Redis
    let client = redis::Client::open("redis://127.0.0.1/")?;
    let mut con = client.get_connection()?;

    // Basic operations
    let _: () = con.set("my_key", "my_value")?;
    let value: String = con.get("my_key")?;
    println!("Value: {}", value);

    Ok(())
}
```

### Connection Pooling
```rust
use deadpool_redis::{Config, Runtime};
use std::env;

#[derive(Clone)]
pub struct RedisPool {
    pool: deadpool_redis::Pool,
}

impl RedisPool {
    pub fn new() -> Self {
        let mut cfg = Config::from_url(env::var("REDIS_URL").unwrap_or("redis://127.0.0.1:6379".to_string()));
        cfg.max_size = Some(16); // Connection pool size

        let pool = cfg.create_pool(Some(Runtime::Tokio1)).unwrap();
        Self { pool }
    }

    pub async fn get_connection(&self) -> deadpool_redis::Connection {
        self.pool.get().await.unwrap()
    }
}
```

### User Session Management
```rust
use serde::{Deserialize, Serialize};
use redis::Commands;

#[derive(Serialize, Deserialize, Debug)]
pub struct UserSession {
    pub user_id: String,
    pub email: String,
    pub role: String,
    pub created_at: i64,
}

pub struct SessionManager {
    redis_pool: RedisPool,
}

impl SessionManager {
    pub fn new(redis_pool: RedisPool) -> Self {
        Self { redis_pool }
    }

    pub async fn create_session(&self, session_id: &str, session: &UserSession) -> Result<(), Box<dyn std::error::Error>> {
        let mut conn = self.redis_pool.get_connection().await;
        let session_json = serde_json::to_string(session)?;

        // Store session with 24 hour expiration
        let _: () = redis::cmd("SETEX")
            .arg(format!("session:{}", session_id))
            .arg(86400) // 24 hours
            .arg(session_json)
            .query_async(&mut conn)
            .await?;

        Ok(())
    }

    pub async fn get_session(&self, session_id: &str) -> Result<Option<UserSession>, Box<dyn std::error::Error>> {
        let mut conn = self.redis_pool.get_connection().await;

        let session_json: Option<String> = redis::cmd("GET")
            .arg(format!("session:{}", session_id))
            .query_async(&mut conn)
            .await?;

        match session_json {
            Some(json) => {
                let session: UserSession = serde_json::from_str(&json)?;
                Ok(Some(session))
            }
            None => Ok(None),
        }
    }

    pub async fn delete_session(&self, session_id: &str) -> Result<(), Box<dyn std::error::Error>> {
        let mut conn = self.redis_pool.get_connection().await;
        let _: () = redis::cmd("DEL")
            .arg(format!("session:{}", session_id))
            .query_async(&mut conn)
            .await?;
        Ok(())
    }
}
```

### Caching Layer for PostgreSQL
```rust
use std::time::Duration;

pub struct CacheManager {
    redis_pool: RedisPool,
}

impl CacheManager {
    pub async fn get_or_set<T, F, Fut>(
        &self,
        key: &str,
        ttl_seconds: u64,
        fetch_fn: F,
    ) -> Result<T, Box<dyn std::error::Error>>
    where
        T: serde::de::DeserializeOwned + serde::Serialize,
        F: FnOnce() -> Fut,
        Fut: std::future::Future<Output = Result<T, Box<dyn std::error::Error>>>,
    {
        let mut conn = self.redis_pool.get_connection().await;

        // Try to get from cache
        let cached: Option<String> = redis::cmd("GET")
            .arg(key)
            .query_async(&mut conn)
            .await?;

        if let Some(cached_json) = cached {
            let data: T = serde_json::from_str(&cached_json)?;
            return Ok(data);
        }

        // Fetch from database
        let data = fetch_fn().await?;

        // Cache the result
        let json_data = serde_json::to_string(&data)?;
        let _: () = redis::cmd("SETEX")
            .arg(key)
            .arg(ttl_seconds)
            .arg(json_data)
            .query_async(&mut conn)
            .await?;

        Ok(data)
    }

    pub async fn invalidate(&self, key: &str) -> Result<(), Box<dyn std::error::Error>> {
        let mut conn = self.redis_pool.get_connection().await;
        let _: () = redis::cmd("DEL")
            .arg(key)
            .query_async(&mut conn)
            .await?;
        Ok(())
    }
}
```

### Rate Limiting
```rust
use std::time::{SystemTime, UNIX_EPOCH};

pub struct RateLimiter {
    redis_pool: RedisPool,
}

impl RateLimiter {
    // Fixed window rate limiting
    pub async fn check_rate_limit(
        &self,
        key: &str,
        max_requests: i64,
        window_seconds: i64,
    ) -> Result<bool, Box<dyn std::error::Error>> {
        let mut conn = self.redis_pool.get_connection().await;
        let now = SystemTime::now().duration_since(UNIX_EPOCH)?.as_secs() as i64;
        let window_start = now - window_seconds;

        // Remove old requests outside the window
        let _: () = redis::cmd("ZREMRANGEBYSCORE")
            .arg(format!("ratelimit:{}", key))
            .arg("-inf")
            .arg(window_start)
            .query_async(&mut conn)
            .await?;

        // Count requests in current window
        let count: i64 = redis::cmd("ZCARD")
            .arg(format!("ratelimit:{}", key))
            .query_async(&mut conn)
            .await?;

        if count >= max_requests {
            return Ok(false); // Rate limit exceeded
        }

        // Add current request
        let _: () = redis::cmd("ZADD")
            .arg(format!("ratelimit:{}", key))
            .arg(now)
            .arg(now)
            .query_async(&mut conn)
            .await?;

        // Set expiration on the sorted set
        let _: () = redis::cmd("EXPIRE")
            .arg(format!("ratelimit:{}", key))
            .arg(window_seconds * 2) // Keep longer for cleanup
            .query_async(&mut conn)
            .await?;

        Ok(true)
    }
}
```

---

## 9. PostgreSQL + Redis Hybrid Patterns

### Cache-Aside Pattern
```rust
pub struct HybridStorage {
    postgres_pool: sqlx::PgPool,
    cache: CacheManager,
}

impl HybridStorage {
    pub async fn get_user(&self, user_id: &str) -> Result<User, Box<dyn std::error::Error>> {
        let cache_key = format!("user:{}", user_id);

        // Try cache first
        if let Ok(Some(user)) = self.cache.get_or_set(&cache_key, 3600, || async {
            // This closure only runs if cache miss
            let user = sqlx::query_as!(
                User,
                "SELECT id, name, email FROM users WHERE id = $1",
                user_id
            )
            .fetch_one(&self.postgres_pool)
            .await?;

            Ok(user)
        }).await {
            return Ok(user);
        }

        Err("User not found".into())
    }

    pub async fn update_user(&self, user_id: &str, updates: UserUpdate) -> Result<(), Box<dyn std::error::Error>> {
        // Update database
        sqlx::query!(
            "UPDATE users SET name = $1, email = $2 WHERE id = $3",
            updates.name,
            updates.email,
            user_id
        )
        .execute(&self.postgres_pool)
        .await?;

        // Invalidate cache
        self.cache.invalidate(&format!("user:{}", user_id)).await?;

        Ok(())
    }
}
```

### Write-Through Caching
```rust
impl HybridStorage {
    pub async fn create_user(&self, user: NewUser) -> Result<String, Box<dyn std::error::Error>> {
        // Insert into database
        let user_id = sqlx::query_scalar!(
            "INSERT INTO users (name, email) VALUES ($1, $2) RETURNING id",
            user.name,
            user.email
        )
        .fetch_one(&self.postgres_pool)
        .await?;

        // Immediately cache the new user
        let cache_key = format!("user:{}", user_id);
        self.cache.get_or_set(&cache_key, 3600, || async {
            Ok(User {
                id: user_id.clone(),
                name: user.name,
                email: user.email,
            })
        }).await?;

        Ok(user_id)
    }
}
```

### Database Result Caching
```rust
pub struct QueryCache {
    redis_pool: RedisPool,
}

impl QueryCache {
    pub async fn cached_query<T>(
        &self,
        query_key: &str,
        ttl: u64,
        query_fn: impl FnOnce() -> std::pin::Pin<Box<dyn std::future::Future<Output = Result<T, sqlx::Error>> + Send>>,
    ) -> Result<T, Box<dyn std::error::Error>>
    where
        T: serde::de::DeserializeOwned + serde::Serialize + Send + Sync,
    {
        let mut conn = self.redis_pool.get_connection().await;

        // Check cache
        let cached: Option<String> = redis::cmd("GET")
            .arg(query_key)
            .query_async(&mut conn)
            .await?;

        if let Some(cached_data) = cached {
            let result: T = serde_json::from_str(&cached_data)?;
            return Ok(result);
        }

        // Execute query
        let result = query_fn().await?;

        // Cache result
        let serialized = serde_json::to_string(&result)?;
        let _: () = redis::cmd("SETEX")
            .arg(query_key)
            .arg(ttl)
            .arg(serialized)
            .query_async(&mut conn)
            .await?;

        Ok(result)
    }
}
```

---

## 10. Performance & Monitoring

### Key Performance Metrics
```bash
# Memory usage
INFO memory

# Hit rate
INFO stats | grep keyspace_hits
INFO stats | grep keyspace_misses

# Connected clients
INFO clients

# Operations per second
INFO stats | grep instantaneous_ops_per_sec
```

### Memory Optimization
```conf
# Memory management
maxmemory 512mb
maxmemory-policy volatile-lru  # Only evict keys with TTL

# Connection limits
maxclients 10000
timeout 300

# Disable dangerous commands in production
rename-command FLUSHDB ""
rename-command FLUSHALL ""
rename-command SHUTDOWN SHUTDOWN_MYADMIN
```

### Monitoring Tools
```bash
# Redis CLI monitoring
redis-cli monitor

# Install Redis exporter for Prometheus
yay -S redis_exporter

# Grafana dashboard setup
# Use Redis dashboard ID: 763
```

### Performance Benchmarks
```bash
# Simple benchmark
redis-benchmark -n 100000 -c 50

# Custom benchmark
redis-benchmark -n 100000 -c 50 -t get,set
```

---

## 11. Production Deployment

### Security Hardening
```conf
# Network security
bind 127.0.0.1  # Only localhost in development
# bind 0.0.0.0   # Listen on all interfaces in production (with firewall)

# Authentication
requirepass your_secure_password_here

# Disable dangerous commands
rename-command FLUSHDB ""
rename-command FLUSHALL ""
rename-command CONFIG "CONFIG_MYADMIN"
rename-command SHUTDOWN "SHUTDOWN_MYADMIN"

# TLS (Redis 6+)
tls-port 6380
tls-cert-file /path/to/redis.crt
tls-key-file /path/to/redis.key
tls-ca-cert-file /path/to/ca.crt
```

### Systemd Service Configuration
```ini
# /etc/systemd/system/redis-custom.service
[Unit]
Description=Redis In-Memory Data Store
After=network.target

[Service]
Type=notify
User=redis
Group=redis
ExecStart=/usr/bin/redis-server /etc/redis.conf
ExecStop=/usr/bin/redis-cli shutdown
Restart=always
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
```

### Backup Strategy
```bash
#!/bin/bash
# Daily Redis backup script

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/var/backups/redis"
BACKUP_FILE="$BACKUP_DIR/redis_backup_$DATE.rdb"

# Create backup directory
mkdir -p $BACKUP_DIR

# Trigger save
redis-cli SAVE

# Copy RDB file
cp /var/lib/redis/dump.rdb $BACKUP_FILE

# Compress
gzip $BACKUP_FILE

# Keep only last 7 days
find $BACKUP_DIR -name "redis_backup_*.rdb.gz" -mtime +7 -delete

echo "Redis backup completed: $BACKUP_FILE.gz"
```

---

## 12. Troubleshooting & Best Practices

### Common Issues & Solutions

#### 1. Connection Refused
```bash
# Check if Redis is running
sudo systemctl status redis

# Check port
netstat -tlnp | grep 6379

# Check firewall
sudo ufw status
sudo ufw allow 6379
```

#### 2. Memory Issues
```bash
# Check memory usage
redis-cli INFO memory

# Find large keys
redis-cli --bigkeys

# Monitor memory growth
redis-cli MONITOR | grep "SET\|HSET\|LPUSH"
```

#### 3. Performance Problems
```bash
# Slow queries
redis-cli SLOWLOG GET 10

# Connection pool issues
redis-cli INFO clients

# Check persistence impact
redis-cli INFO persistence
```

### Best Practices

#### 1. Key Naming Convention
```rust
// Good naming patterns
format!("user:{}:profile", user_id)
format!("cache:{}:{}", resource_type, resource_id)
format!("session:{}:data", session_id)
format!("ratelimit:{}:{}", endpoint, identifier)
```

#### 2. TTL Strategy
```rust
// Different TTL for different data types
const SESSION_TTL: u64 = 86400;      // 24 hours
const CACHE_TTL: u64 = 3600;         // 1 hour
const TEMP_DATA_TTL: u64 = 300;      // 5 minutes
```

#### 3. Error Handling
```rust
pub async fn safe_redis_operation<F, T>(&self, operation: F) -> Result<T, AppError>
where
    F: FnOnce() -> std::pin::Pin<Box<dyn std::future::Future<Output = Result<T, redis::RedisError>> + Send>>,
{
    match operation().await {
        Ok(result) => Ok(result),
        Err(e) => {
            error!("Redis operation failed: {}", e);
            // Fallback logic or circuit breaker
            Err(AppError::CacheError(e.to_string()))
        }
    }
}
```

#### 4. Connection Management
```rust
pub struct RedisManager {
    pool: RedisPool,
    circuit_breaker: CircuitBreaker,
}

impl RedisManager {
    pub async fn execute_with_fallback<F, T, Fallback>(
        &self,
        operation: F,
        fallback: Fallback,
    ) -> Result<T, AppError>
    where
        F: FnOnce() -> std::pin::Pin<Box<dyn std::future::Future<Output = Result<T, redis::RedisError>> + Send>>,
        Fallback: FnOnce() -> Result<T, AppError>,
    {
        if self.circuit_breaker.is_open() {
            return fallback();
        }

        match operation().await {
            Ok(result) => {
                self.circuit_breaker.record_success();
                Ok(result)
            }
            Err(e) => {
                self.circuit_breaker.record_failure();
                warn!("Redis operation failed, using fallback: {}", e);
                fallback()
            }
        }
    }
}
```

### Learning Path Summary

1. **Week 1**: Installation, basic operations, data structures
2. **Week 2**: Configuration, persistence, clustering basics
3. **Week 3**: Rust integration, session management, caching
4. **Week 4**: PostgreSQL hybrid patterns, rate limiting
5. **Week 5**: Performance monitoring, production deployment
6. **Week 6**: Advanced patterns, troubleshooting, best practices

### Recommended Resources
- [Redis Official Documentation](https://redis.io/documentation)
- [Redis Command Reference](https://redis.io/commands)
- [Rust Redis Crate Documentation](https://docs.rs/redis/latest/redis/)
- [Redis in Action Book](https://www.manning.com/books/redis-in-action)

---

*This guide covers everything from Redis/Valkey basics to advanced Rust integration patterns. Start with the installation section and work through each topic systematically. Practice each concept with small Rust projects before moving to complex PostgreSQL hybrid patterns.*