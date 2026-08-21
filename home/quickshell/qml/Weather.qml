import QtQuick 6.0

// Bar icon only, as omarchy does it — all detail lives in WeatherPanel.
Item {
  id: weather

  // Set by ToggleGroup while the cluster is expanded.
  property bool revealed: false
  // Stay pinned while the panel is open, so it doesn't vanish under the cursor.
  readonly property bool shown: WeatherState.loaded
                                && (revealed || GlobalState.activePopup === "weather")

  implicitWidth: shown ? wIcon.width + 6 : 0
  implicitHeight: Theme.barHeight
  clip: true

  Behavior on implicitWidth { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

  Text {
    id: wIcon
    anchors.centerIn: parent
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    color: GlobalState.activePopup === "weather" ? Theme.accent : Theme.fg
    opacity: weather.shown ? 1 : 0
    Behavior on color { ColorAnimation { duration: 120 } }
    Behavior on opacity { NumberAnimation { duration: 160 } }
    text: WeatherState.icon
  }

  MouseArea {
    anchors.fill: parent
    enabled: weather.shown
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      GlobalState.toggle("weather")
      if (GlobalState.activePopup === "weather") WeatherState.refresh()
    }
  }
}
