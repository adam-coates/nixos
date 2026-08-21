pragma Singleton
import QtQuick 6.0
import Quickshell

Singleton {
  id: root

  property string activePopup: ""
  property string previewFile: ""   // path shown in FilePreview window

  // Double-clicking an empty part of the bar fades its background out.
  // The bar keeps its exclusive zone, so windows don't reflow.
  property bool barTransparent: false

  // Distance from the screen's right edge to the centre of the tray icon.
  // Bar.qml publishes this so SysTrayPanel can anchor under the icon instead
  // of a hardcoded margin that breaks whenever bar spacing changes.
  property real trayIconFromRight: 144

  // Lock screen signal
  signal lockRequested()

  function toggle(name) {
    if (activePopup === name) {
      activePopup = ""
    } else {
      activePopup = name
    }
  }

  function closeAll() {
    activePopup = ""
    previewFile = ""
  }

  function requestLock() {
    closeAll()
    lockRequested()
  }
}
