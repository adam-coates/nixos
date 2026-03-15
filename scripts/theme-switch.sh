#!/usr/bin/env bash

THEMES_DIR="$HOME/.config/themes"
CURRENT="$THEMES_DIR/current"

# Ensure correct environment when run from Hyprland keybind
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
export PATH="/run/current-system/sw/bin:$HOME/.nix-profile/bin:$PATH"

# Pick theme via rofi
CHOICE=$(printf "Gruvbox Dark\nGruvbox Light" | rofi -dmenu -p " Theme" -i)

case "$CHOICE" in
  "Gruvbox Dark") THEME="gruvbox-dark" ;;
  "Gruvbox Light") THEME="gruvbox-light" ;;
  *) exit 0 ;;
esac

THEME_DIR="$THEMES_DIR/$THEME"

if [ ! -d "$THEME_DIR" ]; then
  notify-send "Theme Switcher" "Theme not found: $THEME_DIR"
  exit 1
fi

# ── Swap symlinks ─────────────────────────────────────────────────────────────
ln -sf "$THEME_DIR/waybar.css"    "$HOME/.config/waybar/colors.css"
ln -sf "$THEME_DIR/hyprland.conf" "$HOME/.config/hypr/theme.conf"
ln -sf "$THEME_DIR/mako.conf"     "$HOME/.config/mako/config"
ln -sf "$THEME_DIR/rofi.rasi"     "$HOME/.config/rofi/colors.rasi"
ln -sf "$THEME_DIR/hyprlock.conf" "$HOME/.config/hypr/hyprlock-theme.conf"

# ── Ghostty ───────────────────────────────────────────────────────────────────
ln -sf "$HOME/.config/ghostty/themes/$THEME" "$HOME/.config/ghostty/theme-link"
pkill -USR2 ghostty 2>/dev/null || true

# ── Hyprland reload ───────────────────────────────────────────────────────────
hyprctl reload

# ── GTK via dconf ─────────────────────────────────────────────────────────────
if [ "$THEME" = "gruvbox-dark" ]; then
  dconf write /org/gnome/desktop/interface/gtk-theme "'Gruvbox-Dark'"
  dconf write /org/gnome/desktop/interface/color-scheme "'prefer-dark'"
else
  dconf write /org/gnome/desktop/interface/gtk-theme "'Gruvbox-Light'"
  dconf write /org/gnome/desktop/interface/color-scheme "'prefer-light'"
fi
dconf write /org/gnome/desktop/interface/icon-theme "'Gruvbox-Dark'"

# ── Neovim ────────────────────────────────────────────────────────────────────
if [ "$THEME" = "gruvbox-dark" ]; then
  NVIM_BG="dark"
else
  NVIM_BG="light"
fi
for socket in /run/user/$(id -u)/nvim.*.0 "$HOME/.local/state/nvim/"*.sock; do
  [ -S "$socket" ] && nvim --server "$socket" --remote-send \
    ":set background=$NVIM_BG<CR>:colorscheme gruvbox<CR>" 2>/dev/null || true
done

# ── Restart daemons ───────────────────────────────────────────────────────────
pkill waybar; sleep 0.2; waybar &
pkill mako; sleep 0.2; mako &

# ── Save current theme ────────────────────────────────────────────────────────
echo "$THEME" > "$CURRENT"
notify-send "Theme Switcher" "Switched to $CHOICE" --icon=preferences-desktop-theme
