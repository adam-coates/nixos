#!/usr/bin/env bash

# Lock the screen via quickshell
quickshell msg lock

# Set keyboard layout to default
hyprctl switchxkblayout all 0 > /dev/null 2>&1
