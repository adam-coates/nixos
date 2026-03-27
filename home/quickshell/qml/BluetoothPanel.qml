import QtQuick 6.0
import QtQuick.Layouts 6.0
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Wayland

PanelWindow {
  id: btPanel

  property bool showing: GlobalState.activePopup === "bluetooth"
  visible: showing

  anchors.top: true
  anchors.right: true
  margins { top: 30; right: 4 }
  width: 320
  height: Math.min(panelFlick.contentHeight + 24, 480)

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "quickshell-bluetooth"
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore
  color: "transparent"

  property var adapter: Bluetooth.defaultAdapter

  readonly property bool powered: adapter ? adapter.enabled : false
  readonly property bool scanning: adapter ? adapter.discovering : false

  readonly property var connectedDevices: {
    if (!adapter) return []
    var result = []
    for (var i = 0; i < adapter.devices.length; i++) {
      var d = adapter.devices[i]
      if (d.connected) result.push(d)
    }
    return result
  }

  readonly property var pairedDevices: {
    if (!adapter) return []
    var result = []
    for (var i = 0; i < adapter.devices.length; i++) {
      var d = adapter.devices[i]
      if (d.paired && !d.connected) result.push(d)
    }
    return result
  }

  readonly property var availableDevices: {
    if (!adapter) return []
    var result = []
    for (var i = 0; i < adapter.devices.length; i++) {
      var d = adapter.devices[i]
      if (!d.paired && !d.connected && d.deviceName) result.push(d)
    }
    return result
  }

  Rectangle {
    anchors.fill: parent
    color: Theme.bgAlpha(0.97)
    border.color: Theme.accent
    border.width: 1
    radius: 6

    Flickable {
      id: panelFlick
      anchors.fill: parent
      anchors.margins: 12
      contentHeight: content.implicitHeight
      clip: true

      ColumnLayout {
        id: content
        width: parent.width
        spacing: 10

        // Header
        RowLayout {
          Layout.fillWidth: true

          Text {
            text: "Bluetooth"
            font.family: Theme.fontFamily
            font.pixelSize: 13
            font.bold: true
            color: Theme.fg
          }

          Item { Layout.fillWidth: true }

          // Power toggle
          Rectangle {
            width: 36; height: 18; radius: 9
            color: btPanel.powered ? Theme.accent : Theme.bg2

            Rectangle {
              x: btPanel.powered ? parent.width - width - 2 : 2
              y: 2; width: 14; height: 14; radius: 7
              color: Theme.fg
              Behavior on x { NumberAnimation { duration: 150 } }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: { if (btPanel.adapter) btPanel.adapter.enabled = !btPanel.powered }
            }
          }
        }

        // Not powered message
        Text {
          visible: !btPanel.powered
          text: "Bluetooth is off"
          font.family: Theme.fontFamily
          font.pixelSize: 11
          color: Theme.gray
          Layout.fillWidth: true
          horizontalAlignment: Text.AlignHCenter
          topPadding: 10
          bottomPadding: 10
        }

        // ── Connected Devices ──
        Text {
          visible: btPanel.powered && btPanel.connectedDevices.length > 0
          text: "Connected"
          font.family: Theme.fontFamily
          font.pixelSize: 11
          color: Theme.gray
        }

        Repeater {
          model: btPanel.connectedDevices

          Rectangle {
            required property var modelData
            Layout.fillWidth: true
            height: 36; radius: 4
            color: Theme.accentAlpha(0.1)

            RowLayout {
              anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
              spacing: 6

              Text {
                text: "\u{f00af}" // 󰂯
                font.family: Theme.fontFamily
                font.pixelSize: 14
                color: Theme.accent
              }

              ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                  text: modelData.name || modelData.deviceName || "Unknown"
                  font.family: Theme.fontFamily
                  font.pixelSize: 11
                  color: Theme.accent
                  elide: Text.ElideRight
                  Layout.fillWidth: true
                }

                Text {
                  visible: modelData.batteryAvailable
                  text: "Battery: " + Math.round(modelData.battery * 100) + "%"
                  font.family: Theme.fontFamily
                  font.pixelSize: 9
                  color: Theme.gray
                }
              }

              Text {
                text: "Disconnect"
                font.family: Theme.fontFamily
                font.pixelSize: 10
                color: Theme.gray
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: modelData.disconnect()
                }
              }
            }
          }
        }

        // ── Paired Devices ──
        Text {
          visible: btPanel.powered && btPanel.pairedDevices.length > 0
          text: "Paired"
          font.family: Theme.fontFamily
          font.pixelSize: 11
          color: Theme.gray
        }

        Repeater {
          model: btPanel.pairedDevices

          Rectangle {
            required property var modelData
            Layout.fillWidth: true
            height: 36; radius: 4
            color: "transparent"

            RowLayout {
              anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
              spacing: 6

              Text {
                text: "\u{f00af}" // 󰂯
                font.family: Theme.fontFamily
                font.pixelSize: 14
                color: Theme.gray
              }

              Text {
                text: modelData.name || modelData.deviceName || "Unknown"
                font.family: Theme.fontFamily
                font.pixelSize: 11
                color: Theme.fg
                elide: Text.ElideRight
                Layout.fillWidth: true
              }

              Text {
                text: "Connect"
                font.family: Theme.fontFamily
                font.pixelSize: 10
                color: Theme.accent
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: modelData.connect()
                }
              }

              Text {
                text: "×"
                font.pixelSize: 14
                color: Theme.gray
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: modelData.forget()
                }
              }
            }
          }
        }

        Rectangle {
          Layout.fillWidth: true; height: 1; color: Theme.accentAlpha(0.3)
          visible: btPanel.powered
        }

        // ── Scan / Available Devices ──
        RowLayout {
          Layout.fillWidth: true
          visible: btPanel.powered

          Text {
            text: "Available"
            font.family: Theme.fontFamily
            font.pixelSize: 11
            color: Theme.gray
          }

          Item { Layout.fillWidth: true }

          Rectangle {
            width: scanLabel.implicitWidth + 16
            height: 22; radius: 4
            color: btPanel.scanning ? Theme.accentAlpha(0.2) : Theme.bg2

            Text {
              id: scanLabel
              anchors.centerIn: parent
              text: btPanel.scanning ? "Scanning..." : "Scan"
              font.family: Theme.fontFamily
              font.pixelSize: 10
              color: btPanel.scanning ? Theme.accent : Theme.fg
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (!btPanel.adapter) return
                btPanel.adapter.discovering = !btPanel.scanning
              }
            }
          }
        }

        Repeater {
          model: btPanel.availableDevices

          Rectangle {
            required property var modelData
            Layout.fillWidth: true
            height: 36; radius: 4
            color: "transparent"

            RowLayout {
              anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
              spacing: 6

              Text {
                text: "\u{f00af}" // 󰂯
                font.family: Theme.fontFamily
                font.pixelSize: 14
                color: Theme.gray
              }

              ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                  text: modelData.deviceName || modelData.address
                  font.family: Theme.fontFamily
                  font.pixelSize: 11
                  color: Theme.fg
                  elide: Text.ElideRight
                  Layout.fillWidth: true
                }

                Text {
                  text: modelData.address
                  font.family: Theme.fontFamily
                  font.pixelSize: 9
                  color: Theme.gray
                }
              }

              Text {
                text: modelData.pairing ? "Pairing..." : "Pair"
                font.family: Theme.fontFamily
                font.pixelSize: 10
                color: Theme.accent
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    if (!modelData.pairing) {
                      modelData.trusted = true
                      modelData.pair()
                    }
                  }
                }
              }
            }
          }
        }

        Text {
          visible: btPanel.powered && btPanel.scanning && btPanel.availableDevices.length === 0
          text: "Searching for devices..."
          font.family: Theme.fontFamily
          font.pixelSize: 11
          color: Theme.gray
          Layout.fillWidth: true
          horizontalAlignment: Text.AlignHCenter
          topPadding: 6
        }

        Item { height: 4 }
      }
    }
  }
}
