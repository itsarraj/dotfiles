#!/bin/bash

# Get current layout info
layout_info=$(setxkbmap -query)

# Extract layout and variant
current_layout=$(echo "$layout_info" | awk '/layout:/ {print $2}')
current_variant=$(echo "$layout_info" | awk '/variant:/ {print $2}')

# Determine next layout
case "$current_layout,$current_variant" in
    "us,")          # Basic US
        setxkbmap us -variant altgr-intl
        notify-send "Keyboard Layout" "Switched to US International (altgr-intl)"
        ;;
    "us,altgr-intl") # US International
        setxkbmap ru
        notify-send "Keyboard Layout" "Switched to Russian"
        ;;
    "ru,")          # Russian
        setxkbmap us
        notify-send "Keyboard Layout" "Switched to US Basic"
        ;;
    *)              # Fallback (unknown state)
        setxkbmap us
        notify-send "Keyboard Layout" "Reset to US Basic"
        ;;
esac
