import QtQuick 6.0
import Quickshell.Services.Pipewire

Item {
  width: audioText.width + 16
  height: 26

  property var defaultSink: Pipewire.defaultAudioSink
  property real volume: defaultSink ? defaultSink.audio.volume : 0
  property bool muted: defaultSink ? defaultSink.audio.muted : true

  Text {
    id: audioText
    anchors.centerIn: parent
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    color: Theme.fg
    text: {
      if (muted) return "\u{f0581}" // 󰖁 muted
      if (volume > 0.66) return "\u{f057e}" // 󰕾 high
      if (volume > 0.33) return "\u{f0580}" // 󰖀 medium
      return "\u{f057f}" // 󰕿 low
    }
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: (mouse) => {
      if (mouse.button === Qt.RightButton) {
        if (defaultSink) defaultSink.audio.muted = !defaultSink.audio.muted
      } else {
        GlobalState.toggle("audio")
      }
    }
    onWheel: (wheel) => {
      if (!defaultSink) return
      var delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05
      defaultSink.audio.volume = Math.max(0, Math.min(1.5, volume + delta))
    }
    hoverEnabled: true
  }
}
