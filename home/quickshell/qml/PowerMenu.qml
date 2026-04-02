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

  color: "transparent"

  Keys.onEscapePressed: GlobalState.closeAll()

  // Dim backdrop
  Rectangle {
    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, showing ? 0.5 : 0)
    Behavior on color { ColorAnimation { duration: 150 } }

    MouseArea {
      anchors.fill: parent
      onClicked: GlobalState.closeAll()
    }
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

    opacity: showing ? 1 : 0
    scale: showing ? 1 : 0.9
    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

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

          Behavior on color { ColorAnimation { duration: 100 } }

          ColumnLayout {
            anchors.centerIn: parent
            spacing: 8

            Text {
              Layout.alignment: Qt.AlignHCenter
              text: modelData.icon
              font.family: Theme.fontFamily
              font.pixelSize: 28
              color: hoverArea.containsMouse ? Theme.accent : Theme.fg
              Behavior on color { ColorAnimation { duration: 100 } }
            }

            Text {
              Layout.alignment: Qt.AlignHCenter
              text: modelData.label
              font.family: Theme.fontFamily
              font.pixelSize: 11
              color: hoverArea.containsMouse ? Theme.accent : Theme.gray
              Behavior on color { ColorAnimation { duration: 100 } }
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
        GlobalState.requestLock()
        break
      case "sleep":
        GlobalState.requestLock()
        suspendTimer.start()
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

  Timer {
    id: suspendTimer
    interval: 500
    repeat: false
    onTriggered: suspendProc.running = true
  }
  Process { id: suspendProc;  command: ["systemctl", "suspend"] }
  Process { id: rebootProc;   command: ["systemctl", "reboot"] }
  Process { id: poweroffProc; command: ["systemctl", "poweroff"] }
  Process { id: logoutProc;   command: ["hyprctl", "dispatch", "exit"] }
}
