# obsidian-inkscape: create SVG figure from template and open in Inkscape

IMAGES_DIR="/home/adam/notes/999-extra/images"
TEMPLATE_FILE="${IMAGES_DIR}/template.svg"

name="$1"

# Better sanitization - keep more characters, just replace problematic ones
sanitized_name=$(echo "$name" | sed 's/[^a-zA-Z0-9._-]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g')

# Ensure we have a name (fallback if sanitization removes everything)
if [[ -z "$sanitized_name" ]]; then
    sanitized_name="unnamed-figure"
fi

svg_file="${IMAGES_DIR}/${sanitized_name}.svg"

# Copy template and rename
cp "$TEMPLATE_FILE" "$svg_file"

# Open Inkscape
GDK_BACKEND=x11 inkscape "$svg_file" >/dev/null 2>&1 &

# Output the markdown syntax for Neovim to insert (on single line, no trailing newline)
printf "![%s](%s/%s.svg)" "$name" "$IMAGES_DIR" "$sanitized_name"
