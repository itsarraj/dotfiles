# 9. runc / crun — the program that actually creates the container

related: [00-index](00-index.md) · prev: [08-oci-specs](08-oci-specs.md) · next: [10-containerd-internals](10-containerd-internals.md) · implements: [07-container-creation-steps](07-container-creation-steps.md) · consumes: [08-oci-specs](08-oci-specs.md) (config.json) · invoked by: [10-containerd-internals](10-containerd-internals.md) (via the shim)

## what runc is, precisely

`runc` is a small, standalone CLI whose entire job is: read an OCI bundle
(`rootfs/` + `config.json`, see [08-oci-specs](08-oci-specs.md)) and perform
exactly the seven steps in
[07-container-creation-steps](07-container-creation-steps.md) — create
namespaces, set up uid/gid maps, mount rootfs, mount `/proc`/`/dev`/`/sys`,
configure the cgroup, apply capabilities/seccomp/lsm, and `execve` the
target program. it is the reference implementation of the OCI runtime spec
— extracted from early Docker (`libcontainer`) specifically so the "make
the syscalls" part could be a shared, spec-compliant, swappable component
rather than baked into any one tool.

`crun` is a from-scratch reimplementation of the same contract in C
(instead of Go), used by default in podman and CRI-O. it's generally
lighter-weight and starts faster than `runc`, which matters when a runtime
is spawned fresh per container (see below) rather than staying resident.

both are **conformant to the same runtime spec**, so anything that produces
a valid OCI bundle can hand it to either interchangeably — this is the OCI
runtime spec doing its job.

## the CLI surface = the spec's lifecycle operations

recall from [08-oci-specs](08-oci-specs.md#the-two-specs-in-one-sentence-each)
that the runtime spec defines standard lifecycle operations. `runc`'s CLI
is literally that:

- `runc create <id>` — perform steps 1–6 from
  [07](07-container-creation-steps.md) (namespaces, uid/gid maps, rootfs
  mount, `/proc`/`/dev`/`/sys`, cgroup setup, capabilities/seccomp/lsm) and
  leave the process paused *before* the final `execve`, in a well-defined
  "created" state.
- `runc start <id>` — trigger the actual `execve`, moving the container
  into "running."
- `runc kill <id> [signal]` — send a signal to the container's process.
- `runc delete <id>` — clean up state for a stopped container.
- `runc state <id>` — report the container's current lifecycle state as
  JSON.
- `runc run <id>` — a convenience combining `create` + `start` in one call,
  useful for manual/interactive use; production callers (shims) use the
  split `create`/`start` so they can do bookkeeping (like registering the
  container with monitoring, or wiring up console/stdio) in the gap between
  the two.

## why runc is deliberately short-lived

`runc create`/`runc start` run, perform their syscalls, and **exit**. runc
is not a daemon and does not stick around supervising the container process
it just created — once `execve` has happened, the container process is a
normal, independent process on the host, parented (for reaping/lifecycle
purposes) to whatever called `runc`, not to `runc` itself.

this matters because it directly motivates
[containerd's shim](10-containerd-internals.md#why-shims-exist): *something*
has to be the long-lived parent that owns the container's stdio, reaps it
on exit, and reports status — and it can't be `runc`, because `runc`
intentionally doesn't stay alive. that's precisely the gap
`containerd-shim-runc-v2` fills.

## tracing it yourself

because runc's whole value is "translate config.json into syscalls," the
most direct way to *see* the seven steps from
[07-container-creation-steps](07-container-creation-steps.md) as concrete
kernel calls is `strace -f runc run <id>` against a real bundle. expect to
see, roughly in order: `clone`/`unshare` with namespace flags, writes to
`/proc/<pid>/{uid_map,gid_map,setgroups}` if a user namespace is used, a
sequence of `mount` calls (rootfs, then `/proc`, `/dev`, `/sys`, any extra
bind mounts), `pivot_root`, opening and writing cgroup controller files
(or a `clone3` variant with `CLONE_INTO_CGROUP` on newer kernels, which
folds "attach to this cgroup" directly into process creation), capability-
related syscalls (`capset`), `prctl` (no-new-privs), `seccomp`/`prctl`
(installing the BPF filter), and finally `execve`.

## references

- runc: https://github.com/opencontainers/runc
- crun: https://github.com/containers/crun
- OCI runtime spec (what both implement): see
  [08-oci-specs.md](08-oci-specs.md)

## hands-on

- generate a bundle with `runc spec`, populate `rootfs/` from an extracted
  image, and run `runc create` followed by a separate `runc start` —
  observe the container sitting in the paused "created" state via `runc
  state <id>` before you start it.
- `strace -f -o trace.log runc run mycontainer` then grep the trace for
  `clone`, `mount`, `pivot_root`, `capset`, and `execve` to map every line
  back to a step in
  [07-container-creation-steps](07-container-creation-steps.md).
- compare container start latency between `runc` and `crun` for the same
  bundle — this is the practical reason podman/CRI-O default to `crun`.
