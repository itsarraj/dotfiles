# 2. namespaces — what a process can see

related: [00-index](00-index.md) · prev: [01-processes-and-exec](01-processes-and-exec.md) · next: [03-cgroups-v2](03-cgroups-v2.md) · connects to: [04-filesystem-overlayfs](04-filesystem-overlayfs.md) (mount ns), [06-networking-and-ports](06-networking-and-ports.md) (net ns), [11-cri-and-kubelet](11-cri-and-kubelet.md) (pod sandbox shares namespaces across containers)

## the idea

a namespace wraps a global kernel resource (the pid tree, the mount table,
the network stack, ...) so that a process sees its own private, isolated
instance of it. two processes in different namespaces of the same type can
both think they're "pid 1," both think `eth0` is theirs, both mount
different things at `/`, without either seeing the other's view. this is
purely a *visibility* mechanism — it says nothing about resource limits
(that's [cgroups, 03](03-cgroups-v2.md)) or permissions (that's
[capabilities/seccomp, 05](05-security-capabilities-seccomp-lsm.md)).

## the syscalls that create/join them

- **`unshare(2)`** — the calling process detaches parts of its own context
  into new namespaces, in place (no new process created). `unshare -p -m
  -f --mount-proc /bin/bash` is the classic manual demo.
- **`clone(2)`** — create a child that starts life already in new
  namespaces, via `CLONE_NEW*` flags passed at creation time. this is what
  runtimes actually use, since it avoids the window where the parent
  process itself would be affected.
- **`setns(2)`** — join an *existing* namespace given a file descriptor to
  it (opened from `/proc/<pid>/ns/*`). this is how `docker exec` / `crictl
  exec` work: the new exec'd process joins the already-running container's
  namespaces rather than creating new ones, and it's how every container in
  a k8s pod joins the pod sandbox's network namespace.

each namespace type has its own `CLONE_NEW*` flag: `CLONE_NEWPID`,
`CLONE_NEWNS` (mount — historically just "NS" since it was the first one),
`CLONE_NEWNET`, `CLONE_NEWUTS`, `CLONE_NEWIPC`, `CLONE_NEWUSER`,
`CLONE_NEWCGROUP`. a runtime typically calls `clone(2)` once with all the
relevant flags OR'd together.

## the namespace types

### pid namespace
- the process sees a private pid tree; the first process created inside it
  is pid 1 *of that namespace* (see [01](01-processes-and-exec.md) for why
  pid 1 is special), even though the host sees some ordinary large pid for
  the same task.
- pid namespaces nest — a process can see its own namespace and every
  descendant namespace's pids (this is how the host can still `ps` and see
  container processes with different pids than the container sees), but
  never an ancestor's or sibling's.
- **`/proc` must be freshly mounted from inside the new pid namespace** to
  report the right pid tree — a process that unshares `CLONE_NEWPID` but
  keeps an old `/proc` mount will show the *host's* process list, which is
  a common "why does `ps` show everything" bug when hand-rolling namespaces.

### mount namespace
- each mount namespace has its own list of mounts (its own view of "what's
  mounted where"). this is the kernel feature that makes "the container has
  a different `/`" possible at all — see [04](04-filesystem-overlayfs.md)
  for how rootfs assembly and `pivot_root` build on top of this.
- new mount namespaces start as a copy of the parent's mount table (not
  empty!), so a runtime typically also makes the new root mount `private`
  or `slave` (via `mount --make-rprivate`) to stop mount/unmount events from
  propagating back to the host.

### network namespace
- a fully separate network stack: interfaces (except loopback, which exists
  but is down by default), routing tables, netfilter/iptables rules, and
  the socket namespace.
- a fresh net namespace has literally no way to reach the outside — see
  [06-networking-and-ports](06-networking-and-ports.md) for how veth pairs,
  bridges, and CNI plugins wire it up.
- this is the one namespace type that's explicitly **shared across all
  containers in a k8s pod** via the pod sandbox / pause container — see
  [11-cri-and-kubelet](11-cri-and-kubelet.md).

### uts namespace
- isolates hostname and NIS domain name (`sethostname(2)`/`setdomainname(2)`
  become namespace-local). small but real — it's why every container can
  set its own hostname without affecting the host or siblings.

### ipc namespace
- isolates System V IPC objects: shared memory segments, message queues,
  semaphores, plus POSIX message queues. **this is unrelated to the
  gRPC/unix-socket "ipc" used for daemon-to-daemon communication** — see
  [12-grpc-and-ipc](12-grpc-and-ipc.md) for that other meaning of the word;
  don't conflate the two when you see "ipc" used casually.

### user namespace
- remaps uids/gids: a process can be uid 0 ("root") *inside* its user
  namespace while mapping to an unprivileged, non-zero uid on the host.
  many kernel permission checks are then evaluated against the *mapped*
  identity, meaning "root in the container" often genuinely cannot do
  root-level damage to the host.
- this is the mechanism that makes **rootless containers** possible (e.g.
  rootless podman/docker, or unprivileged k8s nodes).
- mappings are configured by writing to `/proc/<pid>/uid_map` and
  `/proc/<pid>/gid_map` (format: `<inside-id> <outside-id> <count>` per
  line), and `/proc/<pid>/setgroups` typically has to be set to `deny`
  before an unprivileged process can write `gid_map`.
- interacts with every other namespace: creating a user namespace can be
  done unprivileged, and once you own a user namespace, you're allowed to
  create the *other* namespace types "as root" inside it even as an
  unprivileged host user — this is the actual mechanism rootless containers
  exploit.

### cgroup namespace
- newer addition; virtualizes the view of cgroup paths under `/proc/self/
  cgroup` and cgroupfs mounts, so a process inside a container sees cgroup
  paths relative to its own cgroup root instead of the host's absolute
  path. doesn't change enforcement (see [03](03-cgroups-v2.md)), only
  visibility/reporting.

## inspecting namespaces from userspace

- `/proc/<pid>/ns/*` — one symlink-like entry per namespace type the
  process belongs to (`pid`, `net`, `mnt`, `uts`, `ipc`, `user`, `cgroup`).
  two processes in the *same* namespace show the same inode number for
  the corresponding entry — this is the cheapest way to check "are these
  two processes actually sharing this namespace?" (`ls -Li
  /proc/<pid1>/ns/net /proc/<pid2>/ns/net`).
- `lsns` — lists all namespaces on the system, their type, and which
  processes belong to them.
- `nsenter --target <pid> --net --pid ...` — joins the namespaces of an
  existing process; this is literally what `docker exec`/`crictl exec` do
  under the hood via `setns(2)`.

## references

- man pages: `namespaces(7)` (the overview page — start here), `unshare(2)`,
  `setns(2)`, `clone(2)`, `user_namespaces(7)`, `pid_namespaces(7)`,
  `network_namespaces(7)`, `mount_namespaces(7)`
- util-linux tools: `unshare(1)`, `nsenter(1)`, `lsns(1)`

## hands-on

- `sudo unshare --pid --mount --fork --mount-proc /bin/bash` — you're now
  pid 1 in a new pid+mount namespace with a correctly scoped `/proc`; run
  `ps aux` and see only your own shell.
- open two terminals, get the pid of a process in each, and diff `ls -Li
  /proc/<pid>/ns/*` between them to see which namespaces they do/don't
  share.
- create a user namespace as your own unprivileged user (`unshare --user
  --map-root-user`) and observe `id` reporting uid 0 inside while the host
  still sees your real uid for the underlying process.
