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

    onNotification: (notification) => {
      notification.tracked = true
    }
  }

  // Notification popup container
  Variants {
    model: Quickshell.screens
    delegate: Component {
      NotificationPopup {
        screen: modelData
        notifications: server.trackedNotifications
      }
    }
  }
}
