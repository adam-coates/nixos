import QtQuick 6.0
import QtQuick.Layouts 6.0
import Quickshell.Io

// Earbuds battery display with circular gauges
// Queries MagicPodsCore via helper script
Item {
  id: root
  implicitHeight: visible ? batteryRow.implicitHeight + 8 : 0
  visible: deviceName !== ""

  property string deviceName: ""
  property int leftBat: 0
  property int leftStatus: 0
  property bool leftCharging: false
  property int rightBat: 0
  property int rightStatus: 0
  property bool rightCharging: false
  property int caseBat: 0
  property int caseStatus: 0
  property bool caseCharging: false

  Process {
    id: batteryProc
    command: ["sh", "-c", "~/.local/bin/qs-get-buds-battery"]
    running: true
    property string _output: ""
    stdout: SplitParser {
      onRead: line => batteryProc._output = line
    }
    onExited: {
      var line = batteryProc._output
      batteryProc._output = ""
      if (line === "none" || line === "") {
        root.deviceName = ""
        return
      }
      var parts = line.split("\t")
      if (parts.length < 10) { root.deviceName = ""; return }
      root.leftBat = parseInt(parts[0]) || 0
      root.leftCharging = parts[1] === "true"
      root.leftStatus = parseInt(parts[2]) || 0
      root.rightBat = parseInt(parts[3]) || 0
      root.rightCharging = parts[4] === "true"
      root.rightStatus = parseInt(parts[5]) || 0
      root.caseBat = parseInt(parts[6]) || 0
      root.caseCharging = parts[7] === "true"
      root.caseStatus = parseInt(parts[8]) || 0
      root.deviceName = parts[9]
    }
  }

  Timer {
    interval: 10000
    running: true
    repeat: true
    onTriggered: batteryProc.running = true
  }

  ColumnLayout {
    id: batteryRow
    anchors { left: parent.left; right: parent.right }
    spacing: 6

    Text {
      text: root.deviceName
      font.family: Theme.fontFamily
      font.pixelSize: 11
      font.bold: true
      color: Theme.fg
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: 12
      Layout.alignment: Qt.AlignHCenter

      // Left earbud
      BatteryGauge {
        percentage: root.leftBat
        available: root.leftStatus >= 2
        charging: root.leftCharging
        label: "L"
        icon: "\u{f025}" 
      }

      // Right earbud
      BatteryGauge {
        percentage: root.rightBat
        available: root.rightStatus >= 2
        charging: root.rightCharging
        label: "R"
        icon: "\u{f025}" 
      }

      // Case
      BatteryGauge {
        percentage: root.caseBat
        available: root.caseStatus >= 2
        charging: root.caseCharging
        label: ""
        icon: "\u{f0f2}" 
      }
    }
  }
}
