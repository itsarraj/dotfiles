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

# ## 3: Aliases | pacman fzf helpers | ------------------------------------------
alias parufzf="paru -Slq | fzf -m --preview 'cat <(paru -Si {1}) <(paru -Fl {1} | awk \"{print \$2}\")' | xargs -ro  paru -S"
alias pacfzf="sudo pacman -Sy; sudo pacman -Slq | fzf -m --preview 'cat <(yay -Si {1}) <(yay -Fl {1} | awk \"{print \$2}\")' | xargs -ro  yay -S"

# ## 4: X11 | xprofile for display and X apps | ------------------------------------------
. ~/.xprofile

# ## 5: Build flags | CMake/OpenMP llama and compilers | ------------------------------------------
export CMAKE_ARGS="-DLLAMA_CMAKE_ARGS='-DLLAMA_OPENBLAS=on'"
export CFLAGS="-fopenmp"
export CXXFLAGS="-fopenmp"
export LDFLAGS="-fopenmp"

# ## 6: Prompt | colored exit-status arrow | ------------------------------------------
PS1='\[\e[0;1;3$(($?==0?2:1))m\]›\[\e[0m\] '

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
