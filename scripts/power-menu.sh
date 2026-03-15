#!/usr/bin/env bash

CHOICE=$(printf "󰌾 Lock\n󰒲 Sleep\n󰜉 Restart\n󰐥 Shutdown\n󰍃 Logout" | \
  rofi -dmenu -p " Power" -i \
  -theme-str 'window {width: 300px;} listview {lines: 5;}')

case "$CHOICE" in
  "󰌾 Lock")     bash ~/.config/scripts/lock.sh ;;
  "󰒲 Sleep")    bash ~/.config/scripts/lock.sh && systemctl suspend ;;
  "󰜉 Restart")  systemctl reboot ;;
  "󰐥 Shutdown") systemctl poweroff ;;
  "󰍃 Logout")   hyprctl dispatch exit ;;
esac
