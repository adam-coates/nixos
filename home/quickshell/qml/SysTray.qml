import QtQuick 6.0
import QtQuick.Layouts 6.0

Item {
  width: 28
  height: 26

  Text {
    anchors.centerIn: parent
    text: "\u{f0614}"
    font.family: Theme.fontFamily
    font.pixelSize: 14
    color: GlobalState.activePopup === "systray" ? Theme.accent : Theme.gray
    Behavior on color { ColorAnimation { duration: 120 } }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: GlobalState.toggle("systray")
    onContainsMouseChanged: {
      if (containsMouse) {
        GlobalState.activePopup = "systray"
      }
    }
  }
}
