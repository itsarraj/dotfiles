# 11. cri + kubelet — how kubernetes drives a runtime

related: [00-index](00-index.md) · prev: [10-containerd-internals](10-containerd-internals.md) · next: [12-grpc-and-ipc](12-grpc-and-ipc.md) · protocol detailed in: [12-grpc-and-ipc](12-grpc-and-ipc.md) · calls into: [10-containerd-internals](10-containerd-internals.md) · sandbox owns: [02-namespaces](02-namespaces.md) (shared netns), triggers: [06-networking-and-ports](06-networking-and-ports.md) (CNI)

## the problem cri solves

kubernetes needs to run containers, but deliberately does not want kubelet
hardcoded against one specific runtime's internal API (containerd's native
gRPC API, or CRI-O's, or anything else). **CRI (Container Runtime
Interface)** is the fix: a single gRPC contract, defined once as protobuf
in `k8s.io/cri-api`, that any runtime can implement. kubelet only ever
speaks CRI — it has zero knowledge of containerd's content store,
snapshotters, or shim protocol from
[10-containerd-internals](10-containerd-internals.md); all of that is
hidden behind the CRI plugin.

## where the plugin actually lives

containerd has had a **built-in CRI plugin** since containerd 1.1 — it's
compiled directly into the containerd binary and listens for CRI gRPC
calls on the *same* unix socket containerd already exposes its native API
on, typically `/run/containerd/containerd.sock`. (older kubernetes setups
used a separate process called **dockershim** to translate CRI into
docker's own API when docker itself was the runtime; that shim was removed
from kubelet in 1.24 — CRI-compliant runtimes like containerd or CRI-O are
now required directly.)

```
kubelet  ──gRPC (unix socket, cri-api protobuf)──▶  containerd CRI plugin
                                                          │
                                            containerd core: content store,
                                            snapshotters, task service    [10]
                                                          │
                                                        shim ──▶ runc ──▶ process
                                                                [10]      [09],[07]
```

## the two cri services

CRI is split into two gRPC services (see
[12-grpc-and-ipc](12-grpc-and-ipc.md) for what "gRPC service" means
concretely):

- **`RuntimeService`** — the container/pod lifecycle surface:
  `RunPodSandbox`, `StopPodSandbox`, `RemovePodSandbox`, `CreateContainer`,
  `StartContainer`, `StopContainer`, `RemoveContainer`, `ListContainers`,
  `ContainerStatus`, `ListPodSandbox`, plus interactive operations `Exec`,
  `ExecSync`, `Attach`, and log retrieval.
- **`ImageService`** — `PullImage`, `ListImages`, `ImageStatus`,
  `RemoveImage`. this is the service that ultimately drives containerd's
  pull → content-store → snapshotter pipeline from
  [10-containerd-internals](10-containerd-internals.md#the-pull--unpack--run-pipeline).

## pod sandbox / pause container — the piece that makes pods a real thing

kubelet's *first* CRI call for any new pod is always `RunPodSandbox`. this
creates the **pause container**: an intentionally trivial process (its
entire job is to sleep and reap orphaned children) whose sole purpose is to
**own the namespaces the pod's containers will share** — principally the
**network namespace** ([02-namespaces](02-namespaces.md#network-namespace)),
and often the IPC and UTS namespaces too.

- this is also the exact moment a **CNI plugin** is invoked
  ([06-networking-and-ports](06-networking-and-ports.md#cni--the-pluggable-model-kubernetes-uses))
  to assign the pod its cluster IP and wire up its networking — one CNI
  invocation per pod, not per container, precisely because the network
  namespace is sandbox-owned.
- every subsequent `CreateContainer` call for that pod produces a container
  whose OCI `config.json` sets `linux.namespaces` to **join** (not create)
  the sandbox's existing namespaces — recall from
  [08-oci-specs](08-oci-specs.md#oci-runtime-spec--the-configjson-contract)
  that a namespace entry with a `path` set means `setns` onto an existing
  namespace rather than creating a fresh one via `clone`/`unshare`. this is
  the literal mechanism by which "containers in the same pod share
  `localhost` and one pod IP" is implemented — there is no separate
  kubernetes-level network stack, just ordinary `setns` onto a shared
  namespace, orchestrated one level up by kubelet's CRI call sequence.
- if the pause container dies, the pod's entire network identity dies with
  it (the namespace itself was owned by that process). kubelet detects this
  and recreates the whole sandbox, which is why killing the pause container
  manually restarts every container in that pod, not just one.

## the request sequence for starting a pod, concretely

1. kubelet calls `RunPodSandbox` → containerd creates the pause
   container, invokes CNI, assigns pod IP.
2. for each container in the pod spec: kubelet calls `PullImage` (if
   needed) → `ImageService` drives the pull/unpack pipeline
   ([10](10-containerd-internals.md)).
3. kubelet calls `CreateContainer` (referencing the sandbox id, so the new
   container's namespaces are set to join it) → containerd builds the
   OCI bundle, spawns a shim, shim invokes `runc create`.
4. kubelet calls `StartContainer` → shim invokes `runc start` → `execve`
   happens ([07](07-container-creation-steps.md), [09](09-runc-crun.md)).
5. kubelet periodically calls `ContainerStatus`/`ListContainers` for
   health/liveness bookkeeping, and `Exec`/`Attach` on demand for
   `kubectl exec`.

## references

- CRI overview: https://kubernetes.io/docs/concepts/architecture/cri/
- CRI-api proto definitions: https://github.com/kubernetes/cri-api
- `crictl`: https://github.com/kubernetes-sigs/cri-tools

## hands-on

- on a node with containerd, run `crictl pods`, `crictl ps`, `crictl
  images` to see the CRI-level view (as opposed to `ctr`, which talks to
  containerd's native API, or `docker ps`, which — if present at all —
  talks to a completely separate dockerd/moby namespace, see
  [10-containerd-internals](10-containerd-internals.md#containerd-namespaces-a-different-concept-from-kernel-namespaces)).
- `crictl inspectp <sandbox-id>` to find the sandbox's network namespace
  path, then `crictl inspect <container-id>` for a container in the same
  pod, and confirm both reference the same netns path.
- kill the pause container's process directly on the node (find it via
  `ps --forest`, it'll be running something like `/pause`) and watch
  kubelet notice and recreate the entire pod's sandbox.
