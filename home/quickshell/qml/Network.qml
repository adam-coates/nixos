import QtQuick 6.0
import Quickshell.Io

Item {
  width: netText.width + 16
  height: 26

  property string status: ""
  property string tooltip: ""

  Process {
    id: nmcliCheck
    command: ["nmcli", "-t", "-f", "TYPE,STATE,CONNECTION", "device"]
    running: true
    onExited: {
      var lines = stdout.trim().split("\n")
      var wifiLine = ""
      var ethLine = ""
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].startsWith("wifi:")) wifiLine = lines[i]
        if (lines[i].startsWith("ethernet:")) ethLine = lines[i]
      }

      if (ethLine.indexOf("connected") >= 0) {
        status = "\u{f0200}" // 󰀂 ethernet
        tooltip = "Ethernet: " + ethLine.split(":").pop()
      } else if (wifiLine.indexOf("connected") >= 0) {
        status = "\u{f05a9}" // 󰖩 wifi
        tooltip = "WiFi: " + wifiLine.split(":").pop()
      } else {
        status = "\u{f092e}" // 󰤮 disconnected
        tooltip = "Disconnected"
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
