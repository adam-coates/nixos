#!/usr/bin/env bash

if pgrep -x hypridle >/dev/null; then
    pkill -x hypridle
    notify-send "󱫖 Idle lock disabled" "Screen will not lock when idle"
    echo '{"text": "󱫖", "tooltip": "Idle lock disabled", "class": "idle-off"}'
else
    hypridle &
    notify-send "󱫖 Idle lock enabled" "Screen will lock after 5 minutes"
    echo '{"text": "󱫖", "tooltip": "Idle lock enabled", "class": "idle-on"}'
fi

# Signal waybar to refresh the idle indicator module
pkill -RTMIN+9 waybar
