# tinklerbox prerequisites notes

## goal

learn what makes docker + k8 possible:
- linux internals primitives that make “containers” real
- oci + runc (how a container is created)
- containerd internals (from work)
- cri + kubelet (how k8 drives runtimes)

---

## linux internals primitives that make “containers” real (detailed)

### core idea

a container is not a kernel object like “struct container”.
it is a linux process (task) that the kernel isolates and constrains.
the isolation/constraints come from a set of kernel features:
- namespaces: isolate what a process can see
- cgroups: limit/account what a process can use
- mount + vfs + overlayfs: give the process a different filesystem root (/)
- security layers: restrict what syscalls/actions are allowed (caps/seccomp/lsm)

if you understand these, then docker/k8/containerd become “just orchestration glue”.

---

### 1) process is the unit of reality

containers start as a normal process created by:
- clone(2) (or fork(2) which is a wrapper style API)
- followed by execve(2) to replace memory with your target program

inside a container, that first process is typically pid 1 in the container pid namespace.
pid 1 is special:
- it should reap zombie children (waitpid) or zombies accumulate
- signal semantics differ (some signals are ignored by pid 1 by default)
this is why init systems/tini exist in containers.

key kernel data structures (names only, so you know what to google)
- task_struct: represents a process/thread in the kernel
- mm_struct: virtual memory mappings
- files_struct: open file table
- fs_struct: cwd + root
- cred: credentials (uids/gids/caps)

---

### 2) namespaces (what this process can see)

namespaces give different “views” of kernel resources.
the runtime sets them up using clone/unshare + setns.

pid namespace
- lets the process see a different pid tree
- inside, your process can be pid 1 even though host pid is something else
- /proc must be mounted from inside the pid namespace to show the right pids

mount namespace
- separate mount table per namespace
- this is the base of “container has its own filesystem layout”
- the runtime mounts rootfs, then mounts /proc, /dev, etc inside the namespace

network namespace
- separate network stack (interfaces, routes, netfilter rules, sockets namespace)
- container gets its own “lo”, “eth0”, ip, etc (often via veth pair + bridge/cni)

uts namespace
- hostname/domainname isolation

ipc namespace
- isolates system v shm segments, message queues, semaphores

user namespace
- remaps uids/gids: “root inside” can map to non-root outside
- this enables rootless containers
- important: many kernel permission checks become “namespaced”
- mapping is configured via /proc/<pid>/uid_map and gid_map (and setgroups)

cgroup namespace (newer)
- changes how processes see cgroup paths in /proc

how they are created (minimal syscall view)
- unshare(2): current process detaches into new namespaces
- clone(2): create a child already in new namespaces via flags
- setns(2): join an existing namespace by fd (from /proc/<pid>/ns/*)

where to inspect
- /proc/<pid>/ns/* are namespace fds (symlinks) you can compare across processes
- lsns / nsenter show/join namespaces from userspace

references (start here)
- namespaces(7), user_namespaces(7), unshare(2), setns(2), clone(2)

---

### 3) cgroups v2 (what this process can use)

cgroups are a filesystem-like API under /sys/fs/cgroup.
each process belongs to exactly one cgroup in the unified v2 hierarchy.
controllers enforce resource policies:
- cpu: throttling and shares (cpu.max, cpu.weight)
- memory: hard limits and oom behavior (memory.max, memory.high)
- io: blkio throttling (io.max, io.weight)
- pids: cap number of processes (pids.max)

why cgroups matter for containers
- without cgroups, a “container” can still consume all host cpu/ram and kill the node
- k8 uses cgroups to implement requests/limits, qos classes, eviction behavior

how runtimes use it
- create a cgroup directory for the container (often under kubepods/ in k8)
- write limits to files (memory.max, cpu.max, pids.max, etc)
- move the container process into that cgroup (by writing pid into cgroup.procs)

where to inspect
- /sys/fs/cgroup/<path>/ (controller files)
- /proc/<pid>/cgroup
- psi (pressure stall): /proc/pressure/*

references
- cgroup v2 docs: https://docs.kernel.org/admin-guide/cgroup-v2.html
- cgroups(7)

---

### 4) filesystem view (mounts + rootfs + overlayfs)

the kernel does not “run images”.
an image is just layers (tar archives) + metadata.
something has to assemble a root filesystem (rootfs) for the process.

rootfs creation (what userspace does)
- unpack layers somewhere on disk
- create a writable layer for this container
- mount overlayfs to present a merged filesystem view

overlayfs mental model
- lowerdir: read-only image layers (stacked)
- upperdir: writable layer (container changes)
- merged mount: what the container sees as /

entering the rootfs
- chroot(2) changes process root but has edge cases and does not change mount namespace root semantics
- pivot_root(2) is used by runtimes to properly switch the namespace root to the new rootfs

necessary “container mounts”
- /proc (procfs): process info (must be mounted inside the pid namespace for correctness)
- /dev: usually a tmpfs + bind mounts for devices (or devpts for /dev/pts)
- /sys: often read-only or masked; depends on security posture

where to inspect
- /proc/<pid>/mountinfo (best source of truth)
- findmnt

references
- overlayfs docs: https://docs.kernel.org/filesystems/overlayfs.html
- pivot_root(2), mount(2), mount_namespaces(7)

---

### 5) security primitives (what the process is allowed to do)

capabilities (fine-grained root power)
- root is not “all or nothing”; it is split into caps like CAP_NET_ADMIN, CAP_SYS_ADMIN, etc
- containers usually drop most caps by default

seccomp (syscall filter)
- a bpf program attached to the process says which syscalls are allowed/denied
- this is one of the biggest practical hardening steps in containers

lsm (apparmor/selinux/landlock, host dependent)
- mandatory access control beyond unix permissions
- in enterprise k8, selinux labels are a major part of containment

also important but easy to miss
- prctl(2): set “no new privs”, dumpable flags, etc
- rlimits: traditional per-process limits (ulimit), separate from cgroups

references
- capabilities(7), seccomp(2), seccomp(7), prctl(2)
- seccomp kernel doc: https://docs.kernel.org/userspace-api/seccomp_filter.html

---

### 6) networking (netns + veth + nat + cni)

the kernel piece is the network namespace.
the “connect it to the world” piece is userspace configuration:
- create a veth pair (like a virtual ethernet cable)
- one end moves into the container netns, becomes eth0
- host end attaches to a bridge or routed setup
- iptables/nftables provide nat/forwarding (common with docker)
- in k8, cni plugins implement the wiring model (bridge, calico, cilium, etc)

references
- network_namespaces(7)
- ip(8) (iproute2), nft(8)/iptables(8) depending on system

---

### 7) what “create a container” looks like as steps

if you reduce everything to “what must be done”, most runtimes do:
- make/choose namespaces (clone/unshare, setns)
- setup uid/gid mappings (userns, if used)
- mount rootfs (overlayfs) in the mount ns
- mount /proc, /dev, /sys policy mounts
- create + configure cgroup v2 directory, move process into it
- drop caps, apply seccomp, apply lsm labels (if configured)
- execve the target program

that’s it.
containerd/k8/runc just decide:
- which exact settings to apply
- how to fetch/unpack the filesystem
- how to keep processes alive across restarts (shims)

---

## on-disk storage: /var/lib/docker and /var/lib/containerd

both directories are local state + storage for container runtimes.
they are not kernel objects — they are how userspace persists images, layers, metadata, logs, and network state on disk.

do not edit files here manually; you can corrupt runtime state.

---

### /var/lib/docker (docker engine storage)

docker keeps everything it needs to run and persist containers here.

typical subfolders (names vary by distro / docker version):

image/
- image metadata: which layers make an image, tags → digests, etc.

overlay2/ (or aufs/, btrfs/, zfs/ depending on storage driver)
- actual filesystem data for images + containers
- layer dirs usually contain:
  - diff/ — files in that layer
  - link + lower — how overlayfs stacks layers
  - merged/ — live mount when a container is running
  - work/ — overlayfs workdir

containers/<container-id>/
- container-specific metadata and runtime files
- usually includes:
  - config.v2.json — docker container config
  - hostconfig.json — mounts, port mappings, limits, etc
  - <id>-json.log — container logs (if using json-file logging driver)

volumes/
- named volumes data (persistent container storage)

network/ (and sometimes plugins/)
- docker networking state (bridge config, endpoints)

swarm/ (if swarm mode enabled)

buildkit/ (if buildkit is enabled and using local storage)

where disk space goes
- biggest usage is usually overlay2/ + logs under containers/

---

### /var/lib/containerd (containerd storage)

containerd uses the same idea but is built around content-addressed blobs + snapshotters.

common layout:

io.containerd.content.v1.content/
- content store: blobs by digest (sha256…)
- pulled image layer blobs live here (compressed)

io.containerd.metadata.v1.bolt/
- metadata database (boltDB): images, containers, snapshot references, leases

io.containerd.snapshotter.v1.overlayfs/ (if overlayfs snapshotter is used)
- unpacked layer snapshots + writable snapshots for containers
- roughly analogous to docker overlay2/, but structured as snapshot ids

io.containerd.runtime.v2.task/
- runtime task state per namespace (ex: k8s.io)
- per-container runtime dirs used by shims/runc integration

namespaces matter
- containerd separates worlds using namespaces like:
  - k8s.io — kubernetes
  - moby — docker when using containerd underneath
  - default — ctr/nerdctl unless specified
- images/containers in one namespace are invisible to another
- docker and k8s can both use containerd but see different data depending on namespace

---

### quick mapping (docker vs containerd on disk)

docker
- storage driver directory (overlay2/) is the main filesystem data store
- image/ holds metadata mapping tags → layer chains

containerd
- content store = downloaded blobs (compressed layer data)
- snapshotter = unpacked filesystem views you can mount/run
- bolt metadata ties blobs + snapshots + container records together

mental model
- pull image → blobs land in content store
- unpack → snapshotter creates overlayfs-ready layer snapshots
- run container → writable snapshot + runc bundle → process

---

### hands-on checkpoints

inspect docker disk usage
- docker system df
- du -sh /var/lib/docker/overlay2 /var/lib/docker/containers

inspect containerd disk usage
- ctr -n k8s.io content ls
- ctr -n k8s.io snapshots ls
- du -sh /var/lib/containerd/io.containerd.content.v1.content
- du -sh /var/lib/containerd/io.containerd.snapshotter.v1.overlayfs

map running container → on-disk dirs
- docker: docker inspect <id> → GraphDriver.Data (MergedDir, UpperDir, LowerDir)
- containerd/k8: crictl inspect <id> → snapshot key, then look under snapshotter dir

references
- docker storage drivers: https://docs.docker.com/storage/storages/
- containerd architecture: https://containerd.io/docs/
- containerd content/snapshots: https://github.com/containerd/containerd/blob/main/docs/content-flow.md

---

## non-negotiable mental model (short)

a “container” is a normal linux process with:
- isolation: namespaces (what it can see)
- limits: cgroups (what it can use)
- filesystem view: mounts + overlayfs (what / looks like)
- security: capabilities + seccomp + lsm (what it can do)

everything else (docker, containerd, k8) is tooling that:
- pulls/unpacks images
- prepares an oci runtime bundle (rootfs + config.json)
- asks an oci runtime (runc/crun) to start the process
- monitors lifecycle + logs + restart policies

---

## learning order (do in this order)

### 1) processes + exec model
- fork/clone/execve/waitpid basics
- pid 1 behavior (signal handling, zombie reaping) matters in containers

references
- man pages: fork(2), clone(2), execve(2), waitpid(2), prctl(2)
- linux kernel docs (process): https://docs.kernel.org/

hands-on checkpoints
- write a tiny program that forks + execs + waits (rust or c)
- observe states with: ps, top/htop, /proc/<pid>/*

---

### 2) namespaces (isolation)
- pid, mount, net, uts, ipc, user namespaces
- what changes are visible inside vs outside

references
- man pages: unshare(2), setns(2), namespaces(7), user_namespaces(7)
- util-linux tool docs: unshare(1), nsenter(1)
- /proc namespaces: /proc/<pid>/ns/*

hands-on checkpoints
- create a new pid + mount ns with unshare(1) and confirm:
  - inside sees its own pid space
  - mount table differs (mount namespace)
- use lsns + nsenter to compare host vs namespace view

---

### 3) cgroups v2 (limits + accounting)
- memory.max, cpu.max, io.max, pids.max, pressure stall info (psi)
- understand that “limits” are enforced by kernel controllers, not by docker

references
- kernel docs: cgroup v2: https://docs.kernel.org/admin-guide/cgroup-v2.html
- man pages: cgroups(7)
- systemd view (if systemd): systemd-cgls(1), systemd-run(1)

hands-on checkpoints
- run a process in a new cgroup and cap memory/cpu
- observe throttling + oom kill behavior

---

### 4) filesystem + overlayfs (images become rootfs)
- image layers + copy-on-write
- overlayfs: lowerdir/upperdir/workdir merged mount
- pivot_root vs chroot and why pivot_root is used

references
- kernel docs: overlayfs: https://docs.kernel.org/filesystems/overlayfs.html
- man pages: mount(2), mount(8), pivot_root(2), chroot(2)

hands-on checkpoints
- manually mount an overlayfs and “enter” it with chroot (demo)
- inspect mounts with findmnt and /proc/self/mountinfo

---

### 5) security: capabilities + seccomp + lsm
- linux capabilities: shrink “root” power
- seccomp-bpf: allow/deny syscalls
- lsm: apparmor/selinux (host dependent)

references
- man pages: capabilities(7), capset(2), prctl(2), seccomp(2), seccomp(7)
- kernel docs: seccomp: https://docs.kernel.org/userspace-api/seccomp_filter.html

hands-on checkpoints
- drop capabilities and see which operations break
- run with a restrictive seccomp profile and observe blocked syscalls

---

### 6) oci specs (the contract)
- oci image spec: how images are described + stored
- oci runtime spec: config.json describing the container process/env/namespaces/cgroups

references
- oci runtime spec: https://github.com/opencontainers/runtime-spec
- oci image spec: https://github.com/opencontainers/image-spec

hands-on checkpoints
- inspect a real oci bundle: rootfs + config.json
- understand how args/env/cwd/user/caps/seccomp map to the kernel

---

### 7) runc/crun (the “container creator”)
- runc reads the oci bundle and performs the namespace/cgroup/mount/security setup

references
- runc: https://github.com/opencontainers/runc
- crun: https://github.com/containers/crun

hands-on checkpoints
- generate an oci bundle and start it with runc
- trace the key syscalls (clone/unshare/mount/pivot_root/execve)

---

### 8) containerd (runtime manager)
- pull images, unpack layers, manage snapshots, spawn shims, call runc
- why shims exist (daemon restart resilience, stdio, reaping, lifecycle)

references
- containerd docs: https://containerd.io/
- containerd repo: https://github.com/containerd/containerd
- nerdctl (cli for containerd): https://github.com/containerd/nerdctl

hands-on checkpoints
- use ctr/nerdctl to run containers without docker
- locate the snapshotter data and understand overlayfs layout
- understand shim per container concept

---

### 9) cri + kubelet (k8 runtime interface)
- kubelet talks to runtime via cri gRPC
- pod sandbox / pause container: stable network namespace for the pod

references
- cri docs (k8): https://kubernetes.io/docs/concepts/architecture/cri/
- cri-api proto: https://github.com/kubernetes/cri-api
- crictl: https://github.com/kubernetes-sigs/cri-tools

hands-on checkpoints
- on a node: use crictl to inspect pods/containers/images
- map pod sandbox → pause container → network namespace

---

## what to build (so you internalize it)

mini project a: “container from scratch (toy)”
- goal: start a process in new namespaces + cgroup + pivot_root (no networking)
- deliverable: a small cli in rust that:
  - prepares a rootfs dir
  - unshares namespaces
  - sets up /proc mount
  - sets up a cgroup v2 limit
  - execs /bin/sh inside

mini project b: “cri mental model in code”
- goal: learn the gRPC shapes (you mentioned tonic)
- deliverable: read the cri proto and write a tiny gRPC client that calls a cri endpoint (even if you only do ListContainers)

---

## quick glossary

- container: a process + kernel isolation/limits
- image: layered filesystem content + config metadata
- rootfs: assembled filesystem view used as /
- oci bundle: rootfs + config.json
- runtime (runc/crun): creates the container process
- containerd: manages images/snapshots/lifecycle + calls runtime
- cri: kubelet ↔ runtime gRPC interface
- pod sandbox/pause: holds shared namespaces (especially network) for a pod
- content store: containerd blob storage under /var/lib/containerd (compressed image layers)
- snapshotter: unpacks blobs into overlayfs-ready filesystem snapshots
- overlay2: docker storage driver dir under /var/lib/docker (layer diffs + merged mounts)
