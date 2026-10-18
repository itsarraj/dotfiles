# 10. containerd — images, snapshots, shims

related: [00-index](00-index.md) · prev: [09-runc-crun](09-runc-crun.md) · next: [11-cri-and-kubelet](11-cri-and-kubelet.md) · produces bundles for: [09-runc-crun](09-runc-crun.md) · unpacks: [08-oci-specs](08-oci-specs.md) images · builds rootfs via: [04-filesystem-overlayfs](04-filesystem-overlayfs.md) or [13-erofs](13-erofs.md) · exposes its API via: [12-grpc-and-ipc](12-grpc-and-ipc.md) · driven by: [11-cri-and-kubelet](11-cri-and-kubelet.md)

## containerd's job, precisely

everything in [01](01-processes-and-exec.md)–[09](09-runc-crun.md) explains
how *one* container gets created from a bundle that already exists.
containerd answers the layer of questions above that: where does the image
come from, how does it become an unpacked rootfs, how do you keep dozens of
containers' lifecycles straight, and how does a container survive the
daemon that started it restarting? containerd deliberately stays out of
*policy* — scheduling, restart policy semantics as k8s defines them, image
policy — that's for its callers (kubelet via CRI, or dockerd) to decide.

## architecture, top to bottom

```
client (ctr / nerdctl / dockerd's containerd client / kubelet via CRI plugin)
      │  gRPC over unix socket (/run/containerd/containerd.sock)   [12]
      ▼
containerd daemon
  ├─ content store        (compressed blobs by digest)              ↓
  ├─ metadata (bolt db)   (images, containers, snapshot refs, leases)
  ├─ snapshotters         (overlayfs / erofs)             [04],[13]
  ├─ image service, task service, events, leases
  └─ CRI plugin (built-in since containerd 1.1)            [11]
      │  spawns, one per container
      ▼
containerd-shim-runc-v2   (long-lived, subreaper, owns stdio + exit status)
      │  invokes once to create/start, then runc exits
      ▼
runc  →  container process                                [09],[07]
```

## why shims exist

`runc` is intentionally short-lived (see
[09-runc-crun](09-runc-crun.md#why-runc-is-deliberately-short-lived)) —
something else has to be the durable parent. that's
**`containerd-shim-runc-v2`**, one instance spawned per container:

- **daemon-restart resilience** — the shim, not containerd itself, is the
  actual process-tree parent of the container process. containerd can be
  restarted or upgraded entirely without killing any running container,
  because the thing keeping the container alive and reaped was never
  containerd in the first place.
- **stdio handling** — the shim owns the container's stdin/stdout/stderr
  pipes/fifos and is what `docker logs`/`crictl logs`/exec-attach actually
  stream from.
- **reaping** — the shim registers itself as a subreaper (`prctl(2)`,
  `PR_SET_CHILD_SUBREAPER`) so that zombies anywhere in the container's
  process subtree get collected correctly, even while containerd itself is
  down or being upgraded.
- **lifecycle reporting** — the shim reports exit codes/status back to
  containerd over its own small protocol, generated from proto definitions
  (the "shim v2 API") — this too is gRPC-shaped, per
  [12-grpc-and-ipc](12-grpc-and-ipc.md).
- runc's role, from the shim's point of view, is just: invoke `runc
  create`/`runc start` once, let it exit, and take over supervision from
  there.

## the pull → unpack → run pipeline

1. **pull** — containerd fetches an image's manifest, config, and layer
   blobs from a registry (speaking the OCI distribution spec, see
   [08-oci-specs](08-oci-specs.md#oci-image-spec--packaging)) and stores
   them, compressed, in the **content store**, keyed by sha256 digest.
2. **unpack** — a **snapshotter** takes those compressed layer blobs and
   produces a mountable filesystem snapshot for each layer, plus a fresh
   writable snapshot for a new container. the default snapshotter does
   this via overlayfs (see [04-filesystem-overlayfs](04-filesystem-overlayfs.md));
   an alternative snapshotter can use erofs instead (see
   [13-erofs](13-erofs.md)) to avoid unpacking into loose files at all.
3. **run** — containerd generates an OCI bundle (rootfs path from the
   snapshot + a `config.json` built from the container's spec, see
   [08-oci-specs](08-oci-specs.md#oci-runtime-spec--the-configjson-contract))
   and hands it to a freshly spawned shim, which invokes runc.

## on-disk layout (`/var/lib/containerd`)

- **`io.containerd.content.v1.content/`** — the content store: blobs by
  sha256 digest — pulled, still-compressed layer/manifest/config blobs.
  this directory is effectively a local cache of exactly what a registry
  serves over the OCI distribution API.
- **`io.containerd.metadata.v1.bolt/`** — a boltDB (embedded key-value
  store) holding metadata: which images exist, which containers reference
  which snapshots, leases (reference-counting to stop garbage collection
  of blobs still in use).
- **`io.containerd.snapshotter.v1.overlayfs/`** — unpacked layer snapshots
  and per-container writable snapshots, keyed by an internal snapshot id
  rather than by layer digest directly. structurally this is the same idea
  as docker's `overlay2/` (each snapshot dir has its own diff/merged/work
  areas), just organized around containerd's own snapshot bookkeeping.
- **`io.containerd.runtime.v2.task/`** — per-namespace (see below) runtime
  task state, one subtree per running task, used by the shim/runc
  integration to track live containers.

## containerd namespaces (a *different* concept from kernel namespaces!)

containerd partitions all images/containers into its own logical
namespaces so unrelated consumers on the same host don't collide or see
each other's state — **do not confuse this with the kernel namespaces from
[02-namespaces](02-namespaces.md)**; it's purely an API-level partitioning
inside containerd's own metadata store:

- `k8s.io` — everything kubernetes creates via the CRI plugin
- `moby` — docker's own containers, when dockerd runs on top of containerd
- `default` — what `ctr`/`nerdctl` use unless told otherwise

images/containers in one containerd-namespace are invisible to API calls
scoped to a different one, even though the underlying content-store blobs
may physically be shared (a shared base-image layer pulled once still lives
once in the content store, regardless of which containerd-namespace
references it).

## docker vs containerd, side by side

| concept | docker (`/var/lib/docker`) | containerd (`/var/lib/containerd`) |
|---|---|---|
| downloaded layer data | `overlay2/` (already unpacked, per storage driver) | `io.containerd.content.v1.content/` (still-compressed blobs) |
| image metadata | `image/` | boltDB metadata |
| mountable rootfs pieces | `overlay2/<id>/{diff,merged,work,lower}` | snapshotter dir, keyed by snapshot id |
| per-container config | `containers/<id>/config.v2.json`, `hostconfig.json` | task/shim state under `io.containerd.runtime.v2.task/` |

mental model, one line: **pull → blobs land in content store → unpack →
snapshotter builds overlayfs/erofs-ready layer snapshots → run → writable
snapshot + OCI bundle handed to a shim → shim invokes runc → process.**

## references

- https://containerd.io/
- https://github.com/containerd/containerd
- https://github.com/containerd/nerdctl (CLI for containerd without docker)
- content/snapshot flow: https://github.com/containerd/containerd/blob/main/docs/content-flow.md

**do not hand-edit anything under `/var/lib/docker` or `/var/lib/containerd`**
— both are consistency-checked internal state (boltDB + content-addressed
blobs), not a stable public format; manual edits can corrupt them silently.

## hands-on

- `ctr -n k8s.io content ls` / `ctr -n k8s.io snapshots ls` to see the
  content store and snapshotter state directly, separate from whatever
  docker or kubelet think is running.
- `du -sh /var/lib/containerd/io.containerd.content.v1.content
  /var/lib/containerd/io.containerd.snapshotter.v1.overlayfs` to see where
  disk usage actually goes.
- run a container with `nerdctl` (no docker involved at all) and use `ps
  --forest` to spot the shim process sitting as parent of the container
  process — direct proof of the "why shims exist" section above.
- map a running container to on-disk state: `crictl inspect <id>` → find
  its snapshot key → locate the corresponding directory under the
  snapshotter dir.
