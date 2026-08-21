import QtQuick 6.0
import Quickshell
import Quickshell.Wayland

PanelWindow {
  id: panel

  property bool showing: GlobalState.activePopup === "calendar"

  // Month currently on screen; reset to today whenever the panel reopens.
  property int viewYear: new Date().getFullYear()
  property int viewMonth: new Date().getMonth()

  readonly property int cell: 30
  readonly property int weekColW: 24

  visible: showing

  onShowingChanged: {
    if (showing) {
      var now = new Date()
      viewYear = now.getFullYear()
      viewMonth = now.getMonth()
    }
  }

  anchors.top: true
  anchors.left: true
  // Sit under the clock, which is centred in the bar.
  margins {
    top: 30
    left: Math.max(4, ((panel.screen ? panel.screen.width : 1920) - panel.width) / 2)
  }
  implicitWidth: weekColW + cell * 7 + 24
  implicitHeight: content.height + 24

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "quickshell-calendar"
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore
  color: "transparent"

  function isoWeek(d) {
    var t = new Date(d.getFullYear(), d.getMonth(), d.getDate())
    t.setDate(t.getDate() + 3 - ((t.getDay() + 6) % 7))
    var firstThursday = new Date(t.getFullYear(), 0, 4)
    firstThursday.setDate(firstThursday.getDate() + 3 - ((firstThursday.getDay() + 6) % 7))
    return 1 + Math.round((t - firstThursday) / (7 * 86400000))
  }

  // 6 rows of [week number + 7 days] = 48 cells, Monday-first, spilling into
  // the neighbouring months.
  readonly property var cells: {
    var first = new Date(viewYear, viewMonth, 1)
    var lead = (first.getDay() + 6) % 7          // Mon = 0
    var start = new Date(viewYear, viewMonth, 1 - lead)
    var today = new Date()
    var out = []

    for (var row = 0; row < 6; row++) {
      var rowStart = new Date(start.getFullYear(), start.getMonth(), start.getDate() + row * 7)
      out.push({ isWeek: true, week: isoWeek(rowStart),
                 day: 0, inMonth: false, isToday: false, weekend: false })

      for (var col = 0; col < 7; col++) {
        var d = new Date(rowStart.getFullYear(), rowStart.getMonth(), rowStart.getDate() + col)
        out.push({
          isWeek: false,
          week: 0,
          day: d.getDate(),
          inMonth: d.getMonth() === viewMonth,
          isToday: d.getFullYear() === today.getFullYear()
                   && d.getMonth() === today.getMonth()
                   && d.getDate() === today.getDate(),
          weekend: col >= 5
        })
      }
    }
    return out
  }

  function shiftMonth(delta) {
    var m = viewMonth + delta
    var y = viewYear
    if (m < 0) { m = 11; y-- } else if (m > 11) { m = 0; y++ }
    viewMonth = m
    viewYear = y
  }

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
      spacing: 8

      // ── Month header with nav ──
      Item {
        width: parent.width
        height: 22

        Text {
          id: prevBtn
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          text: "\u{f0141}" // 󰅁
          font.family: Theme.fontFamily
          font.pixelSize: Theme.fontSize
          color: prevArea.containsMouse ? Theme.accent : Theme.gray
          MouseArea {
            id: prevArea
            anchors.fill: parent
            anchors.margins: -6
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: panel.shiftMonth(-1)
          }
        }

        Text {
          anchors.centerIn: parent
          text: Qt.formatDateTime(new Date(panel.viewYear, panel.viewMonth, 1), "MMMM yyyy")
          font.family: Theme.fontFamily
          font.pixelSize: Theme.fontSize
          color: Theme.fg
        }

        Text {
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          text: "\u{f0142}" // 󰅂
          font.family: Theme.fontFamily
          font.pixelSize: Theme.fontSize
          color: nextArea.containsMouse ? Theme.accent : Theme.gray
          MouseArea {
            id: nextArea
            anchors.fill: parent
            anchors.margins: -6
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: panel.shiftMonth(1)
          }
        }
      }

      // ── Weekday header ──
      Row {
        spacing: 0

        Item { width: panel.weekColW; height: 18 }

        Repeater {
          model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
          Item {
            required property var modelData
            required property int index
            width: panel.cell
            height: 18
            Text {
              anchors.centerIn: parent
              text: modelData
              font.family: Theme.fontFamily
              font.pixelSize: Theme.fontSize - 2
              color: index >= 5 ? Theme.accentAlpha(0.7) : Theme.gray
            }
          }
        }
      }

      // ── Day grid ──
      Grid {
        columns: 8
        spacing: 0

        Repeater {
          model: panel.cells

          delegate: Item {
            required property var modelData

            width: modelData.isWeek ? panel.weekColW : panel.cell
            height: 24

            // Week number, dimmed, in its own leading column.
            Text {
              anchors.centerIn: parent
              visible: modelData.isWeek
              text: modelData.week
              font.family: Theme.fontFamily
              font.pixelSize: Theme.fontSize - 3
              color: Theme.bg2
            }

            Rectangle {
              anchors.centerIn: parent
              visible: !modelData.isWeek && modelData.isToday
              width: 22
              height: 22
              radius: 11
              color: Theme.accent
            }

            Text {
              anchors.centerIn: parent
              visible: !modelData.isWeek
              text: modelData.day
              font.family: Theme.fontFamily
              font.pixelSize: Theme.fontSize - 1
              color: modelData.isToday ? Theme.bg
                   : !modelData.inMonth ? Theme.bg2
                   : modelData.weekend ? Theme.accentAlpha(0.8)
                   : Theme.fg
            }
          }
        }
      }
    }
  }
}
