import QtQuick 6.0
import QtQuick.Layouts 6.0
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications

Scope {
  id: notifScope

  // Strong JS references to notification objects keyed by id
  property var notifMap: ({})

  function removeFromPopup(nid) {
    const n = notifMap[nid]
    if (n) {
      n.expire()
      delete notifMap[nid]
    }
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
      notifScope.notifMap[nid] = notification

      // Store only primitives — QObjects in ListModel are unreliable
      popupModel.insert(0, {
        "notifId":       nid,
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

          // All display data comes from typed model roles — no QObject needed
          required property int    index
          required property var    notifId
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

          // Auto-dismiss: capture id locally so the timer closure is self-contained
          Timer {
            property var nid: card.notifId
            interval: card.expireTimeout > 0 ? card.expireTimeout : 5000
            running: true
            onTriggered: notifScope.removeFromPopup(nid)
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
                  onClicked: notifScope.removeFromPopup(card.notifId)
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

            // Actions — look up the live object only here, evaluated once at creation
            Repeater {
              model: {
                const n = notifScope.notifMap[card.notifId]
                return n ? n.actions : null
              }
              delegate: Rectangle {
                required property var modelData
                Layout.fillWidth: true
                height: 22
                color: Theme.bg1
                radius: 3
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
                  onClicked: {
                    modelData.invoke()
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
