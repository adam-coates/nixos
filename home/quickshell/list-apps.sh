#!/usr/bin/env bash
# Outputs installed applications as "name\texec\ticon" lines, sorted by name.
find \
    /run/current-system/sw/share/applications \
    "$HOME/.nix-profile/share/applications" \
    "$HOME/.local/share/applications" \
    -name '*.desktop' 2>/dev/null \
| sort -u \
| while IFS= read -r f; do
    awk -F= '
        /^\[Desktop Entry\]/ { in_entry=1; next }
        /^\[/               { if (in_entry) exit }
        in_entry && /^Name=/        && !name       { name=substr($0, 6) }
        in_entry && /^Exec=/        && !exec_val   { exec_val=substr($0, 6) }
        in_entry && /^Icon=/        && !icon       { icon=substr($0, 6) }
        in_entry && /^NoDisplay=true/              { no_display=1 }
        in_entry && /^Type=/ && substr($0,6) != "Application" { no_display=1 }
        END {
            if (name && exec_val && !no_display) {
                # Strip field codes like %f %u %F %U etc.
                gsub(/ ?%[fFuUdDnNickvm]/, "", exec_val)
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", exec_val)
                printf "%s\t%s\t%s\n", name, exec_val, icon
            }
        }
    ' "$f"
done | sort -t$'\t' -k1 -u
