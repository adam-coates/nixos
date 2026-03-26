import QtQuick 6.0
import QtQuick.Layouts 6.0
import Quickshell
import Quickshell.Wayland

PanelWindow {
  id: cc

  property bool showing: GlobalState.activePopup === "controlcenter"

  visible: showing
  anchors {
    top: true
    right: true
  }

  margins {
    top: 30
    right: 10
  }

  width: 320
  height: ccContent.implicitHeight + 20

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "quickshell-controlcenter"
  WlrLayershell.keyboardFocus: showing ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore

  color: Theme.bg
  // border
  Rectangle {
    anchors.fill: parent
    color: "transparent"
    border.color: Theme.accent
    border.width: 1
  }

  ColumnLayout {
    id: ccContent
    anchors {
      top: parent.top
      left: parent.left
      right: parent.right
      margins: 10
    }
    spacing: 15

    // ── Audio Section ──
    AudioSlider {}

    // Separator
    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.bg1 }

    // ── Bluetooth Section ──
    BluetoothPanel {}

    // Separator
    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.bg1 }

    // ── Network Section ──
    NetworkPanel {}
  }
}
