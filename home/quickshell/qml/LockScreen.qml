import QtQuick 6.0
import QtQuick.Layouts 6.0
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam

Scope {
  id: lockScope

  property bool locked: false
  property string errorText: ""
  property bool authenticating: false

  function activate() {
    locked = true
    errorText = ""
    authenticating = false
  }

  Component.onCompleted: {
    GlobalState.lockRequested.connect(activate)
  }

  function tryUnlock(password) {
    if (password === "" || authenticating) return
    authenticating = true
    errorText = ""
    pam.start()
  }

  signal authFinished(bool success)

  PamContext {
    id: pam
    configDirectory: "/etc/pam.d"
    config: "quickshell"
    user: Quickshell.env("USER")

    onPamMessage: (message, isError, responseRequired) => {
      if (responseRequired) {
        // PAM is asking for the password
        pam.respond(inputBuffer)
      }
    }

    onCompleted: result => {
      lockScope.authenticating = false
      if (result === PamResult.Success) {
        lockScope.locked = false
        lockScope.errorText = ""
        lockScope.authFinished(true)
      } else {
        lockScope.errorText = "Authentication failed"
        lockScope.authFinished(false)
      }
      inputBuffer = ""
    }

    onError: (error, message) => {
      lockScope.authenticating = false
      lockScope.errorText = message || "Authentication error"
      lockScope.authFinished(false)
      inputBuffer = ""
    }
  }

  // Temporary storage for the password so PamContext can access it
  property string inputBuffer: ""

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

        Connections {
          target: lockScope
          function onAuthFinished(success) {
            passwordInput.text = ""
            if (!success) passwordInput.forceActiveFocus()
          }
        }

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
            border.color: lockScope.authenticating ? Theme.gray : Theme.accent
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
              passwordCharacter: "\u{2022}"
              focus: true
              clip: true
              enabled: !lockScope.authenticating

              onAccepted: {
                lockScope.inputBuffer = text
                lockScope.tryUnlock(text)
              }

              Keys.onEscapePressed: {}

              Text {
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                text: lockScope.authenticating ? "Authenticating..." : "Enter Password"
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
            text: lockScope.errorText
            font.family: Theme.fontFamily
            font.pixelSize: 14
            font.italic: true
            color: Theme.red
            visible: lockScope.errorText !== ""
          }
        }

        Component.onCompleted: {
          passwordInput.forceActiveFocus()
        }
      }
    }
  }
}
