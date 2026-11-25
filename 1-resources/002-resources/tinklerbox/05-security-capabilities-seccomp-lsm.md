# 5. security primitives — capabilities, seccomp, lsm

related: [00-index](00-index.md) · prev: [04-filesystem-overlayfs](04-filesystem-overlayfs.md) · next: [06-networking-and-ports](06-networking-and-ports.md) · configured via: [08-oci-specs](08-oci-specs.md) (`process.capabilities`, `linux.seccomp` in config.json) · applied by: [09-runc-crun](09-runc-crun.md)

## why this layer exists

namespaces hide things, cgroups limit consumption — neither stops a process
from doing something destructive with whatever it *can* still see and
touch. this layer answers: given what the process can see and reach, what
is it actually *allowed to do*? three independent mechanisms stack here:
capabilities (splitting root's power), seccomp (restricting which syscalls
are even callable), and LSMs (mandatory access control beyond unix
permissions).

## capabilities — root is not all-or-nothing

historically, unix permission checks were binary: uid 0 could do anything,
everyone else was bound by file permissions. linux capabilities split root's
power into ~40 discrete, independently grantable units. a process can hold
a subset without being "root" in the traditional sense.

a process actually carries **several capability sets**, not just one:

- **permitted** — the ceiling of what this process is allowed to use; a
  capability not in this set can never be gained (short of exec'ing a
  binary with file capabilities set).
- **effective** — the subset of `permitted` actually in force for the
  *current* set of syscalls; a program can hold a capability in `permitted`
  but temporarily not have it `effective`.
- **inheritable** — capabilities preserved across `execve(2)` under certain
  conditions (interacts with file capabilities on the exec'd binary).
- **bounding** — a system-wide-per-process ceiling that can only shrink,
  never grow, across the lifetime of the process tree; even a `setuid`
  binary cannot grant a capability outside the bounding set. this is the
  set container runtimes actually shrink to "drop capabilities."
- **ambient** (newer, since kernel 4.3) — lets *unprivileged* processes
  preserve specific capabilities across `execve` without needing file
  capabilities set on the target binary, as long as the capability is also
  in `permitted` and `inheritable`. this exists specifically to make
  "run this program with exactly these two capabilities, nothing else,
  without editing binaries on disk" ergonomic — which is exactly the
  container use case.

commonly relevant capabilities:

| capability | grants |
|---|---|
| `CAP_NET_ADMIN` | network configuration: interfaces, routes, firewall rules |
| `CAP_SYS_ADMIN` | huge grab-bag ("almost root") — mount operations, some namespace operations, more; avoid granting this if at all possible |
| `CAP_SYS_PTRACE` | trace/inspect other processes (`ptrace(2)`) |
| `CAP_NET_BIND_SERVICE` | bind to privileged ports (<1024) without full root |
| `CAP_SETUID` / `CAP_SETGID` | change process uid/gid |
| `CAP_DAC_OVERRIDE` | bypass normal file read/write/execute permission checks |
| `CAP_CHOWN` | change file ownership arbitrarily |
| `CAP_KILL` | send signals to processes you don't otherwise own |

container runtimes drop nearly all capabilities by default and grant back a
small curated set (docker's default list is roughly: `CHOWN`, `DAC_OVERRIDE`,
`FOWNER`, `FSETID`, `KILL`, `SETGID`, `SETUID`, `SETPCAP`, `NET_BIND_SERVICE`,
`NET_RAW`, `SYS_CHROOT`, `MKNOD`, `AUDIT_WRITE`, `SETFCAP` — check your
runtime's current default, this list shifts over releases). dropping
capabilities is one of the highest-value, lowest-cost hardening moves
available, because most containerized applications need none of the
dangerous ones.

## seccomp — syscall filtering

capabilities restrict *what a syscall is allowed to do*; seccomp restricts
*which syscalls can even be called at all*. a BPF program attached to a
process is evaluated on every syscall entry and decides an action based on
the syscall number (and optionally its arguments).

- **modes**: `SECCOMP_MODE_STRICT` (only `read`/`write`/`exit`/`sigreturn`
  survive — extremely restrictive, rarely used directly by container
  runtimes) vs `SECCOMP_MODE_FILTER` (a BPF program evaluates an arbitrary
  policy — this is what containers use).
- **possible actions per syscall**:
  - `SECCOMP_RET_ALLOW` — let it through
  - `SECCOMP_RET_ERRNO` — fail the call with a chosen errno, without
    killing anything (the calling program sees a normal syscall failure)
  - `SECCOMP_RET_KILL_PROCESS` / `SECCOMP_RET_KILL_THREAD` — terminate
  - `SECCOMP_RET_TRAP` — deliver `SIGSYS` to the calling thread
  - `SECCOMP_RET_LOG` — allow, but log the call (auditing/dev mode)
  - `SECCOMP_RET_USER_NOTIF` — hand the decision off to a supervising
    userspace process via a notification fd; used for advanced sandboxes
    that want to intercept and emulate specific syscalls rather than just
    allow/deny them
- docker/containerd ship a **default seccomp profile** blocking a curated
  list of dangerous or rarely-needed syscalls (things like `keyctl`,
  arbitrary `mount`, various obscure/legacy syscalls) while allowing the
  wide surface normal applications actually use. custom, tighter profiles
  are common in hardened deployments — the profile is just a JSON file
  referenced from the OCI `config.json` (see
  [08-oci-specs](08-oci-specs.md)).

## lsm — mandatory access control

Linux Security Modules (AppArmor, SELinux, Landlock, ...) sit alongside
standard unix DAC (discretionary access control — the permission bits) and
enforce **mandatory** policy that the process itself cannot waive, even as
root. in enterprise kubernetes, SELinux labels (surfaced via a pod's
`securityContext`) are a major containment layer, particularly for
multi-tenant nodes where you don't fully trust every workload's own
capability/seccomp configuration to be airtight — LSM policy is an
independent layer that still applies even if something else is
misconfigured.

## easy-to-miss adjacent controls

- **`prctl(2)` with `PR_SET_NO_NEW_PRIVS`** — once set, this process (and
  all descendants) can never gain more privileges than it currently has,
  even via `setuid`/`setgid` binaries or file capabilities. container
  runtimes set this by default; it closes off a whole class of "regain
  privilege via exec" tricks.
- **rlimits** (`ulimit`) — traditional, older, per-process resource limits
  (open file descriptors, max processes, etc). distinct from and layered
  *underneath* cgroups — rlimits are per-process kernel accounting, cgroups
  are per-cgroup aggregate accounting; a container is typically constrained
  by both simultaneously.

## references

- man pages: `capabilities(7)`, `capset(2)`, `prctl(2)`, `seccomp(2)`,
  `seccomp(7)`
- kernel docs: https://docs.kernel.org/userspace-api/seccomp_filter.html

## hands-on

- run a container with `--cap-drop=ALL --cap-add=NET_BIND_SERVICE` and
  confirm it can bind port 80 but fails at, say, changing file ownership
  arbitrarily or loading a kernel module.
- run with a restrictive custom seccomp profile (block `mount`, `ptrace`,
  etc) and trigger the blocked syscall; use `strace -f` on the *host* view
  of the process to see exactly which syscall was denied and how (`EPERM`
  vs. process killed, depending on chosen action).
- compare `getpcaps <pid>` output for a normal shell vs. a container
  process to see the capability set shrink concretely.
