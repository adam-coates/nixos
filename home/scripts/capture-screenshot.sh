#!/usr/bin/env bash
export PATH="/run/wrappers/bin:/etc/profiles/per-user/$USER/bin:$HOME/.nix-profile/bin:/run/current-system/sw/bin:$PATH"

cleanup_freeze() {
  [[ -n $PID ]] && kill $PID 2>/dev/null
}
trap cleanup_freeze EXIT

hyprpicker -r -z >/dev/null 2>&1 &
PID=$!
sleep .1

SELECTION=$(slurp 2>/dev/null)
[[ -z $SELECTION ]] && exit 0

IMG=$(mktemp /tmp/screenshot-XXXXXX.png)
grim -g "$SELECTION" "$IMG" || exit 1

kill $PID 2>/dev/null
PID=

swappy -f "$IMG"
rm -f "$IMG"
