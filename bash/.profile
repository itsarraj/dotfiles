#
# ~/.bash_profile
#

# [[ -f ~/.bashrc ]] && . ~/.bashrc

export PATH="$HOME/.local/scripts:$PATH"

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


alias yayfzf="yay -Slq | fzf -m --preview 'cat <(yay -Si {1}) <(yay -Fl {1} | awk \"{print \$2}\")' | xargs -ro  yay -S"
alias pacfzf="sudo pacman -Sy; sudo pacman -Slq | fzf -m --preview 'cat <(yay -Si {1}) <(yay -Fl {1} | awk \"{print \$2}\")' | xargs -ro  yay -S"

export PATH="$HOME/.local/bin:$PATH"
source ~/.xprofile


export CMAKE_ARGS="-DLLAMA_CMAKE_ARGS='-DLLAMA_OPENBLAS=on'"
export CFLAGS="-fopenmp"
export CXXFLAGS="-fopenmp"
export LDFLAGS="-fopenmp"





# PS1='[\u@\h \W]\$ '
# PS1='[\W]\$ '
# PS1='[username@hostname \W]\$ '
# PS1='[usernamea@hostname \W]\$ '
# PS1+='\[\e[0;1;3$(($??5:3))m\]\$\[\e[0m\] '
# PS1='\[\e[0;1;3$(($?==0?2:1))m\]\$\[\e[0m\] '
PS1='\[\e[0;1;3$(($?==0?2:1))m\]›\[\e[0m\] '
# PS1='\[\e[1;34m\]\W\[\e[0m\] \[\e[0;1;3$(($?==0?2:1))m\]\$\[\e[0m\] '
# PS1='\[\e[1;34m\]\W\[\e[0m\] \[\e[0;1;3$(($?==0?2:1))m\]›\[\e[0m\] '

export JAVA_HOME=/usr/lib/jvm/java-17-openjdk/
export PATH=$JAVA_HOME/bin:$PATH
export PATH=$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$PATH

export ANDROID_HOME=$HOME/Android/Sdk
export NDK_HOME="$ANDROID_HOME/ndk/29.0.14033849"
export PATH="$PATH:$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools"

export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools
___MY_VMOPTIONS_SHELL_FILE="${HOME}/.jetbrains.vmoptions.sh"; if [ -f "${___MY_VMOPTIONS_SHELL_FILE}" ]; then . "${___MY_VMOPTIONS_SHELL_FILE}"; fi
. "$HOME/.cargo/env"

export PATH="/home/plutonium/.local/share/solana/install/active_release/bin:$PATH"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

