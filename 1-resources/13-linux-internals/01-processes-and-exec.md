# 1. processes are the unit of reality

related: [00-index](00-index.md) · next: [02-namespaces](02-namespaces.md) · used by: [07-container-creation-steps](07-container-creation-steps.md), [09-runc-crun](09-runc-crun.md)

## the core claim

there is no kernel object called "container." when docker/containerd/k8s
"create a container," the kernel only ever sees: a new process, created via
`clone(2)`, whose memory image is then replaced via `execve(2)`. everything
that makes it *feel* like a container — isolation, limits, a different
filesystem, restricted permissions — is configured on that process before
the `execve`. this file is about the process itself; the configuration is
[02](02-namespaces.md)–[05](05-security-capabilities-seccomp-lsm.md).

## fork vs clone vs execve

- **`fork(2)`** — classic API, duplicates the calling process (copy-on-write
  pages, duplicated fd table, etc). every container runtime actually uses
  `clone(2)` instead because fork gives you no control over *what* is shared
  with the child.
- **`clone(2)`** — the general-purpose process/thread creation syscall.
  takes a `flags` bitmask that controls what's shared vs. copied: memory
  (`CLONE_VM`), file descriptor table (`CLONE_FILES`), filesystem info
  (`CLONE_FS`), and — critically for containers — namespace flags
  (`CLONE_NEWPID`, `CLONE_NEWNET`, `CLONE_NEWNS`, `CLONE_NEWUTS`,
  `CLONE_NEWIPC`, `CLONE_NEWUSER`, `CLONE_NEWCGROUP`). a runtime creates the
  first container process by calling `clone(2)` with the namespace flags for
  every namespace type it wants to isolate, in one syscall.
- **`execve(2)`** — replaces the calling process's memory image (code, data,
  stack) with a new program, keeping the same pid. this is the step that
  turns "a forked/cloned copy of the runtime's helper process" into
  "your actual application process." everything set up before this point
  (namespaces, cgroup membership, capability sets, seccomp filter, mounts)
  persists across `execve` — that's the whole trick: configure the
  environment first, *then* execve into the real binary, and the real binary
  inherits all of it.

## pid 1 semantics (the part that bites people)

inside a container, the first process is pid 1 *within its own pid
namespace* (see [02](02-namespaces.md)), even though it has some large,
ordinary pid on the host. the kernel treats pid 1 specially in every pid
namespace, not just the host's:

- **default signal disposition is different.** an ordinary process without a
  handler installed for, say, `SIGTERM` gets killed by it. pid 1 *ignores*
  signals it hasn't explicitly installed a handler for (except `SIGKILL`/
  `SIGSTOP`, which always work). this is why `docker stop` (which sends
  `SIGTERM`, waits, then `SIGKILL`s) can appear to "hang" if your
  containerized app never installs a `SIGTERM` handler — the signal is
  silently ignored until the timeout forces a `SIGKILL`.
- **it must reap zombies.** when any process's children exit, they become
  zombies until something calls `waitpid(2)` on them. normally a shell or
  init system does this. if your container's pid 1 is your application and
  it spawns subprocesses without ever reaping them, zombies accumulate
  (harmless individually, but they leak pid-table entries and are a code
  smell indicating a missing supervisor).
- **if pid 1 dies, the whole pid namespace is torn down** — the kernel kills
  every other process in that namespace. this is why a container "exits" the
  moment its main process exits, regardless of what background processes it
  spawned.

this is why lightweight init wrappers exist: **tini**, **dumb-init**, or
`docker run --init`. they run as real pid 1, install proper signal handlers,
reap zombies correctly, and then exec/fork your actual application as a
child — giving it normal (non-pid-1) signal semantics.

## key kernel data structures (names to recognize, not memorize)

when you read kernel docs or strace output, these are the structures behind
what you're manipulating:

| struct | holds |
|---|---|
| `task_struct` | the process/thread itself — pid, state, scheduling info, pointers to everything below |
| `mm_struct` | virtual memory mappings (what `CLONE_VM` shares) |
| `files_struct` | the open file descriptor table (what `CLONE_FILES` shares) |
| `fs_struct` | cwd + root directory (what `CLONE_FS` / the mount namespace interacts with) |
| `cred` | uids/gids/capability sets (see [05](05-security-capabilities-seccomp-lsm.md)) |
| `nsproxy` | pointers to the six-ish namespaces this task currently belongs to (see [02](02-namespaces.md)) |

`clone`'s flags essentially decide, per data structure, "share the parent's
or allocate a fresh one." namespace flags (`CLONE_NEW*`) always mean
"allocate a fresh one and put it in `nsproxy`."

## references

- man pages: `fork(2)`, `clone(2)`, `execve(2)`, `waitpid(2)`, `prctl(2)`,
  `signal(7)`
- kernel process docs: https://docs.kernel.org/

## hands-on

- write a tiny c or rust program that `fork`s, `execve`s a child, and
  `waitpid`s on it; watch it in `ps`/`htop` and read `/proc/<pid>/status`
  and `/proc/<pid>/stat` while it runs.
- run a container without an init wrapper, send it `SIGTERM` from the
  outside, and watch whether it actually exits promptly or needs `SIGKILL`
  after the grace period — this demonstrates the pid-1 default-signal-
  disposition trap directly.
