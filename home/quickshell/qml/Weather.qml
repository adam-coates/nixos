import QtQuick 6.0

// Bar icon only, as omarchy does it — all detail lives in WeatherPanel.
Item {
  implicitWidth: WeatherState.loaded ? wIcon.width : 0
  implicitHeight: Theme.barHeight
  visible: WeatherState.loaded

  Text {
    id: wIcon
    anchors.centerIn: parent
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    color: GlobalState.activePopup === "weather" ? Theme.accent : Theme.fg
    Behavior on color { ColorAnimation { duration: 120 } }
    text: WeatherState.icon
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      GlobalState.toggle("weather")
      if (GlobalState.activePopup === "weather") WeatherState.refresh()
    }
  }
}
