#!/bin/bash
set -euo pipefail
# Arch Linux Custom Install Script with LUKS/LVM Encryption
# For UEFI systems with systemd-boot
# Enhanced with detailed step-by-step output and error handling

# Configuration - Customize these variables
HOSTNAME="chernobyl"
USERNAME="uranium"
TIMEZONE="Asia/Kolkata"
LOCALE="en_US.UTF-8"
KEYMAP="us"
EFI_SIZE="1G"
CRYPT_DEVICE_NAME="reich"
VG_NAME="land"
# Account passwords (stored in this file — leave empty to set manually with passwd)
ROOT_PASSWORD="arch"
USER_PASSWORD="arch"   # optional; if empty and ROOT_PASSWORD is set, user gets the same password as root
INSTALL_PKGS="base base-devel linux linux-lts linux-zen linux-firmware linux-headers linux-lts-headers linux-zen-headers cryptsetup lvm2 iwd man-db man-pages texinfo inetutils netctl dhcpcd networkmanager wpa_supplicant dialog network-manager-applet openssh"
# INSTALL_PKGS="base base-devel linux linux-lts linux-firmware linux-firmware-amdgpu linux-firmware-atheros linux-firmware-broadcom linux-firmware-cirrus linux-firmware-intel linux-firmware-mediatek linux-firmware-nvidia linux-firmware-other linux-firmware-radeon linux-firmware-realtek linux-firmware-whence linux-headers linux-lts-headers cryptsetup lvm2 iwd man-db man-pages texinfo inetutils netctl dhcpcd networkmanager wpa_supplicant dialog network-manager-applet openssh"

# Error handling function
error_exit() {
    echo "❌ ERROR: $1" >&2
    exit 1
}

# True when ROOT_PASSWORD or USER_PASSWORD is set in configuration
passwords_set_in_script() {
    [ -n "${ROOT_PASSWORD:-}" ] || [ -n "${USER_PASSWORD:-}" ]
}

# Set root and user passwords non-interactively when configured (chpasswd in chroot)
set_account_passwords() {
    if ! passwords_set_in_script; then
        echo "# [i] No ROOT_PASSWORD/USER_PASSWORD set — use passwd after install or set variables at top of script"
        return 0
    fi

    echo "# [i] Setting account passwords..."

    if [ -n "$ROOT_PASSWORD" ]; then
        if ! echo "root:${ROOT_PASSWORD}" | arch-chroot /mnt chpasswd; then
            error_exit "# [x] Failed to set root password"
        fi
        echo "# [✓] Root password set"
    fi

    local user_password="$USER_PASSWORD"
    if [ -z "$user_password" ] && [ -n "$ROOT_PASSWORD" ]; then
        user_password="$ROOT_PASSWORD"
    fi

    if [ -n "$user_password" ]; then
        if ! echo "${USERNAME}:${user_password}" | arch-chroot /mnt chpasswd; then
            error_exit "# [x] Failed to set password for $USERNAME"
        fi
        echo "# [✓] Password set for $USERNAME"
    fi
}

# Disk selection with detailed output
select_disk() {
    echo "# ===== STEP 1: DISK SELECTION ====="
    
    # List all disks
    echo "# [i] Available disks:"
    lsblk -d -p -n -l -o NAME,SIZE
    # Prompt user to select disk 
    read -p "# [?] Enter disk to install to (e.g., /dev/sda or /dev/nvme0n1): " DISK
    # Validate disk selection
    if [ ! -b "$DISK" ]; then
        error_exit "# [x] $DISK is not a valid block device"
    fi
    
    # Handle NVMe partition naming (nvme0n1p1, nvme0n1p2) vs regular drives (sda1, sda2) and set boot and lvm partitions
    #  if disk name contains nvme, then set boot and lvm partitions to nvme0n1p1 and nvme0n1p2
    #  else set boot and lvm partitions to sda1 and sda2
    #  print success message and boot and lvm partitions
    if [[ "$DISK" =~ nvme ]]; then
        BOOT_PARTITION="${DISK}p1"
        LVM_PARTITION="${DISK}p2"
    else
        BOOT_PARTITION="${DISK}1"
        LVM_PARTITION="${DISK}2"
    fi

    # Print success message and boot and lvm partitions
    echo "# [✓] Selected disk $DISK"
    echo "# [✓] Boot partition will be: $BOOT_PARTITION"
    echo "# [✓] LVM partition will be: $LVM_PARTITION"

    echo "# ===== STEP 1 COMPLETE: disk selection successful ====="
}

# Partitioning with detailed output and error handling
partition_disk() {
    echo "# ===== STEP 2: DISK PARTITIONING ====="

    # Partition the selected disk with GPT, EFI, and LVM partitions
    echo "# [i] Partitioning $DISK..."

    # Create GPT partition table on selected disk
    if ! parted -s "$DISK" mklabel gpt; then
        error_exit "# [x] Failed to create GPT partition table on $DISK"
    fi
    echo "# [✓] Created GPT partition table"

    # Create EFI partition (fat32, size from EFI_SIZE config)
    if ! parted -s "$DISK" mkpart primary fat32 1MiB "$EFI_SIZE"; then
        error_exit "# [x] Failed to create EFI partition"
    fi
    echo "# [✓] Created EFI partition ($EFI_SIZE)"

    # Set boot flag on EFI partition (partition 1)
    if ! parted -s "$DISK" set 1 boot on; then
        error_exit "# [x] Failed to set boot flag on partition 1"
    fi
    echo "# [✓] Set boot flag on EFI partition"

    # Create LVM partition using remaining disk space
    if ! parted -s "$DISK" mkpart primary ext4 "$EFI_SIZE" 100%; then
        error_exit "# [x] Failed to create LVM partition"
    fi
    echo "# [✓] Created LVM partition (remaining space)"

    # Set LVM flag on partition 2
    if ! parted -s "$DISK" set 2 lvm on; then
        error_exit "# [x] Failed to set LVM flag on partition 2"
    fi
    echo "# [✓] Set LVM flag on partition 2"

    # Verify and print final partition table
    echo "# [i] Final partition table:"
    parted -s "$DISK" print

    echo "# ===== STEP 2 COMPLETE: disk partitioning successful ====="
}

# Encryption setup with detailed output
setup_encryption() {
    echo "# ===== STEP 3: LUKS ENCRYPTION SETUP ====="

    # Format and open LUKS on the LVM partition
    echo "# [i] Setting up LUKS encryption on $LVM_PARTITION..."

    # Format partition with LUKS (interactive passphrase prompt)
    if ! cryptsetup luksFormat "$LVM_PARTITION"; then
        error_exit "# [x] Failed to format LUKS partition $LVM_PARTITION"
    fi
    echo "# [✓] LUKS partition formatted"

    # Open encrypted partition as /dev/mapper/$CRYPT_DEVICE_NAME
    if ! cryptsetup open "$LVM_PARTITION" "$CRYPT_DEVICE_NAME"; then
        error_exit "# [x] Failed to open LUKS partition $LVM_PARTITION"
    fi
    echo "# [✓] LUKS partition opened as $CRYPT_DEVICE_NAME"
    echo "# ===== STEP 3 COMPLETE: LUKS encryotion setup successful ====="
}

# LVM configuration with detailed output
setup_lvm() {
    echo "# ===== STEP 4: LVM CONFIGURATION ====="

    # Create physical volume, volume group, and logical volumes on LUKS device
    echo "# [i] Configuring LVM..."

    # Create physical volume on opened LUKS mapper device
    if ! pvcreate "/dev/mapper/$CRYPT_DEVICE_NAME"; then
        error_exit "# [x] Failed to create physical volume on /dev/mapper/$CRYPT_DEVICE_NAME"
    fi
    echo "# [✓] Physical volume created"

    # Create volume group using VG_NAME config
    if ! vgcreate "$VG_NAME" "/dev/mapper/$CRYPT_DEVICE_NAME"; then
        error_exit "# [x] Failed to create volume group $VG_NAME"
    fi
    echo "# [✓] Volume group $VG_NAME created"

    # Create root logical volume using all free space in volume group
    if ! lvcreate -l 100%FREE -n root "$VG_NAME"; then
        error_exit "# [x] Failed to create root logical volume"
    fi
    echo "# [✓] Root logical volume created"

    # Verify and print logical volumes
    echo "# [i] Logical volumes created:"
    lvs

    echo "# ===== STEP 4 COMPLETE: LVM configuration successful ====="
}

# Format filesystems with detailed output
format_filesystems() {
    echo "# ===== STEP 5: FILESYSTEM FORMATTING ====="

    # Format EFI boot partition and root logical volume
    echo "# [i] Formatting filesystems..."

    # Format EFI partition as FAT32
    if ! mkfs.fat -F32 "$BOOT_PARTITION"; then
        error_exit "# [x] Failed to format EFI partition $BOOT_PARTITION"
    fi
    echo "# [✓] EFI partition formatted (FAT32)"

    # Format root logical volume as ext4
    if ! mkfs.ext4 "/dev/$VG_NAME/root"; then
        error_exit "# [x] Failed to format root filesystem /dev/$VG_NAME/root"
    fi
    echo "# [✓] Root filesystem formatted (ext4)"

    # Reduce root LV by 256M to reserve space for e2scrub snapshots
    echo "# [i] Reserving space for e2scrub snapshots..."
    if ! lvreduce -L -256M --resizefs "/dev/$VG_NAME/root" -y; then
        echo "# [!] Failed to reduce root volume, continuing..."
    else
        echo "# [✓] Reserved 256M for e2scrub snapshots"
    fi

    echo "# ===== STEP 5 COMPLETE: filesystem formatting successful ====="
}

# Mount filesystems with detailed output
mount_filesystems() {
    echo "# ===== STEP 6: FILESYSTEM MOUNTING ====="

    # Mount root and EFI partitions under /mnt
    echo "# [i] Mounting filesystems..."

    # Mount root logical volume at /mnt
    if ! mount "/dev/$VG_NAME/root" /mnt; then
        error_exit "# [x] Failed to mount root filesystem /dev/$VG_NAME/root"
    fi
    echo "# [✓] Root filesystem mounted at /mnt"

    # Mount EFI partition at /mnt/boot
    mkdir -p /mnt/boot
    if ! mount "$BOOT_PARTITION" /mnt/boot; then
        error_exit "# [x] Failed to mount EFI partition $BOOT_PARTITION"
    fi
    echo "# [✓] EFI partition mounted at /mnt/boot"

    # Verify and print mounted filesystems
    echo "# [i] Mounted filesystems:"
    lsblk

    echo "# ===== STEP 6 COMPLETE: filesystem mounting successful ====="
}

# GPU detection and driver installation
install_gpu_drivers() {
    echo "# ===== GPU: DETECTION AND DRIVER INSTALLATION ====="

    # Detect GPU vendor (AMD, NVIDIA, Intel) via lspci
    local has_amd=false
    local has_nvidia=false
    local has_intel=false

    # Check for AMD GPU
    if lspci | grep -i "vga\|3d\|display" | grep -i "amd\|ati\|radeon" >/dev/null 2>&1; then
        has_amd=true
        echo "# [✓] Detected: AMD GPU"
    fi

    # Check for NVIDIA GPU
    if lspci | grep -i "vga\|3d\|display" | grep -i "nvidia" >/dev/null 2>&1; then
        has_nvidia=true
        echo "# [✓] Detected: NVIDIA GPU"
    fi

    # Check for Intel GPU
    if lspci | grep -i "vga\|3d\|display" | grep -i "intel" >/dev/null 2>&1; then
        has_intel=true
        echo "# [✓] Detected: Intel GPU"
    fi

    # Build graphics package list (mesa + vesa base, vendor-specific extras)
    local graphics_packages="mesa xf86-video-vesa"

    # Add AMD driver packages if detected
    if [ "$has_amd" = true ]; then
        graphics_packages="$graphics_packages xf86-video-amdgpu vulkan-radeon lib32-vulkan-radeon"
        echo "# [i] Adding AMD graphics packages"
    fi

    # Add NVIDIA driver packages if detected
    if [ "$has_nvidia" = true ]; then
        graphics_packages="$graphics_packages nvidia-dkms nvidia-utils nvidia-settings lib32-nvidia-utils"
        echo "# [i] Adding NVIDIA graphics packages"
    fi

    # Add Intel driver packages if detected
    if [ "$has_intel" = true ]; then
        graphics_packages="$graphics_packages xf86-video-intel vulkan-intel lib32-vulkan-intel"
        echo "# [i] Adding Intel graphics packages"
    fi

    # Install vendor-specific graphics packages via chroot
    if [ "$graphics_packages" != "mesa xf86-video-vesa" ]; then
        echo "# [i] Installing graphics drivers: $graphics_packages"
        if ! arch-chroot /mnt pacman -S --noconfirm $graphics_packages; then
            echo "# [!] Failed to install some graphics packages, continuing..."
        else
            echo "# [✓] Graphics drivers installed"
        fi
    else
        echo "# [i] No specific GPU detected, installing basic graphics support"
        if ! arch-chroot /mnt pacman -S --noconfirm mesa xf86-video-vesa; then
            echo "# [!] Failed to install basic graphics packages, continuing..."
        else
            echo "# [✓] Basic graphics support installed"
        fi
    fi

    # Print detected graphics hardware
    echo "# [i] Detected graphics hardware:"
    lspci | grep -i "vga\|3d\|display" || echo "# [i] No graphics hardware detected"
}

# Install system with detailed output
install_system() {
    echo "# ===== STEP 7: SYSTEM INSTALLATION ====="

    # Install base system packages into /mnt
    echo "# [i] Installing base system..."
    if ! pacstrap /mnt $INSTALL_PKGS; then
        error_exit "# [x] Failed to install base system packages"
    fi
    echo "# [✓] Base system packages installed"

    # Detect CPU vendor and install matching microcode package
    MICROCODE=""
    if lscpu | grep -qi "GenuineIntel"; then
        MICROCODE="intel-ucode"
    elif lscpu | grep -qi "AuthenticAMD"; then
        MICROCODE="amd-ucode"
    fi

    if [ -n "$MICROCODE" ]; then
        echo "# [i] Installing $MICROCODE..."
        if ! arch-chroot /mnt pacman -S --noconfirm $MICROCODE; then
            echo "# [!] Failed to install microcode, continuing..."
        else
            echo "# [✓] Microcode installed"
        fi
    fi

    # Generate fstab with UUIDs for persistent mounts
    echo "# [i] Generating fstab..."
    if ! genfstab -U /mnt >> /mnt/etc/fstab; then
        error_exit "# [x] Failed to generate fstab"
    fi
    echo "# [✓] fstab generated"

    # Detect GPU and install matching drivers (sub-step)
    echo "# [i] Detecting GPU and installing drivers..."
    install_gpu_drivers
    echo "# [✓] GPU driver step finished"

    echo "# ===== STEP 7 COMPLETE: system installation successful ====="
}

# Chroot configuration (passwords via set_account_passwords when ROOT_PASSWORD/USER_PASSWORD set)
configure_system() {
    echo "# ===== STEP 8: SYSTEM CONFIGURATION ====="

    # Configure installed system inside chroot (timezone, locale, boot, user, etc.)
    echo "# [i] Configuring system in chroot..."

    # Get LUKS UUID before entering chroot (needed for bootloader kernel options)
    LUKS_UUID=$(blkid -s UUID -o value $LVM_PARTITION)
    if [ -z "$LUKS_UUID" ]; then
        error_exit "# [x] Failed to get LUKS UUID"
    fi
    echo "# [✓] Retrieved LUKS UUID: $LUKS_UUID"

    arch-chroot /mnt /bin/bash <<EOF
    set -e  # Exit on error in chroot too

    # Initialize pacman keyring on fresh install
    echo "# [i] Initializing pacman keyring..."
    pacman-key --init
    pacman-key --populate archlinux
    echo "# [✓] Pacman keyring initialized"

    # Set timezone and sync hardware clock
    echo "# [i] Configuring timezone..."
    ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
    hwclock --systohc
    echo "# [✓] Timezone configured to $TIMEZONE"

    # Enable locale in locale.gen and set locale.conf
    echo "# [i] Configuring locale..."
    sed -i "s/^#${LOCALE} UTF-8/${LOCALE} UTF-8/" /etc/locale.gen
    locale-gen
    echo "LANG=$LOCALE" > /etc/locale.conf
    echo "# [✓] Locale configured to $LOCALE"

    # Set console keymap
    echo "# [i] Configuring keyboard..."
    echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf
    echo "# [✓] Keyboard configured to $KEYMAP"

    # Set console font (latarcyrheb-sun32 or fallback terminus)
    echo "# [i] Verifying console font..."
    if [ -f "/usr/share/kbd/consolefonts/latarcyrheb-sun32.psfu.gz" ]; then
        echo "FONT=latarcyrheb-sun32" >> /etc/vconsole.conf
        echo "# [✓] Console font set to latarcyrheb-sun32"
    else
        echo "# [!] Console font not found, installing terminus-font..."
        pacman -S --noconfirm terminus-font
        echo "FONT=ter-132n" >> /etc/vconsole.conf
        echo "# [✓] Console font set to ter-132n"
    fi

    # Set hostname and /etc/hosts entries
    echo "# [i] Configuring network..."
    echo "$HOSTNAME" > /etc/hostname
    echo "127.0.0.1 localhost" >> /etc/hosts
    echo "::1       localhost" >> /etc/hosts
    echo "127.0.1.1 $HOSTNAME.localdomain $HOSTNAME" >> /etc/hosts
    echo "# [✓] Network configured for hostname $HOSTNAME"

    # Configure mkinitcpio hooks for LUKS/LVM and regenerate initramfs
    echo "# [i] Configuring initramfs..."
    sed -i 's/^HOOKS=(.*)/HOOKS=(base systemd keyboard autodetect microcode modconf kms sd-vconsole block sd-encrypt lvm2 filesystems fsck)/' /etc/mkinitcpio.conf
    mkinitcpio -P
    echo "# [✓] Initramfs configured and generated"

    # Install systemd-boot and loader.conf
    echo "# [i] Installing bootloader..."
    bootctl install
    cat <<LOADER > /boot/loader/loader.conf
default 02-arch-lts
timeout 2
console-mode keep
editor yes
LOADER
    echo "# [✓] Bootloader installed"

    # Create systemd-boot entries for regular, LTS, and Zen kernels
    echo "# [i] Creating boot entries..."

    # Regular kernel entry with LUKS, LVM root, zswap options
    {
        echo "title Arch Linux Regular"
        echo "linux /vmlinuz-linux"

        # Add microcode initrd if installed
        if [ -f "/boot/intel-ucode.img" ]; then
            echo "initrd /intel-ucode.img"
        elif [ -f "/boot/amd-ucode.img" ]; then
            echo "initrd /amd-ucode.img"
        fi

        echo "initrd /initramfs-linux.img"
        echo "options rd.luks.name=$LUKS_UUID=$CRYPT_DEVICE_NAME root=/dev/$VG_NAME/root rw zswap.enabled=1 zswap.compressor=zstd zswap.zpool=zsmalloc zswap.max_pool_percent=30 zswap.shrinker_enabled=1"
    } > /boot/loader/entries/01-arch-regular.conf
    echo "# [✓] Regular kernel boot entry created"

    # LTS kernel entry with same LUKS/LVM/zswap options
    {
        echo "title Arch Linux LTS"
        echo "linux /vmlinuz-linux-lts"

        # Add microcode initrd if installed
        if [ -f "/boot/intel-ucode.img" ]; then
            echo "initrd /intel-ucode.img"
        elif [ -f "/boot/amd-ucode.img" ]; then
            echo "initrd /amd-ucode.img"
        fi

        echo "initrd /initramfs-linux-lts.img"
        echo "options rd.luks.name=$LUKS_UUID=$CRYPT_DEVICE_NAME root=/dev/$VG_NAME/root rw zswap.enabled=1 zswap.compressor=zstd zswap.zpool=zsmalloc zswap.max_pool_percent=30 zswap.shrinker_enabled=1"
    } > /boot/loader/entries/02-arch-lts.conf
    echo "# [✓] LTS kernel boot entry created"

    # Zen kernel entry with same LUKS/LVM/zswap options
    {
        echo "title Arch Linux Zen"
        echo "linux /vmlinuz-linux-zen"

        # Add microcode initrd if installed
        if [ -f "/boot/intel-ucode.img" ]; then
            echo "initrd /intel-ucode.img"
        elif [ -f "/boot/amd-ucode.img" ]; then
            echo "initrd /amd-ucode.img"
        fi

        echo "initrd /initramfs-linux-zen.img"
        echo "options rd.luks.name=$LUKS_UUID=$CRYPT_DEVICE_NAME root=/dev/$VG_NAME/root rw zswap.enabled=1 zswap.compressor=zstd zswap.zpool=zsmalloc zswap.max_pool_percent=30 zswap.shrinker_enabled=1"
    } > /boot/loader/entries/03-arch-zen.conf
    echo "# [✓] Zen kernel boot entry created"

    # Enable network services for boot
    echo "# [i] Enabling network services..."
    if ! systemctl enable systemd-networkd.service; then
        echo "# [!] Failed to enable systemd-networkd.service"
    else
        echo "# [✓] systemd-networkd enabled"
    fi

    if ! systemctl enable systemd-resolved.service; then
        echo "# [!] Failed to enable systemd-resolved.service"
    else
        echo "# [✓] systemd-resolved enabled"
    fi

    if ! systemctl enable NetworkManager.service; then
        echo "# [!] Failed to enable NetworkManager.service"
    else
        echo "# [✓] NetworkManager enabled"
    fi

    if ! systemctl enable dhcpcd.service; then
        echo "# [!] Failed to enable dhcpcd.service"
    else
        echo "# [✓] dhcpcd enabled"
    fi

    if ! systemctl enable sshd.service; then
        echo "# [!] Failed to enable sshd.service"
    else
        echo "# [✓] sshd enabled"
    fi

    echo "# [✓] Network services step finished"

    # Create wheel user (password set by set_account_passwords if configured)
    echo "# [i] Creating user account..."
    if ! useradd -m -G wheel "$USERNAME"; then
        echo "# [x] Failed to create user $USERNAME"
        exit 1
    fi
    echo "# [✓] User $USERNAME created"

    # Verify user exists in chroot
    if ! id "$USERNAME" >/dev/null 2>&1; then
        echo "# [x] User $USERNAME was not created properly"
        exit 1
    fi
    echo "# [✓] User $USERNAME verified in system"

    # Allow wheel group sudo access
    echo "# [i] Configuring sudo..."
    echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers
    echo "# [✓] Sudo configured for wheel group"
EOF

    # Check chroot configuration exited successfully
    if [ $? -ne 0 ]; then
        error_exit "# [x] Failed to configure system in chroot"
    fi

    # Verify user exists in installed system (outside chroot)
    echo "# [i] Verifying user creation..."
    if ! arch-chroot /mnt id "$USERNAME" >/dev/null 2>&1; then
        error_exit "# [x] User $USERNAME was not created successfully"
    fi
    echo "# [✓] User $USERNAME verified in installed system"

    # Print user id and group membership
    echo "# [i] User information:"
    arch-chroot /mnt id "$USERNAME"
    arch-chroot /mnt groups "$USERNAME"

    set_account_passwords

    echo "# ===== STEP 8 COMPLETE: system configuration successful ====="
}

# Final steps with detailed output
finalize() {
    echo "# ===== STEP 9: FINALIZATION ====="
    echo "# [✓] Installation complete!"
    echo ""
    echo "# [i] Summary:"
    echo "# [✓]   Disk: $DISK"
    echo "# [✓]   Boot partition: $BOOT_PARTITION"
    echo "# [✓]   LVM partition: $LVM_PARTITION"
    echo "# [✓]   Hostname: $HOSTNAME"
    echo "# [✓]   Username: $USERNAME"
    echo "# [✓]   Timezone: $TIMEZONE"
    echo "# [✓]   Locale: $LOCALE"
    echo ""
    if passwords_set_in_script; then
        echo "# [✓] Account passwords set from ROOT_PASSWORD / USER_PASSWORD"
    else
        echo "# [!] Before rebooting, you MUST set passwords!"
        echo ""
        echo "# [i] Set passwords now (filesystem still mounted):"
        echo "# [i]   Root:  arch-chroot /mnt passwd"
        echo "# [i]   User:  arch-chroot /mnt passwd $USERNAME"
        echo ""
        echo "# [!] Reboot without passwords — you will not be able to log in"
        echo ""
    fi
    echo "# [i] Finish install:"
    echo "# [i]   umount -R /mnt"
    echo "# [i]   reboot"
    echo ""
    echo "# [i] Remove installation media before rebooting"
    echo "# ===== STEP 9 COMPLETE: installation finalized successfully ====="
}

# Main installation process
main() {
    set -e  # Exit on error
    select_disk
    partition_disk
    setup_encryption
    setup_lvm
    format_filesystems
    mount_filesystems
    install_system
    configure_system
    finalize
}

# Run main function
main
