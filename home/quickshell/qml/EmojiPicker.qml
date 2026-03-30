import QtQuick 6.0
import QtQuick.Layouts 6.0
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
  id: emojiPicker

  property bool showing: GlobalState.activePopup === "emoji"
  property string query: ""
  property var allEmojis: []

  // Load emoji data from generated file
  FileView {
    id: emojiFile
    path: Quickshell.env("HOME") + "/.local/share/quickshell/emojis.txt"
    onLoaded: {
      var lines = text().split("\n")
      var result = []
      for (var i = 0; i < lines.length; i++) {
        var tab = lines[i].indexOf("\t")
        if (tab > 0) {
          result.push({ emoji: lines[i].substring(0, tab), name: lines[i].substring(tab + 1) })
        }
      }
      emojiPicker.allEmojis = result
    }
  }

  onQueryChanged: emojiList.currentIndex = 0

  visible: showing
  onShowingChanged: {
    if (showing) {
      query = ""
      searchInput.forceActiveFocus()
    }
  }

  anchors { top: true; left: true; right: true; bottom: true }
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "quickshell-emoji"
  WlrLayershell.keyboardFocus: showing ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore
  color: "transparent"

  // Dim backdrop
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
    width: 420
    height: 480
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
      anchors.fill: parent
      anchors.margins: 16
      spacing: 8

      // Search bar
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 40
        color: Theme.bg1
        radius: 6

        TextInput {
          id: searchInput
          anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
          verticalAlignment: TextInput.AlignVCenter
          font.family: Theme.fontFamily
          font.pixelSize: 14
          color: Theme.fg
          clip: true
          text: emojiPicker.query
          onTextChanged: emojiPicker.query = text

          Keys.onEscapePressed: GlobalState.closeAll()
          Keys.onReturnPressed: copySelected()
          Keys.onDownPressed: {
            if (emojiList.currentIndex < emojiList.count - 1)
              emojiList.currentIndex++
          }
          Keys.onUpPressed: {
            if (emojiList.currentIndex > 0)
              emojiList.currentIndex--
          }

          Text {
            anchors.fill: parent
            verticalAlignment: Text.AlignVCenter
            font.family: Theme.fontFamily
            font.pixelSize: 14
            color: Theme.gray
            visible: searchInput.text === ""
            text: "  Search emoji..."
          }
        }
      }

      // Emoji list
      ListView {
        id: emojiList
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        currentIndex: 0
        spacing: 2
        keyNavigationWraps: false

        model: ScriptModel {
          values: {
            const q = emojiPicker.query.trim().toLowerCase()
            const all = emojiPicker.allEmojis
            if (q === "") return all.slice(0, 80)
            const words = q.split(/\s+/)
            var filtered = all.filter(e => {
              const n = e.name
              return words.every(w => n.includes(w))
            })
            filtered.sort((a, b) => {
              const as = a.name.startsWith(q)
              const bs = b.name.startsWith(q)
              if (as && !bs) return -1
              if (!as && bs) return 1
              return 0
            })
            return filtered.slice(0, 80)
          }
        }

        delegate: Rectangle {
          required property int index
          required property var modelData

          width: emojiList.width
          height: 36
          color: emojiList.currentIndex === index ? Theme.accentAlpha(0.2) : "transparent"
          radius: 6

          Behavior on color { ColorAnimation { duration: 80 } }

          RowLayout {
            anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
            spacing: 10

            Text {
              text: modelData.emoji
              font.pixelSize: 20
              Layout.preferredWidth: 32
              horizontalAlignment: Text.AlignHCenter
            }

            Text {
              Layout.fillWidth: true
              text: modelData.name
              font.family: Theme.fontFamily
              font.pixelSize: 13
              color: emojiList.currentIndex === index ? Theme.accent : Theme.fg
              elide: Text.ElideRight
            }
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onEntered: emojiList.currentIndex = index
            onClicked: { emojiList.currentIndex = index; copySelected() }
          }
        }
      }
    }
  }

  // Copy process
  Process {
    id: copyProc
    running: false
  }

  function copySelected() {
    if (emojiList.count === 0) return
    const item = emojiList.model.values[emojiList.currentIndex]
    if (!item) return
    copyProc.command = ["wl-copy", item.emoji]
    copyProc.running = false
    copyProc.running = true
    GlobalState.closeAll()
  }
}
