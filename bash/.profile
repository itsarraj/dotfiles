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
PS1='[username@hostname \W]\$ '


export JAVA_HOME=/usr/lib/jvm/java-17-openjdk/

export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools
___MY_VMOPTIONS_SHELL_FILE="${HOME}/.jetbrains.vmoptions.sh"; if [ -f "${___MY_VMOPTIONS_SHELL_FILE}" ]; then . "${___MY_VMOPTIONS_SHELL_FILE}"; fi
. "$HOME/.cargo/env"
