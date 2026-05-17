#!/bin/bash

OUTPUT_DIR="${HOME}/Videos"
PID_FILE="/tmp/capture-screenrecord-pid"
NAME_FILE="/tmp/capture-screenrecord-filename"

mkdir -p "$OUTPUT_DIR"

DESKTOP_AUDIO="false"
MICROPHONE_AUDIO="false"
WEBCAM="false"
WEBCAM_DEVICE=""

for arg in "$@"; do
  case "$arg" in
  --with-desktop-audio) DESKTOP_AUDIO="true" ;;
  --with-microphone-audio) MICROPHONE_AUDIO="true" ;;
  --with-webcam) WEBCAM="true" ;;
  --webcam-device=*) WEBCAM_DEVICE="${arg#*=}" ;;
  esac
done

# ── Stop recording ──

if [[ -f "$PID_FILE" ]]; then
  pid=$(cat "$PID_FILE" 2>/dev/null)
  if [[ -n $pid ]] && kill -0 "$pid" 2>/dev/null; then
    kill -SIGINT "$pid"
    count=0
    while kill -0 "$pid" 2>/dev/null && ((count < 50)); do
      sleep 0.1
      count=$((count + 1))
    done
  fi

  pkill -f "WebcamOverlay" 2>/dev/null

  filename=$(cat "$NAME_FILE" 2>/dev/null)
  rm -f "$PID_FILE" "$NAME_FILE"

  if [[ -f "$filename" ]]; then
    notify-send "Screen recording saved" "$filename" -t 5000
  else
    notify-send "Screen recording failed" "No output file found" -u critical -t 3000
  fi
  exit 0
fi

# ── Region selection ──

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

select_capture_target() {
  local rects
  rects=$(get_rectangles)
  hyprpicker -r -z >/dev/null 2>&1 &
  local picker_pid=$!
  sleep .1
  local selection
  selection=$(echo "$rects" | slurp 2>/dev/null)
  kill $picker_pid 2>/dev/null

  [[ $selection =~ ^(-?[0-9]+),(-?[0-9]+)[[:space:]]([0-9]+)x([0-9]+)$ ]] || return 1
  local sx=${BASH_REMATCH[1]} sy=${BASH_REMATCH[2]}
  local sw=${BASH_REMATCH[3]} sh=${BASH_REMATCH[4]}

  if ((sw * sh < 20)); then
    while IFS= read -r rect; do
      [[ $rect =~ ^(-?[0-9]+),(-?[0-9]+)[[:space:]]([0-9]+)x([0-9]+)$ ]] || continue
      local rx=${BASH_REMATCH[1]} ry=${BASH_REMATCH[2]}
      local rw=${BASH_REMATCH[3]} rh=${BASH_REMATCH[4]}
      if ((sx >= rx && sx < rx + rw && sy >= ry && sy < ry + rh)); then
        sx=$rx sy=$ry sw=$rw sh=$rh
        break
      fi
    done <<<"$rects"
  fi

  local monitor
  monitor=$(hyprctl monitors -j | jq -r --argjson x "$sx" --argjson y "$sy" --argjson w "$sw" --argjson h "$sh" '
    .[] | select(.x == $x and .y == $y and (.width / .scale | floor) == $w and (.height / .scale | floor) == $h) | .name' | head -1)

  if [[ -n $monitor ]]; then
    echo "monitor:$monitor"
  else
    echo "region:${sw}x${sh}+${sx}+${sy}"
  fi
}

# ── Webcam overlay ──

start_webcam_overlay() {
  pkill -f "WebcamOverlay" 2>/dev/null

  if [[ -z $WEBCAM_DEVICE ]]; then
    WEBCAM_DEVICE=$(v4l2-ctl --list-devices 2>/dev/null | grep -m1 "^[[:space:]]*/dev/video" | tr -d '\t')
    if [[ -z $WEBCAM_DEVICE ]]; then
      notify-send "No webcam devices found" -u critical -t 3000
      return 1
    fi
  fi

  local scale
  scale=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .scale')
  local target_width
  target_width=$(awk "BEGIN {printf \"%.0f\", 360 * ${scale:-1}}")

  local preferred_resolutions=("640x360" "1280x720" "1920x1080")
  local video_size_arg=""
  local available_formats
  available_formats=$(v4l2-ctl --list-formats-ext -d "$WEBCAM_DEVICE" 2>/dev/null)

  for resolution in "${preferred_resolutions[@]}"; do
    if echo "$available_formats" | grep -q "$resolution"; then
      video_size_arg="-video_size $resolution"
      break
    fi
  done

  ffplay -f v4l2 $video_size_arg -framerate 30 "$WEBCAM_DEVICE" \
    -vf "crop=iw/2:ih,scale=${target_width}:-1" \
    -window_title "WebcamOverlay" \
    -noborder \
    -fflags nobuffer -flags low_delay \
    -probesize 32 -analyzeduration 0 \
    -loglevel quiet &
  sleep 1
}

# ── Start recording ──

target=$(select_capture_target) || exit 1

capture_args=()
case $target in
monitor:*)
  capture_args=(-w "${target#monitor:}")
  ;;
region:*)
  capture_args=(-w "${target#region:}")
  ;;
esac

[[ $WEBCAM == "true" ]] && start_webcam_overlay

filename="$OUTPUT_DIR/screenrecording-$(date +'%Y-%m-%d_%H-%M-%S').mp4"
audio_args=()
audio_devices=""

[[ $DESKTOP_AUDIO == "true" ]] && audio_devices+="default_output"
if [[ $MICROPHONE_AUDIO == "true" ]]; then
  [[ -n $audio_devices ]] && audio_devices+="|"
  audio_devices+="default_input"
fi
[[ -n $audio_devices ]] && audio_args+=(-a "$audio_devices" -ac aac)

# Write PID file immediately so bar indicator shows instantly
echo "starting" > "$PID_FILE"
echo "$filename" > "$NAME_FILE"

gpu-screen-recorder "${capture_args[@]}" -k auto -f 60 -fm cfr -fallback-cpu-encoding yes -o "$filename" "${audio_args[@]}" &
pid=$!
echo "$pid" > "$PID_FILE"

sleep 1
if kill -0 "$pid" 2>/dev/null; then
  notify-send " Recording started" "Click ⏺ in bar to stop" -t 2000
else
  rm -f "$PID_FILE" "$NAME_FILE"
  pkill -f "WebcamOverlay" 2>/dev/null
  notify-send "Screen recording failed to start" -u critical -t 3000
fi
