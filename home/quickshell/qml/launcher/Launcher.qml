import QtQuick 6.0
import QtQuick.Layouts 6.0
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
  id: launcher

  property bool showing: GlobalState.activePopup === "launcher"

  visible: showing
  onShowingChanged: {
    if (showing) {
      searchInput.text = ""
      searchInput.forceActiveFocus()
      updateResults()
    }
  }

  anchors {
    top: true
    left: true
    right: true
    bottom: true
  }

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "quickshell-launcher"
  WlrLayershell.keyboardFocus: showing ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore

  color: Qt.rgba(0, 0, 0, 0.3)

  // Click backdrop to close
  MouseArea {
    anchors.fill: parent
    onClicked: GlobalState.closeAll()
  }

  // Centered launcher box
  Rectangle {
    anchors.centerIn: parent
    width: 600
    height: 400
    color: Theme.bgAlpha(0.97)
    border.color: Theme.accent
    border.width: 1
    radius: 12

    // Prevent click-through to backdrop
    MouseArea { anchors.fill: parent }

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 20
      spacing: 10

      // Search bar
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 40
        color: Theme.bg1
        radius: 6

        TextInput {
          id: searchInput
          anchors {
            fill: parent
            leftMargin: 10
            rightMargin: 10
          }
          verticalAlignment: TextInput.AlignVCenter
          font.family: Theme.fontFamily
          font.pixelSize: 14
          color: Theme.fg
          clip: true

          onTextChanged: updateResults()

          Keys.onEscapePressed: GlobalState.closeAll()
          Keys.onReturnPressed: {
            if (resultsList.count > 0) {
              launchApp(resultsModel.get(resultsList.currentIndex).exec)
            }
          }
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
            text: " Search..."
            font.family: Theme.fontFamily
            font.pixelSize: 14
            color: Theme.gray
            visible: searchInput.text === ""
          }
        }
      }

      // Results list
      ListView {
        id: resultsList
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        model: resultsModel
        currentIndex: 0
        spacing: 2

        delegate: Rectangle {
          width: resultsList.width
          height: 40
          color: ListView.isCurrentItem ? Theme.accentAlpha(0.2) : "transparent"
          radius: 6

          RowLayout {
            anchors {
              fill: parent
              leftMargin: 14
              rightMargin: 14
            }
            spacing: 10

            Image {
              source: model.icon ? ("image://icon/" + model.icon) : ""
              Layout.preferredWidth: 24
              Layout.preferredHeight: 24
              visible: source !== ""
            }

            Text {
              Layout.fillWidth: true
              text: model.name
              font.family: Theme.fontFamily
              font.pixelSize: 13
              color: ListView.isCurrentItem ? Theme.accent : Theme.fg
              elide: Text.ElideRight
            }
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: launchApp(model.exec)
            hoverEnabled: true
            onEntered: resultsList.currentIndex = index
          }
        }
      }
    }
  }

  ListModel {
    id: resultsModel
  }

  // Desktop entry scanner
  property var allApps: []

  Process {
    id: appScanner
    command: ["bash", "-c",
      "find /run/current-system/sw/share/applications " +
      "$HOME/.local/share/applications " +
      "$HOME/.nix-profile/share/applications " +
      "/usr/share/applications " +
      "-name '*.desktop' -type f 2>/dev/null | sort -u"
    ]
    onExited: {
      var files = stdout.trim().split("\n")
      allApps = []
      for (var i = 0; i < files.length; i++) {
        if (files[i]) parseDesktop.parseFile(files[i])
      }
    }
  }

  // Parse .desktop files
  QtObject {
    id: parseDesktop
    function parseFile(path) {
      var reader = Qt.createQmlObject(
        'import Quickshell.Io; FileView { path: "' + path + '" }',
        launcher)
      var text = reader.text()
      reader.destroy()

      var name = "", exec = "", icon = "", noDisplay = false
      var lines = text.split("\n")
      var inEntry = false
      for (var i = 0; i < lines.length; i++) {
        var line = lines[i].trim()
        if (line === "[Desktop Entry]") { inEntry = true; continue }
        if (line.startsWith("[") && inEntry) break
        if (!inEntry) continue

        if (line.startsWith("Name=")) name = line.substring(5)
        else if (line.startsWith("Exec=")) exec = line.substring(5).replace(/%[fFuUdDnNickvm]/g, "").trim()
        else if (line.startsWith("Icon=")) icon = line.substring(5)
        else if (line.startsWith("NoDisplay=true")) noDisplay = true
      }

      if (name && exec && !noDisplay) {
        allApps.push({ name: name, exec: exec, icon: icon })
      }
    }
  }

  function updateResults() {
    resultsModel.clear()
    var query = searchInput.text.toLowerCase()
    var matches = []

    for (var i = 0; i < allApps.length; i++) {
      var app = allApps[i]
      if (!query || app.name.toLowerCase().indexOf(query) >= 0) {
        matches.push(app)
      }
    }

    // Sort: exact prefix matches first, then alphabetical
    matches.sort(function(a, b) {
      var aStart = a.name.toLowerCase().startsWith(query)
      var bStart = b.name.toLowerCase().startsWith(query)
      if (aStart && !bStart) return -1
      if (!aStart && bStart) return 1
      return a.name.localeCompare(b.name)
    })

    for (var j = 0; j < Math.min(matches.length, 20); j++) {
      resultsModel.append(matches[j])
    }
    resultsList.currentIndex = 0
  }

  function launchApp(exec) {
    GlobalState.closeAll()
    launchProc.command = ["bash", "-c", exec + " &"]
    launchProc.running = true
  }

  Process {
    id: launchProc
  }

  Component.onCompleted: appScanner.running = true
}
