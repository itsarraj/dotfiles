
export PATH="$HOME/.local/scripts:$PATH"

# Where should I put you?
bind '"\C-f":"tmux-sessionizer\n"'


alias yayfzf="yay -Slq | fzf -m --preview 'cat <(yay -Si {1}) <(yay -Fl {1} | awk \"{print \$2}\")' | xargs -ro  yay -S"
alias pacfzf="sudo pacman -Sy; sudo pacman -Slq | fzf -m --preview 'cat <(yay -Si {1}) <(yay -Fl {1} | awk \"{print \$2}\")' | xargs -ro  yay -S"

export PATH="$HOME/.local/bin:$PATH"
. ~/.xprofile

