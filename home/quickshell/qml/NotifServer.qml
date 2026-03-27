import QtQuick 6.0
import Quickshell
import Quickshell.Services.Notifications

Scope {
  NotificationServer {
    id: server
    bodySupported: true
    bodyMarkupSupported: true
    imageSupported: true
    actionsSupported: true
    keepOnReload: true

    onNotification: notification => {
      notification.tracked = true
    }
  }

  // Single popup — appears on the focused/active output
  NotifPopup {
    notifications: server.trackedNotifications
  }
}
