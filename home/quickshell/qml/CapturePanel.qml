import QtQuick 6.0
import QtQuick.Layouts 6.0
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
  id: capturePanel

  property bool showing: GlobalState.activePopup === "capture"
  property string view: "main"

  onShowingChanged: if (!showing) view = "main"

  visible: showing

  anchors.top: true
  anchors.right: true
  margins { top: 30; right: 4 }

  width: 260
  height: contentCol.implicitHeight + 16

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "quickshell-capture"
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore
  color: "transparent"

  readonly property string nixPath:
    "export PATH=\"$HOME/.nix-profile/bin:/run/current-system/sw/bin:$PATH\"; "

  Process { id: captureProc; running: false }

  Rectangle {
    anchors.fill: parent
    color: Theme.bgAlpha(0.97)
    border.color: Theme.accent
    border.width: 1

    opacity: capturePanel.showing ? 1 : 0
    scale: capturePanel.showing ? 1 : 0.96
    transformOrigin: Item.TopRight
    Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
    radius: 6

    ColumnLayout {
      id: contentCol
      anchors { top: parent.top; left: parent.left; right: parent.right; margins: 8 }
      spacing: 4

      // ── Main view ──
      ColumnLayout {
        visible: capturePanel.view === "main"
        spacing: 4

        Text {
          text: "Capture"
          font.family: Theme.fontFamily
          font.pixelSize: 12
          font.bold: true
          color: Theme.fg
          topPadding: 2
          bottomPadding: 2
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.accentAlpha(0.3) }

        CaptureButton {
          icon: "󰹑"
          label: "Screenshot"
          onActivated: {
            GlobalState.closeAll()
            captureProc.command = [
              "bash", "-c",
              capturePanel.nixPath + "grim -g \"$(slurp)\" - | swappy -f -"
            ]
            captureProc.running = false
            captureProc.running = true
          }
        }

        CaptureButton {
          icon: ""
          label: "Screen Record"
          showArrow: true
          onActivated: capturePanel.view = "record"
        }

        CaptureButton {
          icon: "󰵐"
          label: "Record GIF"
          onActivated: {
            GlobalState.closeAll()
            captureProc.command = [
              "bash", "-c",
              capturePanel.nixPath + "~/.config/scripts/capture-gif.sh"
            ]
            captureProc.running = false
            captureProc.running = true
          }
        }

        CaptureButton {
          icon: "󰴑"
          label: "Text Extraction"
          onActivated: {
            GlobalState.closeAll()
            captureProc.command = [
              "bash", "-c",
              capturePanel.nixPath + "~/.config/scripts/capture-ocr.sh"
            ]
            captureProc.running = false
            captureProc.running = true
          }
        }

        CaptureButton {
          icon: "󰃉"
          label: "Color Picker"
          onActivated: {
            GlobalState.closeAll()
            captureProc.command = [
              "bash", "-c",
              capturePanel.nixPath + "pkill hyprpicker || hyprpicker -a"
            ]
            captureProc.running = false
            captureProc.running = true
          }
        }

        Item { height: 2 }
      }

      // ── Screen record submenu ──
      ColumnLayout {
        visible: capturePanel.view === "record"
        spacing: 4

        RowLayout {
          spacing: 4

          Rectangle {
            width: 24; height: 24
            color: backHover.containsMouse ? Theme.accentAlpha(0.15) : "transparent"
            radius: 4

            Text {
              anchors.centerIn: parent
              text: "󰁍"
              font.family: Theme.fontFamily
              font.pixelSize: 14
              color: backHover.containsMouse ? Theme.accent : Theme.fg
            }

            HoverHandler { id: backHover }
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: capturePanel.view = "main"
            }
          }

          Text {
            text: "Screen Record"
            font.family: Theme.fontFamily
            font.pixelSize: 12
            font.bold: true
            color: Theme.fg
            topPadding: 2
            bottomPadding: 2
          }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.accentAlpha(0.3) }

        CaptureButton {
          icon: "󰕧"
          label: "No audio"
          onActivated: {
            GlobalState.closeAll()
            captureProc.command = [
              "bash", "-c",
              capturePanel.nixPath + "~/.config/scripts/capture-screenrecord.sh"
            ]
            captureProc.running = false
            captureProc.running = true
          }
        }

        CaptureButton {
          icon: "󰕾"
          label: "Desktop audio"
          onActivated: {
            GlobalState.closeAll()
            captureProc.command = [
              "bash", "-c",
              capturePanel.nixPath + "~/.config/scripts/capture-screenrecord.sh --with-desktop-audio"
            ]
            captureProc.running = false
            captureProc.running = true
          }
        }

        CaptureButton {
          icon: "󰍬"
          label: "Desktop + microphone"
          onActivated: {
            GlobalState.closeAll()
            captureProc.command = [
              "bash", "-c",
              capturePanel.nixPath + "~/.config/scripts/capture-screenrecord.sh --with-desktop-audio --with-microphone-audio"
            ]
            captureProc.running = false
            captureProc.running = true
          }
        }

        Item { height: 2 }
      }
    }
  }

  // ── Reusable button component ──
  component CaptureButton: Rectangle {
    Layout.fillWidth: true
    height: 34
    color: btnHover.containsMouse ? Theme.accentAlpha(0.15) : "transparent"
    radius: 4

    property string icon: ""
    property string label: ""
    property bool showArrow: false
    signal activated()

    RowLayout {
      anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
      spacing: 8

      Text {
        text: icon
        font.family: Theme.fontFamily
        font.pixelSize: 14
        color: btnHover.containsMouse ? Theme.accent : Theme.fg
      }

      Text {
        text: label
        font.family: Theme.fontFamily
        font.pixelSize: 12
        color: btnHover.containsMouse ? Theme.accent : Theme.fg
        Layout.fillWidth: true
      }

      Text {
        visible: showArrow
        text: "󰅂"
        font.family: Theme.fontFamily
        font.pixelSize: 12
        color: btnHover.containsMouse ? Theme.accent : Theme.gray
      }
    }

    HoverHandler { id: btnHover }
    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: activated()
    }
  }
}
