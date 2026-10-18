---
id: 20260927172700
title: Android ADB and Udev Rules Setup on Arch Linux
date: 2026-09-27 17:27
type: reference
status: stable
tags: [android, adb, udev, archlinux, linux]
links: []
---

# Notes
# Android ADB & Udev Setup
- [ ] Install ADB (android-tools)
- [ ] Identify Device Vendor & Product IDs (lsusb)
- [ ] Configure Udev Rules (/etc/udev/rules.d/51-android.rules)
- [ ] Reload Udev & Verify Device Connection
- [ ] User Group Permissions (plugdev / uucp)

## 1: Install ADB (Arch) -------------------------------

```bash
sudo pacman -S --needed android-tools
adb version
```

---

## 2: Identify Device Vendor / Product IDs (lsusb) -------------------------------

```bash
lsusb
```

Example output:
```
Bus 002 Device 007: ID 2717:ff48 Xiaomi Inc. Mi/Redmi series (MTP + ADB)
```

---

## 3: Configure Udev Rules (/etc/udev/rules.d/51-android.rules) -------------------------------

### Option A: Specific Device Rule (e.g. Xiaomi / Redmi)

```bash
cat <<'EOF' | sudo tee /etc/udev/rules.d/51-android.rules
# Xiaomi / Redmi (MTP + ADB)
SUBSYSTEM=="usb", ATTR{idVendor}=="2717", ATTR{idProduct}=="ff48", MODE="0666", GROUP="plugdev", SYMLINK+="android%n"

# Broader Xiaomi rule (covers most modes)
SUBSYSTEM=="usb", ATTR{idVendor}=="2717", MODE="0666", GROUP="plugdev"
EOF
```

### Option B: Community Rules (Covers all Android vendors)

```bash
sudo curl -fsSL https://raw.githubusercontent.com/M0Rf30/android-udev-rules/main/51-android.rules -o /etc/udev/rules.d/51-android.rules
```

---

## 4: Reload Udev & Verify Device Connection -------------------------------

Reload rules:

```bash
sudo udevadm control --reload-rules
sudo udevadm trigger
```

Unplug and replug the phone (enable USB Debugging in Android Developer Options).

Check connection:

```bash
adb devices
```

---

## 5: User Group Permissions (plugdev / uucp) -------------------------------

- If `plugdev` group does not exist on your system, either create it:
  ```bash
  sudo groupadd -f plugdev
  sudo usermod -aG plugdev $USER
  ```
- Or switch the rule to a group you use for USB device access (commonly `uucp` on Arch):
  ```bash
  sudo usermod -aG uucp $USER
  ```
- Re-login or run `newgrp <group>` for the changes to take effect.

