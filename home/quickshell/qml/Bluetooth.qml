import QtQuick 6.0
import Quickshell.Io

Item {
  implicitWidth: btText.width
  implicitHeight: Theme.barHeight

  property bool powered: true
  property bool connected: false

  Process {
    id: btCheck
    // Emits one of: off / on / connected
    command: ["bash", "-c",
      "if ! bluetoothctl show 2>/dev/null | grep -q 'Powered: yes'; then echo off; " +
      "elif bluetoothctl info 2>/dev/null | grep -q 'Connected: yes'; then echo connected; " +
      "else echo on; fi"]
    running: true
    property string _output: ""
    stdout: SplitParser {
      onRead: line => btCheck._output = line.trim()
    }
    onExited: {
      powered = btCheck._output !== "off"
      connected = btCheck._output === "connected"
      btCheck._output = ""
    }
  }

  Timer {
    interval: 3000
    running: true
    repeat: true
    onTriggered: btCheck.running = true
  }

  Text {
    id: btText
    anchors.centerIn: parent
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    // Omarchy carries state in the glyph, not the colour.
    color: GlobalState.activePopup === "bluetooth" ? Theme.accent : Theme.fg
    Behavior on color { ColorAnimation { duration: 120 } }
    text: !powered ? "\u{f00b2}"        // 󰂲 off
        : connected ? "\u{f00b1}"       // 󰂱 connected
        : "\u{f294}"                    //  on, nothing paired
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: GlobalState.toggle("bluetooth")
    hoverEnabled: true
  }
}
