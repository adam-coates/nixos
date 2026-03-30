import QtQuick 6.0
import QtQuick.Layouts 6.0
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications

Scope {
  id: notifScope

  NotificationServer {
    id: server
    bodySupported: true
    bodyMarkupSupported: true
    imageSupported: true
    actionsSupported: true
    keepOnReload: true

    onNotification: notification => {
      popupModel.insert(0, {
        "appName":       notification.appName  || "",
        "appIcon":       notification.appIcon  || "",
        "summary":       notification.summary  || "",
        "body":          notification.body     || "",
        "expireTimeout": notification.expireTimeout
      })

      NotifState.addToHistory(
        notification.appName,
        notification.appIcon,
        notification.summary,
        notification.body
      )
    }
  }

  ListModel { id: popupModel }

  PanelWindow {
    anchors.top: true
    anchors.right: true
    margins { top: 36; right: 10 }
    width: 320
    height: notifColumn.implicitHeight > 0 ? notifColumn.implicitHeight + 10 : 1
    visible: popupModel.count > 0

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-notifications"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    ColumnLayout {
      id: notifColumn
      anchors { top: parent.top; left: parent.left; right: parent.right; margins: 5 }
      spacing: 6

      Repeater {
        model: popupModel

        delegate: Rectangle {
          id: card

          required property int    index
          required property string appName
          required property string appIcon
          required property string summary
          required property string body
          required property int    expireTimeout

          Layout.fillWidth: true
          height: cardCol.implicitHeight + 20
          color: Theme.bg
          border.color: Theme.accent
          border.width: 1
          radius: 4

          opacity: 0
          Component.onCompleted: opacity = 1
          Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

          // card.index is kept current by QML as other items are removed
          Timer {
            interval: card.expireTimeout > 0 ? card.expireTimeout : 3000
            running: true
            onTriggered: popupModel.remove(card.index)
          }

          ColumnLayout {
            id: cardCol
            anchors { fill: parent; margins: 10 }
            spacing: 6

            RowLayout {
              Layout.fillWidth: true
              spacing: 8

              Image {
                visible: card.appIcon !== ""
                source: card.appIcon !== "" ? Quickshell.iconPath(card.appIcon, true) : ""
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                fillMode: Image.PreserveAspectFit
              }

              ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                  Layout.fillWidth: true
                  visible: card.appName !== ""
                  text: card.appName
                  font.family: Theme.fontFamily
                  font.pixelSize: 10
                  color: Theme.gray
                  elide: Text.ElideRight
                }

                Text {
                  Layout.fillWidth: true
                  text: card.summary
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
                  onClicked: popupModel.remove(card.index)
                }
              }
            }

            Text {
              Layout.fillWidth: true
              visible: card.body !== ""
              text: card.body
              font.family: Theme.fontFamily
              font.pixelSize: 11
              color: Theme.gray
              wrapMode: Text.WordWrap
              maximumLineCount: 4
              elide: Text.ElideRight
            }
          }
        }
      }
    }
  }
}
