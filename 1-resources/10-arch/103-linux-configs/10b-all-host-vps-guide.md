---
id: 20250711081945
title: allhost vps documentation from preisntalled arch. Error on update - community db failed to download, news/cleaning-up-old-repositories
date: 2025-07-11 08:19
type: reference # note | concept | snippet | bug | journal | reference
status: stable # draft | stable | evergreen
tags: []
links: []
---
# Log
- 2025-07-11 08:19 - Created note.

# Notes
# VPS Setup and Hardening Guide
- [ ] Arch Repository Cleanup ([community] deprecation fix)
- [ ] VPS SSH User & Key Setup
- [ ] VPS Production Bootstrap & Hardening (UFW, Fail2Ban, root disable)
- [ ] Core Services & Directory Layout (Docker, Nginx, Chrony)
- [ ] Monitoring, Backups & Daily Workflow
- [ ] allhost.io Netboot Installation & Static IP Setup

## 1: Arch Repository Cleanup ([community] Deprecation Fix) -------------------------------

- Reference: [Arch Linux News: Cleaning up old repositories](https://archlinux.org/news/cleaning-up-old-repositories)

I got the error saying `community` db failed to download on an old Arch Linux image from allhost.io.
The repository configuration in `/etc/pacman.conf` needs to be updated because `[community]` was merged into `[extra]`.

all I have to do is comment out [community] in /etc/pacman.conf.
```bash
sudo sed -i '/^\[community\]/,/^$/d' /etc/pacman.conf

# Comment the [community] header
sed -i '/^\[community\]/ s/^/#/' /etc/pacman.conf

# Comment the Include line under [community]
sed -i '/^#\[community\]/,/^$/ s/^Include/#Include/' /etc/pacman.conf

# Uncomment the [community] header
sed -i 's/^#\(\[community\]\)/\1/' /etc/pacman.conf

# Uncomment the Include line in the [community] section
sed -i '/^\[community\]/,/^$/ s/^#\(Include.*\)/\1/' /etc/pacman.conf
```

```markdown
https://archlinux.org/news/cleaning-up-old-repositories/
## Cleaning up old repositories
``2025-02-17 - Sven-Hendrik Haase``

Around two years ago, we've merged the [community] repository into [extra] as part of the git migration. In order to not break user setups, we kept these repositories around in an unused and empty state. We're going to clean up these old repositories on 2025-03-01.

On systems where `/etc/pacman.conf` still references the old [community] repository, `pacman -Sy` will return an error on trying to sync repository metadata.

The following deprecated repositories will be removed: [community], [community-testing], [testing], [testing-debug], [staging], [staging-debug].

Please make sure to remove all use of the aforementioned repositories from your `/etc/pacman.conf` (for which a `.pacnew` was shipped with `pacman>=6.0.2-7)`!
```

Run this command now 
`sudo pacman -Syuu`
there will be this error after update
```bash
:: Synchronizing package databases...
error: failed to synchronize all databases (unable to lock database)
then removed  the db.lck
```

```bash
sudo rm -f /var/lib/pacman/db.lck
sudo pacman -Syuu
```
got this error
PGP signature trust errors

```bash
sudo pacman -Sy archlinux-keyring --noconfirm
sudo rm -f /var/cache/pacman/pkg/*.pkg.tar.zst
sudo rm -r /etc/pacman.d/gnupg
sudo pacman-key --init
sudo pacman-key --populate archlinux
```

Run this command now 
`sudo pacman -Syuu`
there will be this error after update
```bash
Job for dbus-broker.service failed.
See "systemctl status dbus-broker.service" and "journalctl -xeu dbus-broker.service" for details.
error: command failed to execute correctly
```

to fix the above error, I will proceed with these commands
```bash
systemctl status dbus-broker.service
systemctl enable dbus-broker.service
systemctl restart dbus-broker.service
```

Now Update will work perfectly
```bash
sudo pacman -Syuu
```

---

## 2: VPS SSH User & Key Setup -------------------------------

Server:

- Provider: EPYC 9004 VPS
- OS: Arch Linux
- Hostname: `technetium`
- SSH user: `prod`

### 1. Verify SSH service

```bash
systemctl status sshd
systemctl start sshd
systemctl enable sshd
systemctl restart sshd
```

### 2. Create deploy user

```bash
useradd -m prod
passwd prod
usermod -s /bin/bash prod
grep prod /etc/passwd
```

Expected `/etc/passwd` shell ending:

```text
/bin/bash
```

Optional: Grant sudo access to the user.

```bash
usermod -aG wheel prod
```

Then enable sudo permissions for the `wheel` group by uncommenting the following line in the sudoers file:

```text
%wheel ALL=(ALL:ALL) ALL
```

If it does not work, edit the sudoers file using:

```bash
visudo
```

### 3. Add SSH public key

Run as `root` on the server:

```bash
mkdir -p /home/prod/.ssh
echo 'YOUR_PUBLIC_KEY' > /home/prod/.ssh/authorized_keys
chown -R prod:prod /home/prod/.ssh
chmod 700 /home/prod/.ssh
chmod 600 /home/prod/.ssh/authorized_keys
cat /home/prod/.ssh/authorized_keys
```

If root already has the correct key:

```bash
mkdir -p /home/prod/.ssh
cp /root/.ssh/authorized_keys /home/prod/.ssh/
chown -R prod:prod /home/prod/.ssh
chmod 700 /home/prod/.ssh
chmod 600 /home/prod/.ssh/authorized_keys
```

Permission reference:

```text
/home/prod/.ssh              -> 700
/home/prod/.ssh/authorized_keys -> 600
```

### 4. Connect from local machine

```bash
ssh prod@SERVER_IP
ssh -i ~/.ssh/id_ed25519 prod@SERVER_IP
```

For this VPS, replace `SERVER_IP` with `45.154.197.90` if that is still the current address.

### 5. Harden SSH

Edit:

```bash
nano /etc/ssh/sshd_config
```

Recommended settings:

```text
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
```

Restart SSH after confirming `prod` login works:

```bash
systemctl restart sshd
```

### 6. Debug SSH issues

Live logs:

```bash
journalctl -u sshd -f
```

Common error:

```text
Permission denied (publickey)
```

Check:

- public key exists in `/home/prod/.ssh/authorized_keys`
- `/home/prod/.ssh` is owned by `prod:prod`
- `.ssh` is `700` and `authorized_keys` is `600`
- `prod` shell is `/bin/bash`
- local client is using the right private key

### 7. Firewall and base packages

```bash
pacman -S ufw git curl wget vim tmux htop unzip docker docker-compose
ufw allow 22/tcp
ufw enable
ufw status
systemctl enable --now docker
usermod -aG docker prod
```

### 8. Initial checklist

- [x] SSH service enabled
- [x] `prod` user created
- [x] SSH key authentication configured
- [x] Root login disabled
- [x] Password authentication disabled
- [x] Firewall enabled
- [x] Docker installed

---

## 3: VPS Production Bootstrap & Hardening (UFW, Fail2Ban, root disable) -------------------------------

After fixing system updates and SSH access, perform the following baseline setup to prepare the VPS for production use.

---

### 3.1 Install Basic Utilities

These tools make server management much easier.

```bash
sudo pacman -S git curl wget htop unzip tar rsync
```

Optional editors:

```bash
sudo pacman -S nano vim
```

Useful tools:

| Tool            | Purpose            |
| --------------- | ------------------ |
| `git`           | code deployment    |
| `curl` / `wget` | downloading files  |
| `htop`          | process monitoring |
| `rsync`         | fast file transfer |
| `unzip`         | archive extraction |

---

### 3.2 Configure Firewall (UFW)

Install firewall:

```bash
sudo pacman -S ufw
```

Enable service:

```bash
sudo systemctl enable --now ufw
```

Allow SSH:

```bash
sudo ufw allow 22
```

Enable firewall:

```bash
sudo ufw enable
```

Check status:

```bash
sudo ufw status
```

Result:

```
22/tcp ALLOW Anywhere
```

---

### 3.3 Install Fail2Ban (SSH brute-force protection)

Fail2Ban blocks repeated failed login attempts.

Install:

```bash
sudo pacman -S fail2ban
```

Enable service:

```bash
sudo systemctl enable --now fail2ban
```

Check status:

```bash
sudo systemctl status fail2ban
```

---

### 3.4 Disable Root SSH Login

Root login over SSH should be disabled after confirming the `prod` user works.

Edit SSH config:

```
/etc/ssh/sshd_config
```

Set:

```
PermitRootLogin no
```

Restart SSH:

```bash
sudo systemctl restart sshd
```

---

## 4: Core Services & Directory Layout (Docker, Nginx, Chrony) -------------------------------

### 4.1 Create Standard Server Directory Structure

A clean structure helps maintain deployments.

```bash
sudo mkdir -p /srv/{apps,logs,backups,docker}
```

Recommended layout:

```
/srv
 ├─ apps
 ├─ docker
 ├─ logs
 └─ backups
```

Descriptions:

| Directory      | Purpose           |
| -------------- | ----------------- |
| `/srv/apps`    | application code  |
| `/srv/docker`  | container configs |
| `/srv/logs`    | centralized logs  |
| `/srv/backups` | backup storage    |

---

### 4.2 Install Docker (Optional but recommended)

Docker simplifies deployments.

Install:

```bash
sudo pacman -S docker docker-compose
```

Enable:

```bash
sudo systemctl enable --now docker
```

Allow `prod` to run docker:

```bash
sudo usermod -aG docker prod
```

Verify:

```bash
docker --version
```

---

### 4.3 Install Web Server (Nginx)

For reverse proxy and hosting applications.

Install:

```bash
sudo pacman -S nginx
```

Enable:

```bash
sudo systemctl enable --now nginx
```

Check status:

```bash
sudo systemctl status nginx
```

---

### 4.4 Enable Automatic Time Sync

Correct time is important for SSL and logs.

```bash
sudo timedatectl set-ntp true
```

Verify:

```bash
timedatectl status
```

---

## 5: Monitoring, Backups & Daily Workflow -------------------------------

### 5.1 Install Monitoring Tools

Useful for production diagnostics.

```bash
sudo pacman -S htop iotop iftop
```

Usage:

| Command | Purpose         |
| ------- | --------------- |
| `htop`  | CPU & RAM usage |
| `iotop` | disk activity   |
| `iftop` | network traffic |

---

### 5.2 Backup Strategy (Basic)

Example manual backup:

```bash
rsync -av /srv/apps /srv/backups/
```

Automated with cron:

```bash
crontab -e
```

Example daily backup:

```
0 2 * * * rsync -a /srv/apps /srv/backups/
```

---

### 5.3 Recommended Daily Workflow & Commands

```bash
ssh prod@45.154.197.90
```

Administrative commands:

```bash
sudo <command>
```

Deploy applications to:

```
/srv/apps
```

### Useful Commands Reference

| Task | Command |
| --- | --- |
| Check firewall status | `sudo ufw status verbose` |
| View blocked IPs | `sudo fail2ban-client status sshd` |
| Check system logs | `sudo journalctl -xe` |
| Check disk space | `df -h` |
| Check memory usage | `free -m` |

---

## 6: allhost.io Netboot Installation & Static IP Setup -------------------------------

### VPS Specifications
```
1 vCPU (EPYC 9004 "GENOA")
2GB DDR5 ECC RAM
32GB NVMe Storage
5TB Bandwidth @ 4Gbit Uplink
1 IPv4 + 1 IPv6
UK Location
Pricing Term: 1 Year
```

### Initial Server Setup
Set up the server name and hostname:
```
berufplattf
technetium.itsarraj.xyz
```

Choose the self ISO install option, then add netboot CD/DVD in media settings and restart to login via VNC (Virtual Network Computer).

### Netboot Installation Process

In VNC after restart, select Arch install. This uses `Netboot.xyz iPXE arch "kernel + initrd" setup` which provides a bootstrap shell (not full Arch ISO).

Based on your VPS data, fill these details in the iPXE prompt in VNC:

#### IPv4 Setup
```bash
set net0/ip 45.154.197.90
set net0/netmask 255.255.255.0
set net0/gateway 45.154.197.1
set dns 8.8.8.8
ifopen net0
chain --autofree https://boot.netboot.xyz
```

#### In case of TLS/HTTPS errors
```bash
chain --autofree http://boot.netboot.xyz
```

#### Optional IPv6 Setup
```bash
set net0/ip6 2a12:ab46:5344:d4::a
set net0/gateway6 2a12:ab46:5344::1
set dns6 2606:4700:4700::1111
ifopen net0
```

Then chain the boot menu as shown above.

### Testing Network Configuration
Inside the Arch Linux install environment:
- Test IPv6 connectivity: `ping6 ipv6.google.com`

### DNS Resolution Fix
If DNS resolution is broken in the bootstrap shell:
```bash
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 1.1.1.1" >> /etc/resolv.conf
```

---

