import QtQuick 6.0
import Quickshell
import Quickshell.Wayland

PanelWindow {
  id: wallpaper

  property var screen

  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }

  WlrLayershell.layer: WlrLayer.Background
  WlrLayershell.namespace: "quickshell-wallpaper"
  exclusionMode: ExclusionMode.Ignore

  color: Theme.bg

  Image {
    anchors.fill: parent
    source: Theme.isDark
      ? "file:///home/adam/Pictures/wallpapers/gruvbox_dark.png"
      : "file:///home/adam/Pictures/wallpapers/gruvbox_light.png"
    fillMode: Image.PreserveAspectCrop
    cache: false

    // Crossfade on theme change
    Behavior on source {
      PropertyAnimation { duration: 300 }
    }
  }
}
