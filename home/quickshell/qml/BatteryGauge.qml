import QtQuick 6.0

// Circular battery gauge with icon in center
Item {
  id: gauge
  width: 56
  height: 70

  property int percentage: 0
  property bool available: false
  property bool charging: false
  property string label: ""
  property string icon: ""

  opacity: available ? 1.0 : 0.3

  // Ring background + arc
  Canvas {
    id: ring
    anchors.horizontalCenter: parent.horizontalCenter
    width: 48; height: 48

    property real pct: gauge.percentage / 100
    property color ringColor: {
      if (gauge.charging) return Theme.green
      if (gauge.percentage <= 15) return Theme.red
      if (gauge.percentage <= 30) return Theme.accent
      return Theme.green
    }

    onPctChanged: requestPaint()
    onRingColorChanged: requestPaint()

    onPaint: {
      var ctx = getContext("2d")
      ctx.reset()
      var cx = width / 2
      var cy = height / 2
      var r = cx - 4
      var startAngle = -Math.PI / 2
      var lineWidth = 4

      // Background ring
      ctx.beginPath()
      ctx.arc(cx, cy, r, 0, 2 * Math.PI)
      ctx.lineWidth = lineWidth
      ctx.strokeStyle = Theme.bg2
      ctx.stroke()

      // Progress arc
      if (pct > 0) {
        ctx.beginPath()
        ctx.arc(cx, cy, r, startAngle, startAngle + 2 * Math.PI * pct)
        ctx.lineWidth = lineWidth
        ctx.lineCap = "round"
        ctx.strokeStyle = ringColor
        ctx.stroke()
      }
    }

    // Center icon
    Text {
      anchors.centerIn: parent
      text: gauge.icon
      font.family: Theme.fontFamily
      font.pixelSize: 16
      color: ring.ringColor
    }

    // Label (L/R) in top-right
    Text {
      visible: gauge.label !== ""
      anchors { right: parent.right; top: parent.top; topMargin: 2; rightMargin: 2 }
      text: gauge.label
      font.family: Theme.fontFamily
      font.pixelSize: 8
      font.bold: true
      color: Theme.fg
    }

    // Charging bolt
    Text {
      visible: gauge.charging
      anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 2 }
      text: "\u{f140b}" // 󰹻 bolt
      font.family: Theme.fontFamily
      font.pixelSize: 8
      color: Theme.green
    }
  }

  // Percentage text below
  Text {
    anchors { horizontalCenter: parent.horizontalCenter; top: ring.bottom; topMargin: 4 }
    text: gauge.available ? gauge.percentage + "%" : "--"
    font.family: Theme.fontFamily
    font.pixelSize: 10
    color: gauge.available ? ring.ringColor : Theme.gray
  }
}
