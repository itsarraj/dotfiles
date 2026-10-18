---
id: 20260101014023
title: Arch Linux Simple Installation Guide GRUB
date: 18-10-2024 at 21:05
type: note # note | concept | snippet | bug | journal | reference
status: stable # draft | stable | evergreen
tags: [archlinux, installation, simple, beginner]
links: [[10b-arch-ssh-remote-install],[10b-arch-lvm-install-guide],[https://www.youtube.com/@chrisatmachine],[https://www.chiarulli.me/Linux/01-Arch-Linux-Install-UEFI/]]
---
# Log
- 2026-01-01 01:40 - Created consolidated simple installation guide
- 2026-01-01 01:40 - Combined Chris@machine approach with comprehensive guide structure
- 2026-09-14 12:05 - Deduped SSH/Boot/swap; point to LVM guide and arch-config.
- 2026-09-14 12:11 - SSH Setup now points to [[10b-arch-ssh-remote-install]].
- 2026-09-14 15:59 - Moved into install/ with arch_install.sh and pkglists.

# Notes

# Arch Linux Simple Installation Guide

This guide provides straightforward instructions for installing Arch Linux with a basic partition scheme (EFI + root + optional home). Perfect for beginners and those who want a simple, reliable setup without full disk encryption.

## Prerequisites & Initial Setup

## Download & Verify ISO
```bash
# Get GPG key for verification
gpg --auto-key-locate clear,wkd -v --locate-external-key pierre@archlinux.org
gpg --keyserver-options auto-key-retrieve --verify archlinux-2024.10.01-x86_64.iso.sig archlinux-2024.10.01-x86_64.iso
```

## Create Bootable USB
```bash
# Verify device first!
lsblk
dd bs=4M if=archlinux-2024.10.01-x86_64.iso of=/dev/sdX conv=fsync oflag=direct status=progress
```

## Boot & Initial Setup

Same live-ISO steps as [[10b-arch-lvm-install-guide]] (font, UEFI check, NTP, iwctl). Ethernet is below as its own section.

```bash
# Set console font for HiDPI
setfont ter-132b

# Verify UEFI mode
ls /sys/firmware/efi/efivars
cat /sys/firmware/efi/fw_platform_size  # Should return 64

# Set keyboard if needed
loadkeys us  # default is US English, or your layout

# Enable NTP
timedatectl set-ntp true

# Connect to WiFi
iwctl
[iwd]# device list
[iwd]# station wlan0 scan
[iwd]# station wlan0 get-networks
[iwd]# station wlan0 connect "SSID"
[iwd]# quit

# Alternative: One-liner with passphrase
iwctl --passphrase <passphrase> station wlan0 connect "SSID"

# Test connection
ping -c 4 archlinux.org
```

## Ethernet Connection

For wired connections, simply bring up the interface:

```bash
ip link set dev enp1s0 up
```

Replace `enp1s0` with your actual ethernet interface name. Use `ip link` to list available interfaces.

## SSH Setup (for Remote Installation)

Same shared note (root passwd, PermitRootLogin, sshd, Tailscale if cross-subnet).

See [[10b-arch-ssh-remote-install]].


## Partitioning

### Identify Target Disk

```bash
lsblk  # Shows all block devices
fdisk -l  # Detailed partition information
```

## Create Partitions (GPT)
```bash
fdisk /dev/sdX        # or /dev/nvme0n1
# Inside fdisk:
# g (create GPT)
# n (EFI partition: +1G, type 1) 
# n (root partition: remaining space, type 23)
# Optional: n (home partition: remaining space, type 42)
# p (verify)
# w (write changes)
```

### Format Partitions

```bash
# Format EFI partition as FAT32
mkfs.fat -F32 /dev/sdX1        # Alternative: mkfs.vfat /dev/sdX1

# Format root partition
mkfs.ext4 /dev/sdX2

# Optional: Format home partition
mkfs.ext4 /dev/sdX3
```

## Mounting and Installation

### Mount Filesystems

```bash
# Create mount point
mkdir /mnt

# Mount root and boot partitions
mount /dev/sdX2 /mnt
mkdir /mnt/boot && mount /dev/sdX1 /mnt/boot

# Optional: Mount home partition
mkdir /mnt/home && mount /dev/sdX3 /mnt/home
```

### Verify Mounts

```bash
df -h  # Check mounted filesystems
lsblk  # Verify all partitions are mounted
```

### Install Base System

```bash
# Install minimal base system (add microcode as needed)
pacstrap -K /mnt base linux linux-firmware  # + intel-ucode or amd-ucode
# Why minimal: base+linux+linux-firmware (core system)
```

### Generate fstab

```bash
# Generate fstab with UUIDs
genfstab -U /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab  # Verify contents
```

## System Configuration

### Enter Chroot

```bash
arch-chroot /mnt
```

### Set Timezone

```bash
ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
hwclock --systohc
```

### Configure Locale

```bash
vim /etc/locale.gen
# Uncomment: en_US.UTF-8 UTF-8

locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf
```

### Set Hostname

```bash
echo 'your-hostname' > /etc/hostname

vim /etc/hosts
# Add these lines:
127.0.0.1    localhost
::1          localhost
127.0.1.1    your-hostname.localdomain    your-hostname
```

### Set Root Password

```bash
passwd
```

# Essential Packages - Minimal Installation Strategy
# Phase 1: Core system functionality (networking, filesystems, security)
pacman -S networkmanager dhcpcd iwd sudo openssh e2fsprogs ntfs-3g vim
# Why: networkmanager+dhcpcd+iwd (networking), sudo+openssh (access), e2fsprogs+ntfs-3g (filesystems), vim (text editor)

# Phase 2: System utilities and package management
pacman -S pacman-contrib reflector man-db man-pages texinfo git base-devel
# Why: pacman-contrib+reflector (optimize pacman), man-* (documentation), git (version control), base-devel (building packages)

## Bootloader Setup (GRUB)

### Install GRUB

```bash
pacman -S grub efibootmgr os-prober

# Install GRUB to EFI partition
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB

# Generate GRUB configuration
grub-mkconfig -o /boot/grub/grub.cfg
```

GRUB will automatically detect your Arch Linux installation and create appropriate menu entries.

## Create Swap File (Optional but Recommended)

Optional during install. Full swapfile + zswap notes: [[10a-arch-config]] §6.

Quick 8G during chroot if you want something now:

```bash
fallocate -l 8G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap defaults 0 0' >> /etc/fstab
```


## Final Steps

### Exit Chroot and Reboot

```bash
exit
umount -a
reboot
```

## Post-Installation Setup

### Network Configuration Options

**Option 1: NetworkManager (Recommended for Desktops)**
```bash
# Enable NetworkManager for user-friendly network management
systemctl enable --now NetworkManager
nmtui  # Interactive WiFi setup
```

**Option 2: systemd-networkd (Minimal, Server-Style)**
```bash
# Create wireless network configuration file
vim /etc/systemd/network/25-wireless.network
# [Match]
# Name=wlan0
# [Network]
# DHCP=yes
# IgnoreCarrierLoss=3s

# Enable systemd network services (lighter than NetworkManager)
systemctl enable systemd-networkd.service
systemctl enable systemd-resolved.service
systemctl enable iwd.service
```

systemd-networkd is a minimal network manager that integrates well with systemd. It's lighter than NetworkManager and works well for servers or headless systems. Use NetworkManager if you prefer a more user-friendly interface.

### Create User Account

```bash
# Create user with sudo privileges
useradd -m -g wheel -s /bin/bash username
passwd username
visudo  # Uncomment %wheel ALL=(ALL) ALL

# Switch to new user
su username
```

## 🎉 Installation Complete!

Your basic Arch Linux installation is now complete. Next: [install_packages.sh](./install_packages.sh) + [pkglist.txt](./pkglist.txt) / [pkglist_aur.txt](./pkglist_aur.txt), then [[10a-arch-config]].
