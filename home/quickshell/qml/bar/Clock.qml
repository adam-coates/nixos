import QtQuick 6.0

Item {
  width: clockText.width
  height: 26

  property bool showDate: false

  Text {
    id: clockText
    anchors.centerIn: parent
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    color: Theme.fg
    text: Qt.formatDateTime(new Date(),
      showDate ? "dd MMMM yyyy" : "dddd HH:mm")
  }

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: clockText.text = Qt.formatDateTime(new Date(),
      showDate ? "dd MMMM yyyy" : "dddd HH:mm")
  }

  MouseArea {
    anchors.fill: parent
    onClicked: showDate = !showDate
  }
}
