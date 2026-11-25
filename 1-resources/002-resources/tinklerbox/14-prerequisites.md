goal

learn what makes docker + k8 possible:
- linux internals primitives that make “containers” real
- oci + runc (how a container is created)
- containerd internals (from work)
- cri + kubelet (how k8 drives runtimes)

non-negotiable mental model

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

learning order (do in this order)

1) processes + exec model
- fork/clone/execve/waitpid basics
- pid 1 behavior (signal handling, zombie reaping) matters in containers

references
- man pages: fork(2), clone(2), execve(2), waitpid(2), prctl(2)
- linux kernel docs (process): https://docs.kernel.org/

hands-on checkpoints
- write a tiny program that forks + execs + waits (rust or c)
- observe states with: ps, top/htop, /proc/<pid>/*

2) namespaces (isolation)
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

3) cgroups v2 (limits + accounting)
- memory.max, cpu.max, io.max, pids.max, pressure stall info (psi)
- understand that “limits” are enforced by kernel controllers, not by docker

references
- kernel docs: cgroup v2: https://docs.kernel.org/admin-guide/cgroup-v2.html
- man pages: cgroups(7)
- systemd view (if systemd): systemd-cgls(1), systemd-run(1)

hands-on checkpoints
- run a process in a new cgroup and cap memory/cpu
- observe throttling + oom kill behavior

4) filesystem + overlayfs (images become rootfs)
- image layers + copy-on-write
- overlayfs: lowerdir/upperdir/workdir merged mount
- pivot_root vs chroot and why pivot_root is used

references
- kernel docs: overlayfs: https://docs.kernel.org/filesystems/overlayfs.html
- man pages: mount(2), mount(8), pivot_root(2), chroot(2)

hands-on checkpoints
- manually mount an overlayfs and “enter” it with chroot (demo)
- inspect mounts with findmnt and /proc/self/mountinfo

overlawfs(in details) - go in full details

5) security: capabilities + seccomp + lsm (learn in details)
- linux capabilities: shrink “root” power
- seccomp-bpf: allow/deny syscalls
- lsm: apparmor/selinux (host dependent)

references
- man pages: capabilities(7), capset(2), prctl(2), seccomp(2), seccomp(7)
- kernel docs: seccomp: https://docs.kernel.org/userspace-api/seccomp_filter.html

hands-on checkpoints
- drop capabilities and see which operations break
- run with a restrictive seccomp profile and observe blocked syscalls

6) oci specs (the contract) in details 
- oci image spec: how images are described + stored
- oci runtime spec: config.json describing the container process/env/namespaces/cgroups

references
- oci runtime spec: https://github.com/opencontainers/runtime-spec
- oci image spec: https://github.com/opencontainers/image-spec

hands-on checkpoints
- inspect a real oci bundle: rootfs + config.json
- understand how args/env/cwd/user/caps/seccomp map to the kernel

7) runc/crun (the “container creator”)
- runc reads the oci bundle and performs the namespace/cgroup/mount/security setup

references
- runc: https://github.com/opencontainers/runc
- crun: https://github.com/containers/crun

hands-on checkpoints
- generate an oci bundle and start it with runc
- trace the key syscalls (clone/unshare/mount/pivot_root/execve)

8) containerd (runtime manager)
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

9) cri + kubelet (k8 runtime interface)
- kubelet talks to runtime via cri gRPC
- pod sandbox / pause container: stable network namespace for the pod

references
- cri docs (k8): https://kubernetes.io/docs/concepts/architecture/cri/
- cri-api proto: https://github.com/kubernetes/cri-api
- crictl: https://github.com/kubernetes-sigs/cri-tools

hands-on checkpoints
- on a node: use crictl to inspect pods/containers/images
- map pod sandbox → pause container → network namespace

what to build (so you internalize it)

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

quick glossary (keep this crisp)

- container: a process + kernel isolation/limits
- image: layered filesystem content + config metadata
- rootfs: assembled filesystem view used as /
- oci bundle: rootfs + config.json
- runtime (runc/crun): creates the container process
- containerd: manages images/snapshots/lifecycle + calls runtime
- cri: kubelet ↔ runtime gRPC interface
- pod sandbox/pause: holds shared namespaces (especially network) for a pod


port handling - how the port is allocated to container 
how the 
ipc protocol and grpc protocol
how erofs works - in ultraedge
