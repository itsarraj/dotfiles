# ===== Variables =====
# Defaults
export EDITOR="${EDITOR:-nvim}"
export VISUAL="${VISUAL:-$EDITOR}"

# ## 1: PATH | core user bins and toolchain | ------------------------------------------
export PATH="$HOME/.local/scripts:$HOME/.local/bin:$HOME/.cargo/bin:/usr/local/go/bin:$PATH"
export EDITOR="${EDITOR:-nvim}"
export VISUAL="${VISUAL:-$EDITOR}"

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

# ## 3b: Editors | helix shorthand | ------------------------------------------
command -v helix >/dev/null 2>&1 && alias hx='helix'

# ## 4: X11 | xprofile for display and X apps | ------------------------------------------
. ~/.xprofile

# ## 5: Prompt | colored exit-status arrow | ------------------------------------------
PS1='\[\e[0;1;3$(($?==0?2:1))m\]›\[\e[0m\] '

# ## 6: Java | prefer system default JDK | ------------------------------------------
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

# ## 7: Android | SDK NDK CMake Gradle paths | ------------------------------------------
export ANDROID_HOME="$HOME/Android/Sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"

# Prefer SDK tools over system packages (e.g. /usr/bin/adb)
[ -d "$ANDROID_HOME/cmdline-tools/latest/bin" ] && export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
[ -d "$ANDROID_HOME/platform-tools" ] && export PATH="$ANDROID_HOME/platform-tools:$PATH"
[ -d "$ANDROID_HOME/emulator" ] && export PATH="$ANDROID_HOME/emulator:$PATH"
[ -d "$ANDROID_HOME/tools" ] && export PATH="$ANDROID_HOME/tools:$PATH"
[ -d "$ANDROID_HOME/tools/bin" ] && export PATH="$ANDROID_HOME/tools/bin:$PATH"
[ -d "$ANDROID_HOME/cmake/3.22.1/bin" ] && export PATH="$ANDROID_HOME/cmake/3.22.1/bin:$PATH"

if [ -d "$ANDROID_HOME/ndk/27.1.12297006" ]; then
  export ANDROID_NDK_HOME="$ANDROID_HOME/ndk/27.1.12297006"
fi

[ -d /usr/share/gradle ] && export GRADLE_HOME=/usr/share/gradle && export PATH="$GRADLE_HOME/bin:$PATH"

# ## 8: Rust | cargo env | ------------------------------------------
. "$HOME/.cargo/env"

# ## 9: Solana | CLI bin if present | ------------------------------------------
[ -d "$HOME/.local/share/solana/install/active_release/bin" ] &&
  export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"

# ## 10: JS tooling | pnpm PATH | ------------------------------------------
export PNPM_HOME="${HOME}/.local/share/pnpm"
case ":${PATH}:" in *":${PNPM_HOME}:"*) ;; *) export PATH="${PNPM_HOME}:${PATH}" ;; esac

# ## 11: fnm | Node version manager and cd hook | ------------------------------------------
FNM_PATH="${HOME}/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
  eval "$(fnm env --use-on-cd --shell bash)"
fi

# ## 12: Bun | JS runtime bin | ------------------------------------------
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# ===== Miniconda3 =====
[ -f /opt/miniconda3/etc/profile.d/conda.sh ] && source /opt/miniconda3/etc/profile.d/conda.sh

# ===== Ollama =====
export OLLAMA_NUM_PARALLEL=1
export OLLAMA_MAX_LOADED_MODELS=1
export OLLAMA_KEEP_ALIVE=30m
export OLLAMA_FLASH_ATTENTION=1

# ===== CUDA ==== 
export CUDA_HOME=/opt/cuda
export PATH=/opt/cuda/bin:$PATH

