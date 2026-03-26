import QtQuick 6.0
import Quickshell
import Quickshell.Io

ShellRoot {
  id: root

  // ── Per-screen bar ──
  Variants {
    model: Quickshell.screens
    delegate: Component {
      Bar.Bar {
        screen: modelData
      }
    }
  }

  // ── Per-screen wallpaper ──
  Variants {
    model: Quickshell.screens
    delegate: Component {
      Wallpaper.Wallpaper {
        screen: modelData
      }
    }
  }

  // ── Notification daemon (single instance) ──
  Notifications.NotificationServer {}

  // ── Launcher (single instance, shown on focused screen) ──
  Launcher.Launcher {}

  // ── Power menu ──
  PowerMenu.PowerMenu {}

  // ── Control center ──
  ControlCenter.ControlCenter {}

  // ── Lock screen ──
  Lock.Lock {}

  // ── IPC handler for external commands ──
  SocketServer {
    active: true
    path: "/tmp/quickshell-" + Qt.application.sessionId + ".sock"

    handler: SocketHandler {
      onConnected: (connection) => {
        connection.onTextReceived.connect(function(text) {
          var cmd = text.trim()
          if (cmd === "toggle-launcher") GlobalState.toggle("launcher")
          else if (cmd === "toggle-powermenu") GlobalState.toggle("powermenu")
          else if (cmd === "toggle-controlcenter") GlobalState.toggle("controlcenter")
          else if (cmd === "lock") Lock.Lock.activate()
          else if (cmd === "close-all") GlobalState.closeAll()
        })
      }
    }
  }
}
