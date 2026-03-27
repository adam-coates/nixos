import QtQuick 6.0
import QtQuick.Layouts 6.0
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications

PanelWindow {
  id: root

  property var screen
  property var notifications

  anchors.top: true
  anchors.right: true
  margins { top: 36; right: 10 }

  width: 320
  // Always occupy space; height collapses to 0 when empty
  height: notifColumn.implicitHeight > 0 ? notifColumn.implicitHeight + 10 : 0
  visible: height > 0

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

      delegate: Rectangle {
        id: card
        property var notif: modelData

        Layout.fillWidth: true
        height: innerLayout.implicitHeight + 20
        color: Theme.bg
        border.color: Theme.accent
        border.width: 1
        radius: 4

        opacity: 0
        Component.onCompleted: opacity = 1
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        Timer {
          interval: card.notif.expireTimeout > 0 ? card.notif.expireTimeout : 5000
          running: true
          onTriggered: card.notif.expire()
        }

        ColumnLayout {
          id: innerLayout
          anchors { fill: parent; margins: 10 }
          spacing: 6

          // Header: icon + text + close
          RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Image {
              visible: card.notif.appIcon !== ""
              source: card.notif.appIcon !== ""
                ? Quickshell.iconPath(card.notif.appIcon, true)
                : ""
              Layout.preferredWidth: 24
              Layout.preferredHeight: 24
              fillMode: Image.PreserveAspectFit
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 1

              Text {
                Layout.fillWidth: true
                visible: card.notif.appName !== ""
                text: card.notif.appName || ""
                font.family: Theme.fontFamily
                font.pixelSize: 10
                color: Theme.gray
                elide: Text.ElideRight
              }

              Text {
                Layout.fillWidth: true
                text: card.notif.summary || ""
                font.family: Theme.fontFamily
                font.pixelSize: 12
                font.bold: true
                color: Theme.fg
                elide: Text.ElideRight
              }
            }

            Text {
              text: "×"
              font.pixelSize: 18
              color: Theme.gray
              Layout.alignment: Qt.AlignTop
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: card.notif.dismiss()
              }
            }
          }

          // Body
          Text {
            Layout.fillWidth: true
            visible: card.notif.body !== ""
            text: card.notif.body || ""
            font.family: Theme.fontFamily
            font.pixelSize: 11
            color: Theme.gray
            wrapMode: Text.WordWrap
            maximumLineCount: 4
            elide: Text.ElideRight
          }

          // Actions
          RowLayout {
            Layout.fillWidth: true
            visible: card.notif.actions.length > 0
            spacing: 4

            Repeater {
              model: card.notif.actions
              delegate: Rectangle {
                property var action: modelData
                Layout.fillWidth: true
                height: 22
                color: Theme.bg1
                radius: 3

                Text {
                  anchors.centerIn: parent
                  text: action.text
                  font.family: Theme.fontFamily
                  font.pixelSize: 11
                  color: Theme.accent
                }
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: action.invoke()
                }
              }
            }
          }
        }
      }
    }
  }
}
