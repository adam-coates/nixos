#!/usr/bin/env bash
export PATH="/run/wrappers/bin:/etc/profiles/per-user/$USER/bin:$HOME/.nix-profile/bin:/run/current-system/sw/bin:$PATH"

SELECTION=$(slurp 2>/dev/null)
[[ -z $SELECTION ]] && exit 0

IMG=$(mktemp /tmp/ocr-XXXXXX.png)
trap 'rm -f "$IMG"' EXIT

if ! grim -g "$SELECTION" "$IMG" 2>/dev/null; then
  notify-send "OCR failed" "Could not capture region" -u critical -t 3000
  exit 1
fi

TEXT=$(tesseract "$IMG" stdout --oem 1 --psm 6 -l eng --dpi 300 -c preserve_interword_spaces=1 2>/dev/null)

if [[ -z $TEXT ]]; then
  notify-send "OCR failed" "No text detected" -u critical -t 3000
  exit 1
fi

printf "%s" "$TEXT" | wl-copy
notify-send "󰴑  Copied text from selection to clipboard"
