import QtQuick 6.0
import QtQuick.Layouts 6.0
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
  id: launcher

  property bool showing: GlobalState.activePopup === "launcher"
  property string query: ""
  property var fileResults: []

  readonly property string mode: {
    const q = query
    if (q.startsWith("=")) return "calc"
    if (q.startsWith("?")) return "web"
    if (q.startsWith("~/") || q.startsWith("/")) return "file"
    return "app"
  }

  // ── Unit conversion tables ──
  readonly property var unitTable: ({
    // Length → meters
    km:  { cat: "length", f: 1000 },
    m:   { cat: "length", f: 1 },
    cm:  { cat: "length", f: 0.01 },
    mm:  { cat: "length", f: 0.001 },
    mi:  { cat: "length", f: 1609.344 },
    yd:  { cat: "length", f: 0.9144 },
    ft:  { cat: "length", f: 0.3048 },
    "in": { cat: "length", f: 0.0254 },
    nm:  { cat: "length", f: 1852 },
    // Weight → grams
    kg:  { cat: "weight", f: 1000 },
    g:   { cat: "weight", f: 1 },
    mg:  { cat: "weight", f: 0.001 },
    lb:  { cat: "weight", f: 453.592 },
    lbs: { cat: "weight", f: 453.592 },
    oz:  { cat: "weight", f: 28.3495 },
    st:  { cat: "weight", f: 6350.29 },
    t:   { cat: "weight", f: 1000000 },
    // Volume → liters
    l:    { cat: "volume", f: 1 },
    ml:   { cat: "volume", f: 0.001 },
    gal:  { cat: "volume", f: 3.78541 },
    qt:   { cat: "volume", f: 0.946353 },
    pt:   { cat: "volume", f: 0.473176 },
    cup:  { cat: "volume", f: 0.236588 },
    floz: { cat: "volume", f: 0.0295735 },
    tbsp: { cat: "volume", f: 0.0147868 },
    tsp:  { cat: "volume", f: 0.00492892 },
    // Speed → m/s
    "m/s":  { cat: "speed", f: 1 },
    "km/h": { cat: "speed", f: 0.277778 },
    kmh:    { cat: "speed", f: 0.277778 },
    kph:    { cat: "speed", f: 0.277778 },
    mph:    { cat: "speed", f: 0.44704 },
    kn:     { cat: "speed", f: 0.514444 },
    knot:   { cat: "speed", f: 0.514444 },
    knots:  { cat: "speed", f: 0.514444 },
    // Data → bytes
    b:   { cat: "data", f: 1 },
    kb:  { cat: "data", f: 1024 },
    mb:  { cat: "data", f: 1048576 },
    gb:  { cat: "data", f: 1073741824 },
    tb:  { cat: "data", f: 1099511627776 },
    // Time → seconds
    s:   { cat: "time", f: 1 },
    sec: { cat: "time", f: 1 },
    min: { cat: "time", f: 60 },
    h:   { cat: "time", f: 3600 },
    hr:  { cat: "time", f: 3600 },
    hrs: { cat: "time", f: 3600 },
    d:   { cat: "time", f: 86400 },
    wk:  { cat: "time", f: 604800 },
    // Area → m²
    m2:   { cat: "area", f: 1 },
    km2:  { cat: "area", f: 1000000 },
    ft2:  { cat: "area", f: 0.092903 },
    mi2:  { cat: "area", f: 2589988 },
    acre: { cat: "area", f: 4046.86 },
    ha:   { cat: "area", f: 10000 },
    // Temperature (special)
    c: { cat: "temp" }, f: { cat: "temp" }, k: { cat: "temp" }
  })

  function tryConvert(expr) {
    const m = expr.match(/^([\d.]+)\s*([a-z/²]+)\s+(?:to|in|as)\s+([a-z/²]+)$/i)
    if (!m) return ""
    const val = parseFloat(m[1])
    const from = m[2].toLowerCase()
    const to = m[3].toLowerCase()
    if (isNaN(val)) return ""

    const fu = unitTable[from]
    const tu = unitTable[to]
    if (!fu || !tu || fu.cat !== tu.cat) return ""

    var result
    if (fu.cat === "temp") {
      // Convert to Celsius first, then to target
      var celsius
      if (from === "c") celsius = val
      else if (from === "f") celsius = (val - 32) * 5 / 9
      else celsius = val - 273.15 // kelvin

      if (to === "c") result = celsius
      else if (to === "f") result = celsius * 9 / 5 + 32
      else result = celsius + 273.15
    } else {
      result = val * fu.f / tu.f
    }

    if (!isFinite(result)) return ""
    var s = Number.isInteger(result) ? String(result) : parseFloat(result.toFixed(6)).toString()
    return val + " " + from + " = " + s + " " + to
  }

  readonly property string calcResult: {
    if (mode !== "calc") return ""
    const expr = query.slice(1).trim()
    if (!expr) return ""

    // Try unit conversion first
    const conv = tryConvert(expr)
    if (conv !== "") return conv

    // Math eval
    if (!/^[\d\s+\-*/().,^%]+$/.test(expr)) return ""
    try {
      const r = Function("return (" + expr.replace(/\^/g, "**") + ")")()
      if (typeof r !== "number" || !isFinite(r)) return ""
      return Number.isInteger(r) ? String(r) : parseFloat(r.toFixed(8)).toString()
    } catch(e) { return "" }
  }

  // Selected file path in file mode
  readonly property string selectedPath: {
    if (mode !== "file" || fileResults.length === 0) return ""
    const idx = resultsList.currentIndex
    return (idx >= 0 && idx < fileResults.length) ? fileResults[idx] : ""
  }

  onSelectedPathChanged: GlobalState.previewFile = selectedPath

  // File search via fd
  Process {
    id: fileProc
    running: false
    stdout: SplitParser {
      onRead: line => {
        if (line.trim()) launcher.fileResults = [...launcher.fileResults, line.trim()]
      }
    }
  }

  Timer {
    id: fileDebounce
    interval: 200
    onTriggered: {
      if (launcher.mode !== "file") return
      const q = launcher.query
      const term = q.startsWith("~/") ? q.slice(2) : q.slice(1)
      launcher.fileResults = []
      fileProc.running = false
      fileProc.command = [
        "fd", "--type", "f", "--absolute-path",
        "--max-results", "30", "--hidden",
        "--exclude", ".git", "--exclude", "node_modules",
        term.trim() || ".", Quickshell.env("HOME")
      ]
      fileProc.running = true
    }
  }

  onQueryChanged: {
    resultsList.currentIndex = 0
    if (mode === "file") {
      fileDebounce.restart()
    } else {
      fileProc.running = false
      fileResults = []
    }
  }

  visible: showing
  onShowingChanged: {
    if (showing) {
      query = ""
      fileResults = []
      searchInput.forceActiveFocus()
    } else {
      GlobalState.previewFile = ""
    }
  }

  anchors { top: true; left: true; right: true; bottom: true }
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "quickshell-launcher"
  WlrLayershell.keyboardFocus: showing ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore
  color: "transparent"

  // Dim backdrop
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
    anchors.centerIn: parent
    width: 620
    height: 480
    color: Theme.bgAlpha(0.97)
    border.color: Theme.accent
    border.width: 1
    radius: 12

    // Slide + fade animation
    opacity: showing ? 1 : 0
    scale: showing ? 1 : 0.95
    Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

    MouseArea { anchors.fill: parent }

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 20
      spacing: 10

      // Search bar
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 40
        color: Theme.bg1
        radius: 6

        RowLayout {
          anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
          spacing: 0

          TextInput {
            id: searchInput
            Layout.fillWidth: true
            verticalAlignment: TextInput.AlignVCenter
            font.family: Theme.fontFamily
            font.pixelSize: 14
            color: Theme.fg
            clip: true
            text: launcher.query
            onTextChanged: launcher.query = text

            Keys.onEscapePressed: GlobalState.closeAll()
            Keys.onReturnPressed: launchCurrent()
            Keys.onDownPressed: {
              if (resultsList.currentIndex < resultsList.count - 1)
                resultsList.currentIndex++
            }
            Keys.onUpPressed: {
              if (resultsList.currentIndex > 0)
                resultsList.currentIndex--
            }

            Text {
              anchors.fill: parent
              verticalAlignment: Text.AlignVCenter
              font.family: Theme.fontFamily
              font.pixelSize: 14
              color: Theme.gray
              visible: searchInput.text === ""
              text: "  Search...  ( = calc/convert   ? web   ~/ files )"
            }
          }

          Rectangle {
            visible: launcher.mode !== "app"
            width: modeLabel.implicitWidth + 12
            height: 24
            radius: 4
            color: Theme.accentAlpha(0.2)
            Text {
              id: modeLabel
              anchors.centerIn: parent
              text: {
                if (launcher.mode === "calc") {
                  return launcher.calcResult.indexOf(" = ") > 0 ? "convert" : "calc"
                }
                return launcher.mode === "web" ? "web" : "files"
              }
              font.family: Theme.fontFamily
              font.pixelSize: 11
              color: Theme.accent
            }
          }
        }
      }

      // Results list
      ListView {
        id: resultsList
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        currentIndex: 0
        spacing: 2
        keyNavigationWraps: false

        model: ScriptModel {
          values: {
            const q = launcher.query.trim()

            if (launcher.mode === "calc") {
              const expr = q.slice(1).trim()
              const r = launcher.calcResult
              if (r !== "") return [{ _t: "calc", expr, result: r }]
              return expr ? [{ _t: "calc_err", expr }] : []
            }

            if (launcher.mode === "web") {
              const wq = q.slice(1).trim()
              return wq ? [{ _t: "web", query: wq }] : []
            }

            if (launcher.mode === "file") {
              return launcher.fileResults.map(p => ({
                _t: "file", path: p, name: p.split("/").pop()
              }))
            }

            const ql = q.toLowerCase()
            const all = [...DesktopEntries.applications.values].filter(e =>
              e.name && e.noDisplay !== true
            )
            const filtered = ql === "" ? all : all.filter(e => e.name.toLowerCase().includes(ql))
            filtered.sort((a, b) => {
              if (ql) {
                const as = a.name.toLowerCase().startsWith(ql)
                const bs = b.name.toLowerCase().startsWith(ql)
                if (as && !bs) return -1
                if (!as && bs) return 1
              }
              return a.name.localeCompare(b.name)
            })
            return filtered.map(e => ({ _t: "app", entry: e }))
          }
        }

        delegate: Rectangle {
          required property int index
          required property var modelData

          width: resultsList.width
          height: 40
          color: resultsList.currentIndex === index ? Theme.accentAlpha(0.2) : "transparent"
          radius: 6

          Behavior on color { ColorAnimation { duration: 80 } }

          RowLayout {
            anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
            spacing: 10

            Text {
              visible: modelData._t === "calc" || modelData._t === "calc_err" || modelData._t === "web"
              text: (modelData._t === "calc" || modelData._t === "calc_err") ? "=" : "?"
              font.family: Theme.fontFamily
              font.pixelSize: 15
              font.bold: true
              color: resultsList.currentIndex === index ? Theme.accent : Theme.gray
              Layout.preferredWidth: 24
              horizontalAlignment: Text.AlignHCenter
            }

            Image {
              visible: modelData._t === "app"
              source: (modelData._t === "app" && modelData.entry.icon)
                      ? Quickshell.iconPath(modelData.entry.icon, true) : ""
              Layout.preferredWidth: 24
              Layout.preferredHeight: 24
              fillMode: Image.PreserveAspectFit
            }

            Text {
              Layout.fillWidth: true
              text: {
                if (modelData._t === "calc")     return modelData.result
                if (modelData._t === "calc_err") return "Invalid expression"
                if (modelData._t === "web")      return "Search Google:  " + modelData.query
                if (modelData._t === "file") {
                  const home = Quickshell.env("HOME")
                  return modelData.path.startsWith(home)
                    ? "~" + modelData.path.slice(home.length)
                    : modelData.path
                }
                return modelData.entry.name
              }
              font.family: Theme.fontFamily
              font.pixelSize: 13
              color: resultsList.currentIndex === index ? Theme.accent : Theme.fg
              elide: Text.ElideRight
            }
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onEntered: resultsList.currentIndex = index
            onClicked: { resultsList.currentIndex = index; launchCurrent() }
          }
        }
      }
    }
  }

  function launchCurrent() {
    if (resultsList.count === 0) return
    const item = resultsList.model.values[resultsList.currentIndex]
    if (!item) return
    if (item._t === "app") {
      GlobalState.closeAll()
      item.entry.execute()
    } else if (item._t === "calc") {
      // For conversions, copy the result number; for math, copy the result
      const parts = item.result.split(" = ")
      const copyVal = parts.length > 1 ? parts[1] : item.result
      searchInput.text = copyVal
      searchInput.selectAll()
    } else if (item._t === "web") {
      GlobalState.closeAll()
      Qt.openUrlExternally("https://www.google.com/search?q=" + encodeURIComponent(item.query))
    } else if (item._t === "file") {
      GlobalState.closeAll()
      Qt.openUrlExternally("file://" + item.path)
    }
  }
}
