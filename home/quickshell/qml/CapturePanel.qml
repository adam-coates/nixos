import QtQuick 6.0
import QtQuick.Layouts 6.0
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
  id: capturePanel

  property bool showing: GlobalState.activePopup === "capture"
  property string query: ""

  readonly property var allItems: [
    { icon: "󰹑", label: "Screenshot",                       cmd: "~/.config/scripts/capture-screenshot.sh" },
    { icon: "", label: "Screen Record",                     cmd: "~/.config/scripts/capture-screenrecord.sh" },
    { icon: "󰕾", label: "Screen Record (audio)",            cmd: "~/.config/scripts/capture-screenrecord.sh --with-desktop-audio" },
    { icon: "󰍬", label: "Screen Record (audio+mic)",         cmd: "~/.config/scripts/capture-screenrecord.sh --with-desktop-audio --with-microphone-audio" },
    { icon: "󰄀", label: "Screen Record (audio+mic+webcam)",  cmd: "~/.config/scripts/capture-screenrecord.sh --with-desktop-audio --with-microphone-audio --with-webcam" },
    { icon: "󰵐", label: "Record GIF",                       cmd: "~/.config/scripts/capture-gif.sh" },
    { icon: "󰴑", label: "Text Extraction",                  cmd: "~/.config/scripts/capture-ocr.sh" },
    { icon: "󰃉", label: "Color Picker",                     cmd: "~/.config/scripts/capture-colorpicker.sh" }
  ]

  readonly property var filteredItems: {
    const q = query.toLowerCase().trim()
    if (!q) return allItems
    return allItems.filter(item => item.label.toLowerCase().includes(q))
  }

  visible: showing
  onShowingChanged: {
    if (showing) {
      query = ""
      searchInput.forceActiveFocus()
    }
  }

  anchors { top: true; left: true; right: true; bottom: true }
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "quickshell-capture"
  WlrLayershell.keyboardFocus: showing ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore
  color: "transparent"

  Process { id: captureProc; running: false }

  Rectangle {
    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, showing ? 0.3 : 0)
    Behavior on color { ColorAnimation { duration: 150 } }
    MouseArea {
      anchors.fill: parent
      onClicked: GlobalState.closeAll()
    }
  }

  Rectangle {
    anchors.centerIn: parent
    width: 460
    height: col.implicitHeight + 40
    color: Theme.bgAlpha(0.97)
    border.color: Theme.accent
    border.width: 1
    radius: 12

    opacity: showing ? 1 : 0
    scale: showing ? 1 : 0.95
    Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

    MouseArea { anchors.fill: parent }

    ColumnLayout {
      id: col
      anchors.fill: parent
      anchors.margins: 20
      spacing: 10

      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 40
        color: Theme.bg1
        radius: 6

        RowLayout {
          anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
          spacing: 8

          Text {
            text: "󰄀"
            font.family: Theme.fontFamily
            font.pixelSize: 14
            color: Theme.gray
          }

          TextInput {
            id: searchInput
            Layout.fillWidth: true
            verticalAlignment: TextInput.AlignVCenter
            font.family: Theme.fontFamily
            font.pixelSize: 14
            color: Theme.fg
            clip: true
            text: capturePanel.query
            onTextChanged: {
              capturePanel.query = text
              resultsList.currentIndex = 0
            }

            Keys.onEscapePressed: GlobalState.closeAll()
            Keys.onReturnPressed: launchCurrent()
            Keys.onDownPressed: {
              if (resultsList.currentIndex < resultsList.count - 1)
                resultsList.currentIndex++
            }
            Keys.onUpPressed: {
              if (resultsList.currentIndex > 0)
                resultsList.currentIndex--
            }

            Text {
              anchors.fill: parent
              verticalAlignment: Text.AlignVCenter
              font.family: Theme.fontFamily
              font.pixelSize: 14
              color: Theme.gray
              visible: searchInput.text === ""
              text: "Capture..."
            }
          }
        }
      }

      ListView {
        id: resultsList
        Layout.fillWidth: true
        Layout.preferredHeight: contentHeight
        clip: true
        currentIndex: 0
        spacing: 2
        interactive: false

        model: ScriptModel { values: capturePanel.filteredItems }

        delegate: Rectangle {
          required property int index
          required property var modelData

          width: resultsList.width
          height: 40
          color: resultsList.currentIndex === index ? Theme.accentAlpha(0.2) : "transparent"
          radius: 6

          Behavior on color { ColorAnimation { duration: 80 } }

          RowLayout {
            anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
            spacing: 10

            Text {
              text: modelData.icon
              font.family: Theme.fontFamily
              font.pixelSize: 16
              color: resultsList.currentIndex === index ? Theme.accent : Theme.fg
              Layout.preferredWidth: 24
              horizontalAlignment: Text.AlignHCenter
            }

            Text {
              Layout.fillWidth: true
              text: modelData.label
              font.family: Theme.fontFamily
              font.pixelSize: 13
              color: resultsList.currentIndex === index ? Theme.accent : Theme.fg
              elide: Text.ElideRight
            }
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onEntered: resultsList.currentIndex = index
            onClicked: { resultsList.currentIndex = index; launchCurrent() }
          }
        }
      }
    }
  }

  function launchCurrent() {
    if (resultsList.count === 0) return
    const items = filteredItems
    const idx = resultsList.currentIndex
    if (idx < 0 || idx >= items.length) return
    const item = items[idx]
    const cmd = item.cmd
    GlobalState.closeAll()
    captureProc.command = ["bash", "-c", "sleep 0.3 && " + cmd]
    captureProc.running = false
    captureProc.running = true
  }
}
