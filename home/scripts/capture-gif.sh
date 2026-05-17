#!/bin/bash

OUTPUT_DIR="${HOME}/Videos"
PID_FILE="/tmp/capture-gif-pid"
TEMP_VIDEO="/tmp/capture-gif-temp.mp4"

mkdir -p "$OUTPUT_DIR"

# ── Stop & convert ──

if [[ -f "$PID_FILE" ]]; then
  pid=$(cat "$PID_FILE" 2>/dev/null)
  if [[ -n $pid ]] && kill -0 "$pid" 2>/dev/null; then
    kill -SIGINT "$pid"
    count=0
    while kill -0 "$pid" 2>/dev/null && ((count < 50)); do
      sleep 0.1
      count=$((count + 1))
    done

    filename="$OUTPUT_DIR/recording-$(date +'%Y-%m-%d_%H-%M-%S').gif"
    notify-send "Converting to GIF..." "This may take a moment" -t 3000

    ffmpeg -i "$TEMP_VIDEO" \
      -vf "fps=15,scale='min(640,iw)':-1:flags=lanczos,split[s0][s1];[s0]palettegen=max_colors=128[p];[s1][p]paletteuse=dither=bayer" \
      -loop 0 "$filename" -loglevel quiet 2>/dev/null

    rm -f "$TEMP_VIDEO" "$PID_FILE"
    notify-send "GIF saved" "$filename" -t 5000
    exit 0
  fi
  rm -f "$PID_FILE"
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

rm -f "$TEMP_VIDEO"

echo "starting" > "$PID_FILE"

gpu-screen-recorder "${capture_args[@]}" -k auto -f 15 -fm cfr -fallback-cpu-encoding yes -o "$TEMP_VIDEO" &
pid=$!
echo "$pid" > "$PID_FILE"

sleep 0.5
if kill -0 $pid 2>/dev/null; then
  notify-send "GIF recording started" "Click ⏺ in bar to stop & convert" -t 2000
else
  rm -f "$PID_FILE" "$TEMP_VIDEO"
  notify-send "GIF recording failed to start" -u critical -t 3000
fi
