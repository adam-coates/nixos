#!/usr/bin/env bash

# Returns JSON for waybar custom module
if pgrep -x hypridle >/dev/null; then
    echo '{"text": "󱫖", "tooltip": "Idle lock enabled - click to disable", "class": "idle-on"}'
else
    echo '{"text": "󱫖", "tooltip": "Idle lock disabled - click to enable", "class": "idle-off"}'
fi
