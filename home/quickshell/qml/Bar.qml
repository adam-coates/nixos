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

  exclusiveZone: Theme.barHeight
  height: Theme.barHeight

  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.namespace: "quickshell-bar"

  // Omarchy's waybar is flat and opaque with no border of any kind.
  color: Theme.bg

  RowLayout {
    anchors.fill: parent
    anchors.leftMargin: Theme.barMargin
    anchors.rightMargin: Theme.barMargin
    spacing: 0

    // ── Left: Workspaces ──
    Workspaces {
      Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
    }

    Item { Layout.fillWidth: true }

    // ── Center: Clock + status indicators ──
    RowLayout {
      Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
      spacing: 5

      Clock {}
      RecordingIndicator {}
      IdleIndicator {}
      DictationIndicator {}
    }

    Item { Layout.fillWidth: true }

    // ── Right: System widgets ──
    RowLayout {
      Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
      spacing: Theme.moduleGap

      // System tray (collapsed by default, expands on hover)
      SysTray {}

      // Clipboard
      Item {
        implicitWidth: clipIcon.width; implicitHeight: Theme.barHeight
        Text {
          id: clipIcon
          anchors.centerIn: parent
          text: "󰅎"
          font.family: Theme.fontFamily
          font.pixelSize: Theme.fontSize
          color: GlobalState.activePopup === "clipboard" ? Theme.accent : Theme.fg
          Behavior on color { ColorAnimation { duration: 120 } }
        }
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: GlobalState.toggle("clipboard")
        }
      }

      // Notification bell
      Item {
        implicitWidth: bellIcon.width; implicitHeight: Theme.barHeight
        Text {
          id: bellIcon
          anchors.centerIn: parent
          text: NotifState.unreadCount > 0 ? "󰂚" : "󰂜"
          font.family: Theme.fontFamily
          font.pixelSize: Theme.fontSize
          color: GlobalState.activePopup === "notifications" ? Theme.accent
               : (NotifState.unreadCount > 0 ? Theme.accent : Theme.fg)
          Behavior on color { ColorAnimation { duration: 120 } }
        }
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
