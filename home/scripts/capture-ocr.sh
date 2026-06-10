#!/usr/bin/env bash
export PATH="/run/wrappers/bin:/etc/profiles/per-user/$USER/bin:$HOME/.nix-profile/bin:/run/current-system/sw/bin:$PATH"

SELECTION=$(slurp 2>/dev/null)

[[ -z $SELECTION ]] && exit 0

TEXT=$(grim -g "$SELECTION" - | tesseract stdin stdout --oem 1 --psm 6 -l eng --dpi 300 -c preserve_interword_spaces=1 2>/dev/null) || exit 1

[[ -z $TEXT ]] && exit 1

printf "%s" "$TEXT" | wl-copy
notify-send "󰴑  Copied text from selection to clipboard"
