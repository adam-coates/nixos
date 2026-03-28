import QtQuick 6.0
import QtQuick.Layouts 6.0
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
  id: netPanel

  property bool showing: GlobalState.activePopup === "network"
  visible: showing

  anchors.top: true
  anchors.right: true
  margins { top: 30; right: 4 }
  width: 320
  height: Math.min(panelFlick.contentHeight + 24, 520)

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "quickshell-network"
  WlrLayershell.keyboardFocus: showing ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore
  color: "transparent"

  // State
  property bool wifiEnabled: true
  property string currentSsid: ""
  property string ethernetStatus: ""
  property var networkList: []     // [{ssid, signal, security, active, saved}]
  property var vpnList: []         // [{name, active}]

  // Password input state
  property string connectingSsid: ""
  property string connectError: ""

  onShowingChanged: {
    if (showing) {
      connectingSsid = ""
      connectError = ""
      passwordInput.text = ""
      refreshAll()
    }
  }

  function refreshAll() {
    wifiStatusProc._output = ""
    wifiStatusProc.running = false
    wifiStatusProc.running = true
    scanProc._lines = []
    scanProc.running = false
    scanProc.running = true
    savedProc._lines = []
    savedProc.running = false
    savedProc.running = true
    vpnProc._lines = []
    vpnProc.running = false
    vpnProc.running = true
    ethProc._lines = []
    ethProc.running = false
    ethProc.running = true
  }

  Timer {
    interval: 8000
    running: netPanel.showing
    repeat: true
    onTriggered: netPanel.refreshAll()
  }

  // WiFi status
  Process {
    id: wifiStatusProc
    command: ["nmcli", "radio", "wifi"]
    property string _output: ""
    stdout: SplitParser { onRead: line => wifiStatusProc._output += line }
    onExited: {
      netPanel.wifiEnabled = wifiStatusProc._output.trim() === "enabled"
      wifiStatusProc._output = ""
    }
  }

  // WiFi scan
  Process {
    id: scanProc
    command: ["nmcli", "-t", "-f", "ACTIVE,SSID,SIGNAL,SECURITY", "dev", "wifi", "list", "--rescan", "auto"]
    property var _lines: []
    stdout: SplitParser { onRead: line => scanProc._lines.push(line) }
    onExited: {
      var nets = []
      netPanel.currentSsid = ""
      var seen = {}
      for (var i = 0; i < scanProc._lines.length; i++) {
        var parts = scanProc._lines[i].split(":")
        if (parts.length >= 4 && parts[1] && !seen[parts[1]]) {
          seen[parts[1]] = true
          var isActive = parts[0] === "yes"
          if (isActive) netPanel.currentSsid = parts[1]
          nets.push({
            ssid: parts[1],
            signal: parseInt(parts[2]) || 0,
            security: parts[3] || "",
            active: isActive,
            saved: false  // updated below
          })
        }
      }
      netPanel.networkList = nets
      scanProc._lines = []
    }
  }

  // Saved connections (to identify known networks)
  Process {
    id: savedProc
    command: ["nmcli", "-t", "-f", "NAME", "connection", "show"]
    property var _lines: []
    stdout: SplitParser { onRead: line => savedProc._lines.push(line) }
    onExited: {
      var savedNames = {}
      for (var i = 0; i < savedProc._lines.length; i++) {
        var name = savedProc._lines[i].trim()
        if (name) savedNames[name] = true
      }
      // Update network list with saved status
      var nets = netPanel.networkList
      for (var j = 0; j < nets.length; j++) {
        nets[j].saved = savedNames[nets[j].ssid] || false
      }
      netPanel.networkList = nets
      savedProc._lines = []
    }
  }

  // VPN connections
  Process {
    id: vpnProc
    command: ["nmcli", "-t", "-f", "NAME,TYPE,ACTIVE", "connection", "show"]
    property var _lines: []
    stdout: SplitParser { onRead: line => vpnProc._lines.push(line) }
    onExited: {
      var vpns = []
      for (var i = 0; i < vpnProc._lines.length; i++) {
        var parts = vpnProc._lines[i].split(":")
        if (parts.length >= 3 && (parts[1].indexOf("vpn") >= 0 || parts[1].indexOf("wireguard") >= 0)) {
          vpns.push({ name: parts[0], active: parts[2] === "yes" })
        }
      }
      netPanel.vpnList = vpns
      vpnProc._lines = []
    }
  }

  // Ethernet status
  Process {
    id: ethProc
    command: ["nmcli", "-t", "-f", "TYPE,STATE", "device"]
    property var _lines: []
    stdout: SplitParser { onRead: line => ethProc._lines.push(line) }
    onExited: {
      netPanel.ethernetStatus = ""
      for (var i = 0; i < ethProc._lines.length; i++) {
        if (ethProc._lines[i].startsWith("ethernet:")) {
          var state = ethProc._lines[i].split(":")[1] || ""
          netPanel.ethernetStatus = state.indexOf("connected") >= 0 ? "Connected" : "Disconnected"
          break
        }
      }
      ethProc._lines = []
    }
  }

  // WiFi toggle
  Process {
    id: wifiToggleProc
    command: ["nmcli", "radio", "wifi", wifiEnabled ? "off" : "on"]
    onExited: {
      netPanel.wifiEnabled = !netPanel.wifiEnabled
      if (netPanel.wifiEnabled) netPanel.refreshAll()
    }
  }

  // Connect to saved network
  Process {
    id: connectProc
    onExited: (code) => {
      if (code !== 0) netPanel.connectError = "Connection failed"
      else netPanel.connectingSsid = ""
      netPanel.refreshAll()
    }
  }

  // Connect with password
  Process {
    id: connectPwProc
    onExited: (code) => {
      if (code !== 0) netPanel.connectError = "Wrong password or connection failed"
      else { netPanel.connectingSsid = ""; netPanel.connectError = "" }
      netPanel.refreshAll()
    }
  }

  // VPN toggle
  Process { id: vpnToggleProc; onExited: netPanel.refreshAll() }

  function connectToNetwork(ssid, saved) {
    if (saved) {
      connectProc.command = ["nmcli", "connection", "up", ssid]
      connectProc.running = false
      connectProc.running = true
    } else {
      connectingSsid = ssid
      connectError = ""
      passwordInput.text = ""
      passwordInput.forceActiveFocus()
    }
  }

  function connectWithPassword() {
    var pass = passwordInput.text
    if (!pass || !connectingSsid) return
    connectPwProc.command = ["nmcli", "device", "wifi", "connect", connectingSsid, "password", pass]
    connectPwProc.running = false
    connectPwProc.running = true
  }

  // --- UI ---
  Rectangle {
    anchors.fill: parent
    color: Theme.bgAlpha(0.97)
    border.color: Theme.accent
    border.width: 1
    radius: 6

    opacity: netPanel.showing ? 1 : 0
    scale: netPanel.showing ? 1 : 0.96
    transformOrigin: Item.TopRight
    Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

    Flickable {
      id: panelFlick
      anchors.fill: parent
      anchors.margins: 12
      contentHeight: content.implicitHeight
      clip: true

      ColumnLayout {
        id: content
        width: parent.width
        spacing: 10

        // Header
        RowLayout {
          Layout.fillWidth: true

          Text {
            text: "Network"
            font.family: Theme.fontFamily
            font.pixelSize: 13
            font.bold: true
            color: Theme.fg
          }

          Item { Layout.fillWidth: true }

          Text {
            text: "WiFi"
            font.family: Theme.fontFamily
            font.pixelSize: 11
            color: Theme.fg
          }

          Rectangle {
            width: 36; height: 18; radius: 9
            color: netPanel.wifiEnabled ? Theme.accent : Theme.bg2

            Rectangle {
              x: netPanel.wifiEnabled ? parent.width - width - 2 : 2
              y: 2; width: 14; height: 14; radius: 7
              color: Theme.fg
              Behavior on x { NumberAnimation { duration: 150 } }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: { wifiToggleProc.running = false; wifiToggleProc.running = true }
            }
          }
        }

        // ── Current Connection ──
        Rectangle {
          Layout.fillWidth: true
          height: 32; radius: 4
          color: Theme.accentAlpha(0.1)
          visible: netPanel.currentSsid !== ""

          RowLayout {
            anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
            spacing: 6

            Text {
              text: "\u{f05a9}" // 󰖩 wifi
              font.family: Theme.fontFamily
              font.pixelSize: 14
              color: Theme.accent
            }

            Text {
              text: netPanel.currentSsid
              font.family: Theme.fontFamily
              font.pixelSize: 12
              color: Theme.accent
              Layout.fillWidth: true
              elide: Text.ElideRight
            }

            Text {
              text: "Connected"
              font.family: Theme.fontFamily
              font.pixelSize: 10
              color: Theme.gray
            }
          }
        }

        // ── Available Networks ──
        Text {
          text: "Available Networks"
          font.family: Theme.fontFamily
          font.pixelSize: 11
          color: Theme.gray
          visible: netPanel.wifiEnabled
        }

        Repeater {
          model: netPanel.wifiEnabled ? netPanel.networkList : []

          Rectangle {
            required property var modelData
            Layout.fillWidth: true
            height: modelData.active ? 0 : 32
            visible: !modelData.active
            radius: 4
            color: netHover.containsMouse ? Theme.accentAlpha(0.1) : "transparent"

            RowLayout {
              anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
              spacing: 6

              Text {
                text: modelData.security ? "\u{f0924}" : "\u{f05a9}" // 󰤤 locked / 󰖩 open
                font.family: Theme.fontFamily
                font.pixelSize: 14
                color: Theme.fg
              }

              Text {
                text: modelData.ssid
                font.family: Theme.fontFamily
                font.pixelSize: 11
                color: Theme.fg
                Layout.fillWidth: true
                elide: Text.ElideRight
              }

              Text {
                text: modelData.signal + "%"
                font.family: Theme.fontFamily
                font.pixelSize: 10
                color: Theme.gray
              }

              Text {
                visible: modelData.saved
                text: "Saved"
                font.family: Theme.fontFamily
                font.pixelSize: 9
                color: Theme.gray
              }
            }

            HoverHandler { id: netHover }
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: netPanel.connectToNetwork(modelData.ssid, modelData.saved)
            }
          }
        }

        // ── Password Input ──
        Rectangle {
          Layout.fillWidth: true
          visible: netPanel.connectingSsid !== ""
          height: visible ? pwCol.implicitHeight + 16 : 0
          color: Theme.bg1
          radius: 4

          ColumnLayout {
            id: pwCol
            anchors { fill: parent; margins: 8 }
            spacing: 6

            Text {
              text: "Connect to " + netPanel.connectingSsid
              font.family: Theme.fontFamily
              font.pixelSize: 11
              color: Theme.fg
            }

            RowLayout {
              Layout.fillWidth: true
              spacing: 6

              Rectangle {
                Layout.fillWidth: true
                height: 28; radius: 4
                color: Theme.bg2

                TextInput {
                  id: passwordInput
                  anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                  verticalAlignment: TextInput.AlignVCenter
                  font.family: Theme.fontFamily
                  font.pixelSize: 12
                  color: Theme.fg
                  echoMode: TextInput.Password
                  clip: true

                  Keys.onReturnPressed: netPanel.connectWithPassword()
                  Keys.onEscapePressed: netPanel.connectingSsid = ""

                  Text {
                    anchors.fill: parent
                    verticalAlignment: Text.AlignVCenter
                    text: "Password"
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    color: Theme.gray
                    visible: passwordInput.text === ""
                  }
                }
              }

              Rectangle {
                width: connLabel.implicitWidth + 16
                height: 28; radius: 4
                color: Theme.accentAlpha(0.2)

                Text {
                  id: connLabel
                  anchors.centerIn: parent
                  text: "Connect"
                  font.family: Theme.fontFamily
                  font.pixelSize: 11
                  color: Theme.accent
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: netPanel.connectWithPassword()
                }
              }
            }

            Text {
              visible: netPanel.connectError !== ""
              text: netPanel.connectError
              font.family: Theme.fontFamily
              font.pixelSize: 10
              color: Theme.red
            }
          }
        }

        // ── VPN ──
        Rectangle {
          Layout.fillWidth: true; height: 1; color: Theme.accentAlpha(0.3)
          visible: netPanel.vpnList.length > 0
        }

        Text {
          text: "VPN"
          font.family: Theme.fontFamily
          font.pixelSize: 11
          color: Theme.gray
          visible: netPanel.vpnList.length > 0
        }

        Repeater {
          model: netPanel.vpnList

          Rectangle {
            required property var modelData
            Layout.fillWidth: true
            height: 32; radius: 4
            color: modelData.active ? Theme.accentAlpha(0.1) : "transparent"

            RowLayout {
              anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
              spacing: 6

              Text {
                text: "\u{f0582}" // 󰖂 vpn/shield
                font.family: Theme.fontFamily
                font.pixelSize: 14
                color: modelData.active ? Theme.accent : Theme.gray
              }

              Text {
                text: modelData.name
                font.family: Theme.fontFamily
                font.pixelSize: 11
                color: modelData.active ? Theme.accent : Theme.fg
                Layout.fillWidth: true
                elide: Text.ElideRight
              }

              Rectangle {
                width: 36; height: 18; radius: 9
                color: modelData.active ? Theme.accent : Theme.bg2

                Rectangle {
                  x: modelData.active ? parent.width - width - 2 : 2
                  y: 2; width: 14; height: 14; radius: 7
                  color: Theme.fg
                  Behavior on x { NumberAnimation { duration: 150 } }
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    vpnToggleProc.command = ["nmcli", "connection", modelData.active ? "down" : "up", modelData.name]
                    vpnToggleProc.running = false
                    vpnToggleProc.running = true
                  }
                }
              }
            }
          }
        }

        // ── Wired ──
        Rectangle {
          Layout.fillWidth: true; height: 1; color: Theme.accentAlpha(0.3)
          visible: netPanel.ethernetStatus !== ""
        }

        RowLayout {
          Layout.fillWidth: true
          visible: netPanel.ethernetStatus !== ""
          spacing: 6

          Text {
            text: "\u{f0200}" // 󰀂 ethernet
            font.family: Theme.fontFamily
            font.pixelSize: 14
            color: netPanel.ethernetStatus === "Connected" ? Theme.accent : Theme.gray
          }

          Text {
            text: "Ethernet"
            font.family: Theme.fontFamily
            font.pixelSize: 11
            color: Theme.fg
          }

          Item { Layout.fillWidth: true }

          Text {
            text: netPanel.ethernetStatus
            font.family: Theme.fontFamily
            font.pixelSize: 10
            color: netPanel.ethernetStatus === "Connected" ? Theme.accent : Theme.gray
          }
        }

        Text {
          visible: !netPanel.wifiEnabled && netPanel.ethernetStatus === ""
          text: "WiFi is off"
          font.family: Theme.fontFamily
          font.pixelSize: 11
          color: Theme.gray
          Layout.fillWidth: true
          horizontalAlignment: Text.AlignHCenter
          topPadding: 10
          bottomPadding: 10
        }

        Item { height: 4 }
      }
    }
  }
}
