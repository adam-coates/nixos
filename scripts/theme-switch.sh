#!/usr/bin/env bash

THEMES_DIR="$HOME/.config/themes"
HYPR_THEME="$HOME/.config/hypr/theme.conf"
WAYBAR_COLORS="$HOME/.config/waybar/colors.css"

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

THEME_FILE="$THEMES_DIR/$THEME.sh"

if [ ! -f "$THEME_FILE" ]; then
    notify-send "Theme Switcher" "Theme file not found: $THEME_FILE"
    exit 1
fi

source "$THEME_FILE"

# ── Waybar ────────────────────────────────────────────────────────────────────
cat >"$WAYBAR_COLORS" <<EOF
@define-color bg $waybar_bg;
@define-color fg $waybar_fg;
@define-color border $waybar_border;
@define-color accent $waybar_accent;
@define-color red $waybar_red;
@define-color green $waybar_green;
@define-color blue $waybar_blue;
@define-color purple $waybar_purple;
@define-color aqua $waybar_aqua;
@define-color orange $waybar_orange;
@define-color gray $waybar_gray;
EOF

# ── Hyprland ──────────────────────────────────────────────────────────────────
cat >"$HYPR_THEME" <<EOF
\$active_border = $active_border
\$inactive_border = $inactive_border
\$bg = $bg
\$fg = $fg
EOF

hyprctl reload

# ── Mako ──────────────────────────────────────────────────────────────────────
cat >"$HOME/.config/mako/config" <<EOF
background-color=$bg
border-color=$active_border_solid
text-color=$fg
border-radius=10
border-size=2
default-timeout=5000
font=JetBrainsMono Nerd Font 11
width=300
height=100
padding=10
margin=10
icons=1
max-icon-size=32
EOF

# ── Rofi ──────────────────────────────────────────────────────────────────────
cat >"$HOME/.config/rofi/colors.rasi" <<EOF
* {
    bg: $bg;
    fg: $fg;
    accent: $waybar_accent;
    gray: $waybar_gray;
    red: $waybar_red;
}
EOF

# ── GTK via dconf ─────────────────────────────────────────────────────────────
if [ "$THEME" = "gruvbox-dark" ]; then
    GTK_THEME="Gruvbox-Dark"
    COLOR_SCHEME="prefer-dark"
else
    GTK_THEME="Gruvbox-Light"
    COLOR_SCHEME="prefer-light"
fi
dconf write /org/gnome/desktop/interface/gtk-theme "'$GTK_THEME'"
dconf write /org/gnome/desktop/interface/icon-theme "'Gruvbox-Dark'"
dconf write /org/gnome/desktop/interface/color-scheme "'$COLOR_SCHEME'"

# ── Ghostty ───────────────────────────────────────────────────────────────────
ln -sf "$HOME/.config/ghostty/themes/$THEME" "$HOME/.config/ghostty/theme-link"
pkill -USR2 ghostty 2>/dev/null || true

# ── Neovim ────────────────────────────────────────────────────────────────────
for socket in /run/user/$(id -u)/nvim.*.0 "$HOME/.local/state/nvim/"*.sock; do
    [ -S "$socket" ] && nvim --server "$socket" --remote-send \
        ":set background=$nvim_background<CR>:colorscheme $nvim_colorscheme<CR>" 2>/dev/null || true
done

# ── Restart daemons ───────────────────────────────────────────────────────────
pkill waybar
sleep 0.2
waybar &
pkill mako
sleep 0.2
mako &

# ── Save current theme ────────────────────────────────────────────────────────
echo "$THEME" >"$THEMES_DIR/current"
notify-send "Theme Switcher" "Switched to $CHOICE" --icon=preferences-desktop-theme
