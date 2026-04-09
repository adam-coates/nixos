import QtQuick 6.0
import QtQuick.Layouts 6.0
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
  id: stylinatorPanel

  property bool showing: GlobalState.activePopup === "stylinator"
  property string query: ""

  visible: showing
  onShowingChanged: {
    if (showing) {
      query = ""
      resultsList.currentIndex = 0
      searchInput.forceActiveFocus()
    }
  }

  anchors { top: true; left: true; right: true; bottom: true }
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "quickshell-stylinator"
  WlrLayershell.keyboardFocus: showing ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore
  color: "transparent"

  readonly property string nixPath:
    "export PATH=\"$HOME/.nix-profile/bin:/run/current-system/sw/bin:$HOME/.local/bin:$PATH\"; "

  Process { id: stylinatorProc; running: false }

  readonly property var styleItems: [
    { key: "s",  label: "Stroke (border)",          icon: "󰜡" },
    { key: "a",  label: "Arrow end",                icon: "󰁔" },
    { key: "x",  label: "Arrows both ends",         icon: "󰁍" },
    { key: "d",  label: "Dashed line",              icon: "󱦱" },
    { key: "e",  label: "Dotted line",              icon: "󰇘" },
    { key: "g",  label: "Thick/bold stroke",        icon: "󰜡" },
    { key: "h",  label: "Very thick stroke",        icon: "󰜡" },
    { key: "f",  label: "Semi-transparent fill",    icon: "󰋘" },
    { key: "b",  label: "Solid black fill",         icon: "󰝤" },
    { key: "w",  label: "Solid white fill",         icon: "󰝤" },
    { key: "sa", label: "Stroke + arrow",           icon: "󰁔" },
    { key: "ag", label: "Bold arrow",               icon: "󰁔" },
    { key: "fs", label: "Fill + stroke",            icon: "󰋘" },
    { key: "sg", label: "Bold stroke",              icon: "󰜡" },
    { key: "dg", label: "Bold dashed line",         icon: "󱦱" }
  ]

  readonly property var filtered: {
    const q = query.toLowerCase()
    if (!q) return styleItems
    return styleItems.filter(item =>
      item.key.toLowerCase().includes(q) ||
      item.label.toLowerCase().includes(q)
    )
  }

  onQueryChanged: resultsList.currentIndex = 0

  function applyCurrent() {
    if (resultsList.count === 0) return
    const item = filtered[resultsList.currentIndex]
    if (!item) return
    GlobalState.closeAll()
    stylinatorProc.command = [
      "bash", "-c",
      nixPath + "echo '" + item.key + "' | stylinator | wl-copy -t 'image/x-inkscape-svg'"
    ]
    stylinatorProc.running = false
    stylinatorProc.running = true
  }

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
    id: panelBox
    anchors.centerIn: parent
    width: 360
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
            text: stylinatorPanel.query
            onTextChanged: stylinatorPanel.query = text

            Keys.onEscapePressed: GlobalState.closeAll()
            Keys.onReturnPressed: stylinatorPanel.applyCurrent()
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
              text: "  Search styles..."
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
          values: stylinatorPanel.filtered
        }

        delegate: Rectangle {
          required property int index
          required property var modelData

          width: resultsList.width
          height: 36
          color: resultsList.currentIndex === index ? Theme.accentAlpha(0.2) : "transparent"
          radius: 6

          Behavior on color { ColorAnimation { duration: 80 } }

          RowLayout {
            anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
            spacing: 8

            Text {
              text: modelData.icon
              font.family: Theme.fontFamily
              font.pixelSize: 13
              color: resultsList.currentIndex === index ? Theme.accent : Theme.fg
              Layout.preferredWidth: 20
              horizontalAlignment: Text.AlignHCenter
            }

            Text {
              text: "<b>" + modelData.key + "</b> — " + modelData.label
              font.family: Theme.fontFamily
              font.pixelSize: 12
              color: resultsList.currentIndex === index ? Theme.accent : Theme.fg
              Layout.fillWidth: true
            }
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onEntered: resultsList.currentIndex = index
            onClicked: { resultsList.currentIndex = index; stylinatorPanel.applyCurrent() }
          }
        }
      }
    }
  }
}
