import QtQuick 6.0
import QtQuick.Layouts 6.0
import Quickshell
import Quickshell.Wayland

PanelWindow {
  id: launcher

  property bool showing: GlobalState.activePopup === "launcher"
  property string query: ""

  visible: showing
  onShowingChanged: {
    if (showing) {
      query = ""
      searchInput.forceActiveFocus()
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

  MouseArea {
    anchors.fill: parent
    onClicked: GlobalState.closeAll()
  }

  Rectangle {
    anchors.centerIn: parent
    width: 600
    height: 420
    color: Theme.bgAlpha(0.97)
    border.color: Theme.accent
    border.width: 1
    radius: 12

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
          anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
          verticalAlignment: TextInput.AlignVCenter
          font.family: Theme.fontFamily
          font.pixelSize: 14
          color: Theme.fg
          clip: true
          text: launcher.query
          onTextChanged: {
            launcher.query = text
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
            text: " Search..."
            font.family: Theme.fontFamily
            font.pixelSize: 14
            color: Theme.gray
            visible: searchInput.text === ""
          }
        }
      }

      // Results list — filtered directly from DesktopEntries
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
            const q = launcher.query.trim().toLowerCase()
            const all = [...DesktopEntries.applications.values].filter(e =>
              e.name && e.noDisplay !== true
            )
            const filtered = q === ""
              ? all
              : all.filter(e => e.name.toLowerCase().includes(q))
            filtered.sort((a, b) => {
              if (q) {
                const as = a.name.toLowerCase().startsWith(q)
                const bs = b.name.toLowerCase().startsWith(q)
                if (as && !bs) return -1
                if (!as && bs) return 1
              }
              return a.name.localeCompare(b.name)
            })
            return filtered
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

            Image {
              source: modelData.icon ? Quickshell.iconPath(modelData.icon, true) : ""
              Layout.preferredWidth: 24
              Layout.preferredHeight: 24
              visible: modelData.icon !== ""
            }

            Text {
              Layout.fillWidth: true
              text: modelData.name
              font.family: Theme.fontFamily
              font.pixelSize: 13
              color: resultsList.currentIndex === parent.parent.index ? Theme.accent : Theme.fg
              elide: Text.ElideRight
            }
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onEntered: resultsList.currentIndex = index
            onClicked: {
              resultsList.currentIndex = index
              launchCurrent()
            }
          }
        }
      }
    }
  }

  function launchCurrent() {
    if (resultsList.currentIndex < 0 || resultsList.count === 0) return
    const entry = resultsList.model.values[resultsList.currentIndex]
    if (entry) {
      GlobalState.closeAll()
      entry.execute()
    }
  }
}
