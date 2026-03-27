import QtQuick 6.0
import QtQuick.Layouts 6.0
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
  id: launcher

  property bool showing: GlobalState.activePopup === "launcher"
  property string query: ""
  property var fileResults: []
  property string previewText: ""

  readonly property string mode: {
    const q = query
    if (q.startsWith("=")) return "calc"
    if (q.startsWith("?")) return "web"
    if (q.startsWith("~/") || q.startsWith("/")) return "file"
    return "app"
  }

  readonly property string calcResult: {
    if (mode !== "calc") return ""
    const expr = query.slice(1).trim()
    if (!expr || !/^[\d\s+\-*/().,^%]+$/.test(expr)) return ""
    try {
      const r = Function("return (" + expr.replace(/\^/g, "**") + ")")()
      if (typeof r !== "number" || !isFinite(r)) return ""
      return Number.isInteger(r) ? String(r) : parseFloat(r.toFixed(8)).toString()
    } catch(e) { return "" }
  }

  // Currently selected file path (file mode only)
  readonly property string selectedPath: {
    if (mode !== "file" || fileResults.length === 0) return ""
    const idx = resultsList.currentIndex
    return (idx >= 0 && idx < fileResults.length) ? fileResults[idx] : ""
  }

  readonly property bool showPreview: mode === "file" && selectedPath !== ""

  function previewKind(path) {
    if (!path) return "none"
    const ext = path.split('.').pop().toLowerCase()
    if (["png","jpg","jpeg","gif","webp","svg","bmp","ico"].includes(ext)) return "image"
    if (["txt","md","js","ts","jsx","tsx","mjs","py","sh","bash","zsh","fish",
         "json","yaml","yml","toml","nix","conf","cfg","ini","env","lock",
         "html","css","scss","rs","go","c","cpp","h","hpp","java","kt",
         "rb","php","sql","xml","csv","diff","patch","log"].includes(ext)) return "text"
    return "other"
  }

  // Load text preview when selected path changes
  onSelectedPathChanged: {
    previewText = ""
    if (selectedPath && previewKind(selectedPath) === "text") {
      textView.reload()
    }
  }

  FileView {
    id: textView
    path: launcher.selectedPath || "/dev/null"
    watchChanges: false
    onLoaded: launcher.previewText = text().slice(0, 4000)
  }

  // File search via fd
  Process {
    id: fileProc
    running: false
    stdout: SplitParser {
      onRead: line => {
        if (line.trim()) launcher.fileResults = [...launcher.fileResults, line.trim()]
      }
    }
  }

  Timer {
    id: fileDebounce
    interval: 200
    onTriggered: {
      if (launcher.mode !== "file") return
      const q = launcher.query
      const term = q.startsWith("~/") ? q.slice(2) : q.slice(1)
      launcher.fileResults = []
      fileProc.running = false
      fileProc.command = [
        "fd", "--max-results", "30", "--hidden",
        "--exclude", ".git", "--exclude", "node_modules",
        term.trim() || ".", Quickshell.env("HOME")
      ]
      fileProc.running = true
    }
  }

  onQueryChanged: {
    resultsList.currentIndex = 0
    if (mode === "file") {
      fileDebounce.restart()
    } else {
      fileProc.running = false
      fileResults = []
    }
  }

  visible: showing
  onShowingChanged: {
    if (showing) {
      query = ""
      fileResults = []
      previewText = ""
      searchInput.forceActiveFocus()
    }
  }

  anchors { top: true; left: true; right: true; bottom: true }
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "quickshell-launcher"
  WlrLayershell.keyboardFocus: showing ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore
  color: Qt.rgba(0, 0, 0, 0.3)

  MouseArea {
    anchors.fill: parent
    onClicked: GlobalState.closeAll()
  }

  Rectangle {
    id: launcherBox
    anchors.centerIn: parent
    width: launcher.showPreview ? 960 : 620
    height: 480
    color: Theme.bgAlpha(0.97)
    border.color: Theme.accent
    border.width: 1
    radius: 12

    Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

    MouseArea { anchors.fill: parent }

    RowLayout {
      anchors.fill: parent
      anchors.margins: 20
      spacing: 12

      // ── Left: search + results ──
      ColumnLayout {
        Layout.preferredWidth: 560
        Layout.fillHeight: true
        spacing: 10

        // Search bar
        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: 40
          color: Theme.bg1
          radius: 6

          RowLayout {
            anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
            spacing: 0

            TextInput {
              id: searchInput
              Layout.fillWidth: true
              verticalAlignment: TextInput.AlignVCenter
              font.family: Theme.fontFamily
              font.pixelSize: 14
              color: Theme.fg
              clip: true
              text: launcher.query
              onTextChanged: launcher.query = text

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
                text: "  Search apps...  ( = calc   ? web   ~/ files )"
              }
            }

            Rectangle {
              visible: launcher.mode !== "app"
              width: modeLabel.implicitWidth + 12
              height: 24
              radius: 4
              color: Theme.accentAlpha(0.2)
              Text {
                id: modeLabel
                anchors.centerIn: parent
                text: launcher.mode === "calc" ? "calc" : launcher.mode === "web" ? "web" : "files"
                font.family: Theme.fontFamily
                font.pixelSize: 11
                color: Theme.accent
              }
            }
          }
        }

        // Results list
        ListView {
          id: resultsList
          Layout.fillWidth: true
          Layout.fillHeight: true
          clip: true
          currentIndex: 0
          spacing: 2
          keyNavigationWraps: false

          model: ScriptModel {
            values: {
              const q = launcher.query.trim()

              if (launcher.mode === "calc") {
                const expr = q.slice(1).trim()
                const r = launcher.calcResult
                if (r !== "") return [{ _t: "calc", expr, result: r }]
                return expr ? [{ _t: "calc_err", expr }] : []
              }

              if (launcher.mode === "web") {
                const wq = q.slice(1).trim()
                return wq ? [{ _t: "web", query: wq }] : []
              }

              if (launcher.mode === "file") {
                return launcher.fileResults.map(p => ({
                  _t: "file", path: p, name: p.split("/").pop()
                }))
              }

              const ql = q.toLowerCase()
              const all = [...DesktopEntries.applications.values].filter(e =>
                e.name && e.noDisplay !== true
              )
              const filtered = ql === "" ? all : all.filter(e => e.name.toLowerCase().includes(ql))
              filtered.sort((a, b) => {
                if (ql) {
                  const as = a.name.toLowerCase().startsWith(ql)
                  const bs = b.name.toLowerCase().startsWith(ql)
                  if (as && !bs) return -1
                  if (!as && bs) return 1
                }
                return a.name.localeCompare(b.name)
              })
              return filtered.map(e => ({ _t: "app", entry: e }))
            }
          }

          delegate: Rectangle {
            required property int index
            required property var modelData

            width: resultsList.width
            height: 40
            color: resultsList.currentIndex === index ? Theme.accentAlpha(0.2) : "transparent"
            radius: 6

            RowLayout {
              anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
              spacing: 10

              Text {
                visible: modelData._t !== "app"
                text: (modelData._t === "calc" || modelData._t === "calc_err") ? "="
                      : modelData._t === "web" ? "?" : "~"
                font.family: Theme.fontFamily
                font.pixelSize: 15
                font.bold: true
                color: resultsList.currentIndex === index ? Theme.accent : Theme.gray
                Layout.preferredWidth: 24
                horizontalAlignment: Text.AlignHCenter
              }

              Image {
                visible: modelData._t === "app"
                source: (modelData._t === "app" && modelData.entry.icon)
                        ? Quickshell.iconPath(modelData.entry.icon, true) : ""
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                fillMode: Image.PreserveAspectFit
              }

              Text {
                Layout.fillWidth: true
                text: modelData._t === "calc"     ? modelData.expr + "  =  " + modelData.result
                    : modelData._t === "calc_err" ? "Invalid expression"
                    : modelData._t === "web"      ? "Search Google:  " + modelData.query
                    : modelData._t === "file"     ? modelData.name
                    : modelData.entry.name
                font.family: Theme.fontFamily
                font.pixelSize: 13
                color: resultsList.currentIndex === index ? Theme.accent : Theme.fg
                elide: Text.ElideRight
              }

              Text {
                visible: modelData._t === "file"
                text: {
                  if (modelData._t !== "file") return ""
                  const home = Quickshell.env("HOME")
                  return modelData.path.startsWith(home)
                    ? "~" + modelData.path.slice(home.length) : modelData.path
                }
                font.family: Theme.fontFamily
                font.pixelSize: 10
                color: Theme.gray
                elide: Text.ElideRight
                Layout.maximumWidth: 180
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

      // ── Right: file preview ──
      Rectangle {
        visible: launcher.showPreview
        Layout.fillWidth: true
        Layout.fillHeight: true
        color: Theme.bg1
        radius: 8
        clip: true

        // Image preview
        Image {
          anchors.fill: parent
          anchors.margins: 8
          visible: launcher.previewKind(launcher.selectedPath) === "image"
          source: visible ? "file://" + launcher.selectedPath : ""
          fillMode: Image.PreserveAspectFit
          asynchronous: true
        }

        // Text preview
        Flickable {
          anchors.fill: parent
          anchors.margins: 10
          visible: launcher.previewKind(launcher.selectedPath) === "text"
          contentWidth: width
          contentHeight: textPreviewContent.implicitHeight
          clip: true

          Text {
            id: textPreviewContent
            width: parent.width
            text: launcher.previewText || "Loading..."
            font.family: Theme.fontFamily
            font.pixelSize: 10
            color: Theme.gray
            wrapMode: Text.WrapAnywhere
          }
        }

        // Generic / unsupported
        Column {
          anchors.centerIn: parent
          visible: launcher.previewKind(launcher.selectedPath) === "other"
          spacing: 8

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "󰈔"
            font.family: Theme.fontFamily
            font.pixelSize: 48
            color: Theme.gray
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: launcher.selectedPath.split("/").pop()
            font.family: Theme.fontFamily
            font.pixelSize: 12
            color: Theme.fg
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: launcher.selectedPath.split('.').pop().toUpperCase()
            font.family: Theme.fontFamily
            font.pixelSize: 11
            color: Theme.gray
          }
        }
      }
    }
  }

  function launchCurrent() {
    if (resultsList.count === 0) return
    const item = resultsList.model.values[resultsList.currentIndex]
    if (!item) return

    if (item._t === "app") {
      GlobalState.closeAll()
      item.entry.execute()
    } else if (item._t === "calc") {
      searchInput.text = item.result
      searchInput.selectAll()
    } else if (item._t === "web") {
      GlobalState.closeAll()
      Qt.openUrlExternally("https://www.google.com/search?q=" + encodeURIComponent(item.query))
    } else if (item._t === "file") {
      GlobalState.closeAll()
      Qt.openUrlExternally("file://" + item.path)
    }
  }
}
