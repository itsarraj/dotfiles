# 13. erofs — an alternative to overlayfs for image layers

related: [00-index](00-index.md) · prev: [12-grpc-and-ipc](12-grpc-and-ipc.md) · contrasts with: [04-filesystem-overlayfs](04-filesystem-overlayfs.md) · used as a: [10-containerd-internals](10-containerd-internals.md) snapshotter backend

## what erofs is

**EROFS** (Enhanced Read-Only File System) is a linux kernel filesystem,
mainlined around kernel 5.4, purpose-built for **read-only** use cases:
heavily compressed content, very low metadata overhead, fast random access
without needing to fully decompress ahead of time. it was originally
developed for Android (where system partitions are read-only and
storage/RAM are both constrained) and has since been picked up by container
tooling for exactly the same reasons — most of a container image really is
read-only data.

## the problem it's solving, relative to overlayfs

recall from [04-filesystem-overlayfs](04-filesystem-overlayfs.md#rootfs-creation-userspace-responsibility)
that overlayfs-based snapshotters must **fully unpack** every image layer's
tar archive into real files and directories on the snapshotter's disk
before anything can be mounted. for an image with many layers and many
small files, this means:

- real inode pressure — every single file in every layer becomes its own
  inode on the host filesystem
- unpack time on the critical path of a cold pull (nothing can be mounted
  until the tar has been fully extracted to disk)
- extra disk space for the unpacked representation, on top of the original
  compressed blob already sitting in the content store

EROFS (in the same spirit as **squashfs**, an older read-only compressed
filesystem) instead packs an **entire layer into one compact, compressed,
read-only image file**. that single file can be **mounted directly** —
there's no "extract every file individually first" step at all. the kernel
transparently decompresses on read, on demand.

## how it fits into the layering model

containers still need a writable layer on top of read-only image content —
EROFS alone doesn't replace overlayfs's *layering* concept, only the
representation of the *read-only* layers underneath it. a typical EROFS-
backed setup still stacks a writable layer on top, via one of:

- mounting each EROFS-packed layer and stacking them as overlayfs
  `lowerdir`s (with a normal writable `upperdir` on top) — same mount
  mechanics as [04-filesystem-overlayfs](04-filesystem-overlayfs.md), just
  with lower layers backed by mounted EROFS images instead of loose
  unpacked directories.
- a **composefs**-style mechanism, which takes the same "don't unpack loose
  files" philosophy further by describing a merged filesystem view
  declaratively (a manifest referencing content-addressed backing files)
  rather than relying on overlayfs's live layer-stacking at all.

## why it matters in practice

- less disk/inode overhead per pulled image, particularly noticeable on
  images with many layers or many small files
- faster cold start, since there's no bulk unpack step blocking the first
  mount
- especially relevant on storage-constrained or edge-style nodes, where
  minimizing both disk footprint and cold-start latency matters more than
  on a beefy standard cluster node — this is exactly the kind of tradeoff
  worth understanding if you're evaluating runtimes for
  resource-constrained deployments.

## status

this is an active area, not a settled default: containerd has experimental
erofs snapshotter/differ support, and **composefs**
(https://github.com/containers/composefs) explores an adjacent approach to
the same underlying problem (avoid unpacking layers into loose files at
all). overlayfs with a standard unpacking snapshotter remains the default,
most broadly compatible path in containerd today — treat EROFS/composefs as
"know this exists and why," not "expect it everywhere."

## references

- kernel docs: https://docs.kernel.org/filesystems/erofs.html
- composefs: https://github.com/containers/composefs
- containerd erofs snapshotter discussion/issues: search the containerd
  repo (https://github.com/containerd/containerd) for "erofs" for current
  state, since this is a moving target

## hands-on

- build a small EROFS image with `mkfs.erofs` from a directory tree, mount
  it read-only, and compare `du -sh` of the packed image file vs. the
  original unpacked directory to see the compression benefit directly.
- if your containerd build has erofs snapshotter support enabled, compare
  `ctr images pull` cold-start time and disk usage against the default
  overlayfs snapshotter for the same image, to see the difference from
  [04-filesystem-overlayfs](04-filesystem-overlayfs.md)'s approach
  quantified rather than just asserted.
