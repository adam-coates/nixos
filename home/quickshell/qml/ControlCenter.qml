import QtQuick 6.0
import QtQuick.Layouts 6.0
import Quickshell
import Quickshell.Wayland

PanelWindow {
  id: cc

  property bool showing: GlobalState.activePopup === "controlcenter"

  visible: showing
  anchors.top: true
  anchors.right: true
  margins { top: 30; right: 4 }

  width: 300
  height: ccContent.implicitHeight + 20

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "quickshell-controlcenter"
  WlrLayershell.keyboardFocus: showing ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore
  color: "transparent"

  Rectangle {
    anchors.fill: parent
    color: Theme.bgAlpha(0.97)
    border.color: Theme.accent
    border.width: 1
    radius: 6

    ColumnLayout {
      id: ccContent
      anchors { top: parent.top; left: parent.left; right: parent.right; margins: 12 }
      spacing: 12

      // ── Audio ──
      AudioSlider {}

      Rectangle { Layout.fillWidth: true; height: 1; color: Theme.accentAlpha(0.3) }

      // ── Bluetooth ──
      BluetoothPanel {}

      Rectangle { Layout.fillWidth: true; height: 1; color: Theme.accentAlpha(0.3) }

      // ── Network ──
      NetworkPanel {}

      Item { height: 4 }
    }
  }
}
