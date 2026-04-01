import QtQuick 6.0
import Quickshell.Io

Item {
  implicitWidth: netText.width + (vpnActive ? 14 : 0) + 16
  implicitHeight: 26

  property string status: ""
  property bool connected: false
  property bool vpnActive: false

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
      var hasVpn = false
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].startsWith("wifi:")) wifiLine = lines[i]
        if (lines[i].startsWith("ethernet:")) ethLine = lines[i]
        if (lines[i].startsWith("tun:") && lines[i].indexOf("connected") >= 0) hasVpn = true
      }
      vpnActive = hasVpn
      if (ethLine.indexOf("connected") >= 0) {
        status = "\u{f0200}" // 󰀂 ethernet
        connected = true
      } else if (wifiLine.indexOf("connected") >= 0) {
        status = "\u{f05a9}" // 󰖩 wifi
        connected = true
      } else {
        status = "\u{f092e}" // 󰤮 disconnected
        connected = false
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
    anchors.horizontalCenterOffset: vpnActive ? -6 : 0
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    color: connected ? Theme.green : Theme.red
    Behavior on color { ColorAnimation { duration: 120 } }
    text: status || "\u{f092e}"
  }

  Text {
    visible: vpnActive
    anchors.left: netText.right
    anchors.leftMargin: 2
    anchors.verticalCenter: parent.verticalCenter
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize - 2
    color: Theme.accent
    text: "\u{f0582}" // 󰖂 vpn shield
  }

  MouseArea {
    anchors.fill: parent
    onClicked: GlobalState.toggle("network")
    hoverEnabled: true
  }
}
