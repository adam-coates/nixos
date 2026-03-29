import QtQuick 6.0
import Quickshell.Bluetooth

Item {
  implicitWidth: btText.width + 16
  implicitHeight: 26

  property bool powered: {
    var adapters = Bluetooth.adapters
    for (var i = 0; i < adapters.length; i++) {
      if (adapters[i].enabled) return true
    }
    return false
  }

  property int connectedCount: {
    var count = 0
    var devices = Bluetooth.devices
    for (var i = 0; i < devices.length; i++) {
      if (devices[i].connected) count++
    }
    return count
  }

  Text {
    id: btText
    anchors.centerIn: parent
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    color: connectedCount > 0 ? Theme.green : Theme.red
    Behavior on color { ColorAnimation { duration: 120 } }
    text: "\u{f00af}" // 󰂯 always the same symbol, no strikethrough
  }

  MouseArea {
    anchors.fill: parent
    onClicked: GlobalState.toggle("bluetooth")
    hoverEnabled: true
  }
}
