#!/usr/bin/env python3

# Usage:
# 1. Show menu: walker --dmenu < <(stylinator.py --menu) | stylinator.py | wl-copy -t "image/x-inkscape-svg"
# 2. Direct input: walker --dmenu | stylinator.py | wl-copy -t "image/x-inkscape-svg"

import sys
from typing import Any

STYLE_OPTIONS = """s - Stroke (border)
a - Arrow end
x - Arrows both ends
d - Dashed line
e - Dotted line
g - Thick/bold stroke
h - Very thick stroke
f - Semi-transparent fill (12%)
b - Solid black fill
w - Solid white fill
---
sa - Stroke + arrow
ag - Bold arrow
fs - Fill + stroke
sg - Bold stroke
dg - Bold dashed line"""


def gen_style(combination):
    """This creates the style depending on the combination of keys."""

    # Stolen from TikZ
    mm = 3.78  # pixels
    w = 0.4 * mm
    thick_width = 0.8 * mm
    very_thick_width = 1.2 * mm

    style: dict[str, Any] = {"stroke-opacity": 1}

    if {"s", "a", "d", "g", "h", "x", "e"} & combination:
        style["stroke"] = "black"
        style["stroke-width"] = w
        style["marker-end"] = "none"
        style["marker-start"] = "none"
        style["stroke-dasharray"] = "none"
    else:
        style["stroke"] = "none"

    if "g" in combination:
        w = thick_width
        style["stroke-width"] = w

    if "h" in combination:
        w = very_thick_width
        style["stroke-width"] = w

    if "a" in combination:
        style["marker-end"] = "url(#ArrowWideAgain)"

    if "x" in combination:
        style["marker-start"] = "url(#ArrowWideAgain)"
        style["marker-end"] = "url(#ArrowWideAgain)"

    if "d" in combination:
        style["stroke-dasharray"] = f"{w},{2 * mm}"

    if "e" in combination:
        style["stroke-dasharray"] = f"{3 * mm},{3 * mm}"

    if "f" in combination:
        style["fill"] = "black"
        style["fill-opacity"] = 0.12

    if "b" in combination:
        style["fill"] = "black"
        style["fill-opacity"] = 1

    if "w" in combination:
        style["fill"] = "white"
        style["fill-opacity"] = 1

    if {"f", "b", "w"} & combination:
        style["marker-end"] = "none"
        style["marker-start"] = "none"

    if not {"f", "b", "w"} & combination:
        style["fill"] = "none"
        style["fill-opacity"] = 1

    if style["fill"] == "none" and style["stroke"] == "none":
        return

    # Start creation of the svg.
    # Later on, we'll write this svg to the clipboard, and send Ctrl+Shift+V to
    # Inkscape, to paste this style.

    svg = """
          <?xml version="1.0" encoding="UTF-8" standalone="no"?>
          <svg>
          """
    # If a marker is applied, add its definition to the clipboard
    # Arrow styles stolen from tikz
    if ("marker-end" in style and style["marker-end"] != "none") or (
        "marker-start" in style and style["marker-start"] != "none"
    ):
        svg += f"""
                <defs id="marker-defs">
                <marker
                   style="overflow:visible"
                   id="ArrowWideAgain"
                   refX="0"
                   refY="0"
                   orient="auto-start-reverse"
                   markerWidth="1"
                   markerHeight="1"
                   viewBox="0 0 1 1"
                   preserveAspectRatio="xMidYMid">
                  <path
                     style="fill:none;stroke:context-stroke;stroke-width:1;stroke-linecap:butt"
                     d="M 3,-3 0,0 3,3"
                     transform="rotate(180,0.125,0)"
                     sodipodi:nodetypes="ccc"
                     id="path4" />
                </marker>
                <marker
                id="marker-arrow-{w}"
                orient="auto-start-reverse"
                refY="0" refX="0"
                markerHeight="1.690" markerWidth="0.911">
                  <g transform="scale({(2.40 * w + 3.87) / (4.5 * w)})">
                    <path
                       d="M -1.55415,2.0722 C -1.42464,1.29512 0,0.1295 0.38852,0 0,-0.1295 -1.42464,-1.29512 -1.55415,-2.0722"
                       style="fill:none;stroke:#000000;stroke-width:{0.6};stroke-linecap:round;stroke-linejoin:round;stroke-miterlimit:10;stroke-dasharray:none;stroke-opacity:1"
                       inkscape:connector-curvature="0" />
                   </g>
                </marker>
                </defs>
                """

    style_string = ";".join(
        "{}: {}".format(key, value)
        for key, value in sorted(style.items(), key=lambda x: x[0])
    )
    svg += f'<inkscape:clipboard style="{style_string}" /></svg>'

    return svg


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--menu":
        # Print menu options
        print(STYLE_OPTIONS)
    else:
        # Process input
        user_input = input().strip()

        # Extract just the key combination (remove description if present)
        # e.g., "sa - Stroke + arrow" -> "sa"
        combination_str = user_input.split()[0] if user_input else ""

        # Skip separator lines
        if combination_str == "---":
            sys.exit(0)

        result = gen_style(combination=set(combination_str))
        if result:
            print(result)
