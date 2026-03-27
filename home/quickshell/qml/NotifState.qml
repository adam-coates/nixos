pragma Singleton
import QtQuick 6.0
import Quickshell

Singleton {
  id: root

  property int unreadCount: 0

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
