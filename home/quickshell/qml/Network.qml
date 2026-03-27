import QtQuick 6.0
import Quickshell.Io

Item {
  width: netText.width + 16
  height: 26

  property string status: ""

  Process {
    id: nmcliCheck
    command: ["nmcli", "-t", "-f", "TYPE,STATE,CONNECTION", "device"]
    running: true
    property var _lines: []
    stdout: SplitParser {
      onRead: line => nmcliCheck._lines.push(line)
    }
    onExited: {
      var lines = nmcliCheck._lines
      nmcliCheck._lines = []
      var wifiLine = ""
      var ethLine = ""
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].startsWith("wifi:")) wifiLine = lines[i]
        if (lines[i].startsWith("ethernet:")) ethLine = lines[i]
      }
      if (ethLine.indexOf("connected") >= 0) {
        status = "\u{f0200}" // 󰀂 ethernet
      } else if (wifiLine.indexOf("connected") >= 0) {
        status = "\u{f05a9}" // 󰖩 wifi
      } else {
        status = "\u{f092e}" // 󰤮 disconnected
      }
    }
  }

  Timer {
    interval: 3000
    running: true
    repeat: true
    onTriggered: nmcliCheck.running = true
  }

  Text {
    id: netText
    anchors.centerIn: parent
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    color: Theme.fg
    text: status || "\u{f092e}"
  }

  MouseArea {
    anchors.fill: parent
    onClicked: GlobalState.toggle("controlcenter")
    hoverEnabled: true
  }
}
