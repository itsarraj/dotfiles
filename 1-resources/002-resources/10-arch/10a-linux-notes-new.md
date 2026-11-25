---
id: 20260107000004
title: Linux notes for tools, new
date: 2026-01-07 00:03
type: reference # note | concept | snippet | bug | journal | reference
status: stable # draft | stable | evergreen
tags: [postgresql, docker, database, archlinux, setup, development]
links: []
---
# Log
- 2026-01-07 00:03 - Created note.
- 2026-05-24 - Added Media Transfer Protocol (Android File Transfer).

# Notes

# ===== Notes =====

## Media Transfer Protocol

[Arch Linux wiki: Media Transfer Protocol](https://wiki.archlinux.org/title/Media_Transfer_Protocol)

### Android File Transfer

MTP client with CLI, Qt UI, and FUSE wrapper (custom MTP implementation).

- Project: https://whoozle.github.io/android-file-transfer-linux/
- Package: `android-file-transfer`

```bash
pacman -S android-file-transfer
```

Mount the device on `~/mnt`:

```bash
aft-mtp-mount ~/mnt
```

Album art: name the file `albumart.xxx` and place it first in the destination folder, then copy other files.

FUSE mounts can be roughly 7–8× slower than UI/CLI file transfer.
