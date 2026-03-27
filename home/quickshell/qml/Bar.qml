import QtQuick 6.0
import QtQuick.Layouts 6.0
import Quickshell
import Quickshell.Wayland

PanelWindow {
  id: bar

  property var screen

  anchors {
    top: true
    left: true
    right: true
  }

  exclusiveZone: 26
  height: 26

  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.namespace: "quickshell-bar"

  color: Theme.bgAlpha(0.9)

  // Bottom border
  Rectangle {
    anchors.bottom: parent.bottom
    width: parent.width
    height: 1
    color: Theme.accentAlpha(0.5)
  }

  RowLayout {
    anchors.fill: parent
    anchors.leftMargin: 4
    anchors.rightMargin: 4
    spacing: 0

    // ── Left: Workspaces ──
    Workspaces {
      Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
    }

    Item { Layout.fillWidth: true }

    // ── Center: Clock + Idle ──
    RowLayout {
      Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
      spacing: 8

      Clock {}
      IdleIndicator {}
    }

    Item { Layout.fillWidth: true }

    // ── Right: System widgets ──
    RowLayout {
      Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
      spacing: 8

      // Notification bell
      Text {
        text: NotifState.unreadCount > 0 ? "󰂚" : "󰂜"
        font.family: Theme.fontFamily
        font.pixelSize: 14
        color: NotifState.unreadCount > 0 ? Theme.accent : Theme.gray
        verticalAlignment: Text.AlignVCenter

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: GlobalState.toggle("notifications")
        }
      }

      Bluetooth {}
      Network {}
      Audio {}
    }
  }
}
