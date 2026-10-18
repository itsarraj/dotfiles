# 3. cgroups v2 — what a process can use

related: [00-index](00-index.md) · prev: [02-namespaces](02-namespaces.md) · next: [04-filesystem-overlayfs](04-filesystem-overlayfs.md) · used by: [07-container-creation-steps](07-container-creation-steps.md), [08-oci-specs](08-oci-specs.md) (`resources` block in config.json)

## the idea

namespaces ([02](02-namespaces.md)) control *visibility*; cgroups control
*consumption*. without cgroups, a process with unlimited namespace isolation
can still allocate all the host's RAM or pin every CPU core, taking down
everything else on the machine — "container" isolation is incomplete
without both.

cgroups (control groups) v2 present as a **filesystem**, mounted (typically)
at `/sys/fs/cgroup`. every process belongs to exactly **one** cgroup at a
time, and cgroups form a tree (a cgroup's limits apply to itself and, via
the tree, constrain how its children can subdivide resources further).

## controllers

each cgroup directory exposes files depending on which controllers are
enabled for it (`cgroup.subtree_control` in the parent decides what's
enabled for children):

- **cpu**
  - `cpu.max` — `"<quota> <period>"` in microseconds, e.g. `50000 100000`
    means "50ms of CPU time per 100ms period" = 0.5 cores. `"max"` = no
    limit.
  - `cpu.weight` — relative share (like the old `cpu.shares`) used when
    multiple cgroups compete for the same CPUs under contention; doesn't
    cap usage the way `cpu.max` does, only affects proportional allocation.
- **memory**
  - `memory.max` — hard ceiling; exceeding it triggers the kernel OOM killer
    *scoped to that cgroup* (kills a process inside the cgroup, not
    necessarily anything else on the host).
  - `memory.high` — a soft throttle: exceeding it causes the kernel to
    aggressively reclaim/throttle the cgroup without necessarily invoking
    the OOM killer — used to apply backpressure before a hard kill.
  - `memory.current` — current usage, read-only.
- **io**
  - `io.max` — per-device read/write bytes-per-second and IOPS caps.
  - `io.weight` — proportional share under contention, same idea as
    `cpu.weight`.
- **pids**
  - `pids.max` — caps the number of processes/threads a cgroup (and its
    descendants) can have alive at once. this is what stops a forkbomb
    inside one container from exhausting the host's pid table.
- **psi (pressure stall information)** — not a controller you configure,
  but a diagnostic: `/proc/pressure/{cpu,memory,io}` (and a per-cgroup
  version under each cgroup dir) report the fraction of time tasks spent
  *stalled* waiting on that resource. this is how modern schedulers/
  autoscalers detect "this node/cgroup is actually under pressure," rather
  than inferring it from raw usage numbers alone.

## how a runtime actually applies this

1. create a cgroup directory for the container, e.g. under
   `/sys/fs/cgroup/kubepods.slice/.../<container-id>/` on a k8s node (the
   exact hierarchy depends on the cgroup driver — `systemd` or `cgroupfs`;
   k8s nodes almost always use the `systemd` cgroup driver today so that
   systemd and the container runtime agree on cgroup ownership).
2. write the desired limits into the controller files in that directory
   (`echo 50000 100000 > cpu.max`, etc). the OCI runtime spec's `resources`
   block (see [08-oci-specs](08-oci-specs.md)) is exactly the portable
   description of these numbers.
3. move the container's process into that cgroup by writing its pid into
   `cgroup.procs` in that directory. from that point on, every syscall the
   kernel uses to check "is this process over its resource budget" consults
   this cgroup.

note the ordering subtlety: the cgroup should generally be set up (or at
least the pid attached) *before* `execve` into the real workload, so the
target program never runs even briefly outside its limits.

## why k8s cares this much

kubernetes' `resources.requests`/`resources.limits` on a pod spec compile
directly down to cgroup v2 controller files:
- `limits.memory` → `memory.max`
- `limits.cpu` → `cpu.max` (quota/period)
- `requests.cpu` → `cpu.weight` (proportional share when nodes are
  contended, not a hard cap — this is why a pod can burst above its
  `requests.cpu` when the node has spare capacity, but is throttled once
  contention appears)
- QoS classes (`Guaranteed`/`Burstable`/`BestEffort`) and eviction
  decisions under memory pressure are effectively policy layered on top of
  these same PSI/usage numbers — nothing about QoS is a separate kernel
  mechanism, it's kubelet reading cgroup/PSI state and deciding what to
  evict.

## where to inspect

- `/sys/fs/cgroup/<path>/` — the controller files themselves
- `/proc/<pid>/cgroup` — which cgroup(s) a given process belongs to
- `/proc/pressure/{cpu,memory,io}` — system-wide PSI
- `systemd-cgls` — tree view of the cgroup hierarchy, if systemd-managed
- `systemd-run --scope -p MemoryMax=100M ...` — quick way to run something
  under a cgroup limit without hand-writing files

## references

- kernel docs: https://docs.kernel.org/admin-guide/cgroup-v2.html
- man page: `cgroups(7)`
- systemd: `systemd-cgls(1)`, `systemd-run(1)`

## hands-on

- `systemd-run --scope -p MemoryMax=50M -p CPUQuota=25% stress --vm 1
  --vm-bytes 200M` (or similar) and watch it get OOM-killed / throttled.
- write a small forkbomb-lite script inside a cgroup with `pids.max=10` set
  and watch `fork` start failing once the cap is hit, instead of taking
  down the host.
- watch `/proc/pressure/memory` while running the memory-limited example
  above, to see PSI numbers rise before/at the point of throttling.
