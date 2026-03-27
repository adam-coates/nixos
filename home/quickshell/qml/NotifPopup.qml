pragma ComponentBehavior: Bound
import QtQuick 6.0
import QtQuick.Layouts 6.0
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications

PanelWindow {
  id: root

  required property ObjectModel notifications

  anchors.top: true
  anchors.right: true
  margins { top: 36; right: 10 }

  width: 320
  height: notifColumn.implicitHeight + (notifColumn.implicitHeight > 0 ? 10 : 0)
  visible: notifications.count > 0

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "quickshell-notifications"
  exclusionMode: ExclusionMode.Ignore

  color: "transparent"

  ColumnLayout {
    id: notifColumn
    anchors { top: parent.top; left: parent.left; right: parent.right; margins: 5 }
    spacing: 6

    Repeater {
      model: root.notifications

      Rectangle {
        id: card
        required property Notification modelData

        Layout.fillWidth: true
        height: cardLayout.implicitHeight + 20
        color: Theme.bg
        border.color: Theme.accent
        border.width: 1
        radius: 4

        // Fade in
        opacity: 0
        Component.onCompleted: opacity = 1
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        // Auto-dismiss
        Timer {
          interval: card.modelData.expireTimeout > 0 ? card.modelData.expireTimeout : 5000
          running: true
          onTriggered: card.modelData.expire()
        }

        ColumnLayout {
          id: cardLayout
          anchors { fill: parent; margins: 10 }
          spacing: 6

          // Header row: icon + summary + close
          RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // App icon
            Image {
              source: card.modelData.appIcon
                ? Quickshell.iconPath(card.modelData.appIcon, true)
                : ""
              Layout.preferredWidth: 24
              Layout.preferredHeight: 24
              visible: card.modelData.appIcon !== ""
              fillMode: Image.PreserveAspectFit
            }

            // App name + summary
            ColumnLayout {
              Layout.fillWidth: true
              spacing: 1

              Text {
                Layout.fillWidth: true
                text: card.modelData.appName || ""
                font.family: Theme.fontFamily
                font.pixelSize: 10
                color: Theme.gray
                elide: Text.ElideRight
                visible: card.modelData.appName !== ""
              }

              Text {
                Layout.fillWidth: true
                text: card.modelData.summary || ""
                font.family: Theme.fontFamily
                font.pixelSize: 12
                font.bold: true
                color: Theme.fg
                elide: Text.ElideRight
              }
            }

            // Close button
            Text {
              text: "×"
              font.pixelSize: 18
              color: Theme.gray
              Layout.alignment: Qt.AlignTop

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: card.modelData.dismiss()
              }
            }
          }

          // Body
          Text {
            Layout.fillWidth: true
            text: card.modelData.body || ""
            font.family: Theme.fontFamily
            font.pixelSize: 11
            color: Theme.gray
            wrapMode: Text.WordWrap
            maximumLineCount: 4
            elide: Text.ElideRight
            visible: card.modelData.body !== ""
          }

          // Actions
          RowLayout {
            Layout.fillWidth: true
            spacing: 4
            visible: card.modelData.actions.length > 0

            Repeater {
              model: card.modelData.actions

              Rectangle {
                required property NotificationAction modelData
                Layout.fillWidth: true
                height: 22
                color: Theme.bg1
                radius: 3

                Text {
                  anchors.centerIn: parent
                  text: parent.modelData.text
                  font.family: Theme.fontFamily
                  font.pixelSize: 11
                  color: Theme.accent
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: parent.modelData.invoke()
                }
              }
            }
          }
        }
      }
    }
  }
}
