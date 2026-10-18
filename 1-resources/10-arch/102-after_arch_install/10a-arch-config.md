---
id: 20260101014021
title: Arch Config - Post-Installation Setup
date: 2026-01-01 01:40
type: note # note | concept | snippet | bug | journal | reference
status: draft # draft | stable | evergreen
tags: [archlinux, config]
links: [[10a-arch-config-dev],[10a-linux-config]]
---
# Log
- 2026-01-01 01:40 - Created note.
- 2026-09-14 12:05 - Deduped with config-dev; fixed section numbering and paru fences.

# Notes
# Things to be done after arch install (system config)
- [ ] pacstrap `-K` (host keyring) note
- [ ] Dual SSD layout note (NVMe + SATA)
- [ ] Laptop Lid Switch Configuration
- [ ] Shell Configuration (.bashrc)
- [ ] Bash Prompt (PS1) Configuration
- [ ] Arch Linux Swap & Zswap Setup Notes
- [ ] Wi-Fi Power Management (Disable Auto-Disconnect)
- [ ] systemd-boot entries: regular + LTS kernels
- [ ] Post-install essentials (paru + fzf package pickers)
- [ ] Responsiveness tweaks (ananicy / earlyoom / cpupower)
- [ ] Docker group access

Day-to-day Linux (stow, fstab, SSH/SCP, git): see [[10a-linux-config]]
Dev stack (bun/fnm, conda, redis, ADB): see [[10a-arch-config-dev]]

## 1: pacstrap `-K` (host keyring) -------------------------------

- Prefer **not** using `pacstrap -K` for normal installs: let the new system maintain its **own** keyring.
- Recommended flow:

```bash
pacstrap /mnt base linux linux-firmware
arch-chroot /mnt
pacman-key --init
pacman-key --populate archlinux
```

- `-K` can be useful for **offline installs** or **keyring recovery**, but it’s not ideal for a long-lived/dev machine.

## 2: Dual SSD layout note (NVMe + SATA) -------------------------------

- **NVMe (fast/low latency)**: keep OS + “lots of small files / heavy I/O” here (best for dev boxes).
  - Good fits: `/` (and optionally `/home`), package/build caches, `node_modules`, Python venv/conda envs, Android Studio + SDK, **Docker** (`/var/lib/docker`).
- **SATA SSD (bulk)**: use as a warehouse for large/less latency-sensitive data.
  - Good fits: datasets, model archives, backups, downloads, media, older/rarely-touched repos.

Suggested approach:

- Mount SATA as something like `/mnt/data` (or split as `/mnt/datasets`, `/mnt/projects`).
- Keep “active work” on NVMe; move heavy folders to SATA and symlink back when convenient:

```bash
mkdir -p /mnt/data
mv ~/Downloads /mnt/data/Downloads
ln -s /mnt/data/Downloads ~/Downloads
```

## 3: Laptop Lid Switch Configuration -------------------------------

### System-wide (/etc/systemd/logind.conf)
```bash
sudo vim /etc/systemd/logind.conf
```
Add/modify:
```
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
```
Restart: `sudo systemctl restart systemd-logind`

### User-level (~/.config/systemd/logind.conf.d/lid.conf)
```bash
mkdir -p ~/.config/systemd/logind.conf.d
vim ~/.config/systemd/logind.conf.d/lid.conf
```
Content:
```ini
[Login]
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
```
Restart: `systemctl --user restart systemd-logind`

## 4: Shell Configuration (.bashrc) -------------------------------

### Source .profile in .bashrc
After Arch installation, ensure .profile is sourced for non-login shells:

**Simple method** (your current setup):
```bash
# Add to ~/.bashrc
. ~/.profile
```

**Conditional method** (safer, but unnecessary if .bash_profile -> .profile):
```bash
# Add to ~/.bashrc
if [ -f ~/.profile ]; then
    . ~/.profile
fi
```

**Warning**: Avoid conditional sourcing if `.bash_profile` is a symlink to `.profile` to prevent infinite recursion.

### Automated Script
```bash
#!/bin/sh
# add_to_bashrc.sh
line=". ~/.profile"
if ! grep -Fxq "$line" ~/.bashrc; then
    echo "$line" >> ~/.bashrc
    echo "Line added to .bashrc"
else
    echo "Line already exists in .bashrc"
fi
```
## 5: Bash Prompt (PS1) Configuration -------------------------------

### Current Working PS1
```bash
# Add to ~/.bashrc 
PS1='\[\e[0;1;3$(($?==0?2:1))m\]›\[\e[0m\] ' # › 
```

### Color Logic
- **Green ›** when last command succeeds (`$?==0`)
- **Red ›** when last command fails
- Uses ANSI escape codes for coloring

### Alternative Options

```bash
# Traditional formats
PS1='[\u@\h \W]\$ '              # username@hostname workingdir $
PS1='[\W]\$ '                    # just working directory $
PS1='[username@hostname \W]\$ '  # explicit username@hostname

# Colored exit status (green=success, red=failure)
PS1='\[\e[0;1;3$(($?==0?2:1))m\]\$\[\e[0m\] '           # just colored $
PS1='\[\e[0;1;3$(($?==0?2:1))m\]›\[\e[0m\] '           # colored › (current)
PS1='\[\e[1;34m\]\W\[\e[0m\] \[\e[0;1;3$(($?==0?2:1))m\]\$\[\e[0m\] '  # dir + colored $
PS1='\[\e[1;34m\]\W\[\e[0m\] \[\e[0;1;3$(($?==0?2:1))m\]›\[\e[0m\] '   # dir + colored ›
```

### Buggy Version (Don't Use)
```bash
# This has syntax errors - double ?? and missing parentheses
PS1+='\[\e[0;1;3$(($??5:3))m\]\$\[\e[0m\] '
```
## 6: Arch Linux Swap & Zswap Setup Notes -------------------------------

### Check Memory & Swap Status
```bash
free -h
```
## 6.1: Swapfile Setup (20GB) ..............................

### 6.1.1 Create 20 GB Swapfile

```bash
sudo fallocate -l 20G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

### 6.1.2 Make Permanent

Add to `/etc/fstab`:

```
/swapfile none swap defaults 0 0
```

### 6.1.3 Verification

```bash
swapon --show
free -h
```

### 6.1.4 Removing `/swapfile` (safe)

If `sudo rm /swapfile` fails with “Operation not permitted”, it’s usually **still active swap** or an **immutable** file flag.

```bash
swapon --show
sudo swapoff /swapfile    # or: sudo swapoff -a
sudo rm /swapfile
```

Also remove/comment the `/swapfile ... swap ...` line in `/etc/fstab` so it doesn’t re-enable on reboot.

If it’s immutable:

```bash
lsattr /swapfile
sudo chattr -i /swapfile
sudo rm /swapfile
```

## 6.2: Zswap Setup ..............................

### 6.2.1 Purpose

* Compressed RAM cache for swap pages.
* Works in conjunction with a swap device (your swapfile).
* Reduces disk I/O and improves responsiveness.

### 6.2.2 Configure systemd-boot Entry

Edit boot entry:

```bash
sudo nvim /boot/loader/entries/arch.conf
```

Update `options` line:

```
options rd.luks.name=0c3a1743-de8a-46b0-9306-930712950834=reich root=/dev/land/root rw quiet zswap.enabled=1 zswap.compressor=zstd zswap.zpool=zsmalloc zswap.max_pool_percent=30 zswap.shrinker_enabled=1
```

* `max_pool_percent=30` → ~4 GB of RAM for zswap pool
* `compressor=zstd` → fast, efficient compression
* `zpool=zsmalloc` → memory allocator
* `shrinker_enabled=1` → evict cold pages when under memory pressure

### 6.2.3 Reboot & Verify

```bash
grep -r . /sys/module/zswap/parameters/
```

Expected:

```
enabled:Y
shrinker_enabled:Y
max_pool_percent:30
compressor:zstd
zpool:zsmalloc
accept_threshold_percent:90
```

### 6.2.4 Optional Boot Message Adjustment

* Remove `quiet` to see full boot messages.
* Optional `loglevel=7` for full verbose messages or `loglevel=3` for warnings/errors only.

## 6.3: Kernel Parameters Notes

* `zswap.enabled=1` → enable zswap
* `zswap.compressor=zstd` → use Zstandard compression
* `zswap.zpool=zsmalloc` → memory pool allocator
* `zswap.max_pool_percent=30` → max compressed pool size (~4 GB)
* `zswap.shrinker_enabled=1` → allow eviction under memory pressure
* `accept_threshold_percent=90` → stop accepting pages when 90% full

## 6.4: Performance Tuning

```bash
echo "vm.swappiness=10" | sudo tee /etc/sysctl.d/99-swappiness.conf
echo "vm.vfs_cache_pressure=50" | sudo tee /etc/sysctl.d/99-cache-pressure.conf
```

* `vm.swappiness=10` → prefer keeping apps in RAM, swap only when necessary
* `vm.vfs_cache_pressure=50` → prioritize filesystem caches

## 6.5: Monitoring Zswap & Swap

```bash
# Check zswap usage:
grep -r . /sys/kernel/debug/zswap/
# Check swapfile usage:
swapon --show
free -h
```

* `stored_pages` → pages currently in zswap
* `pool_total_size` → compressed RAM used
* `written_back_pages` → pages sent to disk swap

## 6.6: Optional: Hibernation Setup

* Swapfile ≥ RAM size required for hibernate.
* Find swapfile offset:

```bash
filefrag -v /swapfile | grep " 0:" | awk '{print $4}' | sed 's/\..*//'
```

* Add to kernel params in boot entry:

```
resume=/dev/land/root resume_offset=<offset>
```

* Reboot and test:

```bash
systemctl hibernate
```

## 6.7: Summary

* **Swapfile**: 20 GB on NVMe → fallback + hibernate support
* **Zswap**: 4 GB RAM compressed → fast memory overflow handling
* **Tuning**: swappiness=10, vfs_cache_pressure=50
* **Bootloader**: systemd-boot, kernel parameters set in `/boot/loader/entries/arch.conf`
* **Monitoring**: `/sys/module/zswap/parameters/` + `/sys/kernel/debug/zswap/`

This setup ensures **responsiveness, stability, and hibernation support** for your Arch Linux laptop with encrypted root and NVMe storage.

## 7: Wi-Fi Power Management (Disable Auto-Disconnect) -------------------------------

### Issue
On Arch Linux, Wi-Fi may appear to **automatically disable** after connecting.  
Cause: **NetworkManager enables Wi-Fi power save by default**, which can cause the adapter to enter a dormant state.

### Check Current Power Save Status
```bash
iw dev wlan0 get power_save
```

### Disable Wi-Fi Power Save (Permanent Fix)
Tell NetworkManager to keep Wi-Fi power save `off`:
```bash
sudo mkdir -p /etc/NetworkManager/conf.d/
echo -e "[connection]\nwifi.powersave = 2" | sudo tee /etc/NetworkManager/conf.d/wifi-powersave.conf
sudo systemctl restart NetworkManager
```

### Temporary Fix (Until Reboot)
```bash
sudo iw dev wlan0 set power_save off
```

### Verify Fix
```bash
iw dev wlan0 get power_save
# Should show: Power save: off
```

### Power Save Values
- `0` → default (usually enabled)
- `1` → enable power save
- `2` → disable power save (recommended)
- `3` → ignore power save settings

## 8: systemd-boot entries: regular + LTS kernels -------------------------------

My install script creates **three systemd-boot entries** so you can boot the latest kernel day-to-day and keep a stable/zen fallback. LTS is numbered `01` so it's both first in the menu and the default:

- **LTS**: `/boot/loader/entries/01-arch-lts.conf` → `/vmlinuz-linux-lts` + `/initramfs-linux-lts.img`
- **Regular**: `/boot/loader/entries/02-arch-regular.conf` → `/vmlinuz-linux` + `/initramfs-linux.img`
- **Zen**: `/boot/loader/entries/03-arch-zen.conf` → `/vmlinuz-linux-zen` + `/initramfs-linux-zen.img`

Both entries also include a **microcode initrd** if present:

- Intel: `/intel-ucode.img`
- AMD: `/amd-ucode.img`

The `options ...` line is your kernel cmdline (in the script: LUKS+LVM root + zswap tuning).

Make sure you have both kernels installed if you want both entries to work:

```bash
sudo pacman -S linux linux-lts
```

### Switch the default entry

`/boot/loader/loader.conf` controls which entry boots by default:

```ini
default 01-arch-lts
timeout 2
console-mode keep
editor yes
```

I prefer defaulting to **LTS** for stability. Your entries are:

- `/boot/loader/entries/01-arch-lts.conf`
- `/boot/loader/entries/02-arch-regular.conf`
- `/boot/loader/entries/03-arch-zen.conf`

If you want to switch to regular, set:

```ini
default 02-arch-regular
```

Or run:

```bash
sudo bootctl set-default 01-arch-lts.conf
```

### Applying this on an already-installed system

The entry filenames control menu order (systemd-boot lists them alphabetically), and `default` in `loader.conf` controls what auto-boots. To move LTS to the top and make it default on a system that was installed before this change:

```bash
# rename LTS to 01 so it sorts first, bump the others out of the way
sudo mv /boot/loader/entries/02-arch-lts.conf     /boot/loader/entries/01-arch-lts.conf
sudo mv /boot/loader/entries/01-arch-regular.conf /boot/loader/entries/02-arch-regular.conf
sudo mv /boot/loader/entries/03-arch-zen.conf      /boot/loader/entries/03-arch-zen.conf  # already 03, no-op if present

# point loader.conf at the new LTS filename
sudo sed -i 's/^default .*/default 01-arch-lts/' /boot/loader/loader.conf

# verify
cat /boot/loader/loader.conf
ls /boot/loader/entries/
```

### My current `/boot` layout (reference)

```bash
cat /boot/loader/loader.conf
default 01-arch-lts
timeout 2
console-mode keep
editor yes
```

```bash
ls /boot/
amd-ucode.img            initramfs-linux-lts.img  vmlinuz-linux
EFI/                     intel-ucode.img          vmlinuz-linux-lts
initramfs-linux.img      loader/
```

```bash
ls /boot/loader/entries/
01-arch-lts.conf  02-arch-regular.conf  03-arch-zen.conf
```

```bash
cat /boot/loader/entries/01-arch-lts.conf
title Arch Linux LTS
linux /vmlinuz-linux-lts
initrd /amd-ucode.img
initrd /initramfs-linux-lts.img
options rd.luks.name=06b5052c-4787-4e6f-8f47-d0d3a08be516=reich root=/dev/land/root rw zswap.enabled=1 zswap.compressor=zstd zswap.zpool=zsmalloc zswap.max_pool_percent=30 zswap.shrinker_enabled=1
```

```bash
cat /boot/loader/entries/02-arch-regular.conf
title Arch Linux Regular
linux /vmlinuz-linux
initrd /amd-ucode.img
initrd /initramfs-linux.img
options rd.luks.name=06b5052c-4787-4e6f-8f47-d0d3a08be516=reich root=/dev/land/root rw zswap.enabled=1 zswap.compressor=zstd zswap.zpool=zsmalloc zswap.max_pool_percent=30 zswap.shrinker_enabled=1
```

## 9: Post-install essentials (paru + fzf pickers) -------------------------------

### Install paru (AUR helper)

```bash
sudo pacman -S --needed base-devel git --noconfirm
git clone https://aur.archlinux.org/paru.git
cd paru && makepkg -si --noconfirm
cd .. && rm -rf paru
```

### fzf package pickers (optional)

```bash
pacman -Slq | fzf -m --preview 'cat <(pacman -Si {1}) <(pacman -Fl {1} | awk "{print \$2}")' | xargs -ro sudo pacman -S
paru -Slq | fzf -m --preview 'cat <(paru -Si {1}) <(paru -Fl {1} | awk "{print \$2}")' | xargs -ro paru -S
```

Bun + fnm (Node.js): see [[10a-arch-config-dev]] §2


## 10: Responsiveness tweaks (ananicy / earlyoom / cpupower) -------------------------------

### 10.1: Immediately control the process (when system hangs)

#### Find the culprit:

```bash
htop
```

#### Then:

* Press `F6` → sort by CPU
* Select the process

#### Reduce its priority:

```bash
renice +10 -p <PID>
```

Or limit CPU usage:

```bash
cpulimit -p <PID> -l 50
```

👉 This prevents it from starving everything else.

---

### 10.2: Use better CPU scheduling (huge impact)

Linux by default is fair, but not always responsive under load.

#### Enable `schedutil` governor:

```bash
sudo pacman -S cpupower
sudo systemctl enable --now cpupower.service
```

Edit:

```bash
sudo nvim /etc/default/cpupower
```

Set:

```
governor='schedutil'
```

Then:

```bash
sudo systemctl restart cpupower
```

---

### 10.3: Install and enable a process optimizer

#### Option A (recommended): `ananicy-cpp`

Automatically adjusts priorities for apps.

```bash
paru -S ananicy-cpp
sudo systemctl enable --now ananicy-cpp
```

👉 This is one of the biggest real-world improvements.

---

### 10.4: Improve responsiveness under load (critical)

#### Enable earlyoom (kills memory hogs before freeze):

```bash
sudo pacman -S earlyoom
sudo systemctl enable --now earlyoom
```

---

### 10.5: Fix I/O bottlenecks (very important)

If disk is slow, system freezes even if CPU is fine.

#### Check:

```bash
iotop
```

#### Improve disk scheduler:

```bash
cat /sys/block/sda/queue/scheduler
```

Set to `mq-deadline`:

```bash
echo mq-deadline | sudo tee /sys/block/sda/queue/scheduler
```

---

### 10.6: Use `nice` when starting heavy programs

Instead of fixing later, prevent the issue:

```bash
nice -n 10 make -j4
```

or

```bash
nice -n 15 firefox
```

---

### 10.7: Limit runaway multi-thread apps

Your CPU:

> i3-7100U → 2 cores / 4 threads

Some apps spawn too many threads.

#### Limit manually:

```bash
make -j2
```

---

### 10.8: Emergency key (when system is frozen)

Enable SysRq:

```bash
echo 1 | sudo tee /proc/sys/kernel/sysrq
```

Then:

```
Alt + SysRq + f
```

👉 kills the most memory-hungry process

---

### 10.9: Bonus: reduce UI lag in i3

Add to config:

```bash
exec --no-startup-id picom --experimental-backends
```

Or disable compositor during heavy work.

---

### 10.10: Reality check (important)

Your system is decent:

* i3-7100U
* 16GB RAM ✅

But:

* If **one badly written process loops**, no OS tweak fully saves you
* The real fix = **control priority + limit CPU + fix app behavior**

---

### 10.11: Best combo (do this first)

If you only do 3 things:

1. Install `ananicy-cpp`
2. Use `cpulimit` / `renice`
3. Enable `earlyoom`

That alone will make your system feel **10x more responsive under stress**

---

## 11: Docker group access -------------------------------

Add your user to the docker group so you do not need sudo every time:

```bash
sudo usermod -aG docker $USER
newgrp docker
```

Docker runs as root and uses `/var/run/docker.sock`. Only users in the docker group can access it.
