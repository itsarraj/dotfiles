# dotfiles

Personal config files, managed with [GNU Stow](https://www.gnu.org/software/stow/). Each
top-level directory is a stow "package" containing the files as they should appear relative
to `$HOME`.

## Setup on a new machine

```sh
sudo pacman -S stow   # or your distro's equivalent
git clone git@github.com:itsarraj/dotfiles.git ~/dotfiles
cd ~/dotfiles
./stow-select.sh
```

`stow-select.sh` prompts for a mode (dry-run / stow / restow / delete) and lets you pick
which packages to link, or link everything at once. Flags also work non-interactively, e.g.:

```sh
./stow-select.sh --apply nvim tmux git
./stow-select.sh -R alacritty   # restow after editing a package
```

## Packages

alacritty, bash, bin, code (VS Code), conda, cursor, git, gtk-2.0/3.0/4.0, helix, i3,
kwalletrc, lf, newsboat, nvim, picom, tmux, xprofile, xresources, zathura.

## Notes

- `docs/` holds other people's dotfiles kept for reference only — it's gitignored and never pushed.
- `bin/.local/scripts/` holds standalone scripts (e.g. `tmux-sessionizer`) meant to end up on `$PATH`.
