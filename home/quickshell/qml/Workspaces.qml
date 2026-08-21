import QtQuick 6.0
import QtQuick.Layouts 6.0
import Quickshell.Hyprland

RowLayout {
  id: root
  spacing: 0

  // Hyprland destroys empty workspaces, so "exists in the model" == "has windows".
  function occupied(id) {
    var ws = Hyprland.workspaces.values
    for (var i = 0; i < ws.length; i++) {
      if (ws[i].id === id) return true
    }
    return false
  }

  Repeater {
    model: 5

    Item {
      required property int index
      property int wsId: index + 1
      property bool active: Hyprland.focusedMonitor?.activeWorkspace?.id == wsId
      property bool hasWindows: root.occupied(wsId)

      Layout.preferredWidth: Theme.wsSlot
      Layout.preferredHeight: Theme.barHeight

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Hyprland.dispatch("workspace " + parent.wsId)
      }

      Text {
        anchors.centerIn: parent
        // Active workspace collapses to a filled dot; the rest stay numbered.
        text: parent.active ? "\u{f14fb}" : parent.wsId.toString()
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        color: parent.active ? Theme.accent : Theme.fg
        opacity: (parent.active || parent.hasWindows) ? 1.0 : Theme.emptyOpacity
        Behavior on color { ColorAnimation { duration: 80 } }
        Behavior on opacity { NumberAnimation { duration: 80 } }
      }
    }
  }
}
