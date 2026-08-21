pragma Singleton
import QtQuick 6.0
import Quickshell
import Quickshell.Io

// CPU / memory / temperature sampling shared by the bar glyph (Cpu.qml) and
// the popup (MonitorPanel.qml).
Singleton {
  id: root

  property real cpuPercent: 0
  property real memPercent: 0
  property real memUsedGb: 0
  property real memTotalGb: 0
  property real load1: 0
  property real cpuTemp: 0
  property real gpuTemp: 0

  // Previous /proc/stat sample, needed because CPU load is a delta.
  property real _prevTotal: 0
  property real _prevIdle: 0

  // Rolling history for the sparkline in the panel.
  property var cpuHistory: []
  readonly property int historyLen: 40

  Process {
    id: sample
    running: false
    command: ["bash", "-c",
      "grep -E '^cpu ' /proc/stat | sed 's/^/CPU /'; " +
      "awk '/^MemTotal:/{t=$2} /^MemAvailable:/{a=$2} END{print \"MEM\", t, a}' /proc/meminfo; " +
      "awk '{print \"LOAD\", $1}' /proc/loadavg; " +
      // acpitz on this board reports nonsense, so resolve hwmon by name.
      "for h in /sys/class/hwmon/*; do " +
      "  n=$(cat $h/name 2>/dev/null); " +
      "  case $n in k10temp|coretemp|zenpower) echo \"CPUTEMP $(cat $h/temp1_input 2>/dev/null)\";; " +
      "             amdgpu|nouveau|radeon) echo \"GPUTEMP $(cat $h/temp1_input 2>/dev/null)\";; esac; " +
      "done"]

    stdout: SplitParser {
      onRead: line => {
        var f = line.trim().split(/\s+/)
        if (f[0] === "CPU") {
          // f[1] is the literal "cpu" label from /proc/stat.
          var total = 0
          for (var i = 2; i < f.length; i++) total += parseFloat(f[i]) || 0
          var idle = (parseFloat(f[5]) || 0) + (parseFloat(f[6]) || 0) // idle + iowait

          if (root._prevTotal > 0) {
            var dTotal = total - root._prevTotal
            var dIdle = idle - root._prevIdle
            if (dTotal > 0) {
              root.cpuPercent = Math.max(0, Math.min(100, 100 * (dTotal - dIdle) / dTotal))
              var h = root.cpuHistory.slice()
              h.push(root.cpuPercent)
              while (h.length > root.historyLen) h.shift()
              root.cpuHistory = h
            }
          }
          root._prevTotal = total
          root._prevIdle = idle
        } else if (f[0] === "MEM") {
          var kbTotal = parseFloat(f[1]) || 0
          var kbAvail = parseFloat(f[2]) || 0
          if (kbTotal > 0) {
            root.memTotalGb = kbTotal / 1048576
            root.memUsedGb = (kbTotal - kbAvail) / 1048576
            root.memPercent = 100 * (kbTotal - kbAvail) / kbTotal
          }
        } else if (f[0] === "LOAD") {
          root.load1 = parseFloat(f[1]) || 0
        } else if (f[0] === "CPUTEMP") {
          root.cpuTemp = (parseFloat(f[1]) || 0) / 1000
        } else if (f[0] === "GPUTEMP") {
          root.gpuTemp = (parseFloat(f[1]) || 0) / 1000
        }
      }
    }
  }

  // Poll faster while the panel is open so the graph moves.
  Timer {
    interval: GlobalState.activePopup === "sysmon" ? 1000 : 5000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: { sample.running = false; sample.running = true }
  }
}
