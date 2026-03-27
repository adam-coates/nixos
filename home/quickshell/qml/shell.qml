import QtQuick 6.0
import Quickshell
import Quickshell.Io

ShellRoot {
  id: root

  // ── Per-screen bar ──
  Variants {
    model: Quickshell.screens
    delegate: Component {
      Bar {
        screen: modelData
      }
    }
  }

  // ── Per-screen wallpaper ──
  Variants {
    model: Quickshell.screens
    delegate: Component {
      Wallpaper {
        screen: modelData
      }
    }
  }

  // ── Notification daemon (single instance) ──
  NotifServer {}

  // ── Launcher (single instance, shown on focused screen) ──
  Launcher {}

  // ── Power menu ──
  PowerMenu {}

  // ── Control center ──
  ControlCenter {}

  // ── Notification history panel ──
  NotifPanel {}

  // ── Clipboard manager ──
  ClipboardPanel {}

  // ── Lock screen ──
  LockScreen {}

  // ── IPC handler for external commands ──
  IpcHandler {
    target: "shell"

    function toggleLauncher(): void { GlobalState.toggle("launcher") }
    function togglePowermenu(): void { GlobalState.toggle("powermenu") }
    function toggleControlcenter(): void { GlobalState.toggle("controlcenter") }
    function lock(): void { GlobalState.requestLock() }
    function closeAll(): void { GlobalState.closeAll() }
  }
}
