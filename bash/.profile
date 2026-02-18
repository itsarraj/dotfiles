#
# ~/.bash_profile
#

# [[ -f ~/.bashrc ]] && . ~/.bashrc


# Consolidated PATH exports for better performance
export PATH="$HOME/.local/scripts:$HOME/.local/bin:$HOME/.cargo/bin:/usr/local/go/bin:$PATH"

# Where should I put you?
# tmux shortcuts (interactive shells only):
# - Ctrl-f: launch tmux-sessionizer to pick a project and jump to a session
# - Ctrl-t: attach to last session or create 'default' in current directory
if [[ $- == *i* ]]; then
bind '"\C-f":"tmux-sessionizer\n"'
# Helper used by Ctrl-t to quickly attach to tmux
__tmux_quick_attach() {
    # Already in tmux? Do nothing
    [[ -n "$TMUX" ]] && return 0
    # tmux not installed? Do nothing
    command -v tmux >/dev/null 2>&1 || return 0
    # Attach to existing session; if none, just echo and return
    if tmux list-sessions >/dev/null 2>&1; then
        tmux attach
    else
        echo "No tmux sessions"
    fi
}
# Bind Ctrl-t to quick attach
bind -x '"\C-t":__tmux_quick_attach'
fi


alias parufzf="paru -Slq | fzf -m --preview 'cat <(paru -Si {1}) <(paru -Fl {1} | awk \"{print \$2}\")' | xargs -ro  paru -S"
alias pacfzf="sudo pacman -Sy; sudo pacman -Slq | fzf -m --preview 'cat <(yay -Si {1}) <(yay -Fl {1} | awk \"{print \$2}\")' | xargs -ro  yay -S"
. ~/.xprofile
source ~/.xprofile


export CMAKE_ARGS="-DLLAMA_CMAKE_ARGS='-DLLAMA_OPENBLAS=on'"
export CFLAGS="-fopenmp"
export CXXFLAGS="-fopenmp"
export LDFLAGS="-fopenmp"

PS1='\[\e[0;1;3$(($?==0?2:1))m\]›\[\e[0m\] '

export JAVA_HOME=/usr/lib/jvm/java-21-openjdk/
# export JAVA_HOME=/usr/lib/jvm/java-17-openjdk/
export PATH=$JAVA_HOME/bin:$PATH
# export PATH=$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$PATH

# Lazy-load Android SDK for faster startup
android_sdk() {
export ANDROID_HOME=$HOME/Android/Sdk
    export PATH=$PATH:$ANDROID_HOME/emulator:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools
    unset -f android_sdk
}
#
# export GRADLE_HOME=/usr/share/gradle
# export PATH=$GRADLE_HOME/bin:$PATH

___MY_VMOPTIONS_SHELL_FILE="${HOME}/.jetbrains.vmoptions.sh"; if [ -f "${___MY_VMOPTIONS_SHELL_FILE}" ]; then . "${___MY_VMOPTIONS_SHELL_FILE}"; fi

. "$HOME/.cargo/env"

export PATH="/home/plutonium/.local/share/solana/install/active_release/bin:$PATH"

# Lazy-load NVM for faster shell startup (50-70% improvement)
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
nvm() {
    unset -f nvm
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" --no-use
    nvm "$@"
}

export PATH=$PATH:/usr/local/go/bin
