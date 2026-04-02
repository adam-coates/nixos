#!/usr/bin/env bash

# Resume from sleep: restart quickshell while display is off,
# then lock and only turn the display on once the lock screen is ready.

# Restart quickshell (display is still off from sleep)
systemctl --user restart quickshell

# Wait for quickshell to be ready
sleep 2

# Lock the screen before showing anything
qs ipc call shell lock

# Small delay to let the lock surface render
sleep 0.3

# Now turn the display on - user sees only the lock screen
hyprctl dispatch dpms on
