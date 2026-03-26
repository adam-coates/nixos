pragma Singleton
import QtQuick 6.0
import Quickshell

Singleton {
  id: root

  // Track which popup is currently open (only one at a time)
  property string activePopup: "" // "launcher", "powermenu", "controlcenter", ""

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
  }

  function requestLock() {
    closeAll()
    lockRequested()
  }
}
