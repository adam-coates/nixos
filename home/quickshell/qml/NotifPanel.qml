import QtQuick 6.0
import QtQuick.Layouts 6.0
import Quickshell
import Quickshell.Wayland

PanelWindow {
  id: root

  property bool showing: GlobalState.activePopup === "notifications"

  visible: showing
  onShowingChanged: { if (showing) NotifState.markRead() }

  anchors.top: true
  anchors.right: true
  margins { top: 30; right: 4 }

  width: 340
  height: Math.min(panelCol.implicitHeight + 16, 480)

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "quickshell-notif-panel"
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore

  color: "transparent"

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

      // Header row
      RowLayout {
        Layout.fillWidth: true

        Text {
          text: "Notifications"
          font.family: Theme.fontFamily
          font.pixelSize: 13
          font.bold: true
          color: Theme.fg
        }

        Item { Layout.fillWidth: true }

        Text {
          text: "Clear all"
          font.family: Theme.fontFamily
          font.pixelSize: 11
          color: Theme.accent
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: NotifState.clearHistory()
          }
        }
      }

      // Empty state
      Text {
        Layout.fillWidth: true
        visible: NotifState.historyModel.count === 0
        text: "No notifications"
        font.family: Theme.fontFamily
        font.pixelSize: 12
        color: Theme.gray
        horizontalAlignment: Text.AlignHCenter
        topPadding: 8
        bottomPadding: 8
      }

      // History list
      ListView {
        id: historyList
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, 420)
        clip: true
        spacing: 4
        model: NotifState.historyModel

        delegate: Rectangle {
          width: historyList.width
          height: itemCol.implicitHeight + 16
          color: Theme.bg1
          radius: 4

          ColumnLayout {
            id: itemCol
            anchors { fill: parent; margins: 8 }
            spacing: 3

            RowLayout {
              Layout.fillWidth: true
              spacing: 6

              Image {
                visible: appIcon !== ""
                source: appIcon !== "" ? Quickshell.iconPath(appIcon, true) : ""
                Layout.preferredWidth: 18
                Layout.preferredHeight: 18
                fillMode: Image.PreserveAspectFit
              }

              Text {
                Layout.fillWidth: true
                text: appName || ""
                visible: appName !== ""
                font.family: Theme.fontFamily
                font.pixelSize: 10
                color: Theme.gray
                elide: Text.ElideRight
              }

              Text {
                text: time || ""
                font.family: Theme.fontFamily
                font.pixelSize: 10
                color: Theme.gray
              }
            }

            Text {
              Layout.fillWidth: true
              text: summary || ""
              font.family: Theme.fontFamily
              font.pixelSize: 12
              font.bold: true
              color: Theme.fg
              elide: Text.ElideRight
              visible: summary !== ""
            }

            Text {
              Layout.fillWidth: true
              text: body || ""
              visible: body !== ""
              font.family: Theme.fontFamily
              font.pixelSize: 11
              color: Theme.gray
              wrapMode: Text.WordWrap
              maximumLineCount: 3
              elide: Text.ElideRight
            }
          }
        }
      }
    }
  }
}
