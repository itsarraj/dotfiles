# tinklerbox — containers, docker, k8s from the ground up

## goal

learn what makes docker + k8 possible:
- linux internals primitives that make "containers" real
- oci + runc (how a container is created)
- containerd internals (shims, snapshots, content store)
- cri + kubelet (how k8 drives runtimes)
- rust/tonic angle: cri is just a gRPC service, so it's reachable from rust

when a container is created, this file should let you answer, at any depth:
what process got created, what kernel features isolate/limit it, what
userspace assembled its filesystem, and which daemon/protocol chain
requested all of that in the first place.

---

## glossary (top-level map — expand any line below in the sections after)

- **container**: a normal linux process + kernel isolation (namespaces) + limits (cgroups) — not a kernel object
- **image**: layered filesystem content + config metadata, content-addressed by digest
- **rootfs**: the assembled filesystem view a container sees as `/` (image layers + writable layer, merged)
- **oci bundle**: `rootfs/` + `config.json` — the on-disk contract a runtime consumes
- **runtime (runc/crun)**: reads the oci bundle, does namespaces/cgroups/mounts/security, execs the process
- **containerd**: daemon that manages images, snapshots, and container lifecycle; calls the runtime via a shim
- **shim (containerd-shim-runc-v2)**: long-lived per-container process; parent of the container process; survives containerd restarts; talks back to containerd over a unix socket
- **cri (container runtime interface)**: gRPC protocol kubelet uses to talk to a container runtime (containerd/CRI-O), so kubelet never has to know runtime internals
- **pod sandbox / pause container**: the first container created for a pod; holds the shared network (and optionally ipc/uts) namespace that every container in the pod joins
- **content store**: containerd's blob storage under `/var/lib/containerd/io.containerd.content.v1.content` — compressed image layers, addressed by sha256 digest
- **snapshotter**: unpacks content-store blobs into filesystem snapshots a runtime can mount as rootfs (overlayfs snapshotter is default; erofs snapshotter is an emerging alternative)
- **overlay2**: docker's storage-driver directory under `/var/lib/docker/overlay2` — same overlayfs idea as containerd's snapshotter, different bookkeeping
- **kubelet ↔ containerd**: kubelet is a gRPC *client*; containerd's built-in CRI plugin is the gRPC *server*, listening on `/run/containerd/containerd.sock`
- **port mapping**: host↔container ports are never "the same port" — they're bridged via veth + iptables/ipvs NAT rules, not magic
- **erofs**: a read-only, compressed linux filesystem; alternative snapshotter backend that mounts a whole layer as one compact image instead of unpacking it into loose files

---

## non-negotiable mental model

a "container" is a normal linux process with:
- **isolation**: namespaces (what it can see)
- **limits**: cgroups (what it can use)
- **filesystem view**: mounts + overlayfs (what `/` looks like)
- **security**: capabilities + seccomp + lsm (what it can do)

everything else (docker, containerd, k8s) is tooling that:
- pulls/unpacks images
- prepares an oci runtime bundle (rootfs + config.json)
- asks an oci runtime (runc/crun) to start the process
- monitors lifecycle + logs + restart policies

if you understand the four bullets above, docker/k8s/containerd become "just orchestration glue" on top of them.

---

## 1) process is the unit of reality

containers start as a normal process created by:
- `clone(2)` (or `fork(2)`, a wrapper-style API)
- followed by `execve(2)` to replace memory with the target program

inside a container, that first process is typically **pid 1** in the container's pid namespace. pid 1 is special:
- it must reap zombie children (`waitpid`) or zombies accumulate
- signal semantics differ (some signals are ignored by pid 1 by default unless a handler is installed)
- this is why init systems / `tini` exist in containers

key kernel data structures (names only, so you know what to search for):
- `task_struct` — represents a process/thread in the kernel
- `mm_struct` — virtual memory mappings
- `files_struct` — open file table
- `fs_struct` — cwd + root
- `cred` — credentials (uids/gids/capabilities)

references: `fork(2)`, `clone(2)`, `execve(2)`, `waitpid(2)`, `prctl(2)`; https://docs.kernel.org/

hands-on: write a tiny program that forks + execs + waits (rust or c); observe with `ps`, `top`/`htop`, `/proc/<pid>/*`.

---

## 2) namespaces (what a process can see)

namespaces give different "views" of kernel resources. the runtime sets them up using `clone`/`unshare` + `setns`.

**pid namespace**
- process sees a different pid tree; inside, it can be pid 1 even though the host pid is something else
- `/proc` must be (re-)mounted from inside the pid namespace to show the right pids

**mount namespace**
- separate mount table per namespace — base of "container has its own filesystem layout"
- runtime mounts rootfs, then mounts `/proc`, `/dev`, etc inside the namespace

**network namespace**
- separate network stack: interfaces, routes, netfilter rules, sockets
- container gets its own `lo`, `eth0`, ip, etc, usually via a veth pair + bridge/cni

**uts namespace** — hostname/domainname isolation

**ipc namespace** — isolates sysv shm segments, message queues, semaphores (this is *not* the same "ipc" as the gRPC/unix-socket ipc discussed in section 9 — this one is a kernel namespace for System V IPC primitives)

**user namespace**
- remaps uids/gids: "root inside" can map to a non-root uid outside
- enables rootless containers
- many kernel permission checks become namespaced
- mapping configured via `/proc/<pid>/uid_map` and `gid_map` (+ `setgroups`)

**cgroup namespace** (newer) — changes how processes see cgroup paths in `/proc`

how they're created (minimal syscall view):
- `unshare(2)` — current process detaches into new namespaces
- `clone(2)` — create a child already in new namespaces via flags
- `setns(2)` — join an existing namespace by fd (from `/proc/<pid>/ns/*`)

where to inspect: `/proc/<pid>/ns/*` (namespace fds/symlinks — compare across processes); `lsns`, `nsenter`.

references: `namespaces(7)`, `user_namespaces(7)`, `unshare(2)`, `setns(2)`, `clone(2)`; `unshare(1)`, `nsenter(1)`.

hands-on: create a new pid+mount ns with `unshare(1)`, confirm the inside sees its own pid space and a different mount table; use `lsns`/`nsenter` to compare host vs namespace view.

---

## 3) cgroups v2 (what a process can use)

cgroups are a filesystem-like api under `/sys/fs/cgroup`. each process belongs to exactly one cgroup in the unified v2 hierarchy. controllers enforce resource policy:
- **cpu**: throttling and shares (`cpu.max`, `cpu.weight`)
- **memory**: hard limits and oom behavior (`memory.max`, `memory.high`)
- **io**: blkio throttling (`io.max`, `io.weight`)
- **pids**: cap number of processes (`pids.max`)
- **psi** (pressure stall info): `/proc/pressure/*` — how much time is spent stalled on a resource

why this matters: without cgroups a "container" can consume all host cpu/ram and take down the node. k8s implements requests/limits, qos classes, and eviction behavior entirely on top of cgroups.

how runtimes use it:
- create a cgroup directory for the container (often under `kubepods/` in k8s)
- write limits to files (`memory.max`, `cpu.max`, `pids.max`, ...)
- move the container process into that cgroup by writing its pid into `cgroup.procs`

where to inspect: `/sys/fs/cgroup/<path>/`, `/proc/<pid>/cgroup`, `/proc/pressure/*`.

references: https://docs.kernel.org/admin-guide/cgroup-v2.html, `cgroups(7)`; if systemd-managed: `systemd-cgls(1)`, `systemd-run(1)`.

hands-on: run a process in a new cgroup, cap memory/cpu, observe throttling and oom-kill behavior.

---

## 4) filesystem view: mounts, rootfs, overlayfs (in full detail)

the kernel does not "run images." an image is layers (tar archives) + metadata; something in userspace has to assemble a root filesystem (rootfs) from them.

### rootfs creation (userspace responsibility)
- unpack layers somewhere on disk
- create a writable layer for this specific container
- mount overlayfs to present one merged filesystem view

### overlayfs mount, concretely

```
mount -t overlay overlay \
  -o lowerdir=L3:L2:L1,upperdir=U,workdir=W \
  merged/
```

- `lowerdir` — colon-separated, **read-only** layers; leftmost has highest priority (checked first)
- `upperdir` — the single **writable** layer (a container's changes)
- `workdir` — required scratch dir, must be empty and on the *same filesystem* as `upperdir`; used internally for atomic rename operations during copy-up
- `merged` — the resulting mount: what the container sees as `/`

### read path
lookups check `upperdir` first, then fall through `lowerdir`s in priority order. a merged directory listing de-duplicates filenames, upper taking priority over lower.

### copy-up
when a process writes to a file that currently exists only in a lower layer, the **whole file** is copied up into `upperdir` first, then the write is applied there. this is per-file, not per-block — modifying one byte of a huge file in a lower layer means copying the entire file up. this is a known overlayfs performance gotcha for large files.

### deletion semantics (whiteouts)
overlayfs represents "this file was deleted in an upper layer" using a **whiteout**: a character device with major/minor `0/0` created in `upperdir` with the same name as the deleted file. when the merged view is computed, a whiteout hides the same-named entry from all lower layers.

OCI image layers use an equivalent but distinct on-disk convention inside layer tarballs: a file named `.wh.<name>` represents "delete `<name>` from the layers below."

### opaque directories
the xattr `trusted.overlay.opaque=y` on a directory in `upperdir` marks it **opaque** — the merged view stops looking at lower layers for that directory's contents entirely (used when a directory is fully replaced rather than merged). the OCI image-spec equivalent is a `.wh..wh..opq` file inside the layer tar.

### other mechanics worth knowing
- **metadata-only copy-up** (optimization on newer kernels): if only metadata (e.g. permissions) changes, avoid copying full file content when possible
- **redirect_dir**: xattr-based mechanism to track renamed directories across layers so lookups still resolve correctly
- limitations historically included: upper/work must be on the same filesystem; certain xattr and nested-overlayfs restrictions depend on kernel version

### entering the rootfs
- `chroot(2)` changes a process's root directory but has well-known escape edge cases and does **not** change mount-namespace root semantics — insufficient alone for container isolation
- `pivot_root(2)` is what runtimes actually use: it properly swaps the mount namespace's root to the new rootfs and moves the old root somewhere it can be unmounted/detached

### necessary "container mounts" beyond rootfs
- `/proc` (procfs) — must be mounted *inside* the pid namespace to show correct pids
- `/dev` — usually a tmpfs + bind mounts for specific devices (or `devpts` for `/dev/pts`)
- `/sys` — often read-only or selectively masked, depending on security posture

### container layer mapping (tying it together)
- image layers, base → top = ordered `lowerdir`s (top layer = highest priority, leftmost)
- container's writable layer = `upperdir`
- the `merged` mount is bind-mounted/used as the rootfs, then the runtime `pivot_root`s into it

where to inspect: `/proc/<pid>/mountinfo` (best source of truth), `findmnt`.

references: https://docs.kernel.org/filesystems/overlayfs.html; `pivot_root(2)`, `mount(2)`, `mount_namespaces(7)`, `chroot(2)`.

hands-on: manually mount an overlayfs and `chroot` into it as a demo; inspect with `findmnt` and `/proc/self/mountinfo`.

---

## 5) security primitives: capabilities, seccomp, lsm (in detail)

### capabilities — root is not all-or-nothing
linux splits root's power into ~40 discrete capabilities. a process has several capability *sets*:
- **permitted** — capabilities the process is allowed to use (a ceiling)
- **effective** — capabilities actually in effect for current permission checks
- **inheritable** — preserved across `execve` under certain conditions
- **bounding** — a ceiling that can only shrink, limits what can ever be gained even via setuid binaries
- **ambient** (newer) — preserved across `execve` for non-privileged processes without needing file capabilities

commonly relevant ones for containers:
- `CAP_NET_ADMIN` — network config (interfaces, routes, firewall)
- `CAP_SYS_ADMIN` — the "almost root" grab-bag capability (mount, some namespace ops, etc) — avoid granting
- `CAP_SYS_PTRACE` — trace/inspect other processes
- `CAP_NET_BIND_SERVICE` — bind to ports < 1024
- `CAP_SETUID`/`CAP_SETGID` — change uid/gid
- `CAP_DAC_OVERRIDE` — bypass file read/write/execute permission checks
- `CAP_CHOWN`, `CAP_KILL` — self-explanatory

containers drop most capabilities by default (docker's default set is a curated subset, not the full list); dropping caps is one of the highest-value, lowest-cost hardening steps.

### seccomp — syscall filtering
a BPF program attached to a process decides, per syscall (+ args), what happens:
- modes: **strict** (only read/write/exit/sigreturn allowed) vs **filter** (BPF program evaluates a policy)
- possible actions per syscall: `ALLOW`, `ERRNO` (fail with an error code), `KILL` (process or thread), `TRAP` (deliver SIGSYS), `LOG`, `USER_NOTIF` (hand the decision to a supervising userspace process — used for advanced sandboxing)
- docker/containerd ship a default seccomp profile that blocks dangerous/rarely-needed syscalls (e.g. `keyctl`, `mount`, various obscure ones) while allowing normal application syscalls

### lsm — mandatory access control
apparmor / selinux / landlock sit beneath/alongside DAC (standard unix permissions) and enforce policy the process can't waive itself. in enterprise k8s, selinux labels (via `securityContext`) are a major containment layer, especially for multi-tenant nodes.

### also easy to miss
- `prctl(2)` — set "no new privileges" (prevents gaining privileges via setuid/setgid/file-caps after this point), dumpable flags, etc
- **rlimits** — traditional per-process limits (`ulimit`), distinct from and layered underneath cgroups

references: `capabilities(7)`, `capset(2)`, `prctl(2)`, `seccomp(2)`, `seccomp(7)`; https://docs.kernel.org/userspace-api/seccomp_filter.html

hands-on: drop capabilities and see which operations break; run with a restrictive seccomp profile and observe blocked syscalls (`strace` helps identify which syscall got denied).

---

## 6) networking: netns + veth + nat + cni

the kernel piece is the network namespace. "connect it to the world" is userspace configuration on top:
- create a **veth pair** (a virtual ethernet cable with two ends)
- one end moves into the container's netns, renamed `eth0`
- the host end attaches to a bridge (docker0) or is routed directly
- iptables/nftables provide NAT/forwarding (classic docker approach)
- in k8s, **CNI plugins** implement the wiring model (bridge, calico, cilium, etc) — invoked by the runtime when the pod sandbox is created

references: `network_namespaces(7)`; `ip(8)` (iproute2); `nft(8)`/`iptables(8)` depending on system.

### port handling — how a port actually gets "allocated" to a container
a container doesn't inherently "have" a host port — it only binds ports inside its own network namespace. mapping a host port to it is NAT, not magic:

**docker (`-p hostPort:containerPort`)**
1. a veth pair connects the container's netns to the host bridge (`docker0`)
2. an iptables NAT-table `DOCKER` chain rule DNATs incoming packets on `hostIP:hostPort` to the container's namespace IP at `containerPort`
3. `docker-proxy` (a userspace process) exists as a fallback path for setups where the iptables NAT route doesn't apply (e.g. some `localhost`-only edge cases)

**kubernetes**
- every pod gets its own routable IP via CNI, so most traffic doesn't need per-container host-port NAT at all — pod-to-pod traffic just routes directly
- `Service` objects (ClusterIP/NodePort/LoadBalancer) are implemented by **kube-proxy**, running in iptables or IPVS mode, which programs NAT/load-balancing rules mapping `ServiceIP:port` → one of the backing `PodIP:targetPort`s across the node
- `NodePort` additionally opens the same port on every node and DNATs into the service
- pod-spec `hostPort` is the direct analog of docker's `-p`; it's implemented by the CNI `portmap` plugin, which installs the equivalent iptables DNAT when the pod sandbox is created

references: `iptables(8)`; CNI portmap plugin docs; kube-proxy modes — https://kubernetes.io/docs/reference/networking/virtual-ips/

---

## 7) "create a container" reduced to steps

most runtimes, when starting a container, do:
1. make/choose namespaces (`clone`/`unshare`, `setns`)
2. set up uid/gid mappings (user namespace, if used)
3. mount rootfs (overlayfs) in the mount namespace
4. mount `/proc`, `/dev`, `/sys` per policy
5. create + configure a cgroup v2 directory, move the process into it
6. drop capabilities, apply seccomp, apply lsm labels (if configured)
7. `execve` the target program

that's the whole trick. docker/containerd/k8s just decide *which exact settings* to apply, *how* to fetch/unpack the filesystem, and *how to keep processes alive* across daemon restarts (shims).

---

## 8) oci specs — the contract (in detail)

everything above is what a runtime *does*. the **OCI (Open Container Initiative)** specs define the *interchange format* so any image can run on any compliant runtime.

### oci image spec — how images are described + stored
- **image manifest** (`application/vnd.oci.image.manifest.v1+json`) — references one config blob and an ordered list of layer blobs, each by sha256 digest
- **image config** — architecture, os, env, entrypoint/cmd, working dir, and critically `rootfs.diff_ids` (uncompressed layer hashes, order = layer application order) + `history`
- **image index** (manifest list) — a list of manifests keyed by platform (os/arch), enabling one tag to serve multiple architectures (`docker manifest`, multi-arch images)
- **layers** — tar (+gzip or zstd) blobs; each is a *changeset* diff applied on top of the previous; deletions represented via whiteout files (`.wh.<name>`, opaque dirs via `.wh..wh..opq`) as described in the overlayfs section
- everything is **content-addressed**: manifests/configs/layers are referenced by their sha256 digest, which is what containerd's content store keys on
- the **distribution spec** defines the registry HTTP API (`/v2/...` endpoints) used to push/pull manifests and blobs

### oci runtime spec — config.json, the process/env/namespace/cgroup contract
a **bundle** = a `rootfs/` directory + a `config.json` at a known path. `config.json` describes, among other things:
- `process` — args, env, cwd, user (uid/gid), capabilities, rlimits, `noNewPrivileges`
- `root` — path to rootfs, readonly flag
- `mounts` — ordered list of `{destination, type, source, options}`
- linux-specific block:
  - `namespaces` — which namespace types to create/join, and paths for joining existing ones
  - `resources` — cgroup settings (memory, cpu, pids, blkio)
  - `seccomp` — the syscall filter profile
  - `maskedPaths` / `readonlyPaths` — paths hidden/frozen inside the container (e.g. masking `/proc/kcore`)
  - `hooks` — commands run at lifecycle points (`prestart`, `createRuntime`, `createContainer`, `startContainer`, `poststart`, `poststop`)
- the runtime spec also defines the **lifecycle operations** every conformant runtime CLI implements: `create`, `start`, `kill`, `delete`, `state` — this is exactly the surface `runc`/`crun` expose

references: https://github.com/opencontainers/image-spec, https://github.com/opencontainers/runtime-spec

hands-on: inspect a real oci bundle (rootfs + config.json); trace how args/env/cwd/user/caps/seccomp map onto the kernel primitives from sections 1–5.

---

## 9) runc/crun — the container creator

`runc` reads an oci bundle and performs the namespace/cgroup/mount/security setup described above, then `execve`s the process. `crun` is a C-based alternative (used by podman/cri-o), generally lighter-weight and faster to start.

references: https://github.com/opencontainers/runc, https://github.com/containers/crun

hands-on: generate an oci bundle and start it with `runc`; trace key syscalls with `strace -f` (`clone`/`unshare`/`mount`/`pivot_root`/`execve`).

---

## 10) containerd — the runtime manager (internals, shims, snapshots)

containerd's job: pull images, unpack layers, manage snapshots, spawn shims, call runc, track lifecycle — while staying out of the "policy" business (that's the CRI plugin / kubelet / docker's job).

### architecture, top to bottom
```
client (ctr / nerdctl / dockerd's containerd client / kubelet via CRI plugin)
      │  gRPC over unix socket (/run/containerd/containerd.sock)
      ▼
containerd daemon
  ├─ content store        (compressed blobs by digest)
  ├─ metadata (bolt db)   (images, containers, snapshot refs, leases)
  ├─ snapshotters         (overlayfs / erofs / ...)
  ├─ image service, task service, events, leases
  └─ CRI plugin (built-in since containerd 1.1)
      │  spawns, one per container
      ▼
containerd-shim-runc-v2   (long-lived, subreaper, owns stdio + exit status)
      │  invokes once to create/start, then runc exits
      ▼
runc  →  container process
```

### why shims exist
- **daemon-restart resilience**: the shim, not containerd, is the parent/reaper of the container process. containerd can restart or be upgraded without killing running containers.
- **stdio handling**: the shim owns the container's stdio pipes/fifos and streams them back to clients (`docker logs`, `crictl logs`, exec attach).
- **reaping**: the shim registers as a subreaper so zombie processes inside the container's process tree get collected correctly even if containerd itself is down.
- **lifecycle reporting**: the shim reports exit codes/status back to containerd over its own small unix-socket protocol (`containerd-shim-runc-v2` implements the shim v2 API).
- **runc itself is short-lived**: `runc create`/`runc start` run, do the syscall setup, and exit — they are not the long-running supervisor.

### on-disk layout (`/var/lib/containerd`)
- `io.containerd.content.v1.content/` — content store: blobs by sha256 digest (pulled, compressed layer/manifest/config blobs)
- `io.containerd.metadata.v1.bolt/` — boltDB metadata: images, containers, snapshot references, leases
- `io.containerd.snapshotter.v1.overlayfs/` — unpacked layer snapshots + writable snapshots for containers (analogous to docker's `overlay2/`, structured by snapshot id instead of layer id)
- `io.containerd.runtime.v2.task/` — per-namespace runtime task state, used by shims/runc integration

### namespaces (containerd's own concept, distinct from kernel namespaces!)
containerd partitions images/containers into namespaces so unrelated consumers don't collide:
- `k8s.io` — kubernetes
- `moby` — docker, when running on top of containerd
- `default` — `ctr`/`nerdctl` unless told otherwise
images/containers in one containerd-namespace are invisible from another, even though the underlying blobs may be shared in the content store.

### quick mapping: docker vs containerd on disk
| concept | docker (`/var/lib/docker`) | containerd (`/var/lib/containerd`) |
|---|---|---|
| downloaded layer data | `overlay2/` (already unpacked per storage driver) | `io.containerd.content.v1.content/` (compressed blobs) |
| image metadata | `image/` | boltDB metadata |
| mountable rootfs pieces | `overlay2/<id>/{diff,merged,work,lower}` | snapshotter dir, keyed by snapshot id |
| per-container config | `containers/<id>/config.v2.json`, `hostconfig.json` | task/shim state under `io.containerd.runtime.v2.task/` |

mental model: **pull** → blobs land in content store → **unpack** → snapshotter creates overlayfs-ready layer snapshots → **run** → writable snapshot + oci bundle handed to a shim → shim calls runc → process.

hands-on:
- `docker system df`; `du -sh /var/lib/docker/overlay2 /var/lib/docker/containers`
- `ctr -n k8s.io content ls`; `ctr -n k8s.io snapshots ls`
- `du -sh /var/lib/containerd/io.containerd.content.v1.content /var/lib/containerd/io.containerd.snapshotter.v1.overlayfs`
- map a running container to its on-disk dirs: docker → `docker inspect <id>` → `GraphDriver.Data` (MergedDir/UpperDir/LowerDir); containerd/k8s → `crictl inspect <id>` → snapshot key → look under the snapshotter dir
- use `ctr`/`nerdctl` to run a container without docker at all; observe one shim process per container (`ps --forest`)

references: https://containerd.io/, https://github.com/containerd/containerd, https://github.com/containerd/nerdctl, content/snapshot flow: https://github.com/containerd/containerd/blob/main/docs/content-flow.md

do not hand-edit files under `/var/lib/docker` or `/var/lib/containerd` — they are consistency-checked internal state, not a public format; you will corrupt it.

---

## 11) cri + kubelet — how k8s drives a runtime

### the protocol, concretely
kubelet never speaks to runc or containerd's native API directly. it speaks **CRI (Container Runtime Interface)**, a gRPC service, defined as protobuf in `k8s.io/cri-api`. containerd's **CRI plugin** (compiled in since containerd 1.1 — no separate "dockershim" process needed anymore) implements that gRPC service and listens on a unix socket, typically `/run/containerd/containerd.sock`.

```
kubelet  ──gRPC (unix socket, cri-api protobuf)──▶  containerd CRI plugin
                                                          │
                                            (containerd core: images/snapshots/tasks)
                                                          │
                                                        shim ──▶ runc ──▶ process
```

### CRI's two gRPC services
- **RuntimeService** — `RunPodSandbox`, `StopPodSandbox`, `RemovePodSandbox`, `CreateContainer`, `StartContainer`, `StopContainer`, `RemoveContainer`, `ListContainers`, `ContainerStatus`, `ListPodSandbox`, `Exec`/`ExecSync`/`Attach`
- **ImageService** — `PullImage`, `ListImages`, `ImageStatus`, `RemoveImage`

### pod sandbox / pause container
for every pod, kubelet's *first* CRI call is `RunPodSandbox`. this creates the **pause container** — a minimal process (literally does nothing but sleep/reap) whose sole job is to **hold the shared namespaces** for the pod, principally the network namespace (often ipc/uts too). every other container kubelet later creates for that pod joins the sandbox's namespaces (via `setns`, orchestrated by the runtime), which is *why* containers in the same pod share `localhost` and one pod IP. this is also the point where CNI plugins are invoked to wire up pod networking (see section 6).

if the pause container dies, the pod's network identity dies with it — kubelet detects this and recreates the sandbox (all containers in the pod restart).

references: https://kubernetes.io/docs/concepts/architecture/cri/, https://github.com/kubernetes/cri-api, https://github.com/kubernetes-sigs/cri-tools (crictl)

hands-on: on a node, use `crictl` to inspect pods/containers/images; map pod sandbox → pause container → network namespace (`crictl inspect <sandbox-id>` → netns path → `nsenter`/`ip netns` style inspection).

---

## 12) ipc + gRPC as the glue protocol (why tonic/rust fits here)

"ipc" shows up at two different layers in this stack — don't conflate them:
- the **ipc kernel namespace** (section 2) isolates SysV shared memory/message queues/semaphores *inside* a container
- the **inter-daemon ipc** discussed here is how host-local daemons talk to each other at all — and that's gRPC over unix domain sockets, not SysV IPC

### the chain, all gRPC
- containerd exposes its entire API (Containers, Tasks, Images, Content, Snapshots, Events, Leases services) as gRPC over a unix socket
- the CRI plugin inside containerd exposes CRI's RuntimeService/ImageService, also gRPC, also over a unix socket
- `ctr`, `nerdctl`, dockerd's containerd client, and kubelet are all just **gRPC clients** hitting these sockets
- the shim protocol (containerd ↔ shim) is its own small API, also generated from proto definitions (shim v2 API)

### why gRPC specifically
- protobuf gives a strongly-typed schema shared across languages/process boundaries (Go daemon, rust client, etc.)
- HTTP/2 transport supports bidirectional streaming — needed for `exec`/`attach`/log streaming, not just request/response
- code generation produces client+server stubs for many languages, including rust via **tonic** — which is exactly why the mini-project below ("write a tonic client against a CRI endpoint") is a realistic, small, high-signal exercise: you're not building a toy protocol, you're speaking the real thing.

references: https://grpc.io/, containerd api protos: https://github.com/containerd/containerd/tree/main/api, cri-api protos: https://github.com/kubernetes/cri-api

---

## 13) erofs — an alternative to overlayfs snapshots

**EROFS** (Enhanced Read-Only File System) is a linux kernel filesystem (mainlined ~5.4), designed for read-only use: compressed, low metadata overhead. originally built for Android, since adopted in container tooling.

### why it's relevant here
overlayfs' approach requires each image layer to be **fully unpacked** into real files/directories on the snapshotter's disk — lots of small files, real inode pressure, slower cold starts on images with many layers.

EROFS (like squashfs) instead packs an entire layer into **one compact read-only image file** that gets mounted directly — no unpack-into-loose-files step. benefits: less disk/inode overhead, faster cold start, especially valuable on layer-heavy images or storage-constrained/edge nodes. containers still need read-write on top, so an EROFS-backed snapshotter typically layers overlayfs (or a composefs-style mechanism) *on top of* the mounted read-only EROFS image for the writable layer, rather than replacing the layering model entirely.

this is an active area (containerd has experimental erofs snapshotter/differ work; related idea: **composefs**, which similarly avoids unpacking layers into loose files).

references: https://docs.kernel.org/filesystems/erofs.html, https://github.com/containers/composefs, containerd erofs snapshotter discussions/issues on the containerd repo

---

## learning order checklist

1. processes + exec model (fork/clone/execve/waitpid, pid 1 behavior)
2. namespaces (pid/mount/net/uts/ipc/user)
3. cgroups v2 (limits + accounting)
4. filesystem + overlayfs (layers → rootfs, pivot_root vs chroot)
5. security: capabilities + seccomp + lsm
6. oci specs (image spec + runtime spec)
7. runc/crun (reads the bundle, does the syscalls)
8. containerd (images, snapshots, shims)
9. cri + kubelet (gRPC contract, pod sandbox)

do each with the hands-on checkpoint in its section before moving on — reading about namespaces without running `unshare` yourself will not stick.

---

## what to build (to internalize it, not just read it)

**mini project a — "container from scratch (toy)"**
start a process in new namespaces + cgroup + pivot_root (no networking). deliverable: a small rust CLI that:
- prepares a rootfs dir
- unshares namespaces
- sets up a `/proc` mount
- sets up a cgroup v2 limit
- execs `/bin/sh` inside

**mini project b — "cri mental model in code"**
read the CRI proto and write a tiny gRPC client (rust + tonic) that calls a real CRI endpoint — even if it only does `ListContainers` against a local containerd's CRI socket. this is the most direct bridge from "I read about CRI" to "I've actually spoken the protocol."
