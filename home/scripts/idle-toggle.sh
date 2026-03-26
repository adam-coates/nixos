#!/usr/bin/env bash

if pgrep -x hypridle >/dev/null; then
    pkill -x hypridle
    notify-send "Idle lock disabled" "Screen will not lock when idle"
else
    hypridle &
    notify-send "Idle lock enabled" "Screen will lock after 5 minutes"
fi
