import QtQuick 6.0
import QtQuick.Layouts 6.0
import Quickshell.Bluetooth

ColumnLayout {
  spacing: 8

  // Header
  RowLayout {
    Layout.fillWidth: true

    Text {
      text: "Bluetooth"
      font.family: Theme.fontFamily
      font.pixelSize: 12
      font.bold: true
      color: Theme.fg
    }

    Item { Layout.fillWidth: true }

    // Power toggle
    Rectangle {
      width: 36
      height: 18
      radius: 9
      color: btPowered ? Theme.accent : Theme.bg2

      property bool btPowered: {
        var adapters = Bluetooth.adapters
        for (var i = 0; i < adapters.length; i++) {
          if (adapters[i].powered) return true
        }
        return false
      }

      Rectangle {
        x: parent.btPowered ? parent.width - width - 2 : 2
        y: 2
        width: 14
        height: 14
        radius: 7
        color: Theme.fg

        Behavior on x { NumberAnimation { duration: 150 } }
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          var adapters = Bluetooth.adapters
          for (var i = 0; i < adapters.length; i++) {
            adapters[i].powered = !parent.btPowered
          }
        }
      }
    }
  }

  // Device list
  Repeater {
    model: Bluetooth.devices

    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: 32
      color: modelData.connected ? Theme.accentAlpha(0.1) : "transparent"
      radius: 4

      RowLayout {
        anchors {
          fill: parent
          leftMargin: 8
          rightMargin: 8
        }
        spacing: 8

        Text {
          text: modelData.name || "Unknown"
          font.family: Theme.fontFamily
          font.pixelSize: 12
          color: modelData.connected ? Theme.accent : Theme.fg
          Layout.fillWidth: true
          elide: Text.ElideRight
        }

        Text {
          text: modelData.connected ? "Connected" : ""
          font.family: Theme.fontFamily
          font.pixelSize: 10
          color: Theme.gray
        }
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          if (modelData.connected) modelData.disconnect()
          else modelData.connect()
        }
      }
    }
  }

  // Empty state
  Text {
    visible: Bluetooth.devices.length === 0
    text: "No devices"
    font.family: Theme.fontFamily
    font.pixelSize: 11
    color: Theme.gray
  }
}
