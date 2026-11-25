#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKGLIST="$SCRIPT_DIR/pkglist.txt"
PKGLIST_AUR="$SCRIPT_DIR/pkglist_aur.txt"
PKGLIST_UNIFIED="$SCRIPT_DIR/pkglist_unified.txt"
PKGLIST_AUR_UNIFIED="$SCRIPT_DIR/pkglist_aur_unified.txt"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[+]${NC} $*"; }
warn()  { echo -e "${YELLOW}[!]${NC} $*"; }
error() { echo -e "${RED}[-]${NC} $*"; }

install_paru() {
    if command -v paru &>/dev/null; then
        info "paru already installed"
        return
    fi
    info "installing paru from AUR..."
    sudo pacman -S --needed --noconfirm git base-devel
    tmpdir=$(mktemp -d)
    git clone https://aur.archlinux.org/paru.git "$tmpdir/paru"
    (cd "$tmpdir/paru" && makepkg -si --noconfirm)
    rm -rf "$tmpdir"
}

install_official() {
    local list="$1"
    if [[ ! -f "$list" ]]; then
        error "file not found: $list"
        return 1
    fi
    local pkgs
    pkgs=$(grep -v '^#\|^$' "$list" | tr '\n' ' ')
    info "installing official packages from $list..."
    sudo pacman -S --needed --noconfirm $pkgs
}

install_aur() {
    local list="$1"
    if [[ ! -f "$list" ]]; then
        error "file not found: $list"
        return 1
    fi
    local pkgs
    pkgs=$(grep -v '^#\|^$' "$list" | tr '\n' ' ')
    info "installing AUR packages from $list..."
    paru -S --needed --noconfirm $pkgs
}

generate_lists() {
    info "generating package lists from current system..."
    pacman -Qqen > "$PKGLIST"
    pacman -Qqem > "$PKGLIST_AUR"
    info "wrote $PKGLIST ($(wc -l < "$PKGLIST") packages)"
    info "wrote $PKGLIST_AUR ($(wc -l < "$PKGLIST_AUR") packages)"
}

usage() {
    cat <<EOF
usage: $(basename "$0") [command] [args]

commands:
  install               install from pkglist.txt + pkglist_aur.txt
  install-unified       install from pkglist_unified.txt + pkglist_aur_unified.txt
  install <file>        install from a specific package list file
  install <pkg> ...     install specific packages (auto-detects repo/AUR)
  generate              regenerate pkglist.txt and pkglist_aur.txt from system
  help                  show this help

examples:
  $(basename "$0") install
  $(basename "$0") install pkglist_unified.txt
  $(basename "$0") install-unified
  $(basename "$0") install vim git htop
  $(basename "$0") generate
EOF
}

cmd_install_packages() {
    for pkg in "$@"; do
        if pacman -Q "$pkg" &>/dev/null; then
            warn "$pkg already installed"
            continue
        fi
        if pacman -Si "$pkg" &>/dev/null 2>&1; then
            sudo pacman -S --needed --noconfirm "$pkg"
        else
            paru -S --needed --noconfirm "$pkg"
        fi
    done
}

main() {
    local cmd="${1:-help}"
    shift || true

    case "$cmd" in
        install)
            if [[ $# -eq 0 ]]; then
                info "syncing repos..."
                sudo pacman -Sy
                install_official "$PKGLIST"
                install_paru
                install_aur "$PKGLIST_AUR"
                info "done"
            elif [[ -f "$1" ]]; then
                sudo pacman -Sy
                if [[ "$1" == *aur* ]]; then
                    install_paru
                    install_aur "$1"
                else
                    install_official "$1"
                fi
            else
                install_paru
                cmd_install_packages "$@"
            fi
            ;;
        install-unified)
            info "syncing repos..."
            sudo pacman -Sy
            install_official "$PKGLIST_UNIFIED"
            install_paru
            install_aur "$PKGLIST_AUR_UNIFIED"
            info "done"
            ;;
        generate)
            generate_lists
            ;;
        help|--help|-h)
            usage
            ;;
        *)
            error "unknown command: $cmd"
            usage
            exit 1
            ;;
    esac
}

main "$@"
