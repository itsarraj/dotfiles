#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
TARGET_DIR="${TARGET_DIR:-$HOME}"

RESTOW=0
DELETE=0
DRY_RUN=1
MODE_SET=0

usage() {
  cat <<'EOF'
Usage: stow-select.sh [options] [packages...]

Options:
  --apply        Actually run stow (default is --dry-run)
  -n, --dry-run  Preview links only (default)
  -R, --restow   Use `stow -R`
  -D, --delete   Use `stow -D` (remove links)
  -h, --help     Show this help

If no mode flags are provided, you will be prompted to pick a mode.
If no packages are provided, you will be prompted to pick from a list.
When prompted: type `0` or `All` to stow everything, or type `q` to finish with what you picked.
EOF
}

args=()
while (($#)); do
  case "$1" in
    --apply) DRY_RUN=0; RESTOW=0; DELETE=0; MODE_SET=1; shift ;;
    -n|--dry-run) DRY_RUN=1; RESTOW=0; DELETE=0; MODE_SET=1; shift ;;
    -R|--restow) DRY_RUN=0; RESTOW=1; DELETE=0; MODE_SET=1; shift ;;
    -D|--delete) DRY_RUN=0; RESTOW=0; DELETE=1; MODE_SET=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) args+=("$1"); shift ;;
  esac
done

if ((${MODE_SET} == 0 && ${#args[@]} == 0)); then
  PS3="Pick stow mode: "
  select mode in "dry-run" "stow" "restow" "delete"; do
    case "$mode" in
      "dry-run") DRY_RUN=1; RESTOW=0; DELETE=0; break ;;
      "stow") DRY_RUN=0; RESTOW=0; DELETE=0; break ;;
      "restow") DRY_RUN=0; RESTOW=1; DELETE=0; break ;;
      "delete") DRY_RUN=0; RESTOW=0; DELETE=1; break ;;
      "") continue ;;
      *) continue ;;
    esac
  done
fi

cd "$DOTFILES_DIR"

# List your dotfile "packages" (directories) in one array for easy selection.
packages=(
  alacritty bash bin conda gtk-2.0 gtk-3.0 gtk-4.0 i3 kwalletrc lf newsboat nvim picom tmux xprofile xresources zathura
)

selected=()

if ((${#args[@]} > 0)); then
  selected=("${args[@]}")
else
  PS3="Pick a package number or name, '0'/'All' for everything, or type 'q' to finish: "
  select opt in "${packages[@]}" "All" "END"; do
    # Bash `select` is 1-indexed; typing `0` yields an empty `$opt` but still
    # sets `$REPLY`. We interpret that as "stow everything".
    if [[ "${REPLY:-}" == "0" ]]; then
      selected=("${packages[@]}")
      break
    fi
    # Some shells/terminals may populate `$REPLY` with the literal token.
    if [[ "${REPLY:-}" == "All" ]]; then
      selected=("${packages[@]}")
      break
    fi
    if [[ "${REPLY:-}" == "END" ]]; then
      break
    fi
    if [[ "${REPLY:-}" == "q" || "${REPLY:-}" == "Q" ]]; then
      break
    fi
    # Allow typing the package name directly (not just the numeric index).
    for p in "${packages[@]}"; do
      if [[ "${REPLY:-}" == "$p" ]]; then
        selected+=("$p")
        opt="" # suppress the default label-based fallthrough
        break
      fi
    done
    case "$opt" in
      "All") selected=("${packages[@]}"); break ;;
      "END") break ;;
      "") continue ;;
      *) selected+=("$opt") ;;
    esac
  done
fi

if ((${#selected[@]} == 0)); then
  echo "No packages selected."
  exit 0
fi

stow_flags=()
if (($DRY_RUN)); then
  stow_flags+=(-n)
fi
if (($RESTOW)); then
  stow_flags+=(-R)
fi
if (($DELETE)); then
  stow_flags+=(-D)
fi

echo "Dotfiles dir: $DOTFILES_DIR"
echo "Target dir:  $TARGET_DIR"
echo "Mode:         $(
  if (($DELETE)); then echo "delete";
  elif (($RESTOW)); then echo "restow";
  else echo "stow";
  fi
)"
echo "Dry-run:      $DRY_RUN"
echo "Packages:     ${selected[*]}"

stow "${stow_flags[@]}" -t "$TARGET_DIR" "${selected[@]}"

