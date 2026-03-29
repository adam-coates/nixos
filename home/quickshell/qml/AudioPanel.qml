import QtQuick 6.0
import QtQuick.Layouts 6.0
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import Quickshell.Io

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

  // ── wpctl-based volume state ──
  property real sinkVolume: 0
  property bool sinkMuted: false
  property real sourceVolume: 0
  property bool sourceMuted: false

  // ── wpctl polling processes ──
  Process {
    id: sinkVolProc
    command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
    running: true
    property string _output: ""
    stdout: SplitParser {
      onRead: line => sinkVolProc._output = line
    }
    onExited: {
      var line = sinkVolProc._output
      sinkVolProc._output = ""
      var match = line.match(/Volume:\s+([\d.]+)/)
      if (match) audioPanel.sinkVolume = parseFloat(match[1])
      audioPanel.sinkMuted = line.indexOf("[MUTED]") >= 0
    }
  }

  Process {
    id: sourceVolProc
    command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"]
    running: true
    property string _output: ""
    stdout: SplitParser {
      onRead: line => sourceVolProc._output = line
    }
    onExited: {
      var line = sourceVolProc._output
      sourceVolProc._output = ""
      var match = line.match(/Volume:\s+([\d.]+)/)
      if (match) audioPanel.sourceVolume = parseFloat(match[1])
      audioPanel.sourceMuted = line.indexOf("[MUTED]") >= 0
    }
  }

  Timer {
    interval: 500
    running: audioPanel.showing
    repeat: true
    onTriggered: {
      sinkVolProc.running = true
      sourceVolProc.running = true
    }
  }

  onShowingChanged: {
    if (showing) {
      sinkVolProc.running = true
      sourceVolProc.running = true
    }
  }

  // ── wpctl set commands ──
  Process {
    id: setSinkVolProc
    running: false
  }

  Process {
    id: setSourceVolProc
    running: false
  }

  Process {
    id: toggleSinkMuteProc
    command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
    running: false
  }

  Process {
    id: toggleSourceMuteProc
    command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"]
    running: false
  }

  function setSinkVol(v) {
    v = Math.max(0, Math.min(1.5, v))
    sinkVolume = v
    setSinkVolProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", v.toFixed(2)]
    setSinkVolProc.running = false
    setSinkVolProc.running = true
  }

  function setSourceVol(v) {
    v = Math.max(0, Math.min(1, v))
    sourceVolume = v
    setSourceVolProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SOURCE@", v.toFixed(2)]
    setSourceVolProc.running = false
    setSourceVolProc.running = true
  }

  // ── Pipewire module for device listing only ──
  property var defaultSink: Pipewire.defaultAudioSink

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

    opacity: audioPanel.showing ? 1 : 0
    scale: audioPanel.showing ? 1 : 0.96
    transformOrigin: Item.TopRight
    Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

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
              if (audioPanel.sinkMuted) return "\u{f0581}"
              var v = audioPanel.sinkVolume
              if (v > 0.66) return "\u{f057e}"
              if (v > 0.33) return "\u{f0580}"
              return "\u{f057f}"
            }
            font.family: Theme.fontFamily
            font.pixelSize: 16
            color: audioPanel.sinkMuted ? Theme.gray : Theme.accent
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                toggleSinkMuteProc.running = false
                toggleSinkMuteProc.running = true
                audioPanel.sinkMuted = !audioPanel.sinkMuted
              }
            }
          }

          Item {
            Layout.fillWidth: true
            height: 14

            Rectangle {
              anchors.verticalCenter: parent.verticalCenter
              width: parent.width
              height: 4
              radius: 2
              color: Theme.bg2

              Rectangle {
                width: Math.min(1, audioPanel.sinkVolume) * parent.width
                height: parent.height
                radius: 2
                color: Theme.accent
              }
            }

            Rectangle {
              x: Math.min(1, audioPanel.sinkVolume) * (parent.width - 12)
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
                audioPanel.setSinkVol(mouse.x / width)
              }
            }
          }

          Text {
            text: Math.round(audioPanel.sinkVolume * 100) + "%"
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
            text: audioPanel.sourceMuted ? "\u{f036e}" : "\u{f036c}"
            font.family: Theme.fontFamily
            font.pixelSize: 14
            color: audioPanel.sourceMuted ? Theme.red : Theme.accent
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                toggleSourceMuteProc.running = false
                toggleSourceMuteProc.running = true
                audioPanel.sourceMuted = !audioPanel.sourceMuted
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
            text: Math.round(audioPanel.sourceVolume * 100) + "%"
            font.family: Theme.fontFamily
            font.pixelSize: 11
            color: Theme.gray
          }
        }

        Item {
          Layout.fillWidth: true
          height: 14

          Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 4
            radius: 2
            color: Theme.bg2

            Rectangle {
              width: Math.min(1, audioPanel.sourceVolume) * parent.width
              height: parent.height
              radius: 2
              color: Theme.accent
            }
          }

          Rectangle {
            x: Math.min(1, audioPanel.sourceVolume) * (parent.width - 12)
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
              audioPanel.setSourceVol(mouse.x / width)
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
                text: modelData.audio && !isNaN(modelData.audio.volume) ? Math.round(modelData.audio.volume * 100) + "%" : "--"
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
                  width: (parent.parent.node.audio && !isNaN(parent.parent.node.audio.volume) ? Math.min(1, parent.parent.node.audio.volume) : 0) * parent.width
                  height: parent.height
                  radius: 1.5
                  color: Theme.accent
                }
              }

              Rectangle {
                x: (parent.node.audio && !isNaN(parent.node.audio.volume) ? Math.min(1, parent.node.audio.volume) : 0) * (parent.width - 8)
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

        // ── Equalizer ──
        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.accentAlpha(0.3) }

        RowLayout {
          Layout.fillWidth: true
          spacing: 6

          Text {
            text: "Equalizer"
            font.family: Theme.fontFamily
            font.pixelSize: 11
            color: Theme.gray
          }

          Item { Layout.fillWidth: true }

          Text {
            text: "Open EasyEffects"
            font.family: Theme.fontFamily
            font.pixelSize: 10
            color: Theme.accent
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                eqLaunchProc.running = false
                eqLaunchProc.running = true
              }
            }
          }
        }

        // Preset buttons
        Flow {
          Layout.fillWidth: true
          spacing: 4

          Repeater {
            model: [
              { label: "Flat", preset: "Flat" },
              { label: "Bass Boost", preset: "BassBoost" },
              { label: "Rock", preset: "Rock" },
              { label: "Vocal", preset: "Vocal" },
              { label: "Treble", preset: "Treble" },
              { label: "Enhanced", preset: "Enhanced" }
            ]

            Rectangle {
              required property var modelData
              required property int index
              width: presetLabel.implicitWidth + 14
              height: 24; radius: 4
              color: audioPanel.activePreset === modelData.preset ? Theme.accentAlpha(0.25) : Theme.bg2

              Behavior on color { ColorAnimation { duration: 100 } }

              Text {
                id: presetLabel
                anchors.centerIn: parent
                text: modelData.label
                font.family: Theme.fontFamily
                font.pixelSize: 10
                color: audioPanel.activePreset === modelData.preset ? Theme.accent : Theme.fg
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  audioPanel.activePreset = modelData.preset
                  eqLoadProc.command = ["easyeffects", "-l", modelData.preset]
                  eqLoadProc.running = false
                  eqLoadProc.running = true
                }
              }
            }
          }
        }

        Item { height: 4 }
      }
    }
  }

  // EQ state
  property string activePreset: "Flat"

  Process { id: eqLoadProc; running: false }
  Process {
    id: eqLaunchProc
    command: ["easyeffects"]
    running: false
  }
}
