import QtQuick 6.0

// Notification silencing, omarchy's third centre indicator — here it lives in
// the hover-expander instead, and stays pinned while active.
Item {
  id: dnd

  // Set by ToggleGroup while the cluster is expanded.
  property bool revealed: false
  readonly property bool active: NotifState.silenced

  implicitWidth: (revealed || active) ? dndIcon.width + 6 : 0
  implicitHeight: Theme.barHeight
  clip: true

  Behavior on implicitWidth { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

  Text {
    id: dndIcon
    anchors.centerIn: parent
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    color: dnd.active ? Theme.indicator : Theme.fg
    opacity: (dnd.revealed || dnd.active) ? 1 : 0
    text: dnd.active ? "\u{f009b}" : "\u{f009a}"  // 󰂛 bell-off / 󰂚 bell
    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on opacity { NumberAnimation { duration: 160 } }
  }

  MouseArea {
    anchors.fill: parent
    enabled: dnd.revealed || dnd.active
    cursorShape: Qt.PointingHandCursor
    onClicked: NotifState.toggleSilenced()
  }
}
