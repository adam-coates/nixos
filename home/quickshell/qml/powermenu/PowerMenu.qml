import QtQuick 6.0
import QtQuick.Layouts 6.0
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
  id: powerMenu

  property bool showing: GlobalState.activePopup === "powermenu"

  visible: showing

  anchors {
    top: true
    left: true
    right: true
    bottom: true
  }

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "quickshell-powermenu"
  WlrLayershell.keyboardFocus: showing ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore

  color: Qt.rgba(0, 0, 0, 0.5)

  Keys.onEscapePressed: GlobalState.closeAll()

  // Click backdrop to close
  MouseArea {
    anchors.fill: parent
    onClicked: GlobalState.closeAll()
  }

  // Centered menu
  Rectangle {
    anchors.centerIn: parent
    width: menuRow.implicitWidth + 60
    height: menuRow.implicitHeight + 60
    color: Theme.bg
    border.color: Theme.accent
    border.width: 1
    radius: 12

    MouseArea { anchors.fill: parent } // prevent click-through

    RowLayout {
      id: menuRow
      anchors.centerIn: parent
      spacing: 20

      Repeater {
        model: [
          { icon: "\u{f033e}", label: "Lock",     cmd: "lock" },
          { icon: "\u{f04b2}", label: "Sleep",    cmd: "sleep" },
          { icon: "\u{f0709}", label: "Restart",  cmd: "restart" },
          { icon: "\u{f0425}", label: "Shutdown", cmd: "shutdown" },
          { icon: "\u{f0343}", label: "Logout",   cmd: "logout" }
        ]

        Rectangle {
          width: 80
          height: 90
          color: hoverArea.containsMouse ? Theme.accentAlpha(0.15) : "transparent"
          radius: 8

          ColumnLayout {
            anchors.centerIn: parent
            spacing: 8

            Text {
              Layout.alignment: Qt.AlignHCenter
              text: modelData.icon
              font.family: Theme.fontFamily
              font.pixelSize: 28
              color: hoverArea.containsMouse ? Theme.accent : Theme.fg
            }

            Text {
              Layout.alignment: Qt.AlignHCenter
              text: modelData.label
              font.family: Theme.fontFamily
              font.pixelSize: 11
              color: hoverArea.containsMouse ? Theme.accent : Theme.gray
            }
          }

          MouseArea {
            id: hoverArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: execAction(modelData.cmd)
          }
        }
      }
    }
  }

  function execAction(cmd) {
    GlobalState.closeAll()
    switch (cmd) {
      case "lock":
        Lock.Lock.activate()
        break
      case "sleep":
        Lock.Lock.activate()
        suspendProc.running = true
        break
      case "restart":
        rebootProc.running = true
        break
      case "shutdown":
        poweroffProc.running = true
        break
      case "logout":
        logoutProc.running = true
        break
    }
  }

  Process { id: suspendProc;  command: ["systemctl", "suspend"] }
  Process { id: rebootProc;   command: ["systemctl", "reboot"] }
  Process { id: poweroffProc; command: ["systemctl", "poweroff"] }
  Process { id: logoutProc;   command: ["hyprctl", "dispatch", "exit"] }
}
