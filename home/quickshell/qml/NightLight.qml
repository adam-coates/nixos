import QtQuick 6.0
import Quickshell.Io

// Warm-screen toggle backed by hyprsunset, matching omarchy-toggle-nightlight.
Item {
  id: night

  // Set by ToggleGroup while the cluster is expanded.
  property bool revealed: false
  property bool active: false

  // Colour temperature in Kelvin when enabled; lower is warmer.
  readonly property int temperature: 4000

  implicitWidth: (revealed || active) ? nightIcon.width + 6 : 0
  implicitHeight: Theme.barHeight
  clip: true

  Behavior on implicitWidth { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

  Process {
    id: check
    command: ["pgrep", "-x", "hyprsunset"]
    onExited: (code) => { night.active = (code === 0) }
  }

  Process {
    id: toggle
    running: false
    // Launch through the compositor so hyprsunset outlives the shell process.
    command: ["bash", "-c",
      "if pgrep -x hyprsunset >/dev/null; then pkill -x hyprsunset; " +
      "notify-send -u low '\u{f0594}    Night light off'; " +
      "else hyprctl dispatch exec 'hyprsunset -t " + night.temperature + "'; " +
      "notify-send -u low '\u{f0599}    Night light on'; fi"]
    onExited: { check.running = false; check.running = true }
  }

  Timer {
    interval: 5000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: check.running = true
  }

  Text {
    id: nightIcon
    anchors.centerIn: parent
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    color: night.active ? Theme.orange : Theme.fg
    opacity: (night.revealed || night.active) ? 1 : 0
    text: "\u{f0f85}"  // 󰾅 weather-night / moon
    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on opacity { NumberAnimation { duration: 160 } }
  }

  MouseArea {
    anchors.fill: parent
    enabled: night.revealed || night.active
    cursorShape: Qt.PointingHandCursor
    onClicked: { toggle.running = false; toggle.running = true }
  }
}
