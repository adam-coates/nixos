pragma Singleton
import QtQuick 6.0
import Quickshell

Singleton {
  id: root

  property string activePopup: ""
  property string previewFile: ""   // path shown in FilePreview window

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
