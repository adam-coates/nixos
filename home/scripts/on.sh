#!/usr/bin/env bash
# on <title> [notebook]
#
# Open (or create) a Joplin note in neovim.
#
# Talks to Joplin's Data API — the Web Clipper server the desktop app runs on
# localhost:41184. The note body is pulled into a temp file, edited in nvim, and
# PUT back on exit. Nothing is written to disk permanently; Joplin's database
# stays the single source of truth and syncs as usual.
#
# API docs: https://joplinapp.org/help/api/references/rest_api

set -uo pipefail

PROFILE="${JOPLIN_PROFILE:-$HOME/.config/joplin-desktop}"
SETTINGS="$PROFILE/settings.json"
DEFAULT_NOTEBOOK="${JOPLIN_DEFAULT_NOTEBOOK:-00 - Inbox}"

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
Requires the Joplin desktop app to be running (Web Clipper server).
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
  # Joplin isn't up. Start it and wait for the clipper to come online.
  command -v joplin-desktop >/dev/null || die "Joplin is not running and joplin-desktop is not on PATH"
  echo "on: starting Joplin..." >&2
  joplin-desktop >/dev/null 2>&1 &
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

CREATED=0
if [ -z "$NOTE_ID" ]; then
  NOTE_ID=$(api POST "/notes?token=$TOKEN" \
    -d "$(jq -n --arg t "$TITLE" --arg p "$PARENT_ID" '{title: $t, body: "", parent_id: $p}')" \
    | jq -r '.id') || die "could not create note"
  [ -n "$NOTE_ID" ] && [ "$NOTE_ID" != "null" ] || die "could not create note"
  CREATED=1
fi

# --- edit ------------------------------------------------------------------
slug=$(printf '%s' "$TITLE" | tr -cs '[:alnum:]' '-' | sed 's/^-//;s/-$//')
TMP=$(mktemp --tmpdir "on-${slug:-note}-XXXXXX.md") || die "mktemp failed"

# -j, not -r: an empty body must stay an empty file, not a stray newline.
api GET "/notes/$NOTE_ID?token=$TOKEN&fields=body" | jq -j '.body' >"$TMP" \
  || die "could not read note body"
before=$(sha256sum <"$TMP")

MAIN_PID=$$

push_body() {
  api PUT "/notes/$NOTE_ID?token=$TOKEN" \
    -d "$(jq -n --rawfile b "$TMP" '{body: $b}')" >/dev/null
}

# Push on every :w, not just on exit — otherwise a long editing session is
# invisible to Joplin (and to sync) until nvim closes. Polled rather than
# inotify-driven to keep this dependency-free; a second of lag is fine.
watch_saves() {
  local last="$before" cur
  while sleep 1; do
    # Belt and braces: if the script itself is gone (terminal closed hard, kill
    # -9), stop polling instead of looping forever against a dead note.
    kill -0 "$MAIN_PID" 2>/dev/null || return
    # nvim may briefly replace the file rather than rewrite it in place; a
    # failed read is a blink, not a reason to stop watching.
    cur=$(sha256sum <"$TMP" 2>/dev/null) || continue
    if [ "$cur" != "$last" ]; then
      push_body && last="$cur"
    fi
  done
}

watch_saves &
WATCHER=$!
trap 'kill "$WATCHER" 2>/dev/null; rm -f "$TMP"' EXIT
# Without this a killed terminal skips the EXIT trap and orphans the watcher.
trap 'exit 130' INT TERM HUP

nvim "$TMP"

kill "$WATCHER" 2>/dev/null
wait "$WATCHER" 2>/dev/null
trap 'rm -f "$TMP"' EXIT

after=$(sha256sum <"$TMP")
if [ "$before" = "$after" ]; then
  # A brand new note left empty is an aborted capture — don't litter the notebook.
  if [ "$CREATED" = 1 ] && [ ! -s "$TMP" ]; then
    api DELETE "/notes/$NOTE_ID?token=$TOKEN&permanent=1" >/dev/null
    echo "on: discarded empty note" >&2
  fi
  exit 0
fi

# Unconditional final push: the watcher may have missed the last save, and a
# repeat PUT of identical text is harmless.
push_body || die "could not save note back to Joplin"

# The desktop app keeps its own buffer for whichever note is selected and will
# not reload it just because the database changed under it, so a note edited
# here can look stale in an open Joplin window. Re-opening it by URL forces the
# editor to re-read from the database. Set ON_NO_FOCUS=1 to skip (this raises
# the Joplin window).
if [ "${ON_NO_FOCUS:-0}" != "1" ] && command -v xdg-open >/dev/null; then
  xdg-open "joplin://x-callback-url/openNote?id=$NOTE_ID" >/dev/null 2>&1 &
fi
