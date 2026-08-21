import QtQuick 6.0
import Quickshell.Io

Item {
  implicitWidth: audioText.width
  implicitHeight: Theme.barHeight

  property real volume: 0
  property bool muted: false

  Process {
    id: volCheck
    command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
    running: true
    property string _output: ""
    stdout: SplitParser {
      onRead: line => volCheck._output = line
    }
    onExited: {
      var line = volCheck._output
      volCheck._output = ""
      var match = line.match(/Volume:\s+([\d.]+)/)
      if (match) volume = parseFloat(match[1])
      muted = line.indexOf("[MUTED]") >= 0
    }
  }

  Timer {
    interval: 2000
    running: true
    repeat: true
    onTriggered: volCheck.running = true
  }

  Process {
    id: setVolProc
    running: false
  }

  Process {
    id: toggleMuteProc
    command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
    running: false
  }

  Text {
    id: audioText
    anchors.centerIn: parent
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    color: GlobalState.activePopup === "audio" ? Theme.accent : Theme.fg
    Behavior on color { ColorAnimation { duration: 120 } }
    // Omarchy's exact pulseaudio glyphs (Font Awesome range, not Material).
    text: {
      if (muted) return "\u{eee8}"          //  format-muted
      if (volume > 0.66) return "\u{f028}"  //  high
      if (volume > 0.33) return "\u{f027}"  //  medium
      return "\u{f026}"                     //  low
    }
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: (mouse) => {
      if (mouse.button === Qt.RightButton) {
        toggleMuteProc.running = false
        toggleMuteProc.running = true
        muted = !muted
      } else {
        GlobalState.toggle("audio")
      }
    }
    onWheel: (wheel) => {
      var delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05
      var newVol = Math.max(0, Math.min(1.5, volume + delta))
      volume = newVol
      setVolProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", newVol.toFixed(2)]
      setVolProc.running = false
      setVolProc.running = true
    }
    hoverEnabled: true
  }
}
