# 8. oci specs — the contract that makes images/runtimes portable

related: [00-index](00-index.md) · prev: [07-container-creation-steps](07-container-creation-steps.md) · next: [09-runc-crun](09-runc-crun.md) · describes the settings for: [02](02-namespaces.md), [03](03-cgroups-v2.md), [04](04-filesystem-overlayfs.md), [05](05-security-capabilities-seccomp-lsm.md) · consumed by: [09-runc-crun](09-runc-crun.md) · produced by: [10-containerd-internals](10-containerd-internals.md)

## why a spec exists at all

[07-container-creation-steps](07-container-creation-steps.md) is a sequence
of syscalls with dozens of possible parameters (which namespaces, which
capabilities, what cgroup limits, which mounts). if every container tool
invented its own way to describe those parameters, no image could run
portably across docker, podman, containerd, or any k8s runtime. the **Open
Container Initiative (OCI)** defines two independent specs that solve this:
the **image spec** (how an image is packaged and described) and the
**runtime spec** (how a runtime should be told to start a process). they're
separable on purpose — a compliant image can be unpacked by any tool into a
bundle that any compliant runtime can run, and neither side needs to know
about the other's implementation.

## oci image spec — packaging

an OCI image is a tree of content-addressed JSON documents and blobs,
referenced by sha256 digest at every level:

- **image manifest** (media type
  `application/vnd.oci.image.manifest.v1+json`) — the root document for one
  platform-specific image. references exactly one **config** blob and an
  ordered list of **layer** blobs, each identified by digest.
- **image config** — a JSON document holding: `architecture`, `os`, `env`,
  `entrypoint`/`cmd`, `workingDir`, `user`, and critically
  `rootfs.diff_ids` — the list of *uncompressed* layer digests in
  application order (this is what proves layer identity/order independent
  of the compression used for transport) — plus `history` (human-readable
  build provenance, one entry per layer/build instruction).
- **image index** (a "manifest list") — one level above the manifest: a
  list of `{platform: {os, architecture}, manifest digest}` entries. this
  is what makes one image *tag* resolve to different manifests per
  architecture — e.g. `arm64` vs `amd64` — transparently (`docker
  manifest`/multi-arch builds).
- **layers** — tar archives, typically gzip- or zstd-compressed. each layer
  is a **changeset diff** relative to the layers before it: added/modified
  files appear as normal tar entries; deletions are represented as a file
  named `.wh.<name>` (a "whiteout" entry — see
  [04-filesystem-overlayfs](04-filesystem-overlayfs.md#deletion-semantics--whiteouts)
  for how this maps onto a live overlayfs mount at unpack time); a fully
  replaced directory is marked with a `.wh..wh..opq` entry inside it (maps
  to overlayfs's *opaque directory* xattr).
- **content addressing** — every manifest, config, and layer is referenced
  purely by its sha256 digest. this is precisely the key containerd's
  content store uses (see
  [10-containerd-internals](10-containerd-internals.md#on-disk-layout-varlibcontainerd)) —
  the image spec's addressing scheme *is* the content store's addressing
  scheme, by design.
- **distribution spec** — a separate, related spec defining the registry
  HTTP API (`GET/HEAD/PUT /v2/<name>/{manifests,blobs}/<reference>`) used
  to push and pull all of the above. this is what `docker pull` / `ctr
  images pull` actually speaks over the wire to a registry.

## oci runtime spec — the config.json contract

a **bundle** is the unit a runtime consumes: a directory containing a
`rootfs/` (already-assembled filesystem, per
[04-filesystem-overlayfs](04-filesystem-overlayfs.md)) and a `config.json`
at a known path describing everything from
[07-container-creation-steps](07-container-creation-steps.md) in
declarative form:

- **`process`** — `args`, `env`, `cwd`, `user` (uid/gid + supplementary
  groups), `capabilities` (the four-ish sets from
  [05-security](05-security-capabilities-seccomp-lsm.md)), `rlimits`,
  `noNewPrivileges` (maps to `PR_SET_NO_NEW_PRIVS`).
- **`root`** — path to the rootfs (relative to the bundle) and a `readonly`
  flag.
- **`mounts`** — an ordered array of `{destination, type, source,
  options}` — this is the declarative form of step 4 in
  [07](07-container-creation-steps.md) (`/proc`, `/dev`, `/sys`, plus any
  bind mounts/volumes).
- **linux-specific block** (`linux.*`, since this section is inherently
  platform-specific — the spec also has `windows.*`, `solaris.*` variants):
  - `namespaces` — an array of `{type, path}`; `path` present means "join
    this existing namespace" (`setns`), absent means "create a new one"
    ([02-namespaces](02-namespaces.md)) — this field is exactly how a
    container joining a pod sandbox's network namespace is expressed (see
    [11-cri-and-kubelet](11-cri-and-kubelet.md)).
  - `resources` — the cgroup numbers: memory, cpu, pids, blkio limits
    ([03-cgroups-v2](03-cgroups-v2.md)).
  - `seccomp` — the full syscall filter policy inline
    ([05-security](05-security-capabilities-seccomp-lsm.md#seccomp--syscall-filtering)).
  - `maskedPaths` / `readonlyPaths` — paths hidden or frozen inside the
    container (e.g. masking `/proc/kcore`, `/proc/keys` from view).
  - `hooks` — external commands the runtime runs at defined lifecycle
    points: `prestart` (deprecated in favor of the more granular ones
    below in newer spec versions), `createRuntime`, `createContainer`,
    `startContainer`, `poststart`, `poststop`. this is the extension point
    CNI-based networking setup often uses to run plugin binaries at exactly
    the right moment in a container's lifecycle.
- **lifecycle operations** — the spec also defines the operations every
  conformant runtime CLI must expose: `create`, `start`, `kill`, `delete`,
  `state`. this is literally the command surface `runc`/`crun` implement —
  see [09-runc-crun](09-runc-crun.md).

## the two specs in one sentence each

- **image spec**: how to describe and store "what files make up this
  container, and how do I run it" as immutable, content-addressed,
  registry-distributable data.
- **runtime spec**: how to describe, for one specific process about to be
  started, exactly which namespaces/cgroups/mounts/security settings from
  [01](01-processes-and-exec.md)–[06](06-networking-and-ports.md) apply.

containerd's job, at a high level, is converting the first into the second
(image → unpacked rootfs + generated config.json) — see
[10-containerd-internals](10-containerd-internals.md).

## references

- image spec: https://github.com/opencontainers/image-spec
- runtime spec: https://github.com/opencontainers/runtime-spec
- distribution spec: https://github.com/opencontainers/distribution-spec

## hands-on

- `runc spec` generates a template `config.json` — read it top to bottom
  and match every field back to a section in this note set.
- pull an image with `skopeo`/`ctr`/`docker`, and inspect its manifest and
  config JSON directly (`docker manifest inspect`, or `ctr -n k8s.io
  images ...`) to see the real `diff_ids`, layer digests, and history.
- manually build a minimal bundle (extract a base image's layers into
  `rootfs/`, write a `config.json` by hand) and start it with `runc run` —
  this is the single best exercise for connecting the image spec, the
  runtime spec, and the seven steps in
  [07-container-creation-steps](07-container-creation-steps.md).
