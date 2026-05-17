#!/usr/bin/env bash
export PATH="/run/wrappers/bin:/etc/profiles/per-user/$USER/bin:$HOME/.nix-profile/bin:/run/current-system/sw/bin:$PATH"
grim -g "$(slurp)" - | swappy -f -
