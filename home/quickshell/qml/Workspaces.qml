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
      property bool active: HyprlandIpc.activeWorkspace === wsId

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
        anchors.centerIn: parent
        text: parent.wsId.toString()
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        color: parent.active ? Theme.accent : Theme.gray
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          HyprlandIpc.dispatch("workspace " + parent.wsId)
        }
      }

      // Hover effect
      MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: HyprlandIpc.dispatch("workspace " + parent.wsId)
      }

      states: State {
        when: hoverArea.containsMouse && !active
        PropertyChanges { target: parent.children[1]; color: Theme.fg }
      }
    }
  }
}
