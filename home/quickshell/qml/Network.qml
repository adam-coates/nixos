import QtQuick 6.0
import Quickshell.Io

Item {
  implicitWidth: netText.width + (vpnActive ? 10 : 0)
  implicitHeight: Theme.barHeight

  property bool ethernet: false
  property bool wifi: false
  property int signalStrength: 0
  property bool vpnActive: false
  property bool connected: ethernet || wifi

  Process {
    id: nmcliCheck
    // Emits a single "eth|wifi|signal|vpn" summary line.
    command: ["bash", "-c",
      "d=$(nmcli -t -f TYPE,STATE device 2>/dev/null); " +
      "eth=$(grep -c '^ethernet:connected' <<< \"$d\"); " +
      "wif=$(grep -c '^wifi:connected' <<< \"$d\"); " +
      "vpn=$(grep -c '^tun:connected' <<< \"$d\"); " +
      "sig=$(nmcli -t -f ACTIVE,SIGNAL device wifi 2>/dev/null | awk -F: '$1==\"yes\"{print $2; exit}'); " +
      "echo \"${eth}|${wif}|${sig:-0}|${vpn}\""]
    running: true
    property string _output: ""
    stdout: SplitParser {
      onRead: line => { if (line.indexOf("|") >= 0) nmcliCheck._output = line.trim() }
    }
    onExited: {
      var parts = nmcliCheck._output.split("|")
      nmcliCheck._output = ""
      if (parts.length < 4) return
      ethernet = parseInt(parts[0]) > 0
      wifi = parseInt(parts[1]) > 0
      signalStrength = parseInt(parts[2]) || 0
      vpnActive = parseInt(parts[3]) > 0
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
    anchors.horizontalCenterOffset: vpnActive ? -5 : 0
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    color: GlobalState.activePopup === "network" ? Theme.accent : Theme.fg
    Behavior on color { ColorAnimation { duration: 120 } }
    text: {
      if (ethernet) return "\u{f0200}"                      // 󰀂 ethernet
      if (!wifi) return "\u{f092e}"                         // 󰤮 disconnected
      // Omarchy's five-step wifi ramp: 󰤯 󰤟 󰤢 󰤥 󰤨
      var icons = ["\u{f092f}", "\u{f091f}", "\u{f0922}", "\u{f0925}", "\u{f0928}"]
      return icons[Math.min(4, Math.floor(signalStrength / 20))]
    }
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
    cursorShape: Qt.PointingHandCursor
    onClicked: GlobalState.toggle("network")
    hoverEnabled: true
  }
}
