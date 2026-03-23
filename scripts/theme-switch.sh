#!/usr/bin/env bash
# Toggle between dark (base) and light (specialisation) themes.
#
# $HOME/.local/state/hm-generation is a symlink written by the
# home.activation.saveThemeProfile step on every nixos-rebuild switch.
# It always points to the BASE home-manager generation (never a specialisation),
# so both activate scripts are always reachable from it.

export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
export PATH="/run/current-system/sw/bin:$HOME/.nix-profile/bin:$PATH"

HM_GEN="$HOME/.local/state/hm-generation"
STATE="$HOME/.local/state/current-theme"
mkdir -p "$(dirname "$STATE")"
CURRENT=$(cat "$STATE" 2>/dev/null || echo "dark")

if [ ! -e "$HM_GEN" ]; then
  notify-send "Theme Switcher" \
    "Home-manager generation not found at:\n$HM_GEN\n\nRun: sudo nixos-rebuild switch" \
    -t 8000
  exit 1
fi

LIGHT_ACTIVATE="$HM_GEN/specialisation/light/activate"
BASE_ACTIVATE="$HM_GEN/activate"

reload_apps() {
  local nvim_bg="$1"

  hyprctl reload 2>/dev/null || true

  local wallpaper="$HOME/Pictures/wallpapers/gruvbox_${nvim_bg}.png"
  hyprctl hyprpaper wallpaper ",${wallpaper}" 2>/dev/null || true

  pkill waybar; sleep 0.2; waybar &
  pkill mako;   sleep 0.2; mako &

  pkill -USR2 ghostty 2>/dev/null || true

  if pgrep -f zathura >/dev/null; then
    for svc in $(dbus-send --session --dest=org.freedesktop.DBus \
        --type=method_call --print-reply \
        /org/freedesktop/DBus org.freedesktop.DBus.ListNames 2>/dev/null \
        | grep -o '"org.pwmt.zathura[^"]*"' | tr -d '"'); do
      dbus-send --session --dest="$svc" --type=method_call \
        /org/pwmt/zathura org.pwmt.zathura.SourceConfig 2>/dev/null || true
    done
  fi

  for socket in /run/user/$(id -u)/nvim.*.0 "$HOME/.local/state/nvim/"*.sock; do
    [ -S "$socket" ] && nvim --server "$socket" --remote-send \
      ":set background=${nvim_bg}<CR>:colorscheme gruvbox-material<CR>" 2>/dev/null || true
  done
}

if [ "$CURRENT" = "dark" ]; then
  if [ ! -f "$LIGHT_ACTIVATE" ]; then
    notify-send "Theme Switcher" \
      "Light specialisation not found.\nExpected: $LIGHT_ACTIVATE\n\nRun: sudo nixos-rebuild switch" \
      -t 8000
    exit 1
  fi
  notify-send "Theme" "Switching to Gruvbox Light..." -t 1500
  "$LIGHT_ACTIVATE"
  echo "light" > "$STATE"
  reload_apps "light"
  notify-send "Theme" "Gruvbox Light active" -t 2000
else
  notify-send "Theme" "Switching to Gruvbox Dark..." -t 1500
  "$BASE_ACTIVATE"
  echo "dark" > "$STATE"
  reload_apps "dark"
  notify-send "Theme" "Gruvbox Dark active" -t 2000
fi
