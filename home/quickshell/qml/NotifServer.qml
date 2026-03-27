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

  // One popup per screen so the layer shell has a valid output to attach to
  Variants {
    model: Quickshell.screens
    delegate: Component {
      NotifPopup {
        screen: modelData
        notifications: server.trackedNotifications
      }
    }
  }
}
