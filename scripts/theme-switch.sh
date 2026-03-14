#!/usr/bin/env bash

# Theme switcher for Gruvbox Dark/Light
# Affects: Hyprland, Waybar, Ghostty, Rofi, Neovim

THEMES_DIR="$HOME/.config/themes"
CURRENT_THEME_FILE="$HOME/.config/themes/current"
HYPR_THEME="$HOME/.config/hypr/theme.conf"
WAYBAR_COLORS="$HOME/.config/waybar/colors.css"
GHOSTTY_THEME_FILE="$HOME/.config/ghostty/theme"

# Ensure themes dir exists
mkdir -p "$THEMES_DIR"

# Pick theme via rofi
CHOICE=$(printf "Gruvbox Dark\nGruvbox Light" | rofi -dmenu -p "Theme" -i)

case "$CHOICE" in
"Gruvbox Dark")
    THEME="gruvbox-dark"
    ;;
"Gruvbox Light")
    THEME="gruvbox-light"
    ;;
*)
    exit 0
    ;;
esac

THEME_FILE="$THEMES_DIR/$THEME.conf"

if [ ! -f "$THEME_FILE" ]; then
    notify-send "Theme Switcher" "Theme file not found: $THEME_FILE"
    exit 1
fi

# Source theme variables
source "$THEME_FILE"

# ── Hyprland ──────────────────────────────────────────────────────────────────
cat >"$HYPR_THEME" <<EOF
\$active_border = $active_border
\$inactive_border = $inactive_border
\$bg = $bg
\$fg = $fg
EOF

# Reload hyprland colors
hyprctl reload

# ── Waybar ────────────────────────────────────────────────────────────────────
cat >"$WAYBAR_COLORS" <<EOF
@define-color bg ${waybar_bg};
@define-color fg ${waybar_fg};
@define-color border ${waybar_border};
@define-color accent ${waybar_accent};
@define-color red ${waybar_red};
@define-color green ${waybar_green};
@define-color blue ${waybar_blue};
@define-color purple ${waybar_purple};
@define-color aqua ${waybar_aqua};
@define-color orange ${waybar_orange};
@define-color gray ${waybar_gray};
EOF

# Restart waybar
pkill waybar && waybar &

# ── Ghostty ───────────────────────────────────────────────────────────────────
echo "theme = $ghostty_theme" >"$GHOSTTY_THEME_FILE"
# Signal ghostty instances to reload (ghostty supports live reload)
pkill -USR1 ghostty 2>/dev/null || true

# ── Mako ──────────────────────────────────────────────────────────────────────
mkdir -p ~/.config/mako
cat >~/.config/mako/config <<EOF
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

pkill mako && mako &

# ── Neovim ────────────────────────────────────────────────────────────────────
# Signal all running neovim instances via their sockets
for socket in /run/user/$(id -u)/nvim.*.0 "$HOME/.local/state/nvim/"*.sock; do
    [ -S "$socket" ] && nvim --server "$socket" --remote-send \
        ":set background=$nvim_background<CR>:colorscheme $nvim_colorscheme<CR>" 2>/dev/null || true
done

# ── Save current theme ────────────────────────────────────────────────────────
echo "$THEME" >"$CURRENT_THEME_FILE"

notify-send "Theme Switcher" "Switched to $CHOICE" --icon=preferences-desktop-theme
