#
# ~/.bash_profile
#

# [[ -f ~/.bashrc ]] && . ~/.bashrc

export PATH="$HOME/.local/scripts:$PATH"

# Where should I put you?
bind '"\C-f":"tmux-sessionizer\n"'

alias yayfzf="yay -Slq | fzf -m --preview 'cat <(yay -Si {1}) <(yay -Fl {1} | awk \"{print \$2}\")' | xargs -ro  yay -S"
alias pacfzf="sudo pacman -Sy; sudo pacman -Slq | fzf -m --preview 'cat <(yay -Si {1}) <(yay -Fl {1} | awk \"{print \$2}\")' | xargs -ro  yay -S"

export PATH="$HOME/.local/bin:$PATH"
source ~/.xprofile

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

export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools
___MY_VMOPTIONS_SHELL_FILE="${HOME}/.jetbrains.vmoptions.sh"; if [ -f "${___MY_VMOPTIONS_SHELL_FILE}" ]; then . "${___MY_VMOPTIONS_SHELL_FILE}"; fi
. "$HOME/.cargo/env"
