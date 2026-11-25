---
id: 20260101014026
title: Arch Linux Install Scripts & Package Lists Documentation
date: 2026-01-01 01:40
type: note # note | concept | snippet | bug | journal | reference
status: stable # draft | stable | evergreen
tags: [archlinux, scripts, automation, packages, installation]
links: []
---
# Log
- 2026-01-01 01:40 - Created note.

# Notes

# Arch Linux Package Management Scripts

## 1. Generate Package Lists

Run this first to create your package lists:

```bash
#!/bin/bash
# generate_pkglist.sh

# Remove old package lists if they exist
rm -f pkglist.txt pkglist_aur.txt

# Generate new package lists
echo "Creating package list for official repositories..."
pacman -Qqen > pkglist.txt
echo "Creating package list for AUR packages..."
pacman -Qqem > pkglist_aur.txt

echo "Package lists have been updated: pkglist.txt and pkglist_aur.txt"
```

## 2. Simple Package Installer (Files & Arrays)

This flexible script handles both package list files and direct package arrays:

```bash
#!/bin/bash
# install_packages_simple.sh

# Simple package installer that handles both file lists and arrays
# Usage:
#   ./install_packages_simple.sh pkglist.txt          # Install from file
#   ./install_packages_simple.sh pkglist_aur.txt     # Install AUR from file
#   ./install_packages_simple.sh vim git htop        # Install from command line
#   packages=(vim git htop); ./install_packages_simple.sh "${packages[@]}"  # Install from array

# Install paru if not present (needed for AUR packages)
if ! command -v paru &> /dev/null; then
  echo "paru is not installed. Installing yay..."
  sudo pacman -S --needed git base-devel --noconfirm
  git clone https://aur.archlinux.org/paru.git
  cd paru
  makepkg -si --noconfirm
  cd ..
  rm -rf paru
fi

# Check if first argument is a file
if [ -f "$1" ]; then
  # Install from package list file
  if [[ "$1" == *"aur"* ]]; then
    echo "Installing AUR packages from $1..."
    paru -S --needed --noconfirm - < "$1"
  else
    echo "Installing packages from $1..."
    sudo pacman -S --needed --noconfirm - < "$1"
  fi
else
  # Install from command line arguments or array
  packages=("$@")
  echo "Installing packages: ${packages[*]}"
  
  for package in "${packages[@]}"; do
    if ! pacman -Q "$package" &> /dev/null; then
      # Check if package exists in official repos
      if pacman -Ss "^$package$" &> /dev/null; then
        sudo pacman -S --needed --noconfirm "$package"
      else
        # Install from AUR
        paru -S --needed --noconfirm "$package"
      fi
    else
      echo "$package is already installed."
    fi
  done
fi

echo "All packages installed successfully!"
```

## Usage Examples

### Install from Package Lists
```bash
# Generate lists first
./generate_pkglist.sh

# Install official packages
./install_packages_simple.sh pkglist.txt

# Install AUR packages
./install_packages_simple.sh pkglist_aur.txt
```

### Install Specific Packages
```bash
# From command line
./install_packages_simple.sh vim git htop neovim

# From array
packages=(vim git htop neovim tmux)
./install_packages_simple.sh "${packages[@]}"

# From comprehensive package list (all categories)
./install_packages_simple.sh pkglist_comprehensive.txt
```

### Comprehensive Package List

The `pkglist_comprehensive.txt` file contains **162 unique packages** from all specialized categories:

- **Development**: Docker, JDKs, development tools (fd, ripgrep, tree, etc.)
- **Desktop Environments**: i3, XFCE4, display managers
- **Audio/Video**: Pipewire, VLC, OBS Studio, Audacity
- **Gaming**: Lutris, Wine, Proton-GE
- **Networking**: NetworkManager, OpenVPN, Tailscale
- **System Utilities**: htop, btop, fastfetch, stow, tmux
- **Applications**: Firefox, Thunderbird, LibreOffice, Discord
- **Drivers**: NVIDIA, Intel, AMD graphics drivers
- **Fonts**: Noto, JetBrains Mono, Nerd Fonts
- **And more...**

This comprehensive list provides a complete desktop environment setup with development tools.

### Alternative: Basic Package Installer

For simple file-based installation:

```bash
#!/bin/bash
# install_packages_basic.sh

# Ensure system is up to date
sudo pacman -Syu --noconfirm

# Install paru if not present
if ! command -v paru &> /dev/null; then
  echo "Installing paru..."
  sudo pacman -S --needed git base-devel --noconfirm
  git clone https://aur.archlinux.org/paru.git
  cd paru && makepkg -si --noconfirm
  cd .. && rm -rf paru
fi

# Install packages
[ -f pkglist.txt ] && sudo pacman -S --needed - < pkglist.txt
[ -f pkglist_aur.txt ] && paru -S --needed --noconfirm - < pkglist_aur.txt

echo "All packages installed successfully!"
```
## 3. FNM & Node.js Installer

Install on system
curl -fsSL https://fnm.vercel.app/install | bash

Install the latest LTS
fnm install --lts

Install the latest
fnm install --latest

Make the defaults
fnm default --lts

use it on current shell
fnm use --lts

verify these
fnm list 
node --version
npm --version

Enable auto-switching
Add this to ~/.bashrc (or ~/.zshrc if you use zsh)
eval "$(fnm env --use-on-cd --shell bash)"


## 3. NVM & Node.js Installer

Install Node Version Manager and Node.js:

```bash
#!/bin/bash
# install_nvm_node.sh

# Install NVM (Node Version Manager)
echo "Installing NVM..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

# Install the latest version of Node.js
echo "Installing the latest version of Node.js..."
nvm install node

# Verify installation
echo "Verifying Node.js installation..."
node -v
npm -v

echo "NVM and Node.js installation completed successfully!"
```

## 4. JDK Installer

Install multiple Java Development Kit versions:

```bash
#!/bin/bash
# install_jdk.sh

# Install the latest version of OpenJDK
echo "Installing the latest version of OpenJDK..."
sudo pacman -S --noconfirm jdk-openjdk

# Install JDK 17
echo "Installing JDK 17..."
sudo pacman -S --noconfirm jdk17-openjdk

# Install JDK 11
echo "Installing JDK 11..."
sudo pacman -S --noconfirm jdk11-openjdk

# Verify the installation of JDKs
echo "Verifying JDK installations..."
java -version

echo "Listing installed Java environments..."
archlinux-java status

# Set JDK 17 as the default Java version
echo "Setting JDK 17 as the default Java version..."
sudo archlinux-java set java-17-openjdk

# Verify the default Java version
echo "Verifying the default Java version..."
java -version

echo "JDK installation and setup completed successfully!"
```
