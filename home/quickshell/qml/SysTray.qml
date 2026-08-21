import QtQuick 6.0
import QtQuick.Layouts 6.0

Item {
  implicitWidth: trayIcon.width
  implicitHeight: Theme.barHeight

  Text {
    id: trayIcon
    anchors.centerIn: parent
    text: "\u{f0614}"
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    color: GlobalState.activePopup === "systray" ? Theme.accent : Theme.fg
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
