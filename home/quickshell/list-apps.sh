#!/usr/bin/env bash
# Outputs installed applications as "name\texec\ticon" lines, sorted by name.
# Uses XDG_DATA_DIRS to find all application directories (correct for NixOS).

# Build list of application directories from XDG_DATA_DIRS + fallback paths
declare -a search_dirs
IFS=: read -ra data_dirs <<< "${XDG_DATA_DIRS:-/run/current-system/sw/share}"

for d in "${data_dirs[@]}" "$HOME/.local/share" "$HOME/.nix-profile/share"; do
    app_dir="$d/applications"
    [ -d "$app_dir" ] && search_dirs+=("$app_dir")
done

[ ${#search_dirs[@]} -eq 0 ] && exit 0

find "${search_dirs[@]}" -name '*.desktop' 2>/dev/null \
| sort -u \
| while IFS= read -r f; do
    awk '
        BEGIN { FS="="; in_entry=0; name=""; exec_val=""; icon=""; no_display=0 }
        /^\[Desktop Entry\]/ { in_entry=1; next }
        /^\[/                { if (in_entry) exit }
        !in_entry            { next }
        /^Name=/ && name==""    { name=substr($0, 6) }
        /^Exec=/ && exec_val=="" { exec_val=substr($0, 6) }
        /^Icon=/ && icon==""    { icon=substr($0, 6) }
        /^NoDisplay=true/       { no_display=1 }
        /^Type=/ && substr($0, 6) != "Application" { no_display=1 }
        END {
            if (name != "" && exec_val != "" && !no_display) {
                gsub(/ ?%[fFuUdDnNickvm]/, "", exec_val)
                sub(/^[[:space:]]+/, "", exec_val)
                sub(/[[:space:]]+$/, "", exec_val)
                printf "%s\t%s\t%s\n", name, exec_val, icon
            }
        }
    ' "$f"
done | sort -t$'\t' -k1 -u
