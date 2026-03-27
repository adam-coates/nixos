import QtQuick 6.0
import QtQuick.Layouts 6.0
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Wayland

PanelWindow {
  id: audioPanel

  property bool showing: GlobalState.activePopup === "audio"
  visible: showing

  anchors.top: true
  anchors.right: true
  margins { top: 30; right: 4 }
  width: 320
  height: Math.min(panelFlick.contentHeight + 24, 520)

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "quickshell-audio"
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore
  color: "transparent"

  property var defaultSink: Pipewire.defaultAudioSink
  property var defaultSource: Pipewire.defaultAudioSource

  readonly property var sinkNodes: {
    if (!Pipewire.ready) return []
    var result = []
    for (var i = 0; i < Pipewire.nodes.length; i++) {
      var n = Pipewire.nodes[i]
      if (n.isSink && n.ready && n.audio) result.push(n)
    }
    return result
  }

  readonly property var streamNodes: {
    if (!Pipewire.ready) return []
    var result = []
    for (var i = 0; i < Pipewire.nodes.length; i++) {
      var n = Pipewire.nodes[i]
      if (n.isStream && n.ready && n.audio) result.push(n)
    }
    return result
  }

  Rectangle {
    anchors.fill: parent
    color: Theme.bgAlpha(0.97)
    border.color: Theme.accent
    border.width: 1
    radius: 6

    Flickable {
      id: panelFlick
      anchors.fill: parent
      anchors.margins: 12
      contentHeight: content.implicitHeight
      clip: true

      ColumnLayout {
        id: content
        width: parent.width
        spacing: 10

        // Header
        Text {
          text: "Audio"
          font.family: Theme.fontFamily
          font.pixelSize: 13
          font.bold: true
          color: Theme.fg
        }

        // ── Master Volume ──
        RowLayout {
          Layout.fillWidth: true
          spacing: 8

          Text {
            text: {
              if (!audioPanel.defaultSink || audioPanel.defaultSink.audio.muted) return "\u{f0581}"
              var v = audioPanel.defaultSink.audio.volume
              if (v > 0.66) return "\u{f057e}"
              if (v > 0.33) return "\u{f0580}"
              return "\u{f057f}"
            }
            font.family: Theme.fontFamily
            font.pixelSize: 16
            color: (audioPanel.defaultSink && audioPanel.defaultSink.audio.muted) ? Theme.gray : Theme.accent
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (audioPanel.defaultSink) audioPanel.defaultSink.audio.muted = !audioPanel.defaultSink.audio.muted
              }
            }
          }

          Item {
            Layout.fillWidth: true
            height: 14

            property real vol: audioPanel.defaultSink ? audioPanel.defaultSink.audio.volume : 0

            Rectangle {
              anchors.verticalCenter: parent.verticalCenter
              width: parent.width
              height: 4
              radius: 2
              color: Theme.bg2

              Rectangle {
                width: Math.min(1, parent.parent.vol) * parent.width
                height: parent.height
                radius: 2
                color: Theme.accent
              }
            }

            Rectangle {
              x: Math.min(1, parent.vol) * (parent.width - 12)
              anchors.verticalCenter: parent.verticalCenter
              width: 12; height: 12; radius: 6
              color: Theme.accent
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onPressed: (mouse) => setVol(mouse)
              onPositionChanged: (mouse) => setVol(mouse)
              function setVol(mouse) {
                if (!audioPanel.defaultSink) return
                audioPanel.defaultSink.audio.volume = Math.max(0, Math.min(1.5, mouse.x / width))
              }
            }
          }

          Text {
            text: audioPanel.defaultSink ? Math.round(audioPanel.defaultSink.audio.volume * 100) + "%" : "--"
            font.family: Theme.fontFamily
            font.pixelSize: 11
            color: Theme.gray
            Layout.preferredWidth: 36
            horizontalAlignment: Text.AlignRight
          }
        }

        // ── Output Devices ──
        Text {
          text: "Output Device"
          font.family: Theme.fontFamily
          font.pixelSize: 11
          color: Theme.gray
          visible: audioPanel.sinkNodes.length > 1
        }

        Repeater {
          model: audioPanel.sinkNodes

          Rectangle {
            required property var modelData
            Layout.fillWidth: true
            height: visible ? 28 : 0
            radius: 4
            visible: audioPanel.sinkNodes.length > 1

            property bool isDefault: modelData.id === (audioPanel.defaultSink ? audioPanel.defaultSink.id : -1)
            color: isDefault ? Theme.accentAlpha(0.15) : "transparent"

            RowLayout {
              anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
              spacing: 6

              Text {
                text: parent.parent.isDefault ? "●" : "○"
                font.pixelSize: 8
                color: parent.parent.isDefault ? Theme.accent : Theme.gray
              }

              Text {
                Layout.fillWidth: true
                text: modelData.description || modelData.nickname || modelData.name
                font.family: Theme.fontFamily
                font.pixelSize: 11
                color: parent.parent.isDefault ? Theme.accent : Theme.fg
                elide: Text.ElideRight
              }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: Pipewire.preferredDefaultAudioSink = modelData
            }
          }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.accentAlpha(0.3) }

        // ── Microphone ──
        RowLayout {
          Layout.fillWidth: true
          spacing: 8

          Text {
            text: (audioPanel.defaultSource && audioPanel.defaultSource.audio.muted) ? "\u{f036e}" : "\u{f036c}"
            font.family: Theme.fontFamily
            font.pixelSize: 14
            color: (audioPanel.defaultSource && audioPanel.defaultSource.audio.muted) ? Theme.red : Theme.accent
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (audioPanel.defaultSource) audioPanel.defaultSource.audio.muted = !audioPanel.defaultSource.audio.muted
              }
            }
          }

          Text {
            text: "Microphone"
            font.family: Theme.fontFamily
            font.pixelSize: 11
            color: Theme.fg
            Layout.fillWidth: true
          }

          Text {
            text: audioPanel.defaultSource ? Math.round(audioPanel.defaultSource.audio.volume * 100) + "%" : "--"
            font.family: Theme.fontFamily
            font.pixelSize: 11
            color: Theme.gray
          }
        }

        Item {
          Layout.fillWidth: true
          height: 14
          visible: audioPanel.defaultSource != null

          property real vol: audioPanel.defaultSource ? audioPanel.defaultSource.audio.volume : 0

          Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 4
            radius: 2
            color: Theme.bg2

            Rectangle {
              width: Math.min(1, parent.parent.vol) * parent.width
              height: parent.height
              radius: 2
              color: Theme.accent
            }
          }

          Rectangle {
            x: Math.min(1, parent.vol) * (parent.width - 12)
            anchors.verticalCenter: parent.verticalCenter
            width: 12; height: 12; radius: 6
            color: Theme.accent
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onPressed: (mouse) => setMicVol(mouse)
            onPositionChanged: (mouse) => setMicVol(mouse)
            function setMicVol(mouse) {
              if (!audioPanel.defaultSource) return
              audioPanel.defaultSource.audio.volume = Math.max(0, Math.min(1, mouse.x / width))
            }
          }
        }

        // ── Applications ──
        Rectangle {
          Layout.fillWidth: true; height: 1; color: Theme.accentAlpha(0.3)
          visible: audioPanel.streamNodes.length > 0
        }

        Text {
          text: "Applications"
          font.family: Theme.fontFamily
          font.pixelSize: 11
          color: Theme.gray
          visible: audioPanel.streamNodes.length > 0
        }

        Repeater {
          model: audioPanel.streamNodes

          ColumnLayout {
            required property var modelData
            Layout.fillWidth: true
            spacing: 4

            RowLayout {
              Layout.fillWidth: true
              spacing: 6

              Text {
                text: modelData.properties["application.name"] || modelData.description || modelData.name || "Unknown"
                font.family: Theme.fontFamily
                font.pixelSize: 11
                color: Theme.fg
                Layout.fillWidth: true
                elide: Text.ElideRight
              }

              Text {
                text: modelData.audio ? Math.round(modelData.audio.volume * 100) + "%" : "--"
                font.family: Theme.fontFamily
                font.pixelSize: 10
                color: Theme.gray
              }

              Text {
                text: (modelData.audio && modelData.audio.muted) ? "\u{f0581}" : "\u{f057e}"
                font.family: Theme.fontFamily
                font.pixelSize: 12
                color: (modelData.audio && modelData.audio.muted) ? Theme.gray : Theme.fg
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: { if (modelData.audio) modelData.audio.muted = !modelData.audio.muted }
                }
              }
            }

            Item {
              Layout.fillWidth: true
              height: 10

              property var node: modelData

              Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 3
                radius: 1.5
                color: Theme.bg2

                Rectangle {
                  width: (parent.parent.node.audio ? Math.min(1, parent.parent.node.audio.volume) : 0) * parent.width
                  height: parent.height
                  radius: 1.5
                  color: Theme.accent
                }
              }

              Rectangle {
                x: (parent.node.audio ? Math.min(1, parent.node.audio.volume) : 0) * (parent.width - 8)
                anchors.verticalCenter: parent.verticalCenter
                width: 8; height: 8; radius: 4
                color: Theme.accent
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onPressed: (mouse) => setAppVol(mouse)
                onPositionChanged: (mouse) => setAppVol(mouse)
                function setAppVol(mouse) {
                  if (parent.node && parent.node.audio) {
                    parent.node.audio.volume = Math.max(0, Math.min(1.5, mouse.x / width))
                  }
                }
              }
            }
          }
        }

        Item { height: 4 }
      }
    }
  }
}
