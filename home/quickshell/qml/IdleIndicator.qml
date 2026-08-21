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

  // Set by ToggleGroup while the cluster is expanded. Stays pinned while the
  // machine is being held awake, so that state is never invisible.
  property bool revealed: false
  readonly property bool shown: revealed || !idleActive

  implicitWidth: shown ? idleText.width + 6 : 0
  implicitHeight: Theme.barHeight
  clip: true

  Behavior on implicitWidth { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

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
    enabled: indicator.shown
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
    opacity: indicator.shown ? 1 : 0
    text: indicator.idleActive ? "\u{f04b2}" : "\u{f0176}"  // 󰒲 sleep / 󰅶 coffee
    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on opacity { NumberAnimation { duration: 160 } }
  }
}
