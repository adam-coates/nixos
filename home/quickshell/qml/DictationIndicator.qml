import QtQuick 6.0
import Quickshell.Io

Item {
  id: dictInd

  property string dictState: "idle"
  property bool recording: dictState === "recording" || dictState === "transcribing"

  width: recording ? (dictText.width + 8) : 0
  height: 26
  visible: recording
  clip: true

  Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

  // Read $XDG_RUNTIME_DIR/voxtype/state which contains "idle", "recording", or "transcribing"
  Process {
    id: stateReader
    property string _output: ""
    command: ["sh", "-c", "cat \"$XDG_RUNTIME_DIR/voxtype/state\" 2>/dev/null || echo idle"]
    running: false
    stdout: SplitParser {
      onRead: line => {
        var trimmed = line.trim()
        if (trimmed) stateReader._output = trimmed
      }
    }
    onExited: (code) => {
      if (code === 0 && stateReader._output) {
        dictInd.dictState = stateReader._output
      } else {
        dictInd.dictState = "idle"
      }
      stateReader._output = ""
    }
  }

  Timer {
    interval: 500
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: stateReader.running = true
  }

  Text {
    id: dictText
    anchors.centerIn: parent
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    color: Theme.red
    text: "\u{f036c}" // 󰍬 microphone

    SequentialAnimation on opacity {
      running: dictInd.recording
      loops: Animation.Infinite
      NumberAnimation { from: 1; to: 0.3; duration: 600; easing.type: Easing.InOutSine }
      NumberAnimation { from: 0.3; to: 1; duration: 600; easing.type: Easing.InOutSine }
    }
  }
}
