import QtQuick 6.0
import Quickshell
import Quickshell.Io

// Always on screen so idle locking can be turned *off* from the bar too.
// Omarchy only shows this while locking is disabled, which means its bar can
// re-enable locking but never disable it.
Item {
  id: indicator

  // True when hypridle is running, i.e. the screen will lock when idle.
  property bool idleActive: true

  // A little padding: this is a permanent control now, not a transient
  // indicator, so it needs a clickable target.
  implicitWidth: idleText.width + 6
  implicitHeight: Theme.barHeight

  Process {
    id: idleCheck
    command: ["pgrep", "-x", "hypridle"]
    onExited: (code) => {
      idleActive = (code === 0)
    }
  }

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
    font.pixelSize: Theme.fontSize
    // Red coffee cup while the machine is being held awake (omarchy's alarm
    // colour); a dim moon while normal idle locking is armed.
    color: indicator.idleActive ? Theme.gray : Theme.indicator
    text: indicator.idleActive ? "\u{f04b2}" : "\u{f0176}"  // 󰒲 sleep / 󰅶 coffee
    Behavior on color { ColorAnimation { duration: 150 } }
  }
}
