---
id: 20260928213500
title: Arch Linux /etc/fstab Configuration Reference
date: 2026-09-28 21:35
type: reference
status: stable
tags: [archlinux, fstab, storage, ssd, hdd, mount]
links: [[10a-arch-config],[10a-linux-config]]
---

# Log
- 2026-09-28 21:35 - Updated canonical fstab with current system UUIDs (cesium), deduped external drive mounts, and added mount flag reference.

# Notes

## Current Production `/etc/fstab`

```fstab
# Static information about the filesystems.
# See fstab(5) for details.

# <file system>                                  <dir>                    <type>    <options>                                                                                                 <dump> <pass>

# 1. Root Filesystem (LVM on LUKS)
# /dev/mapper/land-root
UUID=594d8c76-ecdf-4235-91a6-c9f6ad519612       /                        ext4      rw,relatime                                                                                               0      1

# 2. EFI System Partition
# /dev/nvme0n1p1
UUID=FEBD-29CF                                   /boot                    vfat      rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=ascii,shortname=mixed,utf8,errors=remount-ro    0      2

# 3. Swapfile
/swapfile                                        none                     swap      defaults                                                                                                  0      0

# 4. Internal Secondary SSD (Crucial BX500 - datasets, projects, bulk data)
UUID=4667bc03-0d3f-433c-9de1-315146287ced       /data                    ext4      defaults,nofail                                                                                           0      2

# 5. External USB Drives (Portable HDDs / SSDs)
# noauto: do not mount at boot unless plugged in & requested
# nofail: do not halt or delay boot if the drive is not plugged in

# External HDD: elbe (NTFS)
UUID=762D9C7C7E4F79A3                            /run/media/cesium/elbe   ntfs-3g   defaults,noauto,nofail                                                                                    0      0

# External HDD: HDD1 (NTFS)
UUID=042BE69517C656C1                            /run/media/cesium/HDD1   ntfs-3g   defaults,noauto,nofail                                                                                    0      0

# External HDD: HDD8 (NTFS)
UUID=449353793044BF05                            /run/media/cesium/HDD8   ntfs-3g   defaults,noauto,nofail                                                                                    0      0

# External HDD: HDD10 (ext4)
UUID=1c2b0323-d095-4542-aca6-c18c697178d7       /run/media/cesium/HDD10  ext4      defaults,noauto,nofail                                                                                    0      0

# External Drive: sdd (ext4)
UUID=3111ff5a-bac5-4203-896b-d1d28f231744       /run/media/cesium/sdd    ext4      defaults,noauto,nofail                                                                                    0      0
```

---

## Mount Options Reference

| Option | Meaning |
|---|---|
| `defaults` | Uses `rw`, `suid`, `dev`, `exec`, `auto`, `nouser`, `async`. |
| `nofail` | System continues booting without hanging if the drive is disconnected. **Crucial for all external / secondary drives.** |
| `noauto` | Prevents automatic mount at system boot; only mounts when manually requested or clicked in file manager. |
| `ntfs-3g` | Read/write userspace FUSE driver for Windows NTFS filesystems. |
| `fmask=0022,dmask=0022` | Sets permissions on FAT32 (EFI partition): `755` for directories, `644` for files. |
| `errors=remount-ro` | If filesystem error occurs, automatically remounts as read-only to prevent corruption. |

---

## Useful Verification Commands

### 1. Check all connected drive UUIDs and labels
```bash
lsblk -f
```

### 2. Verify fstab for syntax errors without rebooting
Always run this before rebooting after editing `/etc/fstab`. If it outputs nothing, the syntax is valid:
```bash
sudo mount -a
```

### 3. Create mount directories if missing
```bash
sudo mkdir -p /data
sudo mkdir -p /run/media/cesium/{elbe,HDD1,HDD8,HDD10,sdd}
sudo chown -R cesium:cesium /data
```

---

## Historical Reference (Old Install: user `uranium`)

<details>
<summary>Click to view previous machine UUIDs</summary>

```fstab
# /dev/mapper/land-root (old)
UUID=52ea8b92-a91c-4b9c-8aca-821764991120  /                        ext4     rw,relatime  0 1
# /dev/nvme0n1p1 (old)
UUID=1B1D-A9D3                             /boot                    vfat     rw,relatime  0 2
# SATA SSD (NTFS data mount)
UUID=74A0D19FA0D167DE                      /mnt/data                ntfs-3g  uid=1000,gid=1000,dmask=022,fmask=133,noatime,windows_names,nofail  0 0
```

</details>