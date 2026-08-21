import QtQuick 6.0
import Quickshell.Io

// Omarchy shows a static 󰍛 and defers to btop. This keeps the glyph but tints
// it as load climbs, and opens a real panel instead of a terminal.
Item {
  implicitWidth: cpuIcon.width
  implicitHeight: Theme.barHeight

  Text {
    id: cpuIcon
    anchors.centerIn: parent
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    text: "\u{f035b}" // 󰍛 memory/monitor
    color: {
      if (GlobalState.activePopup === "sysmon") return Theme.accent
      if (SysMonState.cpuPercent > 85) return Theme.indicator
      if (SysMonState.cpuPercent > 60) return Theme.orange
      return Theme.fg
    }
    Behavior on color { ColorAnimation { duration: 200 } }
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor
    onClicked: (mouse) => {
      if (mouse.button === Qt.RightButton) {
        // Omarchy's behaviour: drop straight into btop.
        btop.running = false
        btop.running = true
      } else {
        GlobalState.toggle("sysmon")
      }
    }
  }

  Process {
    id: btop
    running: false
    command: ["hyprctl", "dispatch", "hl.dsp.exec_cmd(\"ghostty -e btop\")"]
  }
}
