import QtQuick 6.0
import QtQuick.Layouts 6.0
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
  id: todoist

  property bool showing: GlobalState.activePopup === "todoist"
  property string apiKey: ""
  property var tasks: []
  property var projects: []
  property string activeFilter: "today"
  property string selectedProjectId: ""
  property string statusMsg: ""
  property bool loading: false
  property bool projectsOpen: false

  FileView {
    id: apiKeyFile
    path: Quickshell.env("HOME") + "/.config/todoist/api-key"
    watchChanges: true
    onFileChanged: reload()
    onLoaded: todoist.apiKey = text().trim()
  }

  function apiRequest(method, path, body, callback) {
    var xhr = new XMLHttpRequest()
    xhr.open(method, "https://api.todoist.com/api/v1" + path)
    xhr.setRequestHeader("Authorization", "Bearer " + apiKey)
    xhr.setRequestHeader("Content-Type", "application/json")
    xhr.onreadystatechange = function() {
      if (xhr.readyState === XMLHttpRequest.DONE) {
        if (xhr.status >= 200 && xhr.status < 300) {
          try {
            callback(true, xhr.responseText ? JSON.parse(xhr.responseText) : null)
          } catch (e) {
            callback(false, null)
          }
        } else {
          callback(false, xhr.status)
        }
      }
    }
    if (body) xhr.send(JSON.stringify(body))
    else xhr.send()
  }

  function parseList(data) {
    if (Array.isArray(data)) return data
    if (data && Array.isArray(data.items)) return data.items
    if (data && Array.isArray(data.results)) return data.results
    return []
  }

  function sortTasks(list) {
    return list.slice().sort(function(a, b) {
      var da = a.due ? (a.due.date || "") : ""
      var db = b.due ? (b.due.date || "") : ""
      if (da && !db) return -1
      if (!da && db) return 1
      if (da && db && da !== db) return da.localeCompare(db)
      var pa = a.priority || 1
      var pb = b.priority || 1
      if (pa !== pb) return pb - pa
      return 0
    })
  }

  function fetchTasks() {
    if (!apiKey) return
    loading = true
    var path
    if (selectedProjectId) {
      path = "/tasks?project_id=" + selectedProjectId
    } else if (activeFilter === "today") {
      path = "/tasks/filter?query=" + encodeURIComponent("today")
    } else if (activeFilter === "overdue") {
      path = "/tasks/filter?query=" + encodeURIComponent("overdue")
    } else {
      path = "/tasks/filter?query=" + encodeURIComponent("all")
    }

    apiRequest("GET", path, null, function(ok, data) {
      loading = false
      if (ok) {
        tasks = sortTasks(parseList(data))
      } else {
        statusMsg = "Failed to load tasks"
        statusTimer.restart()
      }
    })
  }

  function fetchProjects() {
    if (!apiKey) return
    apiRequest("GET", "/projects", null, function(ok, data) {
      if (ok) projects = parseList(data)
    })
  }

  function quickAdd(text) {
    if (!apiKey || !text.trim()) return
    loading = true
    apiRequest("POST", "/tasks/quick", { text: text.trim() }, function(ok, data) {
      loading = false
      if (ok) {
        statusMsg = "✓ Added"
        addInput.text = ""
        fetchTasks()
      } else {
        statusMsg = "✗ Failed to add"
      }
      statusTimer.restart()
    })
  }

  function closeTask(taskId) {
    apiRequest("POST", "/tasks/" + taskId + "/close", null, function(ok) {
      if (ok) {
        tasks = tasks.filter(function(t) { return t.id !== taskId })
        statusMsg = "✓ Done"
      } else {
        statusMsg = "✗ Failed"
      }
      statusTimer.restart()
    })
  }

  Timer {
    id: statusTimer
    interval: 3000
    onTriggered: todoist.statusMsg = ""
  }

  visible: showing
  onShowingChanged: {
    if (showing) {
      addInput.text = ""
      statusMsg = ""
      projectsOpen = false
      if (!apiKey) apiKeyFile.reload()
      addInput.forceActiveFocus()
      if (apiKey) {
        fetchTasks()
        fetchProjects()
      }
    }
  }

  anchors { top: true; left: true; right: true; bottom: true }
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "quickshell-todoist"
  WlrLayershell.keyboardFocus: showing ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore
  color: "transparent"

  Keys.onEscapePressed: GlobalState.closeAll()

  Rectangle {
    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, showing ? 0.3 : 0)
    Behavior on color { ColorAnimation { duration: 150 } }
    MouseArea {
      anchors.fill: parent
      onClicked: GlobalState.closeAll()
    }
  }

  Rectangle {
    id: panel
    anchors.centerIn: parent
    width: 620
    height: 550
    color: Theme.bgAlpha(0.97)
    border.color: Theme.accent
    border.width: 1
    radius: 12

    opacity: showing ? 1 : 0
    scale: showing ? 1 : 0.95
    Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

    MouseArea { anchors.fill: parent }

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 16
      spacing: 10

      // ── No API key ──
      Item {
        visible: !todoist.apiKey
        Layout.fillWidth: true
        Layout.fillHeight: true

        Column {
          anchors.centerIn: parent
          spacing: 8
          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "No API key found"
            font.family: Theme.fontFamily
            font.pixelSize: 15
            font.bold: true
            color: Theme.fg
          }
          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Save your Todoist API token to:\n~/.config/todoist/api-key"
            font.family: Theme.fontFamily
            font.pixelSize: 12
            color: Theme.gray
            horizontalAlignment: Text.AlignHCenter
          }
        }
      }

      // ── Quick add ──
      Rectangle {
        visible: !!todoist.apiKey
        Layout.fillWidth: true
        Layout.preferredHeight: 40
        color: Theme.bg1
        radius: 6

        RowLayout {
          anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
          spacing: 8

          Text {
            text: "+"
            font.family: Theme.fontFamily
            font.pixelSize: 18
            font.bold: true
            color: Theme.accent
          }

          TextInput {
            id: addInput
            Layout.fillWidth: true
            verticalAlignment: TextInput.AlignVCenter
            font.family: Theme.fontFamily
            font.pixelSize: 14
            color: Theme.fg
            clip: true

            Keys.onEscapePressed: GlobalState.closeAll()
            Keys.onReturnPressed: {
              if (text.trim()) todoist.quickAdd(text)
            }

            Text {
              anchors.fill: parent
              verticalAlignment: Text.AlignVCenter
              font.family: Theme.fontFamily
              font.pixelSize: 14
              color: Theme.gray
              visible: addInput.text === ""
              text: "  Add task...  \"Buy milk tomorrow #Shopping p1\""
            }
          }
        }
      }

      // ── Filter tabs ──
      Row {
        visible: !!todoist.apiKey
        Layout.fillWidth: true
        spacing: 4

        Rectangle {
          width: todayText.implicitWidth + 20
          height: 28
          radius: 4
          color: todoist.activeFilter === "today" && !todoist.selectedProjectId
                 ? Theme.accentAlpha(0.25) : Theme.bg1
          Text {
            id: todayText
            anchors.centerIn: parent
            text: "Today"
            font.family: Theme.fontFamily
            font.pixelSize: 12
            color: todoist.activeFilter === "today" && !todoist.selectedProjectId
                   ? Theme.accent : Theme.fg
          }
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              todoist.selectedProjectId = ""
              todoist.activeFilter = "today"
              todoist.projectsOpen = false
              todoist.fetchTasks()
            }
          }
        }

        Rectangle {
          width: overdueText.implicitWidth + 20
          height: 28
          radius: 4
          color: todoist.activeFilter === "overdue" && !todoist.selectedProjectId
                 ? Theme.accentAlpha(0.25) : Theme.bg1
          Text {
            id: overdueText
            anchors.centerIn: parent
            text: "Overdue"
            font.family: Theme.fontFamily
            font.pixelSize: 12
            color: todoist.activeFilter === "overdue" && !todoist.selectedProjectId
                   ? Theme.accent : Theme.fg
          }
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              todoist.selectedProjectId = ""
              todoist.activeFilter = "overdue"
              todoist.projectsOpen = false
              todoist.fetchTasks()
            }
          }
        }

        Rectangle {
          width: allText.implicitWidth + 20
          height: 28
          radius: 4
          color: todoist.activeFilter === "all" && !todoist.selectedProjectId
                 ? Theme.accentAlpha(0.25) : Theme.bg1
          Text {
            id: allText
            anchors.centerIn: parent
            text: "All"
            font.family: Theme.fontFamily
            font.pixelSize: 12
            color: todoist.activeFilter === "all" && !todoist.selectedProjectId
                   ? Theme.accent : Theme.fg
          }
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              todoist.selectedProjectId = ""
              todoist.activeFilter = "all"
              todoist.projectsOpen = false
              todoist.fetchTasks()
            }
          }
        }

        Rectangle {
          width: projBtnText.implicitWidth + 20
          height: 28
          radius: 4
          color: todoist.selectedProjectId ? Theme.accentAlpha(0.25) : Theme.bg1
          Text {
            id: projBtnText
            anchors.centerIn: parent
            text: {
              if (todoist.selectedProjectId) {
                var p = todoist.projects.find(function(proj) {
                  return proj.id === todoist.selectedProjectId
                })
                return p ? p.name + " ×" : "Project ▾"
              }
              return "Project ▾"
            }
            font.family: Theme.fontFamily
            font.pixelSize: 12
            color: todoist.selectedProjectId ? Theme.accent : Theme.fg
          }
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              if (todoist.selectedProjectId) {
                todoist.selectedProjectId = ""
                todoist.activeFilter = "today"
                todoist.fetchTasks()
              } else {
                todoist.projectsOpen = !todoist.projectsOpen
              }
            }
          }
        }
      }

      // ── Project dropdown ──
      Rectangle {
        visible: todoist.projectsOpen && !!todoist.apiKey
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(todoist.projects.length * 30 + 8, 150)
        color: Theme.bg1
        radius: 6
        border.color: Theme.accentAlpha(0.3)
        border.width: 1
        clip: true

        ListView {
          anchors { fill: parent; margins: 4 }
          model: todoist.projects
          spacing: 2

          delegate: Rectangle {
            required property var modelData
            required property int index
            property bool hovered: false

            width: ListView.view.width
            height: 28
            radius: 4
            color: hovered ? Theme.accentAlpha(0.15) : "transparent"

            Text {
              anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
              text: modelData.name || ""
              font.family: Theme.fontFamily
              font.pixelSize: 12
              color: Theme.fg
              elide: Text.ElideRight
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onContainsMouseChanged: parent.hovered = containsMouse
              onClicked: {
                todoist.selectedProjectId = modelData.id
                todoist.activeFilter = ""
                todoist.projectsOpen = false
                todoist.fetchTasks()
              }
            }
          }
        }
      }

      // ── Task list ──
      ListView {
        visible: !!todoist.apiKey
        id: taskList
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 2

        model: todoist.tasks

        Text {
          anchors.centerIn: parent
          visible: todoist.loading && todoist.tasks.length === 0
          text: "Loading…"
          font.family: Theme.fontFamily
          font.pixelSize: 13
          color: Theme.gray
        }

        Text {
          anchors.centerIn: parent
          visible: !todoist.loading && todoist.tasks.length === 0
          text: todoist.activeFilter === "today" ? "All clear for today" : "No tasks"
          font.family: Theme.fontFamily
          font.pixelSize: 13
          color: Theme.gray
        }

        delegate: Rectangle {
          required property var modelData
          required property int index
          property bool hovered: false

          width: taskList.width
          height: taskRow.implicitHeight + 14
          color: hovered ? Theme.accentAlpha(0.1) : "transparent"
          radius: 6

          RowLayout {
            id: taskRow
            anchors {
              left: parent.left; right: parent.right
              verticalCenter: parent.verticalCenter
              leftMargin: 10; rightMargin: 10
            }
            spacing: 10

            Rectangle {
              Layout.preferredWidth: 18
              Layout.preferredHeight: 18
              Layout.alignment: Qt.AlignTop
              Layout.topMargin: 2
              radius: 9
              color: "transparent"
              border.color: {
                var p = modelData.priority || 1
                if (p === 4) return Theme.red
                if (p === 3) return Theme.orange
                if (p === 2) return Theme.blue
                return Theme.gray
              }
              border.width: 1.5

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: todoist.closeTask(modelData.id)
              }
            }

            Column {
              Layout.fillWidth: true
              spacing: 2

              Text {
                width: parent.width
                text: modelData.content || ""
                font.family: Theme.fontFamily
                font.pixelSize: 13
                color: Theme.fg
                wrapMode: Text.WordWrap
              }

              Row {
                spacing: 8
                Text {
                  visible: !!modelData.due
                  text: modelData.due
                        ? (modelData.due.string || modelData.due.date || "")
                        : ""
                  font.family: Theme.fontFamily
                  font.pixelSize: 10
                  color: Theme.gray
                }
                Text {
                  visible: !todoist.selectedProjectId && !!modelData.project_id
                  text: {
                    if (!modelData.project_id) return ""
                    var p = todoist.projects.find(function(proj) {
                      return proj.id === modelData.project_id
                    })
                    return p ? p.name : ""
                  }
                  font.family: Theme.fontFamily
                  font.pixelSize: 10
                  color: Theme.accentAlpha(0.6)
                }
              }
            }
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            onContainsMouseChanged: parent.hovered = containsMouse
          }
        }
      }

      // ── Status bar ──
      RowLayout {
        visible: !!todoist.apiKey
        Layout.fillWidth: true
        Layout.preferredHeight: 20

        Text {
          text: todoist.statusMsg
          font.family: Theme.fontFamily
          font.pixelSize: 11
          color: todoist.statusMsg.startsWith("✓") ? Theme.green
               : todoist.statusMsg.startsWith("✗") ? Theme.red
               : Theme.gray
        }

        Item { Layout.fillWidth: true }

        Text {
          visible: todoist.loading
          text: "⟳"
          font.family: Theme.fontFamily
          font.pixelSize: 13
          color: Theme.accent

          RotationAnimator on rotation {
            from: 0; to: 360
            duration: 1000
            loops: Animation.Infinite
            running: todoist.loading
          }
        }
      }
    }
  }
}
