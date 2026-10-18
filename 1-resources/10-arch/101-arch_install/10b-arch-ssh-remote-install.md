---
id: 20260914121106
title: Arch Install - SSH Setup for Remote Installation
date: 2026-09-14 12:11
type: note # note | concept | snippet | bug | journal | reference
status: stable # draft | stable | evergreen
tags: [archlinux, installation, ssh]
links: [[10b-arch-simple-install-guide],[10b-arch-lvm-install-guide]]
---
# Log
- 2026-09-14 12:11 - Extracted from install guides so both simple and LVM share one copy.

# Notes

# SSH Setup (for Remote Installation)

Enable SSH access for remote installation management:

```bash
# Set root password (required for SSH login)
passwd

# Enable root login in SSH config
vim /etc/ssh/sshd_config
# Change: PermitRootLogin yes

# Start SSH service
systemctl start sshd
```

Check network interfaces and current IP addresses:

```bash
ip a
```

## Connecting from Another Machine

If your host and target machines are on the same network, connect directly:

```bash
ssh root@192.168.1.100
```

If on different subnets (e.g., laptop on 192.168.1.x/24 and target on 192.168.32.x/24), set up Tailscale VPN first:

```bash
pacman -Sy
pacman -S curl
curl -fsSL https://tailscale.com/install.sh | sh
tailscale up
# Visit the authentication URL shown to complete setup
```

Then connect using the Tailscale IP:

```bash
ssh root@100.x.x.x  # Use Tailscale IP for cross-subnet connections
```

For security options when connecting:

```bash
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@ip.address
```

## SSH Security Notes
- Root login should be disabled in production (`PermitRootLogin no`)
- Use SSH keys instead of passwords for security
- Consider changing default SSH port (22) for additional security
- Enable SSH after creating regular user account
