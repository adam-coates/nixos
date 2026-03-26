import QtQuick 6.0
import Quickshell.Io

Item {
  width: idleText.width + 16
  height: 26

  property bool idleActive: false

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
    color: idleActive ? Theme.green : Theme.gray
    text: "\u{f1BA6}" // 󱮦
  }

  MouseArea {
    anchors.fill: parent
    onClicked: {
      toggleIdle.running = true
    }
  }

  Process {
    id: toggleIdle
    command: ["bash", "-c", "~/.config/scripts/idle-toggle.sh"]
    onExited: idleCheck.running = true
  }
}
