import QtQuick 6.0
import QtQuick.Layouts 6.0
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

Scope {
  id: lockScope

  property bool locked: false
  property string errorText: ""

  function activate() {
    locked = true
    errorText = ""
    passwordInput.text = ""
  }

  Component.onCompleted: {
    GlobalState.lockRequested.connect(activate)
  }

  function tryUnlock() {
    var password = passwordInput.text
    if (password === "") return

    pamAuth.command = ["bash", "-c",
      "echo '" + password.replace(/'/g, "'\\''") + "' | " +
      "su -c 'exit 0' adam 2>/dev/null"
    ]
    pamAuth.running = true
  }

  Process {
    id: pamAuth
    onExited: (code) => {
      if (code === 0) {
        locked = false
        passwordInput.text = ""
        errorText = ""
      } else {
        errorText = "Authentication failed"
        passwordInput.text = ""
        passwordInput.forceActiveFocus()
      }
    }
  }

  // Lock surface per screen
  Variants {
    model: locked ? Quickshell.screens : []
    delegate: Component {
      PanelWindow {
        property var screen: modelData

        anchors {
          top: true
          bottom: true
          left: true
          right: true
        }

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-lockscreen"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        exclusionMode: ExclusionMode.Ignore

        color: Theme.bg

        // Centered password field
        ColumnLayout {
          anchors.centerIn: parent
          spacing: 20

          // Lock icon
          Text {
            Layout.alignment: Qt.AlignHCenter
            text: "\u{f033e}" // 󰌾
            font.family: Theme.fontFamily
            font.pixelSize: 48
            color: Theme.accent
          }

          // Password input container
          Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 650
            height: 100
            color: Theme.bgAlpha(0.8)
            border.color: Theme.accent
            border.width: 4
            radius: 0

            TextInput {
              id: passwordInput
              anchors {
                fill: parent
                margins: 20
              }
              verticalAlignment: TextInput.AlignVCenter
              horizontalAlignment: TextInput.AlignHCenter
              font.family: Theme.fontFamily
              font.pixelSize: 18
              color: Theme.fg
              echoMode: TextInput.Password
              passwordCharacter: "\u{2022}" // bullet
              focus: true
              clip: true

              onAccepted: lockScope.tryUnlock()

              Keys.onEscapePressed: {} // prevent escape from doing anything

              Text {
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                text: "Enter Password"
                font.family: Theme.fontFamily
                font.pixelSize: 18
                color: Theme.gray
                visible: passwordInput.text === ""
              }
            }
          }

          // Error message
          Text {
            Layout.alignment: Qt.AlignHCenter
            text: errorText
            font.family: Theme.fontFamily
            font.pixelSize: 14
            font.italic: true
            color: Theme.red
            visible: errorText !== ""
          }
        }

        Component.onCompleted: {
          passwordInput.forceActiveFocus()
        }
      }
    }
  }
}
