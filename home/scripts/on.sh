#!/usr/bin/env bash
# on <title> [notebook]
#
# Create (or find) a Joplin note and open it in neovim.
#
# The note itself is created over Joplin's Data API — the Web Clipper server the
# desktop app runs on localhost:41184. The *editing* is then handed to Joplin's
# own external-editor feature rather than done behind its back: the script
# selects the note by URL and presses Ctrl+E for you, and Joplin spawns
# `editor` from its settings (ghostty -e nvim, see home/programs/joplin.nix).
#
# Doing it this way is the whole point. Writing note bodies straight to the API
# works, but the desktop app holds its own buffer for the selected note and will
# not reload it when the database changes underneath, so edits only appear after
# a restart. Under external editing Joplin owns the temp file, watches it, and
# renders every :w live. The first line of that file is the note title, so
# renaming a note is just editing line 1.
#
# API docs: https://joplinapp.org/help/api/references/rest_api

set -uo pipefail

PROFILE="${JOPLIN_PROFILE:-$HOME/.config/joplin-desktop}"
SETTINGS="$PROFILE/settings.json"
DEFAULT_NOTEBOOK="${JOPLIN_DEFAULT_NOTEBOOK:-00 - Inbox}"
JOPLIN_CLASS="appimagekit-joplin"

die() {
  echo "on: $*" >&2
  exit 1
}

usage() {
  cat >&2 <<'EOF'
Usage: on <title> [notebook]

  on "the wonderful thing about tiggers"
  on "reading list" "01 - Library"

Opens the note if it already exists, otherwise creates it.
EOF
  exit 1
}

[ $# -ge 1 ] && [ -n "$1" ] || usage

TITLE="$1"
NOTEBOOK="${2:-$DEFAULT_NOTEBOOK}"

[ -f "$SETTINGS" ] || die "no Joplin profile at $PROFILE"
TOKEN=$(jq -r '."api.token" // empty' "$SETTINGS")
[ -n "$TOKEN" ] || die "no api.token in $SETTINGS — enable the Web Clipper service in Joplin once"

# The clipper walks up from 41184 if the port is taken, so probe a small range.
find_port() {
  local p
  for p in $(seq 41184 41194); do
    if [ "$(curl -sf -m 1 "http://127.0.0.1:$p/ping" 2>/dev/null)" = "JoplinClipperServer" ]; then
      echo "$p"
      return 0
    fi
  done
  return 1
}

PORT=$(find_port) || {
  command -v joplin-desktop >/dev/null || die "Joplin is not running and joplin-desktop is not on PATH"
  echo "on: starting Joplin..." >&2
  setsid joplin-desktop </dev/null >/dev/null 2>&1 &
  for _ in $(seq 1 30); do
    sleep 1
    PORT=$(find_port) && break
  done
  [ -n "${PORT:-}" ] || die "Joplin's clipper server never came up"
}

API="http://127.0.0.1:$PORT"

api() {
  local method="$1" path="$2"
  shift 2
  curl -sf -X "$method" "$API$path" -H 'Content-Type: application/json' "$@"
}

# --- resolve the notebook ---------------------------------------------------
# /folders is paginated; walk it rather than trusting the first page.
folder_id() {
  local want="$1" page=1 resp id
  while :; do
    resp=$(api GET "/folders?token=$TOKEN&page=$page&fields=id,title") || return 1
    id=$(jq -r --arg t "$want" '.items[] | select(.title == $t) | .id' <<<"$resp" | head -n1)
    [ -n "$id" ] && { echo "$id"; return 0; }
    [ "$(jq -r '.has_more' <<<"$resp")" = "true" ] || return 1
    page=$((page + 1))
  done
}

PARENT_ID=$(folder_id "$NOTEBOOK") || die "no notebook titled '$NOTEBOOK'"

# --- find an existing note, else create one ---------------------------------
# Listed straight out of the notebook rather than via /search: the full-text
# index lags behind writes, so a note created a moment ago is not searchable yet.
note_id() {
  local page=1 resp id
  while :; do
    resp=$(api GET "/folders/$PARENT_ID/notes?token=$TOKEN&page=$page&fields=id,title") || return 1
    id=$(jq -r --arg t "$TITLE" '.items[] | select(.title == $t) | .id' <<<"$resp" | head -n1)
    [ -n "$id" ] && { echo "$id"; return 0; }
    [ "$(jq -r '.has_more' <<<"$resp")" = "true" ] || return 1
    page=$((page + 1))
  done
}

NOTE_ID=$(note_id)

if [ -z "$NOTE_ID" ]; then
  NOTE_ID=$(api POST "/notes?token=$TOKEN" \
    -d "$(jq -n --arg t "$TITLE" --arg p "$PARENT_ID" '{title: $t, body: "", parent_id: $p}')" \
    | jq -r '.id') || die "could not create note"
  [ -n "$NOTE_ID" ] && [ "$NOTE_ID" != "null" ] || die "could not create note"
fi

# --- select it in the desktop app -------------------------------------------
xdg-open "joplin://x-callback-url/openNote?id=$NOTE_ID" >/dev/null 2>&1

for _ in $(seq 1 20); do
  hyprctl clients -j 2>/dev/null | jq -e --arg c "$JOPLIN_CLASS" 'any(.[]; .class == $c)' >/dev/null && break
  sleep 0.5
done

# --- hand editing to Joplin -------------------------------------------------
# Joplin names the watched file after the note id, so its presence means this
# note is already being edited externally. Ctrl+E toggles, so sending it again
# would stop the session rather than open a second editor.
if [ -f "$PROFILE/edit-$NOTE_ID.md" ]; then
  hyprctl dispatch "hl.dsp.focus{ window = \"class:^(com\\.mitchellh\\.ghostty)\$\" }" >/dev/null 2>&1
  exit 0
fi

if ! command -v hyprctl >/dev/null; then
  echo "on: note is open in Joplin — press Ctrl+E to edit it in nvim" >&2
  exit 0
fi

hyprctl dispatch "hl.dsp.focus{ window = \"class:^($JOPLIN_CLASS)\$\" }" >/dev/null 2>&1

# Ctrl+E is Joplin's default binding for "edit in external editor". Sent to the
# window by regex rather than typed blind, so it cannot land in the wrong app.
if ! hyprctl dispatch \
  "hl.dsp.send_shortcut{ mods = \"CTRL\", key = \"e\", window = \"class:^($JOPLIN_CLASS)\$\" }" \
  >/dev/null 2>&1; then
  echo "on: note is open in Joplin — press Ctrl+E to edit it in nvim" >&2
fi
