---
id: 20250726042622
title: Termux Setup self
date: 2025-07-26 04:26
type: note # note | concept | snippet | bug | journal | reference
status: draft # draft | stable | evergreen
tags: []
links: []
---
# Log
- 2025-07-26 04:26 - Created note.

# Notes

# ssh setup and passwd for remote connection 
```bash
sv-enable ssh-agent;sv-enable sshd
pkg install openssh
sshd
passwd

pkg install iproute2
ip a
whoami
```

# must have pakages installed 

```bash
pkg install termux-tools termux-services
pkg update && pkg upgrade -y
pkg install -y openssh git curl wget neovim rsync htop tmux termux-api
pkg install -y grep man linux-man-pages ripgrep stow tree fzf
```

# setup ssh and also connect ssh to github
```bash
ssh-keygen -t ed25519 -C "bismuth@droid.com"

ssh-keygen -t ed25519 -C "technetium@itsarraj.xyz"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
cat ~/.ssh/id_ed25519.pub
ssh -T git@github.com
```
# can connect to phone using this ssh
```bash
# Android doesn’t allow apps (like Termux) to bind 
# to low-numbered ports (<1024) unless they’re root. 
# So Termux can’t use port 22, which is the default for SSH.

ssh u0_a704@192.168.67.222
or 
ssh u0_a704@192.168.67.222 -p 8022

```
# clone dotfiles and stow these 
```bash
  git clone https://github.com/itsarraj/dotfiles.git
  stow -S nvim
  stow -S tmux
  stow -S newboat
  stow -S newsboat
  stow -S bin
```

# update bashrc with these 
```bash
export PATH="$HOME/.local/scripts:$PATH"
bind '"\C-f":"tmux-sessionizer\n"'
PS1='\[\e[0;1;3$(($?==0?2:1))m\]›\[\e[0m\] '
```

# solarized color theme installed

## Step 3: Setup Solarized Dark Theme in Termux

There are **3 layers** you want to theme for a clean Solarized Dark experience:

### ① Termux App Colors (Terminal emulator UI)
### ② Shell prompt (zsh/bash)
### ③ Tools like `tmux`, `neovim`, `htop`, etc.

---

## ✅ Step 3.1: Termux App Colors (UI theme)

Termux has no GUI theme system — but you can **configure colors via `.termux/colors.properties`**

### 📁 Create directory:

```bash
mkdir -p ~/.termux
```

### 🎨 Add Solarized Dark color scheme:

Create the file:

```bash
nano ~/.termux/colors.properties
```

Paste this (Solarized Dark): 
reference - https://github.com/termux/termux-styling/blob/master/app/src/main/assets/colors/solarized-dark.properties

```ini
# https://github.com/altercation/solarized/blob/master/xresources/solarized
background=#002b36
foreground=#839496
cursor=#93a1a1

color0=#073642
color1=#dc322f
color2=#859900
color3=#b58900
color4=#268bd2
color5=#d33682
color6=#2aa198
color7=#eee8d5
color9=#cb4b16
color8=#002b36
color10=#586e75
color11=#657b83
color12=#839496
color13=#6c71c4
color14=#93a1a1
color15=#fdf6e3
```

> Based on official Solarized Dark palette.

### 🖥️ Apply theme:

You must **restart** the Termux app or run:

```bash
termux-reload-settings
```

---

## ✅ Step 3.2: Set shell and prompt colors (zsh/bash)

If you're using `bash`:
Edit `~/.bashrc`

If using `zsh` :

```bash
pkg install zsh
chsh -s zsh
```

Then edit `~/.zshrc`

### Simple solarized prompt (bash)

```sh
PS1='\[\e[0;1;3$(($?==0?2:1))m\]›\[\e[0m\] '

```

# Font Installations 

## Install JetBrains Mono Nerd Font in Termux

### ⚠️ Important:

**Fonts for Termux terminal UI are NOT controlled from inside Termux.**
Instead, you must **manually install the font in Android’s Termux app folder** using **Termux's `.termux/font.ttf` file**.

---

## ✅ Step-by-step: Use JetBrains Mono Nerd Font in Termux

### 📥 1. Download the font (JetBrainsMono Nerd Font)

From your Termux shell:

```bash
mkdir -p ~/.termux
cd ~/.termux
curl -LO https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
unzip JetBrainsMono.zip
cp "JetBrainsMonoNerdFont-Regular.ttf" font.ttf
rm JetBrainsMono.zip
```

> ✅ The font must be named `font.ttf` inside `~/.termux/`.

You can pick another variant (e.g., `Mono`, `Bold`) from the unzipped files if desired.

---

### 🔁 2. Apply the font

In Termux, run:

```bash
termux-reload-settings
```

Or close and reopen Termux app.

---

## 🧪 Verify:

Run something like `htop`, `tmux`, or your zsh prompt — you should now see:

* Nerd icons (, , , etc.)
* Proper powerline separators (, )
* JetBrains Mono spacing and style

# nvim error 
Error detected while processing /data/data/com.termux/files/home/dotfiles/nvim/.config/nvim/init.lua:
No C compiler found! "cc", "gcc", "clang", "cl", "zig" are not executable.
No C compiler found! "cc", "gcc", "clang", "cl", "zig" are not executable.pkg install clang
fix the above error with this 

```bash
pkg install clang build-essential
```
# also added the alias in bash profile
```bash
› cat .bash_profile
export PATH="$HOME/.local/scripts:$PATH"
bind '"\C-f":"tmux-sessionizer\n"'
PS1='\[\e[0;1;3$(($?==0?2:1))m\]›\[\e[0m\] '

alias cdshared="cd /data/data/com.termux/files/home/storage/shared/"
alias cdnotes="cd /data/data/com.termux/files/home/storage/shared/notes"
alias cddot="cd /data/data/com.termux/files/home/dotfiles/"
alias pushall="git add -A; git commit -sm 'Updated Notes vom Handy'; git push -uf github master; git push -uf gitlab master;"
```
