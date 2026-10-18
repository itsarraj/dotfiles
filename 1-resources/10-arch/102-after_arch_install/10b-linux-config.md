---
id: 20260101014025
title: Linux Config - Day-to-day Tools & Workflows
date: 2026-01-01 01:40
type: note # note | concept | snippet | bug | journal | reference
status: draft # draft | stable | evergreen
tags: [linux, tools, config, stow, ssh, git]
links: []
---
# Log
- 2026-01-01 01:40 - Created note.

# Notes
# Day-to-day Linux tools and workflows
- [ ] Website Blocking (YouTube)
- [ ] GNU Stow (Dotfile Management)
- [ ] Screen Resolution Management
- [ ] External Drive Configuration (/etc/fstab)
- [ ] Gaming Setup
- [ ] Python Environment Management
- [ ] SSH/SCP File Transfer
- [ ] Backlight/Brightness Control
- [ ] Git Configuration
- [ ] SSH Key Setup for GitHub
- [ ] Application Transparency (Picom)
- [ ] PipeWire External Microphone
- [ ] MAC Address & Hostname Randomization

## 1: Website Blocking (YouTube) -------------------------------

### /etc/hosts Block (System-wide)
```bash
sudo vim /etc/hosts
```
Add:
```
127.0.0.1 youtube.com
127.0.0.1 www.youtube.com
127.0.0.1 m.youtube.com
127.0.0.1 youtu.be
127.0.0.1 www.youtu.be
127.0.0.1 music.youtube.com
```
Flush DNS: `sudo systemd-resolve --flush-caches`

### yt-dlp (CLI Downloads Still Work)
```bash
yt-dlp "https://www.youtube.com/watch?v=..." -o "~/Lectures/%(title)s.%(ext)s"
mkdir -p ~/Lectures/YT
```

---

## 2: GNU Stow (Dotfile Management) -------------------------------

### Setup & Initial Stow
```bash
cd ~
git clone https://github.com/user/dotfiles.git
cd dotfiles
stow -n *                    # Preview what will be linked
stow *                       # Link all packages to ~
```

### Package Operations
```bash
stow nvim                    # Link nvim config (~/.config/nvim -> dotfiles/nvim/.config/nvim)
stow -R nvim                 # Update nvim links after config changes
stow -D nvim                 # Remove nvim symlinks
stow -d ~/dotfiles -t ~ i3   # Explicit: stow dir ~/dotfiles, target ~, package i3
```

### Managing Existing Files
```bash
stow --adopt -S bash         # Move existing ~/.bashrc to dotfiles/bash/ then link
stow -n --adopt -S bash      # Preview adopt operation first
```

### Workflow Examples
- **New machine**: `cd ~/dotfiles && stow *`
- **Updated config**: `cd ~/dotfiles && stow -R nvim`
- **Remove package**: `cd ~/dotfiles && stow -D tmux`
- **Add new package**: `mkdir ~/dotfiles/newpkg && stow -R newpkg`

### Common Issues
- Always run from dotfiles directory
- Use directory names (packages) not filenames
- Test with `stow -n` before real operations
- Backup before `stow --adopt`

---

## 3: Screen Resolution Management -------------------------------

### Check Available Resolutions
```bash
xrandr                         # List displays and available modes
```

### Add Custom Resolution
```bash
cvt 1920 1080 60               # Generate modeline for 1920x1080@60Hz
xrandr --newmode "1920x1080_60.00"  173.00  1920 2048 2248 2576  1080 1083 1088 1120 -hsync +vsync
xrandr --addmode eDP-1 "1920x1080_60.00"
xrandr --output eDP-1 --mode "1920x1080_60.00"
```

### Scale Display (Simulate Higher Resolution)
```bash
xrandr --output eDP-1 --scale 1.5x1.5    # Shrink everything to simulate higher res
xrandr --output eDP-1 --scale 1x1        # Reset scaling
```

### Revert to Native Resolution
```bash
xrandr --output eDP-1 --mode 1366x768    # Revert to native resolution
```

### Emergency Revert (TTY)
If display becomes unusable, switch to TTY (Ctrl+Alt+F3) and run:
```bash
xrandr --output eDP-1 --mode 1366x768
# Return to GUI: Ctrl+Alt+F1/F7
```

---

## 4: External Drive Configuration (/etc/fstab) -------------------------------

### Find Drive UUID
```bash
sudo blkid                        # List all drives with UUIDs
sudo blkid | grep sda1            # Find specific drive info
```

### Label Drive (ext4)
```bash
sudo e2label /dev/sda1 HDD10      # Rename label to HDD10
blkid | grep sda1                 # Verify label change
```

### Create Mount Point
```bash
sudo mkdir -p /run/media/$USER/HDD10
```

### Add to /etc/fstab
```bash
sudo vim /etc/fstab
```
Add line:
```
UUID=1c2b0323-d095-4542-aca6-c18c697178d7  /run/media/cesium/HDD10  ext4  defaults,noauto,nofail  0  2
```

### Mount & Test
```bash
sudo mount /run/media/$USER/HDD10     # Mount manually
df -h | grep HDD10                   # Verify mount
sudo mount -a                        # Test all fstab entries
```

### NTFS Drives (Alternative)
For NTFS drives, use:
```
UUID=762D9C7C7E4F79A3  /run/media/cesium/elbe  ntfs-3g  defaults,noauto,nofail  0  0
```

### fstab Options Explained
- `noauto`: Don't mount at boot
- `nofail`: Don't fail boot if drive missing
- `defaults`: Standard mount options
- `0 2`: No dump, check second

### NTFS Troubleshooting
```bash
sudo pacman -S ntfs-3g          # Install NTFS support
sudo ntfsfix /dev/sdc1          # Fix NTFS errors
sudo mount -t ntfs-3g /dev/sdc1 /mnt  # Manual mount
```

### Automount Setup
```bash
sudo pacman -S udisks2 gvfs     # Required for automounting
```

### Desktop Environment Automount Settings
**GNOME**: Disks app → Gear icon → Edit Mount Options → Enable automount
**KDE**: System Settings → Removable Devices → Enable automounting
**XFCE**: Settings Manager → Removable Drives → Enable hot-plug mounting

### Secondary Drive Setup (Manual)
```bash
mkdir /mnt/secondary
sudo mount /dev/sdb1 /mnt/secondary
sudo chown -R $USER:$USER /mnt/secondary
sudo chmod -R 755 /mnt/secondary
```

---

## 5: Gaming Setup -------------------------------

### Enable Multilib Repository
```bash
sudo vim /etc/pacman.conf
```
Uncomment:
```
[multilib]
Include = /etc/pacman.d/mirrorlist
```

### Basic Gaming Packages
```bash
sudo pacman -Syu
sudo pacman -S wine lutris winetricks gamemode lib32-gamemode lib32-libpulse
sudo pacman -S wine-gecko wine-mono lib32-pipewire
```

### Lutris & Wine Setup
```bash
sudo pacman -S lutris gamemode
# For Windows games (.exe files)
wine setup.exe
winetricks # Install additional Windows components
```

### NVIDIA Drivers (Gaming)
```bash
# Choose one based on kernel:
sudo pacman -S --needed nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings  # For custom kernels
# OR
sudo pacman -S --needed nvidia-lts nvidia-utils lib32-nvidia-utils nvidia-settings    # For LTS kernel

sudo pacman -S vulkan-icd-loader lib32-vulkan-icd-loader vulkan-tools
```

### Additional Gaming Packages
```bash
sudo pacman -S proton-ge-custom-bin  # From AUR
# Verify with: pacman -Sl multilib
```

### GameMode Integration
```bash
gamemoded -t  # Test gamemode
# Integrates with Lutris and Steam for performance boost
```

---

## 6: Python Environment Management -------------------------------

### Virtual Environment Setup
```bash
python3 -m venv myenv              # Create virtual environment
source myenv/bin/activate          # Activate environment
pip install package_name           # Install packages in venv
deactivate                         # Exit virtual environment
```

### Common Usage
```bash
# Create and activate
python3 -m venv ~/projects/myproject
cd ~/projects/myproject
source bin/activate

# Install packages
pip install requests numpy pandas

# Run scripts
python script.py

# Deactivate when done
deactivate
```

### Virtual Environment Best Practices
- Create separate venv for each project
- Activate venv before working on project
- Use `requirements.txt` for dependencies: `pip freeze > requirements.txt`
- Install from requirements: `pip install -r requirements.txt`

---

## 7: SSH/SCP File Transfer -------------------------------

### Install OpenSSH
```bash
sudo pacman -S openssh
sudo systemctl enable --now sshd
```

### SCP File Transfer Examples
```bash
# Copy single file to remote
scp /path/to/local/file user@remote:/path/to/destination/

# Copy directory recursively to remote
scp -r /path/to/local/dir user@remote:/path/to/destination/

# Copy from remote to local
scp user@remote:/path/to/remote/file /local/destination/

# Copy directory from remote to local
scp -r user@remote:/path/to/remote/dir /local/destination/
```

### Common SCP Options
- `-r` → recursive (directories)
- `-P port` → specify custom SSH port
- `-i keyfile` → use specific SSH key
- `-v` → verbose output for debugging

### Example Usage
```bash
# Transfer project files to remote server
scp -r ~/projects/myapp user@server:/var/www/

# Download config files from remote
scp user@server:/etc/nginx/sites-available/default ~/backups/
```

---

## 8: Backlight/Brightness Control -------------------------------

### Install brightnessctl
```bash
sudo pacman -S brightnessctl
```

### i3 Key Bindings
```bash
# Increase brightness
bindsym XF86MonBrightnessUp exec --no-startup-id brightnessctl set +10% && $refresh_i3status

# Decrease brightness
bindsym XF86MonBrightnessDown exec --no-startup-id brightnessctl set 10%- && $refresh_i3status
```

### Basic Commands
```bash
brightnessctl                    # Show current status
brightnessctl m                  # Get maximum brightness
brightnessctl g                  # Get current brightness
brightnessctl s 50%             # Set to 50%
brightnessctl s +10%            # Increase by 10%
brightnessctl s 10%-            # Decrease by 10%
```

### List Devices
```bash
brightnessctl -l                 # List all brightness devices
```

---

## 9: Git Configuration -------------------------------

### Global Git Setup
```bash
# Set user identity
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Set Vim as default editor
git config --global core.editor "vim"
```

### Multiple Remotes Setup
```bash
# Remove existing origin and add multiple remotes
git remote remove origin
git remote add github git@github.com:username/repo.git
git remote add gitlab git@gitlab.com:username/repo.git
```

### Push to Multiple Remotes
```bash
# Add, commit, and push to both remotes
git add .
git commit -sm "Updated configuration"
git push -uf github master
git push -uf gitlab master
```

### Git Push Flags
- `-u` → set upstream branch
- `-f` → force push (overwrites remote)
- Use carefully when sure about changes

### Fetch All Remote Branches
```bash
# Fetch all branches and set up tracking
git branch -r | grep -v '\->' | sed "s,\x1B\[[0-9;]*[a-zA-Z],,g" | while read remote; do git branch --track "${remote#origin/}" "$remote"; done

# Fetch and pull everything
git fetch --all
git pull --all
```

---

## 10: SSH Key Setup for GitHub -------------------------------

### Install OpenSSH
```bash
sudo pacman -S openssh
```

[Generating the new ssh key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)
### Generate SSH Key
```bash
ssh-keygen -t ed25519 -C "your.email@example.com"
# Save as: ~/.ssh/id_ed25519 (default)
```

### Start SSH Agent
```bash
eval "$(ssh-agent -s)"
```

### Add Key to SSH Agent
```bash
ssh-add ~/.ssh/id_ed25519
```

[Adding a new SSH key to your github account](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account)
### Copy Public Key
```bash
cat ~/.ssh/id_ed25519.pub
# Copy the output and add to GitHub Settings > SSH Keys
```

### Test Connection
```bash
ssh -T git@github.com
# Type 'yes' to accept the host fingerprint
# Should see: "Hi username! You've successfully authenticated..."
```

---

## 11: Application Transparency (Picom) -------------------------------

### Find Window Class with xprop
```bash
xprop | grep CLASS
# Click on window to get WM_CLASS
# Output: WM_CLASS(STRING) = "brave-browser", "Brave-browser"
```

### Common WM_CLASS Examples
```bash
"brave-browser", "Brave-browser"    # Brave browser
"thunar", "Thunar"                  # Thunar file manager
"org.pwmt.zathura", "Zathura"       # Zathura PDF reader
"Navigator", "firefox"              # Firefox (note lowercase)
"bar-0", "i3bar"                    # i3 status bar
```

### Picom Opacity Configuration
```bash
# Add to ~/.config/picom/picom.conf
opacity-rule = [
  "90:class_g = 'Brave-browser'",    # 90% opacity for Brave
  "85:class_g = 'Thunar'",           # 85% opacity for Thunar
  "95:class_g = 'Zathura'"           # 95% opacity for Zathura
]
```

### i3 Window Assignment (Related)
```bash
# Add to ~/.config/i3/config
assign [class="Alacritty"] workspace $ws1
assign [class="Brave-browser"] workspace $ws2
assign [class="Thunar"] workspace $ws3
```

### WM_CLASS Notes
- **First value**: Instance (usually lowercase)
- **Second value**: Class (usually capitalized by convention)
- Use `class_g` in picom rules (case-insensitive)
- Not all applications follow capitalization convention

---

## 12: PipeWire External Microphone -------------------------------

### Create Microphone Configuration
```bash
sudo mkdir -p /etc/pipewire/pipewire.conf.d
sudo vim /etc/pipewire/pipewire.conf.d/microphone.conf
```

### Add Microphone Config
```bash
# External microphone configuration
context.objects = [
    { factory = adapter
        args = {
            factory.name           = api.alsa.pcm.source
            node.name              = "microphone"
            node.description       = "ext_mic_arch"
            media.class            = "Audio/Source"
            api.alsa.path          = "hw:0,0"
        }
    }
]
```

### Restart PipeWire
```bash
systemctl --user restart pipewire
```

### Verify Configuration
```bash
# Check PipeWire status
pactl list sources | grep -A 10 "ext_mic_arch"

# Test microphone
arecord -f cd -d 5 test-mic.wav
aplay test-mic.wav
```

### Notes
- `api.alsa.path = "hw:0,0"` → Hardware device 0, subdevice 0
- Change the path if your microphone uses different hardware
- Use `arecord -l` to list available audio devices

---

## 13: MAC Address & Hostname Randomization -------------------------------

### MAC Address Randomization (NetworkManager)
```bash
sudo vim /etc/NetworkManager/NetworkManager.conf
```

Add to config:
```ini
[device]
wifi.scan-rand-mac-address=yes

[connection]
wifi.cloned-mac-address=random
```

Restart NetworkManager:
```bash
sudo systemctl restart NetworkManager
```

### MAC Address Randomization (macchanger)
```bash
# Install macchanger
sudo pacman -S macchanger

# Disconnect and randomize
sudo ip link set wlan0 down
sudo macchanger -r wlan0
sudo ip link set wlan0 up
```

### Random Hostname at Boot
Create script `/usr/local/bin/random-hostname.sh`:
```bash
#!/bin/bash
RANDOM_HOST="arch-$(head /dev/urandom | tr -dc a-z0-9 | head -c6)"
hostnamectl set-hostname "$RANDOM_HOST"
```

Make executable:
```bash
sudo chmod +x /usr/local/bin/random-hostname.sh
```

Create systemd service `/etc/systemd/system/random-hostname.service`:
```ini
[Unit]
Description=Set random hostname at boot
After=network-pre.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/random-hostname.sh

[Install]
WantedBy=multi-user.target
```

Enable service:
```bash
sudo systemctl enable random-hostname.service
```
Now, every reboot will generate a random hostname like `arch-4f7a2b`.

### Check Current MAC
```bash
ip link show wlan0
# Look for "link/ether" line
```

