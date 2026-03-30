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
      property bool active: Hyprland.focusedMonitor?.activeWorkspace?.id == wsId
      property bool hovered: false

      Layout.preferredWidth: 28
      Layout.preferredHeight: 26
      color: "transparent"

      HoverHandler {
        onHoveredChanged: parent.hovered = hovered
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Hyprland.dispatch("workspace " + parent.wsId)
      }

      // Bottom indicator
      Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 2
        color: parent.active ? Theme.accent : "transparent"
        Behavior on color { ColorAnimation { duration: 80 } }
      }

      Text {
        anchors.centerIn: parent
        text: parent.wsId.toString()
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        color: parent.active ? Theme.accent : (parent.hovered ? Theme.fg : Theme.gray)
        Behavior on color { ColorAnimation { duration: 80 } }
      }
    }
  }
}
