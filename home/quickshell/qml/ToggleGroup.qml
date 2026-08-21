import QtQuick 6.0

// Hover-expanding cluster of toggles, modelled on omarchy's tray-expander
// drawer. Collapsed it is just a chevron; hovering slides the toggles out.
// Anything currently active stays pinned so state is visible at a glance.
Item {
  id: group

  property bool expanded: false

  implicitWidth: row.width
  implicitHeight: Theme.barHeight

  // Small grace period so the cluster doesn't snap shut when the pointer
  // crosses a gap between icons.
  Timer {
    id: collapseTimer
    interval: 350
    onTriggered: group.expanded = false
  }

  // Covers the whole cluster without stealing clicks from the toggles.
  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.NoButton
    z: -1
    onContainsMouseChanged: {
      if (containsMouse) {
        collapseTimer.stop()
        group.expanded = true
      } else {
        collapseTimer.restart()
      }
    }
  }

  Row {
    id: row
    height: parent.height
    spacing: 0

    Text {
      id: chevron
      height: parent.height
      verticalAlignment: Text.AlignVCenter
      font.family: Theme.fontFamily
      font.pixelSize: Theme.fontSize
      color: group.expanded ? Theme.accent : Theme.gray
      text: "\u{f0141}"   // 󰅁 chevron; flips when the drawer opens
      rightPadding: 4

      rotation: group.expanded ? 180 : 0
      Behavior on rotation { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
      Behavior on color { ColorAnimation { duration: 150 } }
    }

    NightLight { revealed: group.expanded }
    DndToggle  { revealed: group.expanded }
  }
}
