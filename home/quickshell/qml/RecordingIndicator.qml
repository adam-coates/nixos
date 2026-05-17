import QtQuick 6.0
import Quickshell.Io

Item {
  id: indicator

  property bool recording: false

  width: recording ? (recIcon.width + 12) : 0
  height: 26
  visible: recording

  readonly property string nixPath:
    "export PATH=\"/run/wrappers/bin:/etc/profiles/per-user/$USER/bin:$HOME/.nix-profile/bin:/run/current-system/sw/bin:$PATH\"; "

  Process {
    id: recCheck
    command: ["bash", "-c", "test -f /tmp/capture-screenrecord-pid || test -f /tmp/capture-gif-pid"]
    onExited: (code) => { indicator.recording = (code === 0) }
  }

  Process { id: stopProc; running: false }

  Timer {
    interval: 500
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: { recCheck.running = false; recCheck.running = true }
  }

  Text {
    id: recIcon
    anchors.centerIn: parent
    font.family: Theme.fontFamily
    font.pixelSize: 12
    color: Theme.red
    text: "⏺"

    SequentialAnimation on opacity {
      running: indicator.recording
      loops: Animation.Infinite
      NumberAnimation { to: 0.3; duration: 800; easing.type: Easing.InOutSine }
      NumberAnimation { to: 1.0; duration: 800; easing.type: Easing.InOutSine }
    }
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      stopProc.command = [
        "bash", "-c",
        indicator.nixPath +
        "if [ -f /tmp/capture-screenrecord-pid ]; then ~/.config/scripts/capture-screenrecord.sh; " +
        "elif [ -f /tmp/capture-gif-pid ]; then ~/.config/scripts/capture-gif.sh; fi"
      ]
      stopProc.running = false
      stopProc.running = true
    }
  }
}
