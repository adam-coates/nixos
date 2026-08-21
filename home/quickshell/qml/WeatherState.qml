pragma Singleton
import QtQuick 6.0
import Quickshell
import Quickshell.Io

// Shared weather data for the bar icon (Weather.qml) and the popup
// (WeatherPanel.qml), so both read one fetch instead of polling separately.
Singleton {
  id: root

  property bool loaded: false
  property bool failed: false

  property string place: ""
  property string tempC: ""
  property string feelsC: ""
  property string desc: ""
  property string humidity: ""
  property string windKmph: ""
  property string windDir: ""
  property int code: 113
  property bool daytime: true

  // [{ date, minC, maxC, code, desc }]
  property var forecast: []

  // wttr.in asks callers not to hammer it; omarchy polls every 60s, which is
  // enough to get rate-limited. 15 minutes is plenty for weather, and opening
  // the panel forces a refresh anyway.
  readonly property int refreshMs: 15 * 60 * 1000

  function iconFor(wcode, isDay) {
    var c = parseInt(wcode)
    if (c === 113) return isDay ? "\u{f0599}" : "\u{f0594}"   // 󰖙 clear / 󰖔 night
    if (c === 116) return "\u{f0595}"                          // 󰖕 partly cloudy
    if (c === 119 || c === 122) return "\u{f0590}"             // 󰖐 cloudy
    if (c === 143 || c === 248 || c === 260) return "\u{f0591}" // 󰖑 fog
    if (c === 200 || c === 386 || c === 389 || c === 392 || c === 395)
      return "\u{f0593}"                                       // 󰖓 thunder
    // Snow / sleet / freezing
    if ([179, 182, 185, 227, 230, 281, 284, 311, 314, 317, 320, 323, 326,
         329, 332, 335, 338, 350, 362, 365, 368, 371, 374, 377].indexOf(c) >= 0)
      return "\u{f0598}"                                       // 󰖘 snow
    // Heavy rain
    if ([299, 302, 305, 308, 356, 359].indexOf(c) >= 0)
      return "\u{f0596}"                                       // 󰖖 heavy rain
    // Everything else that falls out of the sky
    if (c >= 176) return "\u{f0597}"                           // 󰖗 rain
    return "\u{f0590}"
  }

  readonly property string icon: iconFor(code, daytime)

  Process {
    id: fetch
    running: false
    command: ["curl", "-fsS", "--max-time", "10", "https://wttr.in/?format=j1"]

    // StdioCollector buffers the whole response; the JSON spans many lines,
    // so a line-splitting parser would fragment it.
    stdout: StdioCollector { id: collector }

    onExited: (code) => {
      var raw = collector.text
      if (code !== 0 || raw.trim() === "") { root.failed = true; return }

      try {
        var d = JSON.parse(raw)
        var cur = d.current_condition[0]

        root.tempC = cur.temp_C
        root.feelsC = cur.FeelsLikeC
        root.humidity = cur.humidity
        root.windKmph = cur.windspeedKmph
        root.windDir = cur.winddir16Point
        root.desc = (cur.weatherDesc && cur.weatherDesc[0]) ? cur.weatherDesc[0].value.trim() : ""
        root.code = parseInt(cur.weatherCode)

        var area = d.nearest_area && d.nearest_area[0]
        if (area && area.areaName && area.areaName[0]) root.place = area.areaName[0].value

        var hour = new Date().getHours()
        root.daytime = hour >= 7 && hour < 20

        var out = []
        for (var i = 0; i < Math.min(3, d.weather.length); i++) {
          var w = d.weather[i]
          // Midday hourly entry is the most representative for a day summary.
          var mid = w.hourly[Math.min(4, w.hourly.length - 1)]
          out.push({
            date: w.date,
            minC: w.mintempC,
            maxC: w.maxtempC,
            code: parseInt(mid.weatherCode),
            desc: (mid.weatherDesc && mid.weatherDesc[0]) ? mid.weatherDesc[0].value.trim() : ""
          })
        }
        root.forecast = out

        root.failed = false
        root.loaded = true
      } catch (e) {
        root.failed = true
      }
    }
  }

  function refresh() {
    if (fetch.running) return
    fetch.running = true
  }

  Timer {
    interval: root.refreshMs
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }
}
