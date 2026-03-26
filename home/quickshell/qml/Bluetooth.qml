import QtQuick 6.0
import Quickshell.Bluetooth

Item {
  width: btText.width + 16
  height: 26

  property bool powered: {
    var adapters = Bluetooth.adapters
    for (var i = 0; i < adapters.length; i++) {
      if (adapters[i].powered) return true
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
    color: Theme.fg
    text: {
      if (!powered) return "\u{f00b2}" // 󰂲 off
      if (connectedCount > 0) return "\u{f00b1}" // 󰂱 connected
      return "\u{f00af}" // 󰂯 on
    }
  }

  MouseArea {
    anchors.fill: parent
    onClicked: GlobalState.toggle("controlcenter")
    hoverEnabled: true
  }
}
