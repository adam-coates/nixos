import QtQuick 6.0
import QtQuick.Layouts 6.0
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
  id: triggersPanel

  property bool showing: GlobalState.activePopup === "triggers"

  visible: showing

  anchors.top: true
  anchors.right: true
  margins { top: 30; right: 4 }

  width: 220
  height: col.implicitHeight + 16

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "quickshell-triggers"
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore
  color: "transparent"

  readonly property string nixPath:
    "export PATH=\"$HOME/.nix-profile/bin:/run/current-system/sw/bin:$PATH\"; "

  Process { id: screenshotProc; running: false }
  Process { id: idleToggleProc; running: false }
  Process { id: themeSwitchProc; running: false }

  Rectangle {
    anchors.fill: parent
    color: Theme.bgAlpha(0.97)
    border.color: Theme.accent
    border.width: 1
    radius: 6

    ColumnLayout {
      id: col
      anchors { top: parent.top; left: parent.left; right: parent.right; margins: 8 }
      spacing: 4

      Text {
        text: "Quick Actions"
        font.family: Theme.fontFamily
        font.pixelSize: 12
        font.bold: true
        color: Theme.fg
        topPadding: 2
        bottomPadding: 2
      }

      Rectangle { Layout.fillWidth: true; height: 1; color: Theme.accentAlpha(0.3) }

      // Screenshot
      Rectangle {
        Layout.fillWidth: true
        height: 34
        color: ssHover.containsMouse ? Theme.accentAlpha(0.15) : "transparent"
        radius: 4

        RowLayout {
          anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
          spacing: 8

          Text {
            text: "󰹑"
            font.family: Theme.fontFamily
            font.pixelSize: 14
            color: ssHover.containsMouse ? Theme.accent : Theme.fg
          }

          Text {
            text: "Screenshot"
            font.family: Theme.fontFamily
            font.pixelSize: 12
            color: ssHover.containsMouse ? Theme.accent : Theme.fg
          }
        }

        HoverHandler { id: ssHover }
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            GlobalState.closeAll()
            screenshotProc.command = [
              "bash", "-c",
              triggersPanel.nixPath + "grim -g \"$(slurp)\" - | swappy -f -"
            ]
            screenshotProc.running = false
            screenshotProc.running = true
          }
        }
      }

      // Toggle idle lock
      Rectangle {
        Layout.fillWidth: true
        height: 34
        color: idleHover.containsMouse ? Theme.accentAlpha(0.15) : "transparent"
        radius: 4

        RowLayout {
          anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
          spacing: 8

          Text {
            text: "󱫖"
            font.family: Theme.fontFamily
            font.pixelSize: 14
            color: idleHover.containsMouse ? Theme.accent : Theme.fg
          }

          Text {
            text: "Toggle Idle Lock"
            font.family: Theme.fontFamily
            font.pixelSize: 12
            color: idleHover.containsMouse ? Theme.accent : Theme.fg
          }
        }

        HoverHandler { id: idleHover }
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            GlobalState.closeAll()
            idleToggleProc.command = [
              "bash", "-c",
              triggersPanel.nixPath + "~/.config/scripts/idle-toggle.sh"
            ]
            idleToggleProc.running = false
            idleToggleProc.running = true
          }
        }
      }

      // Switch theme
      Rectangle {
        Layout.fillWidth: true
        height: 34
        color: themeHover.containsMouse ? Theme.accentAlpha(0.15) : "transparent"
        radius: 4

        RowLayout {
          anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
          spacing: 8

          Text {
            text: "󰔎"
            font.family: Theme.fontFamily
            font.pixelSize: 14
            color: themeHover.containsMouse ? Theme.accent : Theme.fg
          }

          Text {
            text: "Switch Theme"
            font.family: Theme.fontFamily
            font.pixelSize: 12
            color: themeHover.containsMouse ? Theme.accent : Theme.fg
          }
        }

        HoverHandler { id: themeHover }
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            GlobalState.closeAll()
            themeSwitchProc.command = [
              "bash", "-c",
              triggersPanel.nixPath + "~/.config/scripts/theme-switch.sh"
            ]
            themeSwitchProc.running = false
            themeSwitchProc.running = true
          }
        }
      }

      Item { height: 2 }
    }
  }
}
