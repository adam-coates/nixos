import QtQuick 6.0
import Quickshell
import Quickshell.Wayland

PanelWindow {
  id: panel

  property bool showing: GlobalState.activePopup === "weather"

  visible: showing

  anchors.top: true
  anchors.right: true
  margins { top: 30; right: 4 }
  implicitWidth: 260
  implicitHeight: content.height + 24

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "quickshell-weather"
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore
  color: "transparent"

  Rectangle {
    anchors.fill: parent
    color: Theme.bgAlpha(0.97)
    border.color: Theme.accentAlpha(0.5)
    border.width: 1
    radius: 6

    opacity: panel.showing ? 1 : 0
    scale: panel.showing ? 1 : 0.96
    transformOrigin: Item.Top
    Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

    Column {
      id: content
      anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
      spacing: 8

      // ── Current conditions ──
      Item {
        width: parent.width
        height: 40
        visible: WeatherState.loaded

        Text {
          id: bigIcon
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          font.family: Theme.fontFamily
          font.pixelSize: 28
          color: Theme.accent
          text: WeatherState.icon
        }

        Column {
          anchors.left: bigIcon.right
          anchors.leftMargin: 12
          anchors.verticalCenter: parent.verticalCenter
          spacing: 2

          Text {
            text: WeatherState.place
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize + 1
            color: Theme.fg
          }
          Text {
            text: WeatherState.desc
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 1
            color: Theme.gray
          }
        }

        Text {
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          text: WeatherState.tempC + "°"
          font.family: Theme.fontFamily
          font.pixelSize: 22
          color: Theme.fg
        }
      }

      // ── Detail rows ──
      Column {
        width: parent.width
        spacing: 3
        visible: WeatherState.loaded

        Repeater {
          model: [
            { k: "Feels like", v: WeatherState.feelsC + "°C" },
            { k: "Wind",       v: WeatherState.windKmph + " km/h " + WeatherState.windDir },
            { k: "Humidity",   v: WeatherState.humidity + "%" }
          ]
          Item {
            required property var modelData
            width: parent.width
            height: 17
            Text {
              anchors.left: parent.left
              text: modelData.k
              font.family: Theme.fontFamily
              font.pixelSize: Theme.fontSize - 1
              color: Theme.gray
            }
            Text {
              anchors.right: parent.right
              text: modelData.v
              font.family: Theme.fontFamily
              font.pixelSize: Theme.fontSize - 1
              color: Theme.fg
            }
          }
        }
      }

      Rectangle {
        width: parent.width
        height: 1
        color: Theme.bg2
        visible: WeatherState.loaded && WeatherState.forecast.length > 0
      }

      // ── Forecast ──
      Column {
        width: parent.width
        spacing: 4
        visible: WeatherState.loaded

        Repeater {
          model: WeatherState.forecast

          Item {
            required property var modelData
            width: parent.width
            height: 19

            Text {
              id: dayName
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
              // wttr dates are yyyy-MM-dd; index 0 is today.
              text: Qt.formatDateTime(new Date(modelData.date), "ddd")
              font.family: Theme.fontFamily
              font.pixelSize: Theme.fontSize - 1
              color: Theme.fg
            }

            Text {
              anchors.left: dayName.right
              anchors.leftMargin: 10
              anchors.verticalCenter: parent.verticalCenter
              text: WeatherState.iconFor(modelData.code, true)
              font.family: Theme.fontFamily
              font.pixelSize: Theme.fontSize
              color: Theme.accent
            }

            Text {
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              text: modelData.maxC + "° / " + modelData.minC + "°"
              font.family: Theme.fontFamily
              font.pixelSize: Theme.fontSize - 1
              color: Theme.gray
            }
          }
        }
      }

      // ── Placeholder states ──
      Text {
        width: parent.width
        visible: !WeatherState.loaded
        text: WeatherState.failed ? "Weather unavailable" : "Loading weather…"
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        color: Theme.gray
        horizontalAlignment: Text.AlignHCenter
      }
    }
  }
}
