#
# ~/.profile (login shell; often symlinked from ~/.bash_profile)
#
# Notes Rules (Minimal) — comments only; see sibling docs for full spec.
#
# Quick index
# 1: PATH | core user bins and toolchain |
# 2: Readline | tmux-sessionizer and tmux attach |
# 3: Aliases | pacman fzf helpers |
# 4: X11 | xprofile for display and X apps |
# 5: Build flags | CMake/OpenMP llama and compilers |
# 6: Prompt | colored exit-status arrow |
# 7: Java | JDK 21 if installed |
# 8: Android | SDK NDK CMake Gradle paths |
# 9: Rust | cargo env |
# 10: Solana | CLI bin if present |
# 11: JS tooling | pnpm PATH |
# 12: fnm | Node version manager and cd hook |
# 13: Bun | JS runtime bin |
#
# Optional (uncomment if login shells should pull interactive rc):
# [[ -f ~/.bashrc ]] && . ~/.bashrc
#
# ---

# ## 1: PATH | core user bins and toolchain | ------------------------------------------
export PATH="$HOME/.local/scripts:$HOME/.local/bin:$HOME/.cargo/bin:/usr/local/go/bin:$PATH"

# ## 2: Readline | tmux-sessionizer and tmux attach | ------------------------------------------
# Ctrl-f: tmux new window running tmux-sessionizer
# Ctrl-t: attach to tmux or report no sessions
if [[ $- == *i* ]]; then
  bind '"\C-f":"tmux-sessionizer\n"'
  __tmux_quick_attach() {
    [[ -n "$TMUX" ]] && return 0
    command -v tmux >/dev/null 2>&1 || return 0
    if tmux list-sessions >/dev/null 2>&1; then
      tmux attach
    else
      echo "No tmux sessions"
    fi
  }
  bind -x '"\C-t":__tmux_quick_attach'
fi

# ## 3: Package pickers | pacman/paru skim popups | ------------------------------------------
__pkg_skim_preview_window='right:65%:wrap:hidden'
__pkg_skim_preview_bind='ctrl-p:toggle-preview,ctrl-/:change-preview-window(right:65%:wrap|down:45%:wrap|hidden),alt-a:select-all,alt-d:deselect-all'
__pkg_skim_header='tab: toggle | alt-a/d: all/none | ctrl-p: preview | ctrl-/: layout | enter: install'

__pkg_skim_opts=(
  --multi
  --bind="$__pkg_skim_preview_bind"
  --preview-window="$__pkg_skim_preview_window"
)

__pkg_preview() {
  local manager=$1
  local pkg=$2

  printf '%s\n\n' "$pkg"
  "$manager" -Si "$pkg" 2>/dev/null || true

  printf '\nFiles\n'
  "$manager" -Fl "$pkg" 2>/dev/null | awk '{print $2}' | sed -n '1,80p' || true
}
export -f __pkg_preview

parufzf() {
  command -v paru >/dev/null 2>&1 || {
    printf 'parufzf: paru is not installed\n' >&2
    return 1
  }
  command -v sk >/dev/null 2>&1 || {
    printf 'parufzf: skim (sk) is not installed\n' >&2
    return 1
  }

  local selected=()
  mapfile -t selected < <(
    paru -Slq | sk "${__pkg_skim_opts[@]}" \
      --prompt='paru > ' \
      --header="$__pkg_skim_header" \
      --preview='bash -lc '\''__pkg_preview paru "$1"'\'' _ {}'
  )

  ((${#selected[@]})) || return 0
  paru -S "${selected[@]}"
}

pacfzf() {
  command -v pacman >/dev/null 2>&1 || {
    printf 'pacfzf: pacman is not installed\n' >&2
    return 1
  }
  command -v sk >/dev/null 2>&1 || {
    printf 'pacfzf: skim (sk) is not installed\n' >&2
    return 1
  }

  local selected=()
  mapfile -t selected < <(
    pacman -Slq | sk "${__pkg_skim_opts[@]}" \
      --prompt='pacman > ' \
      --header="$__pkg_skim_header" \
      --preview='bash -lc '\''__pkg_preview pacman "$1"'\'' _ {}'
  )

  ((${#selected[@]})) || return 0
  sudo pacman -S "${selected[@]}"
}

# ## 4: X11 | xprofile for display and X apps | ------------------------------------------
. ~/.xprofile

# ## 5: Build flags | CMake/OpenMP llama and compilers | ------------------------------------------
export CMAKE_ARGS="-DLLAMA_CMAKE_ARGS='-DLLAMA_OPENBLAS=on'"
export CFLAGS="-fopenmp"
export CXXFLAGS="-fopenmp"
export LDFLAGS="-fopenmp"

# ## 6: Prompt | colored exit-status arrow | ------------------------------------------
PS1='\[\e[0;1;3$(($?==0?2:1))m\]›\[\e[0m\] '

# # ## 6: Prompt | colored exit-status arrow, cwd, git branch | ------------------------------------------
# if [[ $- == *i* ]]; then
#   __prompt_git() {
#     command -v git >/dev/null 2>&1 || return
#     git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return

#     local branch line marks staged=0 unstaged=0 untracked=0 ahead=0 behind=0
#     branch=$(git symbolic-ref --quiet --short HEAD 2>/dev/null) ||
#       branch=$(git rev-parse --short HEAD 2>/dev/null) ||
#       return

#     while IFS= read -r line; do
#       case "$line" in
#         '## '*)
#           [[ $line =~ ahead[[:space:]]([0-9]+) ]] && ahead=${BASH_REMATCH[1]}
#           [[ $line =~ behind[[:space:]]([0-9]+) ]] && behind=${BASH_REMATCH[1]}
#           ;;
#         '?? '*)
#           ((untracked++))
#           ;;
#         *)
#           [[ ${line:0:1} != ' ' ]] && ((staged++))
#           [[ ${line:1:1} != ' ' ]] && ((unstaged++))
#           ;;
#       esac
#     done < <(git status --porcelain=v1 --branch 2>/dev/null)

#     ((staged)) && marks+=" +$staged"
#     ((unstaged)) && marks+=" !$unstaged"
#     ((untracked)) && marks+=" ?$untracked"
#     ((ahead)) && marks+=" ⇡$ahead"
#     ((behind)) && marks+=" ⇣$behind"

#     printf '  %s%s' "$branch" "$marks"
#   }

#   PS1='\n\[\e[0;1;3$(($?==0?2:1))m\]❯\[\e[0m\] \[\e[0;34m\]󰉋 \w\[\e[0m\]\[\e[0;36m\]$(__prompt_git)\[\e[0m\] \[\e[0;90m\]\[\e[0m\] '
# fi

# ## 7: Java | JDK 21 if installed | ------------------------------------------
if [ -d /usr/lib/jvm/java-21-openjdk ]; then
  export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
  export PATH="$JAVA_HOME/bin:$PATH"
fi
# export JAVA_HOME=/usr/lib/jvm/java-17-openjdk/

# ## 8: Android | SDK NDK CMake Gradle paths | ------------------------------------------
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/emulator:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin
export ANDROID_NDK_HOME=$ANDROID_HOME/ndk/27.1.12297006
export PATH=$PATH:$ANDROID_HOME/cmake/3.22.1/bin
[ -d /usr/share/gradle ] && export GRADLE_HOME=/usr/share/gradle && export PATH=$GRADLE_HOME/bin:$PATH

# ## 9: Rust | cargo env | ------------------------------------------
. "$HOME/.cargo/env"

# ## 10: Solana | CLI bin if present | ------------------------------------------
[ -d "$HOME/.local/share/solana/install/active_release/bin" ] &&
  export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"

# ## 11: JS tooling | pnpm PATH | ------------------------------------------
export PNPM_HOME="${HOME}/.local/share/pnpm"
case ":${PATH}:" in *":${PNPM_HOME}:"*) ;; *) export PATH="${PNPM_HOME}:${PATH}" ;; esac

# ## 12: fnm | Node version manager and cd hook | ------------------------------------------
FNM_PATH="${HOME}/.local/share/fnm"
if [ -x "${FNM_PATH}/fnm" ]; then
  export PATH="${FNM_PATH}:${PATH}"
  eval "$(fnm env --shell bash)"
fi

if [[ $- == *i* ]] && command -v fnm >/dev/null 2>&1; then
  __fnm_use_if_file_found() {
    if [[ -f .node-version || -f .nvmrc || -f package.json ]]; then
      fnm use --silent-if-unchanged
    fi
  }
  __fnmcd() {
    \cd "$@" || return $?
    __fnm_use_if_file_found
  }
  alias cd='__fnmcd'
fi

# ## 13: Bun | JS runtime bin | ------------------------------------------
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
