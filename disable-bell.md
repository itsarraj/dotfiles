# Disable terminal bell (system-wide)

Bash rings the terminal bell when you press an arrow key at the start or end of the line. That is not in the stow packages; it is applied under `/etc` so it is permanent for every user and survives reboot.

Do not add `~/.inputrc`. If that file exists, readline ignores `/etc/inputrc`.

## Files

`/etc/inputrc`

Uncomment so readline never sends BEL:

```
set bell-style none
```

`/etc/modprobe.d/nobeep.conf`

Unload the PC speaker and keep it off after reboot:

```
blacklist pcspkr
blacklist snd_pcsp
```

`/etc/xprofile`

LightDM sources this for every graphical session:

```
xset b off
```

`/etc/X11/xinit/xinitrc.d/90-disable-bell.sh`

Same `xset b off` for startx / other DMs. Must be executable.

User session still has `xset b off` in `xprofile/.xprofile` as a fallback.

## Apply on a new machine

```
sudo sed -i 's/^#set bell-style none/set bell-style none/' /etc/inputrc
printf '%s\n' 'blacklist pcspkr' 'blacklist snd_pcsp' | sudo tee /etc/modprobe.d/nobeep.conf
sudo rmmod pcspkr 2>/dev/null || true
sudo rmmod snd_pcsp 2>/dev/null || true
printf '%s\n' '# System-wide X session profile (sourced by LightDM)' 'xset b off' | sudo tee /etc/xprofile
printf '%s\n' '#!/bin/sh' 'command -v xset >/dev/null 2>&1 && xset b off' | sudo tee /etc/X11/xinit/xinitrc.d/90-disable-bell.sh
sudo chmod 755 /etc/X11/xinit/xinitrc.d/90-disable-bell.sh
xset b off
```

## Check

```
grep bell-style /etc/inputrc
lsmod | grep -E 'pcspkr|snd_pcsp' || echo 'pcspkr unloaded'
xset q | grep bell
```

`bell percent` should be `0`. Open a new terminal after changing `/etc/inputrc`.
