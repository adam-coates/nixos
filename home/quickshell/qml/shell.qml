//@ pragma UseQApplication
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

  // ── Click-off backdrop for panel popups (must be before panels for z-order) ──
  PopupBackdrop {}

  // ── Audio panel ──
  AudioPanel {}

  // ── Bluetooth panel ──
  BluetoothPanel {}

  // ── Network panel ──
  NetworkPanel {}

  // ── Notification history panel ──
  NotifPanel {}

  // ── Emoji picker ──
  EmojiPicker {}

  // ── System tray panel ──
  SysTrayPanel {}

  // ── Clipboard manager ──
  ClipboardPanel {}

  // ── Triggers / quick actions panel ──
  TriggersPanel {}

  // ── File preview (companion to launcher file mode) ──
  FilePreview {}

  // ── Lock screen ──
  LockScreen {}

  // ── IPC handler for external commands ──
  IpcHandler {
    target: "shell"

    function toggleLauncher(): void { GlobalState.toggle("launcher") }
    function togglePowermenu(): void { GlobalState.toggle("powermenu") }
    function toggleAudio(): void { GlobalState.toggle("audio") }
    function toggleBluetooth(): void { GlobalState.toggle("bluetooth") }
    function toggleNetwork(): void { GlobalState.toggle("network") }
    function toggleTriggers(): void { GlobalState.toggle("triggers") }
    function toggleEmoji(): void { GlobalState.toggle("emoji") }
    function toggleClipboard(): void { GlobalState.toggle("clipboard") }
    function lock(): void { GlobalState.requestLock() }
    function closeAll(): void { GlobalState.closeAll() }
  }
}
