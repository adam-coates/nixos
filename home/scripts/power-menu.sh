#!/usr/bin/env bash

menu() {
  local prompt="$1"
  local options="$2"
  echo -e "$options" | walker --dmenu --width 300 --minheight 1 --maxheight 400 -p "$prompt" 2>/dev/null
}

case $(menu "Power" "󰌾  Lock\n󰒲  Sleep\n󰜉  Restart\n󰐥  Shutdown\n󰍃  Logout") in
  *Lock*)     bash ~/.config/scripts/lock.sh ;;
  *Sleep*)    bash ~/.config/scripts/lock.sh && systemctl suspend ;;
  *Restart*)  systemctl reboot ;;
  *Shutdown*) systemctl poweroff ;;
  *Logout*)   hyprctl dispatch exit ;;
esac
