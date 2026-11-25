# 7. "create a container," reduced to steps

related: [00-index](00-index.md) · prev: [06-networking-and-ports](06-networking-and-ports.md) · next: [08-oci-specs](08-oci-specs.md) · this is the synthesis of [01](01-processes-and-exec.md)–[06](06-networking-and-ports.md); executed concretely by [09-runc-crun](09-runc-crun.md)

## the point of this file

every file so far covered one kernel mechanism in isolation. this file is
the payoff: strip away every daemon, protocol, and file format, and "create
a container" is exactly these seven steps, done to one ordinary process,
before it execs into your actual program.

## the seven steps

1. **make/choose namespaces** — `clone(2)` (or `unshare(2)` + `setns(2)`)
   with the `CLONE_NEW*` flags for pid, mount, net, uts, ipc, and
   optionally cgroup namespaces. see [02-namespaces](02-namespaces.md).
   (network namespace may instead be *joined* via `setns` if this
   container is joining an existing pod sandbox — see
   [11-cri-and-kubelet](11-cri-and-kubelet.md).)

2. **set up uid/gid mappings** — if a user namespace is in play, write
   `/proc/<pid>/uid_map` and `gid_map` before the process does anything
   privilege-sensitive. see [02-namespaces](02-namespaces.md#user-namespace).

3. **mount rootfs** — assemble the overlayfs merged view from image layers
   + a fresh writable layer, mount it, then `pivot_root(2)` into it from
   inside the new mount namespace. see
   [04-filesystem-overlayfs](04-filesystem-overlayfs.md).

4. **mount `/proc`, `/dev`, `/sys`** per policy — `/proc` specifically must
   be mounted *after* step 1's pid namespace is active, or it reports the
   host's process list. see
   [04-filesystem-overlayfs](04-filesystem-overlayfs.md#the-other-required-mounts).

5. **create + configure the cgroup**, write resource limits to its
   controller files, and move the process's pid into `cgroup.procs`. see
   [03-cgroups-v2](03-cgroups-v2.md).

6. **drop capabilities, load the seccomp filter, apply LSM labels** (if
   configured) — shrink the bounding capability set, attach the BPF seccomp
   program, set `PR_SET_NO_NEW_PRIVS`, apply an AppArmor/SELinux profile if
   present. see
   [05-security-capabilities-seccomp-lsm](05-security-capabilities-seccomp-lsm.md).

7. **`execve(2)` the target program** — memory image is replaced, pid stays
   the same, and everything configured in steps 1–6 persists across the
   exec because it's attached to the *process*, not the program image. see
   [01-processes-and-exec](01-processes-and-exec.md).

networking ([06-networking-and-ports](06-networking-and-ports.md)) is
usually wired up **around** this sequence rather than inside it — the veth
pair and CNI configuration typically happen once per **pod sandbox**
(before any of the pod's real containers are created), and subsequent
containers in the pod just join that already-configured network namespace
at step 1 via `setns` instead of getting a fresh one.

## what's *not* in this list

notice everything absent: no mention of docker, containerd, kubelet, OCI,
gRPC, images, registries, or YAML. that's deliberate — none of those things
are kernel concepts. they exist to answer three questions that this
seven-step recipe assumes are already answered:

- **which exact settings** go into steps 1–6? → answered by a config file
  format: [08-oci-specs](08-oci-specs.md).
- **how do you get from "an image sitting in a registry" to "a rootfs on
  disk ready for step 3"?** → answered by a daemon that pulls, unpacks, and
  snapshots images: [10-containerd-internals](10-containerd-internals.md).
- **how does the process survive on the host, get logs streamed, and get
  reported as exited, independent of whatever daemon asked for it to be
  created?** → answered by a long-lived shim process:
  [10-containerd-internals](10-containerd-internals.md#why-shims-exist).

## who actually performs these seven steps

the program that literally makes these syscalls, in this order, is the OCI
**runtime** — `runc` or `crun`. see
[09-runc-crun.md](09-runc-crun.md). everything above it in the stack
(shim → containerd → CRI plugin → kubelet) exists purely to decide *when*
to invoke the runtime and *with what config.json*, never to perform these
steps itself.

## hands-on

the single best exercise for internalizing this file: generate a real OCI
bundle (`runc spec` produces a template `config.json`), point `rootfs/` at
a minimal extracted image, and run `strace -f runc run mycontainer`. Read
the strace output looking specifically for, in order: `clone`/`unshare`
calls with namespace flags, writes to `uid_map`/`gid_map` if applicable,
`mount` calls (rootfs, then `/proc`/`/dev`/`/sys`), `pivot_root`, cgroup
file writes, `prctl`/`seccomp`/capability-related syscalls, and finally
`execve`. seeing all seven steps as literal syscalls in one trace is the
fastest way to make this permanent.
