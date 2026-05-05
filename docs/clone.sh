# BrodieRobertson : https://github.com/BrodieRobertson/dotfiles.git
# johnsonjh : https://github.com/johnsonjh/dotfiles.git
# thelinuxcast : https://gitlab.com/thelinuxcast/my-dots.git
# ThePrimeagen : https://github.com/ThePrimeagen/.dotfiles.git
# tjdevries : https://github.com/tjdevries/config_manager.git
# end : 0

#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

FORCE="${1-}"
file="${BASH_SOURCE[0]}"

trim() { # trims leading + trailing whitespace
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

while IFS= read -r line; do
  [ -z "${line}" ] && continue
  if [[ "${line}" =~ ^#?[[:space:]]*end[[:space:]]*:[[:space:]]*0[[:space:]]*$ ]]; then
    break
  fi

  entry="${line#\#}"
  entry="$(trim "$entry")"

  name="$(trim "${entry%%:*}")"
  url="$(trim "${entry#*:}")"
  dest="${SCRIPT_DIR}/${name}"

  if [ -e "${dest}" ] && [ "${FORCE}" != "--force" ]; then
    echo "Skipping ${name} (exists): ${dest}"
    continue
  fi
  if [ "${FORCE}" == "--force" ] && [ -e "${dest}" ]; then
    rm -rf "${dest}"
  fi

  echo "Cloning ${name} -> ${dest} (depth 1)"
  git clone --depth 1 --single-branch "${url}" "${dest}"
done < "${file}"