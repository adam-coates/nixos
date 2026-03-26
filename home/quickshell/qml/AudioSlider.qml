import QtQuick 6.0
import QtQuick.Layouts 6.0
import Quickshell.Services.Pipewire

ColumnLayout {
  spacing: 8

  // Header
  RowLayout {
    Layout.fillWidth: true

    Text {
      text: "Audio"
      font.family: Theme.fontFamily
      font.pixelSize: 12
      font.bold: true
      color: Theme.fg
    }

    Item { Layout.fillWidth: true }

    // Mute toggle
    Text {
      property var sink: Pipewire.defaultAudioSink
      property bool muted: sink ? sink.audio.muted : true
      text: muted ? "\u{f0581}" : "\u{f057e}" // 󰖁 / 󰕾
      font.family: Theme.fontFamily
      font.pixelSize: 16
      color: muted ? Theme.gray : Theme.accent

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          if (parent.sink) parent.sink.audio.muted = !parent.sink.audio.muted
        }
      }
    }
  }

  // Volume slider
  Rectangle {
    Layout.fillWidth: true
    Layout.preferredHeight: 6
    radius: 3
    color: Theme.bg2

    property var sink: Pipewire.defaultAudioSink
    property real vol: sink ? sink.audio.volume : 0

    Rectangle {
      width: parent.vol * parent.width
      height: parent.height
      radius: 3
      color: Theme.accent
    }

    // Slider knob
    Rectangle {
      x: parent.vol * parent.width - 6
      y: -3
      width: 12
      height: 12
      radius: 6
      color: Theme.accent
    }

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onPressed: updateVol(mouse)
      onPositionChanged: updateVol(mouse)

      function updateVol(mouse) {
        var newVol = Math.max(0, Math.min(1, mouse.x / parent.width))
        if (parent.sink) parent.sink.audio.volume = newVol
      }
    }
  }

  // Volume percentage
  Text {
    property var sink: Pipewire.defaultAudioSink
    text: sink ? Math.round(sink.audio.volume * 100) + "%" : "0%"
    font.family: Theme.fontFamily
    font.pixelSize: 11
    color: Theme.gray
  }
}
