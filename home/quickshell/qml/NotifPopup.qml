import QtQuick 6.0
import QtQuick.Layouts 6.0
import Quickshell
import Quickshell.Wayland

PanelWindow {
  id: popup

  property var screen
  property var notifications

  anchors {
    top: true
    right: true
  }

  margins {
    top: 36 // below bar
    right: 10
  }

  width: 310
  height: notifColumn.implicitHeight + 10
  visible: notifications.count > 0

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "quickshell-notifications"
  exclusionMode: ExclusionMode.Ignore

  color: "transparent"

  ColumnLayout {
    id: notifColumn
    anchors {
      top: parent.top
      left: parent.left
      right: parent.right
      margins: 5
    }
    spacing: 5

    Repeater {
      model: notifications

      Rectangle {
        id: notifCard
        Layout.fillWidth: true
        Layout.preferredHeight: notifContent.implicitHeight + 20
        color: Theme.bg
        border.color: Theme.accent
        border.width: 1
        radius: 0

        property var notif: modelData

        RowLayout {
          id: notifContent
          anchors {
            fill: parent
            margins: 10
          }
          spacing: 10

          // App icon
          Image {
            source: notif.appIcon || ""
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            visible: source !== ""
            fillMode: Image.PreserveAspectFit
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
              Layout.fillWidth: true
              text: notif.summary || ""
              font.family: Theme.fontFamily
              font.pixelSize: 12
              font.bold: true
              color: Theme.fg
              elide: Text.ElideRight
            }

            Text {
              Layout.fillWidth: true
              text: notif.body || ""
              font.family: Theme.fontFamily
              font.pixelSize: 11
              color: Theme.gray
              wrapMode: Text.WordWrap
              maximumLineCount: 3
              elide: Text.ElideRight
            }
          }

          // Close button
          Text {
            text: "\u{00d7}" // ×
            font.pixelSize: 16
            color: Theme.gray
            Layout.alignment: Qt.AlignTop

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: notif.dismiss()
            }
          }
        }

        // Actions row
        RowLayout {
          visible: notif.actions.length > 0
          anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
            margins: 5
          }
          spacing: 4

          Repeater {
            model: notif.actions

            Rectangle {
              Layout.fillWidth: true
              Layout.preferredHeight: 24
              color: Theme.bg1
              radius: 2

              Text {
                anchors.centerIn: parent
                text: modelData.text
                font.family: Theme.fontFamily
                font.pixelSize: 11
                color: Theme.accent
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: modelData.invoke()
              }
            }
          }
        }

        // Auto-dismiss timer
        Timer {
          interval: notif.expireTimeout > 0 ? notif.expireTimeout : 5000
          running: true
          onTriggered: notif.expire()
        }

        // Fade in
        opacity: 0
        Component.onCompleted: opacity = 1
        Behavior on opacity {
          NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
      }
    }
  }
}
