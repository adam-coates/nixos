import QtQuick 6.0
import QtQuick.Layouts 6.0
import Quickshell.Hyprland

RowLayout {
  spacing: 0

  Repeater {
    model: 5

    Rectangle {
      required property int index
      property int wsId: index + 1
      property bool active: Hyprland.focusedMonitor?.activeWorkspace?.id === wsId

      Layout.preferredWidth: 28
      Layout.preferredHeight: 26
      color: "transparent"

      // Bottom indicator
      Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 2
        color: parent.active ? Theme.accent : "transparent"
      }

      Text {
        id: wsText
        anchors.centerIn: parent
        text: parent.wsId.toString()
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        color: parent.active ? Theme.accent : (hoverArea.containsMouse ? Theme.fg : Theme.gray)
      }

      MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Hyprland.dispatch("workspace " + parent.wsId)
      }
    }
  }
}
