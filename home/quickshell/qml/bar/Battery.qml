import QtQuick 6.0
import Quickshell.Services.UPower

Item {
  width: battText.width + 16
  height: 26

  property var battery: UPower.displayDevice
  property int percent: battery ? Math.round(battery.percentage) : -1
  property bool charging: battery ? battery.state === UPowerDeviceState.Charging : false

  Text {
    id: battText
    anchors.centerIn: parent
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    color: {
      if (percent < 10) return Theme.red
      if (percent < 20) return Theme.orange
      return Theme.fg
    }
    text: {
      if (percent < 0) return ""
      if (charging) {
        if (percent >= 90) return "\u{f0085}" // 󰂅
        if (percent >= 70) return "\u{f008a}" // 󰂊
        if (percent >= 50) return "\u{f0089}" // 󰂉
        if (percent >= 30) return "\u{f0088}" // 󰂈
        return "\u{f089e}" // 󰢞
      }
      if (percent >= 90) return "\u{f0079}" // 󰁹
      if (percent >= 80) return "\u{f0082}" // 󰂂
      if (percent >= 70) return "\u{f0081}" // 󰂁
      if (percent >= 60) return "\u{f0080}" // 󰂀
      if (percent >= 50) return "\u{f007f}" // 󰁿
      if (percent >= 40) return "\u{f007e}" // 󰁾
      if (percent >= 30) return "\u{f007d}" // 󰁽
      if (percent >= 20) return "\u{f007c}" // 󰁼
      if (percent >= 10) return "\u{f007b}" // 󰁻
      return "\u{f007a}" // 󰁺
    }

    ToolTip.visible: battMouse.containsMouse
    ToolTip.text: {
      if (charging) return percent + "% (charging)"
      return percent + "%"
    }
  }

  MouseArea {
    id: battMouse
    anchors.fill: parent
    hoverEnabled: true
  }
}
