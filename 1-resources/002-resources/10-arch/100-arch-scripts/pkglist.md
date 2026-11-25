## Install (copy/paste)

### Pacman repo packages

```bash
sudo pacman -Syu --needed base base-devel linux linux-headers linux-firmware linux-lts linux-lts-headers amd-ucode intel-ucode
```

```bash
sudo pacman -Syu --needed \
  base base-devel \                            # base system + build tools
  linux linux-headers linux-firmware \         # mainline kernel + headers + firmware
  linux-lts linux-lts-headers \                # LTS kernel (fallback)
  amd-ucode intel-ucode                        # CPU microcode (install the one you need)
```

- **base/base-devel**: required for a working system + building packages (AUR, dev tools).
- **linux/linux-headers**: kernel + headers (needed for some modules).
- **linux-lts**: stable fallback kernel.
- **amd-ucode/intel-ucode**: pick the one for your CPU vendor.

--------------------------------

```bash
sudo pacman -Syu --needed networkmanager network-manager-applet iwd wpa_supplicant dhcpcd netctl openssh openvpn ufw
```

```bash
sudo pacman -Syu --needed \
  networkmanager network-manager-applet \      # networking + tray applet
  iwd wpa_supplicant \                         # Wi‑Fi backends (you may only need one)
  dhcpcd \                                     # DHCP client (optional if using NetworkManager only)
  netctl \                                     # legacy network profiles (optional)
  openssh \                                    # ssh client/server
  openvpn \                                    # VPN (OpenVPN)
  ufw                                          # firewall frontend
```

- **NetworkManager + applet**: simplest desktop networking setup.
- **iwd / wpa_supplicant**: Wi‑Fi backend; keep one if you prefer.
- **openssh/openvpn/ufw**: remote access + VPN + firewall.

--------------------------------

```bash
sudo pacman -Syu --needed xorg-server xorg-xinit xorg-xrandr xorg-xinput xorg-setxkbmap xorg-xset xorg-xsetroot xorg-xev xorg-xdpyinfo xorg-xwininfo xorg-xlsclients xorg-xhost xorg-xprop xorg-xauth xf86-video-amdgpu xf86-video-vesa
```

```bash
sudo pacman -Syu --needed \
  xorg-server xorg-xinit \                     # Xorg display server + startx
  xorg-xrandr xorg-xinput \                    # display + input config tools
  xorg-setxkbmap \                             # keyboard layout config
  xorg-xset xorg-xsetroot \                    # X settings + root window
  xorg-xev xorg-xdpyinfo \                     # X debugging helpers
  xorg-xwininfo xorg-xlsclients xorg-xhost \   # window/session inspection helpers
  xorg-xprop \                                 # X window properties (handy with i3)
  xorg-xauth \                                 # X authentication cookies
  xf86-video-amdgpu xf86-video-vesa            # Xorg video drivers (vesa = generic fallback)
```

- **xorg-xprop/xlsclients/xwininfo**: the exact “useful xorg utils for i3” tools you mentioned.
- **xf86-video-amdgpu**: AMD GPUs; **xf86-video-vesa**: fallback.

--------------------------------

```bash
sudo pacman -Syu --needed i3-wm i3status i3lock i3blocks dmenu rofi picom dunst autotiling feh maim xclip xdotool
```

```bash
sudo pacman -Syu --needed \
  i3-wm i3status i3lock i3blocks \             # i3 + status bar + lock + blocks
  dmenu rofi \                                 # launchers
  picom \                                      # compositor
  dunst \                                      # notifications
  autotiling \                                 # auto tiling helper for i3
  feh \                                        # wallpaper + image viewer basics
  maim \                                       # screenshots
  xclip xdotool                                # clipboard + scripting X input
```

--------------------------------

```bash
sudo pacman -Syu --needed alacritty tmux neovim vim lf ripgrep fd fzf bat tree jq rsync stow fastfetch htop btop dust dialog
```

```bash
sudo pacman -Syu --needed \
  alacritty tmux \                             # terminal + multiplexer
  neovim vim \                                 # editors (keep what you use)
  lf \                                         # terminal file manager
  ripgrep fd fzf \                             # search + fuzzy finding
  bat tree jq \                                # better cat/tree + JSON cli
  rsync stow \                                 # syncing + dotfiles mgmt
  fastfetch htop btop dust dialog              # system info + monitors + disk + TUI prompts
```

--------------------------------

```bash
sudo pacman -Syu --needed pipewire pipewire-pulse pavucontrol easyeffects
```

```bash
sudo pacman -Syu --needed \
  pipewire pipewire-pulse \                    # audio server + PulseAudio compatibility
  pavucontrol \                                # volume control GUI
  easyeffects                                  # audio effects / EQ
```

--------------------------------

```bash
sudo pacman -Syu --needed docker docker-buildx docker-compose lazydocker
```

```bash
sudo pacman -Syu --needed \
  docker docker-buildx docker-compose \         # containers + buildx + compose
  lazydocker                                   # TUI for Docker
```

--------------------------------

```bash
sudo pacman -Syu --needed firefox vlc vlc-plugins-all libreoffice-fresh-en-gb obsidian newsboat nginx postgresql mariadb dbeaver
```

```bash
sudo pacman -Syu --needed \
  firefox \                                    # browser
  vlc vlc-plugins-all \                         # media player + plugins
  libreoffice-fresh-en-gb \                    # office suite
  obsidian \                                   # notes
  newsboat \                                   # RSS
  nginx \                                      # web server
  postgresql mariadb \                         # databases
  dbeaver                                      # DB GUI client
```

--------------------------------

```bash
sudo pacman -Syu --needed thunar thunar-volman tumbler nautilus gvfs-mtp atril gpicview imagemagick img2pdf kid3 zathura zathura-pdf-mupdf
```

```bash
sudo pacman -Syu --needed \
  thunar thunar-volman tumbler \               # XFCE file manager + removable media + thumbnails
  nautilus \                                   # GNOME file manager (optional)
  gvfs-mtp \                                   # MTP (Android) support in file managers
  atril \                                      # document viewer
  gpicview \                                   # lightweight image viewer
  imagemagick img2pdf \                        # image tools + image->pdf
  kid3 \                                       # audio tag editor
  zathura zathura-pdf-mupdf                    # PDF viewer
```

--------------------------------

```bash
sudo pacman -Syu --needed man-db man-pages texinfo inetutils lynx w3m curl wget aria2 7zip zip unzip unrar ntfs-3g exfatprogs fuse3 dosfstools
```

```bash
sudo pacman -Syu --needed \
  man-db man-pages texinfo \                   # docs
  inetutils \                                  # basic network utils
  lynx w3m \                                   # terminal browsers
  curl wget aria2 \                            # downloaders (curl is very useful)
  7zip zip unzip unrar \                       # archives
  ntfs-3g exfatprogs fuse3 \                   # NTFS + modern exFAT USB drives
  dosfstools                                   # FAT tools
```

--------------------------------

```bash
sudo pacman -Syu --needed udisks2 polkit blueman
```

```bash
sudo pacman -Syu --needed \
  udisks2 \                                    # better USB/auto-mount support
  polkit \                                     # needed for some GUI privileges
  blueman                                      # Bluetooth manager (if you use Bluetooth)
```

--------------------------------

```bash
sudo pacman -Syu --needed noto-fonts noto-fonts-emoji ttf-dejavu ttf-liberation ttf-dejavu-nerd ttf-jetbrains-mono-nerd gnu-free-fonts
```

```bash
sudo pacman -Syu --needed \
  noto-fonts noto-fonts-emoji \                # good defaults + emoji
  ttf-dejavu ttf-liberation \                  # common fonts
  ttf-dejavu-nerd ttf-jetbrains-mono-nerd \    # nerd fonts (glyphs)
  gnu-free-fonts                               # extra coverage
```

--------------------------------

```bash
sudo pacman -Syu --needed lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings
```

```bash
sudo pacman -Syu --needed \
  lightdm \                                    # display manager
  lightdm-gtk-greeter lightdm-gtk-greeter-settings
```

--------------------------------

```bash
sudo pacman -Syu --needed git go jdk-openjdk jdk8-openjdk jdk11-openjdk jdk17-openjdk jdk21-openjdk python-pip python-virtualenv pnpm yarn watchman
```

```bash
sudo pacman -Syu --needed \
  git go \                                     # dev basics
  jdk-openjdk jdk8-openjdk jdk11-openjdk jdk17-openjdk jdk21-openjdk \  # Java toolchains (keep only what you need)
  python-pip python-virtualenv \               # Python env tooling
  pnpm yarn \                                  # JS package managers
  watchman                                    # file watcher (some dev tools rely on it)
```

--------------------------------

```bash
sudo pacman -Syu --needed tlp tlp-rdw powertop earlyoom acpi brightnessctl cpupower
```

```bash
sudo pacman -Syu --needed \
  tlp tlp-rdw \                                # laptop power management
  powertop \                                   # power tuning/insight
  earlyoom \                                   # prevent hard lockups under memory pressure
  acpi brightnessctl cpupower                  # battery/brightness/cpu controls
```

--------------------------------

```bash
sudo pacman -Syu --needed zram-generator
```

```bash
sudo pacman -Syu --needed \
  zram-generator                               # add swap via zram (great on laptops / 16GB RAM)
```

--------------------------------

### AUR packages (use paru)

```bash
sudo pacman -Syu --needed paru
```

```bash
sudo pacman -Syu --needed \
  paru                                         # AUR helper (if you don't have it yet)
```

--------------------------------

```bash
paru -S --needed android-studio brave-bin google-chrome cursor-bin visual-studio-code-bin postman-bin telegram-desktop-bin figma-linux freedownloadmanager gparted-git arc-gtk-theme antigravity void-bin
```

```bash
paru -S --needed \
  android-studio \                             # IDE
  brave-bin google-chrome \                    # browsers
  cursor-bin visual-studio-code-bin \          # editors
  postman-bin \                                # API client
  telegram-desktop-bin \                       # chat
  figma-linux \                                # design
  freedownloadmanager \                        # downloads
  gparted-git \                                # partition editor (git version)
  arc-gtk-theme \                              # GTK theme
  antigravity void-bin                         # misc tools
```