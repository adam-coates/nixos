import QtQuick 6.0
import QtQuick.Layouts 6.0
import Quickshell.Io

ColumnLayout {
  spacing: 8

  property string currentNetwork: ""
  property bool wifiEnabled: true
  property var networkList: []

  // Header
  RowLayout {
    Layout.fillWidth: true

    Text {
      text: "Network"
      font.family: Theme.fontFamily
      font.pixelSize: 12
      font.bold: true
      color: Theme.fg
    }

    Item { Layout.fillWidth: true }

    // WiFi toggle
    Rectangle {
      width: 36
      height: 18
      radius: 9
      color: wifiEnabled ? Theme.accent : Theme.bg2

      Rectangle {
        x: wifiEnabled ? parent.width - width - 2 : 2
        y: 2
        width: 14
        height: 14
        radius: 7
        color: Theme.fg

        Behavior on x { NumberAnimation { duration: 150 } }
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          wifiToggle.running = true
        }
      }
    }
  }

  // Current connection
  Text {
    visible: currentNetwork !== ""
    text: "\u{f05a9} " + currentNetwork // 󰖩
    font.family: Theme.fontFamily
    font.pixelSize: 12
    color: Theme.accent
  }

  // Network list
  Repeater {
    model: networkList

    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: 32
      color: modelData.active ? Theme.accentAlpha(0.1) : "transparent"
      radius: 4

      RowLayout {
        anchors {
          fill: parent
          leftMargin: 8
          rightMargin: 8
        }
        spacing: 8

        Text {
          text: modelData.ssid
          font.family: Theme.fontFamily
          font.pixelSize: 12
          color: modelData.active ? Theme.accent : Theme.fg
          Layout.fillWidth: true
          elide: Text.ElideRight
        }

        Text {
          text: modelData.signal || ""
          font.family: Theme.fontFamily
          font.pixelSize: 10
          color: Theme.gray
        }
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          connectNetwork.command = ["nmcli", "connection", "up", modelData.ssid]
          connectNetwork.running = true
        }
      }
    }
  }

  // Scan for networks
  Process {
    id: networkScanner
    command: ["nmcli", "-t", "-f", "ACTIVE,SSID,SIGNAL", "dev", "wifi", "list", "--rescan", "auto"]
    onExited: {
      var lines = stdout.trim().split("\n")
      var nets = []
      currentNetwork = ""
      for (var i = 0; i < lines.length; i++) {
        var parts = lines[i].split(":")
        if (parts.length >= 3 && parts[1]) {
          var isActive = parts[0] === "yes"
          if (isActive) currentNetwork = parts[1]
          nets.push({ ssid: parts[1], signal: parts[2] + "%", active: isActive })
        }
      }
      networkList = nets
    }
  }

  Process {
    id: wifiStatusCheck
    command: ["nmcli", "radio", "wifi"]
    onExited: {
      wifiEnabled = stdout.trim() === "enabled"
    }
  }

  Process {
    id: wifiToggle
    command: ["nmcli", "radio", "wifi", wifiEnabled ? "off" : "on"]
    onExited: {
      wifiEnabled = !wifiEnabled
      if (wifiEnabled) refreshTimer.restart()
    }
  }

  Process {
    id: connectNetwork
  }

  Timer {
    id: refreshTimer
    interval: 5000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      networkScanner.running = true
      wifiStatusCheck.running = true
    }
  }
}
