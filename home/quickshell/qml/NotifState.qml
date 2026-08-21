pragma Singleton
import QtQuick 6.0
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property int unreadCount: 0

  // ── Do-not-disturb ──
  // Suppresses popups only; notifications still land in history so nothing
  // is lost while silenced. Persisted so it survives a shell restart.
  property bool silenced: false
  property string silenceFile: Quickshell.env("HOME") + "/.local/state/notif-silenced"

  FileView {
    id: silenceFileView
    path: root.silenceFile
    watchChanges: true
    // Absent on first run, which is not an error — DND just defaults to off.
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.silenced = (text().trim() === "1")
  }

  Process { id: persist; running: false }

  function toggleSilenced() {
    root.silenced = !root.silenced
    persist.command = ["sh", "-c",
      "mkdir -p \"$(dirname '" + root.silenceFile + "')\" && echo " +
      (root.silenced ? "1" : "0") + " > '" + root.silenceFile + "'"]
    persist.running = false
    persist.running = true
  }

  property list<QtObject> _historyItems: []

  // History as a ListModel so panels can bind to it reactively
  property ListModel historyModel: ListModel {}

  function addToHistory(appName, appIcon, summary, body) {
    const now = new Date()
    const h = now.getHours().toString().padStart(2, "0")
    const m = now.getMinutes().toString().padStart(2, "0")
    historyModel.insert(0, {
      "appName":  appName  || "",
      "appIcon":  appIcon  || "",
      "summary":  summary  || "",
      "body":     body     || "",
      "time":     h + ":" + m
    })
    unreadCount++
  }

  function clearHistory() {
    historyModel.clear()
    unreadCount = 0
  }

  function markRead() {
    unreadCount = 0
  }
}
