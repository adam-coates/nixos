import QtQuick 6.0
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
  id: panel

  property bool showing: GlobalState.activePopup === "sysmon"

  visible: showing

  anchors.top: true
  anchors.right: true
  margins { top: 30; right: 4 }
  implicitWidth: 260
  implicitHeight: content.height + 24

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "quickshell-sysmon"
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore
  color: "transparent"

  Rectangle {
    anchors.fill: parent
    color: Theme.bgAlpha(0.97)
    border.color: Theme.accentAlpha(0.5)
    border.width: 1
    radius: 6

    opacity: panel.showing ? 1 : 0
    scale: panel.showing ? 1 : 0.96
    transformOrigin: Item.Top
    Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

    Column {
      id: content
      anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
      spacing: 10

      // ── CPU sparkline ──
      Column {
        width: parent.width
        spacing: 4

        Item {
          width: parent.width
          height: 16
          Text {
            anchors.left: parent.left
            text: "CPU"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 1
            color: Theme.gray
          }
          Text {
            anchors.right: parent.right
            text: SysMonState.cpuPercent.toFixed(0) + "%"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 1
            color: Theme.fg
          }
        }

        Canvas {
          id: spark
          width: parent.width
          height: 38

          // Repaint whenever a new sample lands.
          Connections {
            target: SysMonState
            function onCpuHistoryChanged() { spark.requestPaint() }
          }

          onPaint: {
            var ctx = getContext("2d")
            ctx.reset()

            var h = SysMonState.cpuHistory
            var n = SysMonState.historyLen
            if (h.length < 2) return

            var stepX = width / (n - 1)
            // Right-align the trace so it grows leftwards from "now".
            var offset = n - h.length

            ctx.beginPath()
            for (var i = 0; i < h.length; i++) {
              var x = (offset + i) * stepX
              var y = height - (h[i] / 100) * height
              if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y)
            }

            ctx.strokeStyle = Theme.accent
            ctx.lineWidth = 1.5
            ctx.stroke()

            // Fill under the trace.
            ctx.lineTo((offset + h.length - 1) * stepX, height)
            ctx.lineTo(offset * stepX, height)
            ctx.closePath()
            ctx.fillStyle = Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.15)
            ctx.fill()
          }
        }
      }

      Rectangle { width: parent.width; height: 1; color: Theme.bg2 }

      // ── Memory bar ──
      Column {
        width: parent.width
        spacing: 4

        Item {
          width: parent.width
          height: 16
          Text {
            anchors.left: parent.left
            text: "Memory"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 1
            color: Theme.gray
          }
          Text {
            anchors.right: parent.right
            text: SysMonState.memUsedGb.toFixed(1) + " / " + SysMonState.memTotalGb.toFixed(0) + " GB"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 1
            color: Theme.fg
          }
        }

        Rectangle {
          width: parent.width
          height: 5
          radius: 2.5
          color: Theme.bg2

          Rectangle {
            width: parent.width * (SysMonState.memPercent / 100)
            height: parent.height
            radius: parent.radius
            color: SysMonState.memPercent > 85 ? Theme.indicator : Theme.accent
            Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
          }
        }
      }

      Rectangle { width: parent.width; height: 1; color: Theme.bg2 }

      // ── Stat rows ──
      Column {
        width: parent.width
        spacing: 3

        Repeater {
          model: [
            { k: "Load (1m)", v: SysMonState.load1.toFixed(2), show: true },
            { k: "CPU temp",  v: SysMonState.cpuTemp.toFixed(0) + "°C", show: SysMonState.cpuTemp > 0 },
            { k: "GPU temp",  v: SysMonState.gpuTemp.toFixed(0) + "°C", show: SysMonState.gpuTemp > 0 }
          ]
          Item {
            required property var modelData
            width: parent.width
            height: modelData.show ? 17 : 0
            visible: modelData.show
            Text {
              anchors.left: parent.left
              text: modelData.k
              font.family: Theme.fontFamily
              font.pixelSize: Theme.fontSize - 1
              color: Theme.gray
            }
            Text {
              anchors.right: parent.right
              text: modelData.v
              font.family: Theme.fontFamily
              font.pixelSize: Theme.fontSize - 1
              color: Theme.fg
            }
          }
        }
      }

      // ── btop shortcut ──
      Rectangle {
        width: parent.width
        height: 24
        radius: 4
        color: btopArea.containsMouse ? Theme.accentAlpha(0.15) : "transparent"
        Behavior on color { ColorAnimation { duration: 100 } }

        Text {
          anchors.centerIn: parent
          text: "Open btop"
          font.family: Theme.fontFamily
          font.pixelSize: Theme.fontSize - 1
          color: btopArea.containsMouse ? Theme.accent : Theme.gray
        }

        MouseArea {
          id: btopArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            btopProc.running = false
            btopProc.running = true
            GlobalState.closeAll()
          }
        }
      }
    }
  }

  Process {
    id: btopProc
    running: false
    command: ["hyprctl", "dispatch", "exec", "ghostty -e btop"]
  }
}
