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

# ## 3: Package pickers | pacman/paru skim (simple) | ------------------------------------------
alias yayfzf="yay -Slq | fzf -m --preview 'cat <(yay -Si {1}) <(yay -Fl {1} | awk \"{print \$2}\")' | xargs -ro  yay -S"
alias pacfzf="sudo pacman -Sy; sudo pacman -Slq | fzf -m --preview 'cat <(pacman -Si {1}) <(pacman -Fl {1} | awk \"{print \$2}\")' | xargs -ro  pacman -S"
alias parufzf="paru -Slq | fzf -m --preview 'cat <(paru -Si {1}) <(paru -Fl {1} | awk \"{print \$2}\")' | xargs -ro  paru -S"
alias pacsk="sudo pacman -Sy; sudo pacman -Slq | sk -m --preview 'cat <(pacman -Si {}) <(pacman -Fl {} | awk \"{print \$2}\")' | xargs -ro pacman -S"
alias yaysk="yay -Slq | sk -m --preview 'cat <(yay -Si {}) <(yay -Fl {} | awk \"{print \$2}\")' | xargs -ro  yay -S"
alias parusk="paru -Slq | sk -m --preview 'cat <(paru -Si {}) <(paru -Fl {} | awk \"{print \$2}\")' | xargs -ro  paru -S"
# ## 4: X11 | xprofile for display and X apps | ------------------------------------------
. ~/.xprofile

# ## 5: Build flags | CMake/OpenMP llama and compilers | ------------------------------------------
export CMAKE_ARGS="-DLLAMA_CMAKE_ARGS='-DLLAMA_OPENBLAS=on'"
export CFLAGS="-fopenmp"
export CXXFLAGS="-fopenmp"
export LDFLAGS="-fopenmp"

# ## 6: Prompt | colored exit-status arrow | ------------------------------------------
PS1='\[\e[0;1;3$(($?==0?2:1))m\]›\[\e[0m\] '

# ## 7: Java | prefer system default JDK | ------------------------------------------
if [ -d /usr/lib/jvm/default ]; then
  export JAVA_HOME=/usr/lib/jvm/default
elif [ -d /usr/lib/jvm/default-runtime ]; then
  export JAVA_HOME=/usr/lib/jvm/default-runtime
elif [ -d /usr/lib/jvm/java-26-openjdk ]; then
  export JAVA_HOME=/usr/lib/jvm/java-26-openjdk
elif [ -d /usr/lib/jvm/java-21-openjdk ]; then
  export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
elif [ -d /usr/lib/jvm/java-17-openjdk ]; then
  export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
fi

if [ -n "${JAVA_HOME:-}" ] && [ -d "$JAVA_HOME/bin" ]; then
  export PATH="$JAVA_HOME/bin:$PATH"
fi

# ## 8: Android | SDK NDK CMake Gradle paths | ------------------------------------------
export ANDROID_HOME="$HOME/Android/Sdk"
[ -d "$ANDROID_HOME/emulator" ] && export PATH="$PATH:$ANDROID_HOME/emulator"
[ -d "$ANDROID_HOME/platform-tools" ] && export PATH="$PATH:$ANDROID_HOME/platform-tools"
[ -d "$ANDROID_HOME/cmdline-tools/latest/bin" ] && export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin"
export ANDROID_NDK_HOME=$ANDROID_HOME/ndk/27.1.12297006
[ -d "$ANDROID_HOME/cmake/3.22.1/bin" ] && export PATH="$PATH:$ANDROID_HOME/cmake/3.22.1/bin"
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
if [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
  eval "$(fnm env --shell bash)"
fi

eval "$(fnm env --use-on-cd --shell bash)"

# ## 13: Bun | JS runtime bin | ------------------------------------------
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

export PATH="/home/cesium/.local/share/solana/install/active_release/bin:$PATH"
