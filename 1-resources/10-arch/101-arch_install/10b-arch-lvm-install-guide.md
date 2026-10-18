---
id: 20260101014022
title: Arch Linux LVM on LUKS Installation Guide SYSTEMD-BOOT
date: 2026-01-01 01:40
type: note # note | concept | snippet | bug | journal | reference
status: stable # draft | stable | evergreen
tags: [archlinux, lvm, luks, encryption, installation]
links: [[10b-arch-simple-install-guide],[10b-arch-ssh-remote-install],[10a-arch-config],[10a-arch-config-dev]]
---
# Log
- 2026-09-14 15:59 - Moved into install/; arch_install.sh is the canonical installer.
- 2026-09-14 12:05 - Marked SSH Setup as canonical shared section for both install guides.
- 2026-09-14 12:11 - Moved SSH Setup into [[10b-arch-ssh-remote-install]].
- 2026-01-01 01:40 - Created consolidated LVM on LUKS installation guide
- 2026-01-01 01:40 - Combined Mischa's approach with comprehensive guide structure

# Arch Linux LVM on LUKS Installation Guide

Automated install (same folder): [arch_install.sh](./arch_install.sh)

This comprehensive guide consolidates multiple Arch Linux installation methods and configurations based on various tutorials and personal experience. The guide covers both simple installations and advanced encrypted setups with LVM on LUKS.

## Prerequisites & Initial Setup

### Download Verification
```bash
# Get GPG key for verification
gpg --auto-key-locate clear,wkd -v --locate-external-key pierre@archlinux.org

# Verify the signature
gpg --keyserver-options auto-key-retrieve --verify archlinux-2024.10.01-x86_64.iso.sig archlinux-2024.10.01-x86_64.iso
```

### Create Bootable USB
```bash
# Verify device first!
lsblk
dd bs=4M if=path-to-arch-iso of=/dev/sdX conv=fsync oflag=direct status=progress
```

## Boot & Initial Setup

Live-ISO bootstrap (shared with the simple guide; ethernet one-liner is inline here).

```bash
# Set console font for HiDPI
setfont ter-132b

# Verify UEFI mode
ls /sys/firmware/efi/efivars
cat /sys/firmware/efi/fw_platform_size # Should return 64

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

# Ethernet Connection
# For wired connections, simply bring up the interface:
ip link set dev enp1s0 up
# Replace `enp1s0` with your actual ethernet interface name. Use `ip link` to list available interfaces.

# Test connection
ping -c 4 archlinux.org
```

## SSH Setup (for Remote Installation)

Same shared note (root passwd, PermitRootLogin, sshd, Tailscale if cross-subnet).

See [[10b-arch-ssh-remote-install]].

## Partitioning & Encryption

## Identify Disk
```bash
lsblk  # Find your target disk
```

## Create Partitions (GPT)
```bash
fdisk /dev/sdX  # or /dev/nvme0n1
# Inside fdisk:
# g (create GPT)
# n (EFI partition: +1G, type 1)
# n (LVM partition: remaining space, type 44)
# w (write changes)
```
sda becomes sda1 sda2
nvme0n1 becomes nvme0n1p1 nvme0n1p2

## Encrypt & Setup LVM
```bash
# Format EFI partition as FAT32
mkfs.fat -F32 /dev/sdX1        
# Alternative: mkfs.vfat /dev/sdX1

# Encrypt LVM partition
# Create LUKS encrypted container
cryptsetup luksFormat /dev/sdX2 
# Open the container
cryptsetup open /dev/sdX2 cryptlvm

# Create LVM structure
# Create physical volume
pvcreate /dev/mapper/cryptlvm
# Create volume group
vgcreate MyVolGroup /dev/mapper/cryptlvm

# Create logical volumes
lvcreate -l 100%FREE -n root MyVolGroup

# Display logical volumes
lvdisplay

# Format volumes
mkfs.ext4 /dev/MyVolGroup/root

# Optional: Reserve space for e2scrub snapshots (if using ext4)
lvreduce -L -256M --resizefs /dev/MyVolGroup/root
```

## Installation & Mounting

## Mount Filesystems
```bash
# Mount root and boot
mount /dev/MyVolGroup/root /mnt
mkdir /mnt/boot && mount /dev/sdX1 /mnt/boot

# Verify mounts
df -h && lsblk
```

## Install Base System
```bash
# Install minimal base system (add microcode as needed)
pacstrap -K /mnt base linux linux-firmware lvm2 iwd  # + intel-ucode or amd-ucode
# Why minimal: base+linux+linux-firmware (core), lvm2 (LVM support), iwd (WiFi)

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab
```

## System Configuration

## Chroot & Basic Setup
```bash
arch-chroot /mnt

# Set timezone
ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
hwclock --systohc

# Configure locale
vim /etc/locale.gen  # Uncomment en_US.UTF-8 UTF-8
locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf

# Set hostname
echo 'hostname' > /etc/hostname
vim /etc/hosts
# Add:
# 127.0.0.1 localhost
# ::1 localhost
# 127.0.1.1 hostname.localdomain hostname

# Set root password
passwd

# Essential Packages - Minimal Installation Strategy
# Phase 1: Core system functionality (networking, filesystems, security)
pacman -S networkmanager dhcpcd iwd sudo openssh e2fsprogs ntfs-3g vim
# Why: networkmanager+dhcpcd+iwd (networking), sudo+openssh (access), e2fsprogs+ntfs-3g (filesystems), vim (text editor)

# Phase 2: System utilities and package management
pacman -S pacman-contrib reflector man-db man-pages texinfo git base-devel
# Why: pacman-contrib+reflector (optimize pacman), man-* (documentation), git (version control), base-devel (building packages)

# Phase 3: After user creation - development essentials
# pacman -S neovim htop curl wget tree ripgrep fd fzf tmux stow rsync unzip zip fastfetch btop
# Why: neovim (advanced editor), htop+btop (monitoring), curl+wget (downloads), tree+ripgrep+fd+fzf (navigation/search), tmux (multiplexer), stow (dotfiles), rsync (sync), unzip+zip (archives), fastfetch (system info)
```

## Bootloader Setup (systemd-boot)

systemd-boot is the modern UEFI boot manager from systemd. It's simpler than GRUB and works well with encrypted systems. For detailed boot process info, see [Arch boot process](https://wiki.archlinux.org/title/Arch_boot_process#Boot_loader).

## Configure Initramfs
```bash
# Install LVM2 tools essential for initramfs regeneration (prevents errors)
pacman -S lvm2

# Configure mkinitcpio hooks for LUKS/LVM encryption
vim /etc/mkinitcpio.conf
# HOOKS=(base systemd keyboard autodetect microcode modconf kms sd-vconsole block sd-encrypt lvm2 filesystems fsck)

# Optional: Set console font for HiDPI displays
vim /etc/vconsole.conf
# FONT=latarcyrheb-sun32

# Regenerate initramfs with new hooks
mkinitcpio -P
```

## Install & Configure systemd-boot

systemd-boot comes with systemd (dependency of base package), so no additional installation needed.

```bash
# Install systemd-boot to ESP and create UEFI boot entry
bootctl install
```

This copies systemd-boot to your ESP (/boot), creates a UEFI boot entry, and sets it as the default. It looks for ESP at /efi, /boot, or /boot/efi.

After installation, verify files were created:
```bash
ls /boot/
# Should show: EFI initramfs-linux*.img loader vmlinuz-linux (+ microcode.img if installed)
```

### Configure Boot Loader Settings
```bash
# Configure global boot settings
vim /boot/loader/loader.conf
# default arch
# timeout 3
# console-mode keep
# editor no
```

### Create Boot Entry for Encrypted System

Get the UUID of your encrypted partition (NOT the LVM UUID):
```bash
blkid
# Look for TYPE="crypto_LUKS" - use that UUID
# Example: /dev/nvme0n1p2: UUID="06b5052c-4787-4e6f-8f47-d0d3a08be516" TYPE="crypto_LUKS"
```

Create the boot entry:
```bash
vim /boot/loader/entries/arch.conf
```

```
title Arch Linux
linux /vmlinuz-linux
initrd /intel-ucode.img    # or /amd-ucode.img if using AMD
initrd /initramfs-linux.img
options rd.luks.name=06b5052c-4787-4e6f-8f47-d0d3a08be516=cryptlvm root=/dev/MyVolGroup/root rw
```

**Important:** Replace the UUID with your encrypted partition's UUID (from blkid), and replace `MyVolGroup` with your volume group name.

### Optional: LTS Kernel Entry
```bash
vim /boot/loader/entries/arch-lts.conf
```

```
title Arch Linux LTS
linux /vmlinuz-linux-lts
initrd /intel-ucode.img
initrd /initramfs-linux-lts.img
options rd.luks.name=06b5052c-4787-4e6f-8f47-d0d3a08be516=cryptlvm root=/dev/MyVolGroup/root rw
```

## Final Steps & Post-Installation

## Complete Installation
```bash
exit  # Exit chroot
umount -a
reboot
```

## Post-Install Setup

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
# Add the following configuration:
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

# DNS for encrypted systems (systemd-resolved stub mode)
# https://wiki.archlinux.org/title/Systemd-resolved#DNS
# Creates 127.0.0.53 stub resolver symlink for encrypted systems
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

# Setup swap (optional - can be done after installation)
# See: [[10a-arch-config]] §6 for swapfile + zswap

# Enable essential services
sudo systemctl enable systemd-timesyncd systemd-resolved paccache.timer reflector.timer fstrim.timer

# Install firewall
sudo pacman -S ufw
sudo systemctl enable ufw
sudo ufw enablea


# Switch to new user
su username
```

## 🎉 Installation Complete!

Your Arch Linux LVM on LUKS installation is now complete. Next: run [install_packages.sh](./install_packages.sh) with [pkglist.txt](./pkglist.txt) / [pkglist_aur.txt](./pkglist_aur.txt), then [[10a-arch-config]] and [[10a-arch-config-dev]].

The system is now ready for post-installation configuration and customization.

## Post-Installation Setup (Desktop Environment)

### Start the Network Manager

```bash
systemctl start NetworkManager
systemctl enable NetworkManager
```

### Install the OpenSSH : if not installed previously

```bash
sudo pacman -S openssh
```

### Start the sshd before connecting via remote shell
```bash
sudo systemctl status sshd
sudo systemctl start sshd
sudo systemctl enable sshd
```

## Installing the Window Manager and Terminal

### Install Xorg
```bash
pacman -S xorg-server xorg-xinit
```

### Installing a DM
```bash
pacman -S lightdm
pacman -S lightdm-gtk-greeter
pacman -S lightdm-gtk-greeter-settings
```

### Enable lightdm service
```bash
systemctl enable lightdm
```

### List our enabled services
```bash
systemctl list-unit-files --state=enabled
```
```bash
# Install i3wm (or any WM or DE)
pacman -S i3-gaps i3status i3lock dmenu
```

### Install DE (Optional)
```bash
pacman -S xfce4
# xfce4 will install xfce4-terminal run it by default.
# Uninstall it with $ pacman -Rns xfce4-terminal
```

## Alacritty

### Install a terminal emulator
```bash
pacman -S alacritty
```

### Web Browser and File Manager - (Optional)

After everything we got, the web browser and file manager would make things complete.
But I have a script to install everything at once in my notes.I will prefer that.
```bash
pacman -S firefox
pacman -S nautilus
```

---

## After this Follow These Guides

Local next steps:
- [[10a-arch-config]] (system post-install)
- [[10a-arch-config-dev]] (dev stack)
- [[10a-linux-config]] (day-to-day Linux)

External references:
[Install packages from AUR with yay](https://www.chiarulli.me/Linux/03-AUR-yay/)
[Configuring i3wm](https://www.chiarulli.me/Linux/04-i3wm/)
[i3](https://wiki.archlinux.org/title/I3)
[i3-extras](https://github.com/ashinkarov/i3-extras)
[Nerd-Font](https://www.chiarulli.me/Linux/05-nerd-fonts/)

--- 
