import QtQuick 6.0
import QtQuick.Layouts 6.0
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
  id: clipPanel

  property bool showing: GlobalState.activePopup === "clipboard"
  property var entries: []    // [{ line: int, preview: string }]
  property string filterText: ""

  visible: showing
  onShowingChanged: {
    if (showing) {
      filterText = ""
      clipFilter.text = ""
      loadHistory()
    }
  }

  anchors.top: true
  anchors.right: true
  margins { top: 30; right: 4 }

  width: 360
  height: Math.min(panelCol.implicitHeight + 16, 500)

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "quickshell-clipboard"
  WlrLayershell.keyboardFocus: showing ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore
  color: "transparent"

  // Ensure home packages (cliphist, wl-copy) are on PATH
  readonly property string nixPath:
    "export PATH=\"$HOME/.nix-profile/bin:/run/current-system/sw/bin:$PATH\"; "

  property bool loaded: false

  // Load clipboard history from cliphist
  Process {
    id: listProc
    command: ["bash", "-c", clipPanel.nixPath + "cliphist list 2>/dev/null"]
    running: false
    onExited: clipPanel.loaded = true
    stdout: SplitParser {
      onRead: line => {
        if (!line.trim()) return
        const tab = line.indexOf("\t")
        if (tab < 0) return
        const lineNum = parseInt(line.slice(0, tab))
        const preview = line.slice(tab + 1).trim()
        if (preview && !preview.startsWith("[[")) {
          clipPanel.entries = [...clipPanel.entries, { line: lineNum, preview }]
        }
      }
    }
  }

  Process { id: pasteProc; running: false }

  Process {
    id: wipeProc
    running: false
    onExited: clipPanel.entries = []
  }

  function loadHistory() {
    entries = []
    loaded = false
    listProc.running = false
    listProc.running = true
  }

  function pasteEntry(lineNum) {
    pasteProc.command = [
      "bash", "-c",
      nixPath + "cliphist list | awk -F'\\t' -v id=" + lineNum +
      " '$1==id{print;exit}' | cliphist decode | wl-copy"
    ]
    pasteProc.running = false
    pasteProc.running = true
    GlobalState.closeAll()
  }

  function clearHistory() {
    wipeProc.command = ["bash", "-c", nixPath + "cliphist wipe"]
    wipeProc.running = false
    wipeProc.running = true
  }

  Rectangle {
    anchors.fill: parent
    color: Theme.bgAlpha(0.97)
    border.color: Theme.accent
    border.width: 1
    radius: 6

    ColumnLayout {
      id: panelCol
      anchors { top: parent.top; left: parent.left; right: parent.right; margins: 8 }
      spacing: 6

      // Header
      RowLayout {
        Layout.fillWidth: true

        Text {
          text: "Clipboard"
          font.family: Theme.fontFamily
          font.pixelSize: 13
          font.bold: true
          color: Theme.fg
        }

        Item { Layout.fillWidth: true }

        Text {
          text: "Clear"
          font.family: Theme.fontFamily
          font.pixelSize: 11
          color: Theme.accent
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: clipPanel.clearHistory()
          }
        }
      }

      // Filter input
      Rectangle {
        Layout.fillWidth: true
        height: 28
        color: Theme.bg1
        radius: 4

        TextInput {
          id: clipFilter
          anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
          verticalAlignment: TextInput.AlignVCenter
          font.family: Theme.fontFamily
          font.pixelSize: 12
          color: Theme.fg
          clip: true
          onTextChanged: clipPanel.filterText = text

          Keys.onEscapePressed: GlobalState.closeAll()
          Keys.onReturnPressed: {
            const visible = filteredEntries()
            if (visible.length > 0) clipPanel.pasteEntry(visible[0].line)
          }

          Text {
            anchors.fill: parent
            verticalAlignment: Text.AlignVCenter
            text: " Filter..."
            font.family: Theme.fontFamily
            font.pixelSize: 12
            color: Theme.gray
            visible: clipFilter.text === ""
          }
        }
      }

      // Empty state
      Text {
        Layout.fillWidth: true
        visible: clipPanel.entries.length === 0 && clipPanel.loaded
        text: "No clipboard history"
        font.family: Theme.fontFamily
        font.pixelSize: 12
        color: Theme.gray
        horizontalAlignment: Text.AlignHCenter
        topPadding: 10
        bottomPadding: 10
      }

      // Entries list
      ListView {
        id: clipList
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, 400)
        clip: true
        spacing: 2

        model: ScriptModel {
          values: {
            const f = clipPanel.filterText.toLowerCase()
            if (!f) return clipPanel.entries
            return clipPanel.entries.filter(e => e.preview.toLowerCase().includes(f))
          }
        }

        delegate: Rectangle {
          required property int index
          required property var modelData

          width: clipList.width
          height: 36
          color: clipHover.containsMouse ? Theme.accentAlpha(0.15) : "transparent"
          radius: 4

          Text {
            anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
            verticalAlignment: Text.AlignVCenter
            text: modelData.preview
            font.family: Theme.fontFamily
            font.pixelSize: 12
            color: Theme.fg
            elide: Text.ElideRight
          }

          MouseArea {
            id: clipHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: clipPanel.pasteEntry(modelData.line)
          }
        }
      }
    }
  }

  function filteredEntries() {
    const f = filterText.toLowerCase()
    if (!f) return entries
    return entries.filter(e => e.preview.toLowerCase().includes(f))
  }
}
