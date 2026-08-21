import QtQuick 6.0
import QtQuick.Layouts 6.0
import Quickshell
import Quickshell.Wayland

PanelWindow {
  id: bar

  property var screen

  // Maps the tray icon's centre into screen coordinates for SysTrayPanel.
  // The bar spans the full width, so bar-local x is already screen x.
  function publishTrayPos() {
    if (!trayItem || bar.width <= 0) return
    var p = trayItem.mapToItem(null, trayItem.width / 2, 0)
    GlobalState.trayIconFromRight = bar.width - p.x
  }

  onWidthChanged: publishTrayPos()

  anchors {
    top: true
    left: true
    right: true
  }

  exclusiveZone: Theme.barHeight
  implicitHeight: Theme.barHeight

  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.namespace: "quickshell-bar"

  // Painted by the Rectangle below so the background can animate; the window
  // itself stays transparent.
  color: "transparent"

  // Omarchy's waybar is flat and opaque with no border of any kind.
  Rectangle {
    anchors.fill: parent
    color: GlobalState.barTransparent ? Theme.bgAlpha(0) : Theme.bg
    Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.OutCubic } }
  }

  // Double-click any empty stretch of the bar to fade the background out.
  // Sits behind the widgets, so their own MouseAreas still win.
  MouseArea {
    anchors.fill: parent
    z: -1
    acceptedButtons: Qt.LeftButton
    onDoubleClicked: GlobalState.barTransparent = !GlobalState.barTransparent
  }

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
      // Transient alerts stay unconditionally visible — they already show
      // only while active, and hiding a live recording would be wrong.
      RecordingIndicator {}
      DictationIndicator {}
      // Weather, idle lock, night light and DND live behind the chevron.
      ToggleGroup {}
    }

    Item { Layout.fillWidth: true }

    // ── Right: System widgets ──
    RowLayout {
      Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
      spacing: Theme.moduleGap

      // System tray (collapsed by default, expands on hover)
      SysTray {
        id: trayItem
        // Publish where the icon sits so SysTrayPanel can anchor under it.
        onXChanged: bar.publishTrayPos()
        onWidthChanged: bar.publishTrayPos()
      }

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
      Cpu {}
    }
  }
}
