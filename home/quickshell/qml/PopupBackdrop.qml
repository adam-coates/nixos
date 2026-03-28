import QtQuick 6.0
import Quickshell
import Quickshell.Wayland

PanelWindow {
  id: backdrop

  // Visible for all small panel popups (not launcher/powermenu which have their own)
  readonly property bool active: {
    const p = GlobalState.activePopup
    return p !== "" && p !== "launcher" && p !== "powermenu"
  }

  visible: active

  anchors { top: true; left: true; right: true; bottom: true }
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.namespace: "quickshell-backdrop"
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore
  color: "transparent"

  MouseArea {
    anchors.fill: parent
    onClicked: GlobalState.closeAll()
  }
}
