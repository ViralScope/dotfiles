#!/bin/bash

entries="Lock\nLogout\nSuspend\nReboot\nShutdown"

selected=$(echo -e $entries | wofi --show dmenu --prompt "Power Menu" --width=250 --height=220 --style=$HOME/.config/wofi/style.css)

case $selected in
  "Lock")
    hyprlock
    ;;
  "Logout")
    hyprctl dispatch exit
    ;;
  "Suspend")
    systemctl suspend
    ;;
  "Reboot")
    systemctl reboot
    ;;
  "Shutdown")
    systemctl poweroff
    ;;
esac
