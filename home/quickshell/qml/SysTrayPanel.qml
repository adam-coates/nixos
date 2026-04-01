import QtQuick 6.0
import QtQuick.Layouts 6.0
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import Quickshell.Widgets

PanelWindow {
  id: trayPanel

  property bool showing: GlobalState.activePopup === "systray"
  property int iconSize: 20
  property int cellSize: 36

  visible: showing

  anchors.top: true
  anchors.right: true
  margins { top: 30; right: 144 }
  width: cellSize + 32
  height: trayColumn.height + 32

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "quickshell-systray"
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore
  color: "transparent"

  Timer {
    id: closeTimer
    interval: 400
    onTriggered: GlobalState.activePopup = ""
  }

  Rectangle {
    anchors.fill: parent
    color: Theme.bgAlpha(0.97)
    border.color: Theme.accentAlpha(0.5)
    border.width: 1
    radius: 6

    opacity: trayPanel.showing ? 1 : 0
    scale: trayPanel.showing ? 1 : 0.96
    transformOrigin: Item.Top
    Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

    // Hover detection for the whole panel
    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.NoButton
      z: -1

      onContainsMouseChanged: {
        if (containsMouse) {
          closeTimer.stop()
        } else {
          closeTimer.start()
        }
      }
    }

    Column {
      id: trayColumn
      anchors.centerIn: parent
      spacing: 0

      Repeater {
        model: SystemTray.items

        Item {
          required property var modelData
          width: trayPanel.cellSize
          height: trayPanel.cellSize

          IconImage {
            id: itemIcon
            anchors.centerIn: parent
            width: trayPanel.iconSize
            height: trayPanel.iconSize
            backer.fillMode: Image.PreserveAspectFit
            source: {
              let icon = modelData.icon ?? ""
              if (icon === "") return ""
              if (icon.includes("?path=")) {
                const chunks = icon.split("?path=")
                const name = chunks[0]
                const path = chunks[1]
                const fileName = name.substring(name.lastIndexOf("/") + 1)
                return "file://" + path + "/" + fileName
              }
              return icon
            }
            visible: status === Image.Ready
          }

          // Fallback: resolve from hicolor theme directly (for apps not in active icon theme)
          Image {
            id: fallbackIcon
            anchors.centerIn: parent
            sourceSize.width: trayPanel.iconSize
            sourceSize.height: trayPanel.iconSize
            smooth: true
            visible: itemIcon.status !== Image.Ready && status === Image.Ready
            source: {
              if (itemIcon.status === Image.Ready) return ""
              let icon = modelData.icon ?? ""
              if (icon === "" || icon.startsWith("/") || icon.startsWith("file:")) return ""
              return "file:///run/current-system/sw/share/icons/hicolor/scalable/apps/" + icon + ".svg"
            }
          }

          Text {
            anchors.centerIn: parent
            visible: itemIcon.status !== Image.Ready && fallbackIcon.status !== Image.Ready
            text: modelData.title ? modelData.title.charAt(0).toUpperCase() : "?"
            font.family: Theme.fontFamily
            font.pixelSize: 13
            color: Theme.gray
          }

          MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onContainsMouseChanged: {
              if (containsMouse) closeTimer.stop()
            }

            Rectangle {
              anchors.fill: parent
              radius: 4
              z: -1
              color: parent.containsMouse ? Theme.accentAlpha(0.15) : "transparent"
              Behavior on color { ColorAnimation { duration: 100 } }
            }

            onClicked: mouse => {
              if (mouse.button === Qt.RightButton) {
                if (modelData.hasMenu) {
                  modelData.display(trayPanel, mouse.x, mouse.y)
                } else {
                  modelData.secondaryActivate()
                }
              } else {
                modelData.activate()
              }
            }
          }
        }
      }
    }
  }
}
