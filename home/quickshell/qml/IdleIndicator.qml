import QtQuick 6.0
import Quickshell
import Quickshell.Io

Item {
  // Only occupies space when visible; when idle is ON (hypridle running) this is hidden
  property bool idleActive: true

  implicitWidth: idleActive ? 0 : idleText.width
  implicitHeight: Theme.barHeight
  visible: !idleActive

  Process {
    id: idleCheck
    command: ["pgrep", "-x", "hypridle"]
    onExited: (code) => {
      idleActive = (code === 0)
    }
  }

  // Same behaviour as omarchy-toggle-idle: the indicator is only on screen
  // while idle locking is OFF, so clicking it turns locking back on.
  Process {
    id: idleToggle
    running: false
    command: [Quickshell.env("HOME") + "/.config/scripts/idle-toggle.sh"]
    onExited: { idleCheck.running = false; idleCheck.running = true }
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: { idleToggle.running = false; idleToggle.running = true }
  }

  Timer {
    interval: 5000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: idleCheck.running = true
  }

  Text {
    id: idleText
    anchors.centerIn: parent
    font.family: Theme.fontFamily
    font.pixelSize: Theme.indicatorSize
    color: Theme.indicator
    text: "󱫖"
  }
}
