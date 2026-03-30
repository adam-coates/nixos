import QtQuick 6.0
import Quickshell.Io

Item {
  // Only occupies space when visible; when idle is ON (hypridle running) this is hidden
  property bool idleActive: true

  width: idleActive ? 0 : (idleText.width + 8)
  height: 26
  visible: !idleActive

  Process {
    id: idleCheck
    command: ["pgrep", "-x", "hypridle"]
    onExited: (code) => {
      idleActive = (code === 0)
    }
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
    font.pixelSize: Theme.fontSize
    color: Theme.red
    text: "󱫖"
  }
}
