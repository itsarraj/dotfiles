# 4. filesystem view — mounts, rootfs, overlayfs

related: [00-index](00-index.md) · prev: [03-cgroups-v2](03-cgroups-v2.md) · next: [05-security-capabilities-seccomp-lsm](05-security-capabilities-seccomp-lsm.md) · builds on: [02-namespaces](02-namespaces.md) (mount namespace) · connects to: [08-oci-specs](08-oci-specs.md) (image layers), [10-containerd-internals](10-containerd-internals.md) (snapshotters), [13-erofs](13-erofs.md) (alternative backend)

## the kernel doesn't run images

an image is just layers (tar archives) + json metadata sitting in some
content store ([10](10-containerd-internals.md)). something in userspace
has to turn that into an actual directory tree the kernel can mount as a
process's `/`. that assembled tree is the **rootfs**, and the mechanism that
assembles it cheaply — without copying every layer's files on every
container start — is **overlayfs**.

## rootfs creation, the steps

1. unpack image layers somewhere on disk (or, per [13-erofs](13-erofs.md),
   mount a pre-packed read-only image directly without unpacking).
2. allocate a fresh, empty **writable layer** for this specific container.
3. mount overlayfs, stacking the read-only layers under the writable one,
   producing one **merged** view.
4. that merged view becomes the rootfs the runtime `pivot_root`s into (see
   below).

## the actual mount

```
mount -t overlay overlay \
  -o lowerdir=L3:L2:L1,upperdir=U,workdir=W \
  merged/
```

- **`lowerdir`** — colon-separated, read-only. order matters: the
  **leftmost** entry has the highest priority (checked/shown first). in
  container terms, image layers stack base-first, so the *top* (most
  recently added) layer goes leftmost.
- **`upperdir`** — the single writable layer. this is where a running
  container's file changes actually land.
- **`workdir`** — required, must be **empty** and on the **same filesystem**
  as `upperdir`. purely internal scratch space overlayfs uses to make
  certain operations (renames during copy-up) atomic. you never read or
  write it directly.
- **`merged`** — the mountpoint; this is what a process sees as `/` once
  it's put there via `pivot_root`.

## read path

a lookup for a path checks `upperdir` first; if absent there, it falls
through `lowerdir`s in priority order and returns the first hit. a directory
listing merges entries from every layer, de-duplicating by filename with
upper-layer entries winning over lower ones of the same name.

## copy-up (the performance gotcha)

writing to a file that currently exists **only in a lower layer** triggers
**copy-up**: the *entire file* is copied into `upperdir` first, and the
write is then applied to that copy. this is per-file, not per-byte or
per-block — appending one byte to a 2GB file that lives in a lower layer
means copying all 2GB up before the append happens. this is the single
most common overlayfs performance surprise in production, and it's why
things like databases are usually pointed at a bind-mounted volume rather
than left to write into the overlay rootfs.

there is a **metadata-only copy-up** optimization on newer kernels — if only
metadata (permissions, timestamps) changes and not content, the kernel can
sometimes avoid duplicating the full file body. still, treat "any write to a
lower-layer file is potentially expensive" as the mental default.

## deletion semantics — whiteouts

you can't literally "delete an entry from a read-only lower layer," so
overlayfs represents deletion with a **whiteout**: a character device node
with major/minor **0/0**, created in `upperdir` with the same name as the
file being "deleted." when computing the merged view, a whiteout at path
`X` hides any same-named `X` in every lower layer, even though `X` still
physically exists down there.

**this is a different, but analogous, convention from the OCI image-layer
format on disk.** inside an OCI layer tarball (see
[08-oci-specs](08-oci-specs.md)), a deleted file is represented by a
regular file named `.wh.<name>` — when a layer is unpacked into an overlay
lower/upper dir, the unpacking tool translates that `.wh.<name>` tar entry
into an actual overlayfs char-device whiteout on disk. the two whiteout
representations (tar-layer convention vs. live-overlayfs convention) exist
because a tar file has no concept of a live mounted filesystem's special
files — the translation step is exactly the "unpack" part of a snapshotter's
job ([10](10-containerd-internals.md)).

## opaque directories

setting the xattr `trusted.overlay.opaque=y` on a directory in `upperdir`
marks it **opaque**: the merged view stops looking at lower layers for that
directory's contents entirely, even for files not explicitly whited out.
used when a directory was fully replaced (not just modified) between image
layers. the OCI image-spec equivalent, inside a layer tarball, is a file
named `.wh..wh..opq` inside that directory.

## other mechanics worth knowing

- **redirect_dir** — xattr-based bookkeeping overlayfs uses to correctly
  resolve lookups across renamed directories spanning multiple layers.
- constraints: `upperdir` and `workdir` must live on the same underlying
  filesystem; certain xattr and nested-overlayfs behaviors are kernel-
  version-dependent — check `docs.kernel.org` for your kernel's exact
  guarantees if you're debugging something subtle.

## entering the rootfs: chroot vs pivot_root

- **`chroot(2)`** only changes *this process's* notion of `/` for path
  resolution. it does **not** change the mount namespace's root, has
  well-known escape techniques (a process with enough privilege can often
  break out via a retained fd to the old root), and was never designed as a
  security boundary.
- **`pivot_root(2)`** is what real runtimes use: it swaps the **mount
  namespace's** root filesystem for a new one, moving the old root to a
  directory you specify (commonly then unmounted/detached so it's
  unreachable). combined with a private mount namespace
  ([02-namespaces](02-namespaces.md)), this is what actually makes "the
  container cannot see the host's original `/`" true, rather than just
  cosmetically true.

## the other required mounts

rootfs alone isn't enough; a usable container also needs, mounted **inside**
the new mount+pid namespace:
- **`/proc`** (procfs) — must be (re-)mounted from inside the new pid
  namespace, or it will report the *host's* process list ([see
  02](02-namespaces.md)).
- **`/dev`** — typically a fresh `tmpfs` plus a small set of bind-mounted
  device nodes (or `devpts` for `/dev/pts`), not the host's full `/dev`.
- **`/sys`** — often mounted read-only or with specific paths masked,
  since it exposes a lot of host/kernel state a container shouldn't be able
  to touch (see `maskedPaths`/`readonlyPaths` in
  [08-oci-specs](08-oci-specs.md)).

## tying the layers together

- image layers, ordered base → top, become ordered `lowerdir`s (top layer
  = highest priority = leftmost in the mount option string).
- the container's own writable layer = `upperdir`.
- the `merged` mount becomes the rootfs handed to `pivot_root`.
- this exact assembly step is what a **snapshotter** automates — see
  [10-containerd-internals](10-containerd-internals.md) for the overlayfs
  snapshotter, and [13-erofs](13-erofs.md) for an alternative that skips
  "unpack every layer into loose files" entirely.

## where to inspect

- `/proc/<pid>/mountinfo` — best source of truth for what's actually
  mounted where, from that process's point of view.
- `findmnt` — human-readable view of the mount table.
- `docker inspect <id>` → `GraphDriver.Data` shows `MergedDir`/`UpperDir`/
  `LowerDir` directly for a running docker container.

## references

- kernel docs: https://docs.kernel.org/filesystems/overlayfs.html
- man pages: `pivot_root(2)`, `mount(2)`, `mount(8)`, `chroot(2)`,
  `mount_namespaces(7)`

## hands-on

- manually build a 3-layer overlayfs by hand (three plain directories as
  lowers, one as upper, one empty workdir) and `chroot` into the merged
  result to see de-duplication and copy-up happen live.
- delete a file that only exists in a lower dir, then `find` the upperdir
  and see the whiteout char-device node appear (`ls -l` shows it as a
  device file with `0, 0` where size normally is).
- inspect `/proc/self/mountinfo` before and after mounting to see the raw
  fields (mount id, parent id, options, superblock options) that `findmnt`
  is summarizing for you.
