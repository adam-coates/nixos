import QtQuick 6.0
import QtQuick.Layouts 6.0
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications

Scope {
  id: notifScope

  function removeFromPopup(nid) {
    for (var i = 0; i < popupModel.count; i++) {
      if (popupModel.get(i).notifId === nid) {
        popupModel.remove(i)
        break
      }
    }
  }

  NotificationServer {
    id: server
    bodySupported: true
    bodyMarkupSupported: true
    imageSupported: true
    actionsSupported: true
    keepOnReload: true

    onNotification: notification => {
      const nid = notification.id
      popupModel.insert(0, { "notif": notification, "notifId": nid })

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
          required property int index
          required property var notif
          required property int notifId

          Layout.fillWidth: true
          height: cardCol.implicitHeight + 20
          color: Theme.bg
          border.color: Theme.accent
          border.width: 1
          radius: 4

          opacity: 0
          Component.onCompleted: opacity = 1
          Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

          // Auto-dismiss — directly removes from model, no signal dependency
          Timer {
            property int nid: card.notifId
            interval: card.notif.expireTimeout > 0 ? card.notif.expireTimeout : 5000
            running: true
            onTriggered: {
              card.notif.expire()
              notifScope.removeFromPopup(nid)
            }
          }

          ColumnLayout {
            id: cardCol
            anchors { fill: parent; margins: 10 }
            spacing: 6

            RowLayout {
              Layout.fillWidth: true
              spacing: 8

              Image {
                visible: card.notif.appIcon !== ""
                source: card.notif.appIcon !== "" ? Quickshell.iconPath(card.notif.appIcon, true) : ""
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
                  onClicked: {
                    card.notif.dismiss()
                    notifScope.removeFromPopup(card.notifId)
                  }
                }
              }
            }

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

            RowLayout {
              Layout.fillWidth: true
              spacing: 4
              visible: card.notif.actions.length > 0

              Repeater {
                model: card.notif.actions
                delegate: Rectangle {
                  required property var modelData
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
                    onClicked: {
                      parent.modelData.invoke()
                      notifScope.removeFromPopup(card.notifId)
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
