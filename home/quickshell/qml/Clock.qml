import QtQuick 6.0

Item {
  id: clock

  implicitWidth: clockText.width
  implicitHeight: Theme.barHeight

  property bool showDate: false

  // ISO-8601 week number, matching omarchy's "W%V" alt format. Qt's
  // formatDateTime has no week token, so compute it.
  function isoWeek(d) {
    var t = new Date(d.getFullYear(), d.getMonth(), d.getDate())
    // Thursday of the current week determines the year the week belongs to.
    t.setDate(t.getDate() + 3 - ((t.getDay() + 6) % 7))
    var firstThursday = new Date(t.getFullYear(), 0, 4)
    firstThursday.setDate(firstThursday.getDate() + 3 - ((firstThursday.getDay() + 6) % 7))
    return 1 + Math.round((t - firstThursday) / (7 * 86400000))
  }

  function render() {
    var now = new Date()
    clockText.text = showDate
      ? Qt.formatDateTime(now, "dd MMMM") + " W" + isoWeek(now) + " " + Qt.formatDateTime(now, "yyyy")
      : Qt.formatDateTime(now, "dddd HH:mm")
  }

  onShowDateChanged: render()

  Text {
    id: clockText
    anchors.centerIn: parent
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    color: GlobalState.activePopup === "calendar" ? Theme.accent : Theme.fg
    Behavior on color { ColorAnimation { duration: 120 } }
    Component.onCompleted: clock.render()
  }

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: clock.render()
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor
    // Left opens the calendar; right keeps omarchy's format-alt text swap.
    onClicked: (mouse) => {
      if (mouse.button === Qt.RightButton) clock.showDate = !clock.showDate
      else GlobalState.toggle("calendar")
    }
  }
}
