import QtQuick 6.0
import Quickshell.Io

Item {
  implicitWidth: btText.width + 16
  implicitHeight: 26

  property bool connected: false

  Process {
    id: btCheck
    command: ["bluetoothctl", "info"]
    running: true
    property string _output: ""
    stdout: SplitParser {
      onRead: line => btCheck._output += line + "\n"
    }
    onExited: {
      connected = btCheck._output.indexOf("Connected: yes") >= 0
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
    color: connected ? Theme.green : Theme.red
    Behavior on color { ColorAnimation { duration: 120 } }
    text: "\u{f00af}" // 󰂯
  }

  MouseArea {
    anchors.fill: parent
    onClicked: GlobalState.toggle("bluetooth")
    hoverEnabled: true
  }
}
