import QtQuick 6.0
import QtQuick.Layouts 6.0
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
  id: preview

  readonly property string filePath: GlobalState.previewFile

  visible: filePath !== ""

  anchors.right: true
  anchors.top: true
  anchors.bottom: true
  margins { top: 60; right: 20; bottom: 20 }
  width: 460

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "quickshell-file-preview"
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore
  color: "transparent"

  // --- state ---
  property int  pdfStamp: 0      // bumped on each new PDF render to bust image cache
  property string bodyText: ""   // loaded text file content

  function fileKind(path) {
    if (!path) return "none"
    const ext = path.split('.').pop().toLowerCase()
    if (["png","jpg","jpeg","gif","webp","svg","bmp","ico","avif","tiff"].includes(ext))
      return "image"
    if (ext === "pdf") return "pdf"
    if (["txt","md","markdown","rst","log","diff","patch",
         "js","ts","jsx","tsx","mjs","cjs",
         "py","rb","go","rs","c","cpp","h","hpp","java","kt","swift",
         "sh","bash","zsh","fish",
         "json","yaml","yml","toml","nix","conf","cfg","ini","env",
         "html","css","scss","sass","xml","svg",
         "sql","csv","gitignore","dockerfile","makefile"].includes(ext))
      return "text"
    return "other"
  }

  // PDF → PNG via pdftoppm
  Process {
    id: pdfProc
    running: false
    onExited: preview.pdfStamp = Date.now()
  }

  // Text file reader
  FileView {
    id: textView
    path: (preview.filePath && preview.fileKind(preview.filePath) === "text")
          ? preview.filePath : "/dev/null"
    watchChanges: false
    onLoaded: preview.bodyText = text().slice(0, 6000)
  }

  onFilePathChanged: {
    pdfStamp = 0
    bodyText = ""
    if (!filePath) return
    const kind = fileKind(filePath)
    if (kind === "pdf") {
      pdfProc.running = false
      pdfProc.command = [
        "pdftoppm", "-png", "-f", "1", "-l", "1", "-r", "150",
        filePath, "/tmp/qs-preview"
      ]
      pdfProc.running = true
    } else if (kind === "text") {
      textView.reload()
    }
  }

  // --- UI ---
  Rectangle {
    anchors.fill: parent
    color: Theme.bgAlpha(0.97)
    border.color: Theme.accent
    border.width: 1
    radius: 8
    clip: true

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 12
      spacing: 8

      // Header: filename + close button
      RowLayout {
        Layout.fillWidth: true
        spacing: 6

        Text {
          text: {
            const k = preview.fileKind(preview.filePath)
            return k === "image" ? "󰋩" : k === "pdf" ? "󰈦" : k === "text" ? "󰈙" : "󰈔"
          }
          font.family: Theme.fontFamily
          font.pixelSize: 14
          color: Theme.accent
        }

        Text {
          Layout.fillWidth: true
          text: preview.filePath.split("/").pop()
          font.family: Theme.fontFamily
          font.pixelSize: 13
          font.bold: true
          color: Theme.fg
          elide: Text.ElideMiddle
        }

        Text {
          text: "×"
          font.pixelSize: 18
          color: Theme.gray
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: GlobalState.previewFile = ""
          }
        }
      }

      Rectangle { Layout.fillWidth: true; height: 1; color: Theme.accentAlpha(0.3) }

      // Content area
      Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        // ── Image ──
        Image {
          anchors.fill: parent
          visible: preview.fileKind(preview.filePath) === "image"
          source: visible ? "file://" + preview.filePath : ""
          fillMode: Image.PreserveAspectFit
          asynchronous: true
          smooth: true
        }

        // ── PDF (first page rendered by pdftoppm) ──
        Item {
          anchors.fill: parent
          visible: preview.fileKind(preview.filePath) === "pdf"

          Text {
            anchors.centerIn: parent
            visible: preview.pdfStamp === 0
            text: "Rendering PDF…"
            font.family: Theme.fontFamily
            font.pixelSize: 12
            color: Theme.gray
          }

          Image {
            anchors.fill: parent
            visible: preview.pdfStamp !== 0
            // Append stamp as fragment to bust QML's image cache
            source: preview.pdfStamp !== 0
                    ? "file:///tmp/qs-preview-1.png#" + preview.pdfStamp : ""
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            cache: false
            smooth: true
          }
        }

        // ── Text / code ──
        Flickable {
          anchors.fill: parent
          visible: preview.fileKind(preview.filePath) === "text"
          contentWidth: width
          contentHeight: codeText.implicitHeight + 8
          clip: true

          Text {
            id: codeText
            width: parent.width
            text: preview.bodyText || "Loading…"
            font.family: Theme.fontFamily
            font.pixelSize: 11
            color: Theme.gray
            wrapMode: Text.WrapAnywhere
            lineHeight: 1.3
          }
        }

        // ── Other / unsupported ──
        Column {
          anchors.centerIn: parent
          spacing: 10
          visible: preview.fileKind(preview.filePath) === "other"

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "󰈔"
            font.family: Theme.fontFamily
            font.pixelSize: 56
            color: Theme.gray
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: preview.filePath.split('.').pop().toUpperCase()
            font.family: Theme.fontFamily
            font.pixelSize: 13
            color: Theme.gray
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "No preview available"
            font.family: Theme.fontFamily
            font.pixelSize: 11
            color: Theme.gray
          }
        }
      }

      // Open button
      Rectangle {
        Layout.fillWidth: true
        height: 28
        color: Theme.accentAlpha(0.15)
        radius: 4

        Text {
          anchors.centerIn: parent
          text: "Open with default app"
          font.family: Theme.fontFamily
          font.pixelSize: 11
          color: Theme.accent
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            Qt.openUrlExternally("file://" + preview.filePath)
            GlobalState.closeAll()
          }
        }
      }
    }
  }
}
