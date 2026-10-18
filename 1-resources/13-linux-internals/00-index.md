# tinklerbox notes — index

deep, interconnected notes on "what makes docker + k8s possible." each file
below is a standalone deep-dive; read them in order the first time, then use
this index as a map to jump around. this expands on the summary in
[../tinklerbox.md](../tinklerbox.md) — that file stays as the fast-reference
version; these files are the "dig as deep as you want" version.

## reading order

1. [01-processes-and-exec.md](01-processes-and-exec.md) — the process is the unit of reality
2. [02-namespaces.md](02-namespaces.md) — what a process can see
3. [03-cgroups-v2.md](03-cgroups-v2.md) — what a process can use
4. [04-filesystem-overlayfs.md](04-filesystem-overlayfs.md) — what `/` looks like
5. [05-security-capabilities-seccomp-lsm.md](05-security-capabilities-seccomp-lsm.md) — what a process can do
6. [06-networking-and-ports.md](06-networking-and-ports.md) — how it talks to the world
7. [07-container-creation-steps.md](07-container-creation-steps.md) — all of the above, as one ordered recipe
8. [08-oci-specs.md](08-oci-specs.md) — the interchange format that makes 1–7 portable
9. [09-runc-crun.md](09-runc-crun.md) — the program that actually executes step 7
10. [10-containerd-internals.md](10-containerd-internals.md) — the daemon that manages images + calls runc
11. [11-cri-and-kubelet.md](11-cri-and-kubelet.md) — how kubernetes drives containerd
12. [12-grpc-and-ipc.md](12-grpc-and-ipc.md) — the protocol every arrow above is drawn with
13. [13-erofs.md](13-erofs.md) — an alternative to overlayfs for image layers

## the one-paragraph mental model

a **container** is a normal linux process. it is made to *feel* like a
container by four independent kernel mechanisms: **namespaces** (what it can
see — [02](02-namespaces.md)), **cgroups** (what it can use —
[03](03-cgroups-v2.md)), **mounts/overlayfs** (what `/` looks like —
[04](04-filesystem-overlayfs.md)), and **capabilities/seccomp/lsm** (what it's
allowed to do — [05](05-security-capabilities-seccomp-lsm.md)). nothing above
that is a kernel concept — **OCI** ([08](08-oci-specs.md)) is just a file
format for describing "which settings," **runc** ([09](09-runc-crun.md)) is
just a program that reads that file format and makes the syscalls, and
**containerd** ([10](10-containerd-internals.md)) /
**kubelet+CRI** ([11](11-cri-and-kubelet.md)) are just daemons that decide
*when* to ask runc to do that, wired together over **gRPC**
([12](12-grpc-and-ipc.md)).

## how the pieces call each other (top to bottom, one request)

```
kubectl run pod
    │  (k8s API, not covered here — out of scope for this note set)
    ▼
kubelet                                         [11]
    │  gRPC (CRI) over /run/containerd/containerd.sock         [12]
    ▼
containerd (CRI plugin)                         [10]
    │  pulls image → content store → snapshotter (overlayfs/erofs)  [10],[04],[13]
    │  writes an OCI bundle: rootfs/ + config.json               [08]
    │  spawns containerd-shim-runc-v2                             [10]
    ▼
shim
    │  invokes `runc create` / `runc start`                       [09]
    ▼
runc
    │  clone/unshare namespaces           [02]
    │  create cgroup, write limits         [03]
    │  mount rootfs via overlayfs, pivot_root   [04]
    │  drop capabilities, load seccomp, apply lsm labels  [05]
    │  execve(2)                           [01]
    ▼
your container process
    │  networked via CNI-created veth + netns, ports via iptables/ipvs  [06]
```

read [07-container-creation-steps.md](07-container-creation-steps.md) for
this same chain condensed to the seven kernel-level steps, stripped of all
daemon/protocol scaffolding — that's the version worth memorizing.

## quick glossary

- **container**: a process + namespaces + cgroups — not a kernel object
- **image**: layered filesystem content + config metadata, content-addressed
- **rootfs**: assembled filesystem view used as `/`
- **oci bundle**: `rootfs/` + `config.json`
- **runtime (runc/crun)**: creates the container process from a bundle
- **containerd**: manages images/snapshots/lifecycle, calls the runtime via a shim
- **shim**: long-lived per-container process; survives daemon restarts
- **cri**: kubelet ↔ runtime gRPC interface
- **pod sandbox/pause container**: holds the shared namespaces (esp. network) for a pod
- **content store**: containerd's compressed-blob storage
- **snapshotter**: unpacks blobs into a mountable filesystem (overlayfs or erofs)
- **overlay2**: docker's storage-driver directory, same idea as a snapshotter

## what to build

see the end of [../tinklerbox.md](../tinklerbox.md) for the two mini
projects (toy container runtime in rust; tonic gRPC client against CRI) —
kept there since they're deliverables, not reference notes.
