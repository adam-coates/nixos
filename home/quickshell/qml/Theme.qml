pragma Singleton
import QtQuick 6.0
import Quickshell.Io

QtObject {
  id: root

  // ── File watcher: reads ~/.local/state/current-theme ──
  property string themeFile: StandardPaths.home + "/.local/state/current-theme"
  property bool isDark: true

  FileView {
    id: themeFileView
    path: root.themeFile
    watchChanges: true
    onTextChanged: {
      root.isDark = (text.trim() !== "light")
    }
  }

  // ── Dark palette ──
  readonly property var dark: ({
    bg:      "#282828",
    fg:      "#ebdbb2",
    accent:  "#d79921",
    red:     "#cc241d",
    green:   "#98971a",
    blue:    "#458588",
    purple:  "#b16286",
    aqua:    "#689d6a",
    orange:  "#d65d0e",
    gray:    "#928374",
    bg1:     "#3c3836",
    bg2:     "#504945"
  })

  // ── Light palette ──
  readonly property var light: ({
    bg:      "#fbf1c7",
    fg:      "#3c3836",
    accent:  "#b57614",
    red:     "#cc241d",
    green:   "#79740e",
    blue:    "#076678",
    purple:  "#8f3f71",
    aqua:    "#427b58",
    orange:  "#af3a03",
    gray:    "#7c6f64",
    bg1:     "#d5c4a1",
    bg2:     "#d5c4a1"
  })

  // ── Active colors (reactive) ──
  readonly property var colors: isDark ? dark : light

  readonly property color bg:     colors.bg
  readonly property color fg:     colors.fg
  readonly property color accent: colors.accent
  readonly property color red:    colors.red
  readonly property color green:  colors.green
  readonly property color blue:   colors.blue
  readonly property color purple: colors.purple
  readonly property color aqua:   colors.aqua
  readonly property color orange: colors.orange
  readonly property color gray:   colors.gray
  readonly property color bg1:    colors.bg1
  readonly property color bg2:    colors.bg2

  // ── Helpers ──
  function bgAlpha(a) { return Qt.rgba(bg.r, bg.g, bg.b, a) }
  function accentAlpha(a) { return Qt.rgba(accent.r, accent.g, accent.b, a) }

  readonly property string fontFamily: "TX02 Nerd Font"
  readonly property int fontSize: 13
}
