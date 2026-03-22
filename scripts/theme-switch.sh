#!/usr/bin/env bash
# Toggle between dark (base) and light (specialisation) themes.
# The home-manager specialisation system manages all config files;
# this script just activates the appropriate profile and reloads apps.

export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
export PATH="/run/current-system/sw/bin:$HOME/.nix-profile/bin:$PATH"

# Home-manager profile — always points to the latest nixos-rebuild result
PROFILE="/nix/var/nix/profiles/per-user/$(whoami)/home-manager"

# Persist current theme so we know what to toggle next time
STATE="$HOME/.local/state/current-theme"
mkdir -p "$(dirname "$STATE")"
CURRENT=$(cat "$STATE" 2>/dev/null || echo "dark")

reload_apps() {
  local nvim_bg="$1"

  # Hyprland (border colours are baked into hyprland config)
  hyprctl reload 2>/dev/null || true

  # Waybar
  pkill waybar; sleep 0.2; waybar &

  # Mako
  pkill mako; sleep 0.2; mako &

  # Ghostty — reload config in place
  pkill -USR2 ghostty 2>/dev/null || true

  # Zathura — dbus reload
  if pgrep -f zathura >/dev/null; then
    for svc in $(dbus-send --session --dest=org.freedesktop.DBus \
        --type=method_call --print-reply \
        /org/freedesktop/DBus org.freedesktop.DBus.ListNames 2>/dev/null \
        | grep -o '"org.pwmt.zathura[^"]*"' | tr -d '"'); do
      dbus-send --session --dest="$svc" --type=method_call \
        /org/pwmt/zathura org.pwmt.zathura.SourceConfig 2>/dev/null || true
    done
  fi

  # Neovim — update background in running instances
  for socket in /run/user/$(id -u)/nvim.*.0 "$HOME/.local/state/nvim/"*.sock; do
    [ -S "$socket" ] && nvim --server "$socket" --remote-send \
      ":set background=${nvim_bg}<CR>:colorscheme gruvbox<CR>" 2>/dev/null || true
  done
}

if [ "$CURRENT" = "dark" ]; then
  LIGHT_ACTIVATE="$PROFILE/specialisation/light/activate"
  if [ ! -f "$LIGHT_ACTIVATE" ]; then
    notify-send "Theme Switcher" "Light specialisation not found.\nRun nixos-rebuild switch first." -t 5000
    exit 1
  fi
  notify-send "Theme" "Switching to Gruvbox Light..." -t 1500
  "$LIGHT_ACTIVATE"
  echo "light" > "$STATE"
  reload_apps "light"
  notify-send "Theme" "Gruvbox Light active" -t 2000
else
  notify-send "Theme" "Switching to Gruvbox Dark..." -t 1500
  "$PROFILE/activate"
  echo "dark" > "$STATE"
  reload_apps "dark"
  notify-send "Theme" "Gruvbox Dark active" -t 2000
fi
