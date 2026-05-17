#!/bin/bash

OUTPUT_DIR="${HOME}/Videos"
PID_FILE="/tmp/capture-screenrecord-pid"
NAME_FILE="/tmp/capture-screenrecord-filename"

mkdir -p "$OUTPUT_DIR"

stop_recording() {
  local pid
  pid=$(cat "$PID_FILE" 2>/dev/null)
  [[ -z $pid ]] && return 1
  kill -0 "$pid" 2>/dev/null || { rm -f "$PID_FILE" "$NAME_FILE"; return 1; }

  kill -SIGINT "$pid"
  local count=0
  while kill -0 "$pid" 2>/dev/null && ((count < 50)); do
    sleep 0.1
    count=$((count + 1))
  done

  local filename
  filename=$(cat "$NAME_FILE" 2>/dev/null)
  notify-send "Screen recording saved" "$filename" -t 5000
  rm -f "$PID_FILE" "$NAME_FILE"
  return 0
}

if [[ -f "$PID_FILE" ]]; then
  stop_recording
  exit 0
fi

DESKTOP_AUDIO="false"
MICROPHONE_AUDIO="false"

for arg in "$@"; do
  case "$arg" in
  --with-desktop-audio) DESKTOP_AUDIO="true" ;;
  --with-microphone-audio) MICROPHONE_AUDIO="true" ;;
  esac
done

get_rectangles() {
  local active_workspace
  active_workspace=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .activeWorkspace.id')
  hyprctl monitors -j | jq -r --arg ws "$active_workspace" '
    .[] | select(.activeWorkspace.id == ($ws | tonumber)) |
    "\(.x),\(.y) \(.width / .scale | floor)x\(.height / .scale | floor)"'
  hyprctl clients -j | jq -r --arg ws "$active_workspace" '
    .[] | select(.workspace.id == ($ws | tonumber)) |
    "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"'
}

rects=$(get_rectangles)
hyprpicker -r -z >/dev/null 2>&1 &
picker_pid=$!
sleep .1
selection=$(echo "$rects" | slurp 2>/dev/null)
kill $picker_pid 2>/dev/null

[[ ! $selection =~ ^(-?[0-9]+),(-?[0-9]+)[[:space:]]([0-9]+)x([0-9]+)$ ]] && exit 1
sx=${BASH_REMATCH[1]} sy=${BASH_REMATCH[2]}
sw=${BASH_REMATCH[3]} sh=${BASH_REMATCH[4]}

if ((sw * sh < 20)); then
  while IFS= read -r rect; do
    [[ $rect =~ ^(-?[0-9]+),(-?[0-9]+)[[:space:]]([0-9]+)x([0-9]+)$ ]] || continue
    rx=${BASH_REMATCH[1]} ry=${BASH_REMATCH[2]}
    rw=${BASH_REMATCH[3]} rh=${BASH_REMATCH[4]}
    if ((sx >= rx && sx < rx + rw && sy >= ry && sy < ry + rh)); then
      sx=$rx sy=$ry sw=$rw sh=$rh
      break
    fi
  done <<<"$rects"
fi

monitor=$(hyprctl monitors -j | jq -r --argjson x "$sx" --argjson y "$sy" --argjson w "$sw" --argjson h "$sh" '
  .[] | select(.x == $x and .y == $y and (.width / .scale | floor) == $w and (.height / .scale | floor) == $h) | .name' | head -1)

capture_args=()
if [[ -n $monitor ]]; then
  capture_args=(-w "$monitor")
else
  capture_args=(-w "${sw}x${sh}+${sx}+${sy}")
fi

filename="$OUTPUT_DIR/screenrecording-$(date +'%Y-%m-%d_%H-%M-%S').mp4"
audio_args=()
audio_devices=""

[[ $DESKTOP_AUDIO == "true" ]] && audio_devices+="default_output"
if [[ $MICROPHONE_AUDIO == "true" ]]; then
  [[ -n $audio_devices ]] && audio_devices+="|"
  audio_devices+="default_input"
fi
[[ -n $audio_devices ]] && audio_args+=(-a "$audio_devices" -ac aac)

gpu-screen-recorder "${capture_args[@]}" -k auto -f 60 -fm cfr -o "$filename" "${audio_args[@]}" &
pid=$!

while kill -0 $pid 2>/dev/null && [[ ! -f $filename ]]; do
  sleep 0.2
done

if kill -0 $pid 2>/dev/null; then
  echo "$pid" > "$PID_FILE"
  echo "$filename" > "$NAME_FILE"
  notify-send "Recording started" "Run again to stop" -t 2000
fi
