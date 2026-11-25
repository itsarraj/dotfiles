#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PKGLIST="${SCRIPT_DIR}/pkglist_seekersconnect_server.txt"

if [[ ! -f "${PKGLIST}" ]]; then
  echo "Package list not found: ${PKGLIST}" >&2
  exit 1
fi

if [[ "${EUID}" -eq 0 ]]; then
  echo "Run this script as your normal sudo user, not as root." >&2
  echo "Example: ./setup_seekersconnect_arch_server.sh" >&2
  exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
  echo "sudo is required." >&2
  exit 1
fi

echo "Updating system and installing SeekersConnect server packages..."
sudo pacman -Syu --needed --noconfirm
sudo pacman -S --needed --noconfirm - < "${PKGLIST}"

echo "Configuring Rust stable toolchain..."
rustup toolchain install stable
rustup default stable
export PATH="$HOME/.cargo/bin:$PATH"

echo "Initializing PostgreSQL data directory if needed..."
sudo install -d -o postgres -g postgres -m 0700 /var/lib/postgres/data
if [[ ! -s /var/lib/postgres/data/PG_VERSION ]]; then
  sudo -iu postgres initdb -D /var/lib/postgres/data
else
  echo "PostgreSQL data directory already exists; skipping initdb."
fi

echo "Enabling core runtime services..."
sudo systemctl enable --now sshd
sudo systemctl enable --now postgresql
sudo systemctl enable --now valkey
sudo systemctl enable --now nginx

echo "Enabling firewall with SSH, HTTP, and HTTPS allowed..."
sudo systemctl enable --now ufw
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw --force enable

echo "Setup complete."
echo
echo "Next steps:"
echo "1. Create PostgreSQL databases/users for universal-auth-service and matchmyresume-bff."
echo "2. Configure MinIO or external S3-compatible object storage for the BFF."
echo "3. Build Rust services with cargo build --release."
echo "4. Build the web frontend with npm run build and serve dist through nginx."
