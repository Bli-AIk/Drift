import QtQuick
import Drift

// One ruler tick and its timestamp. Only ticks in the viewport are created.
Item {
    id: tick

    required property int index
    property real firstTick: 0
    property real stepSeconds: 1
    property real pxPerSecond: 1
    property var formatTick
    property real rulerHeight: 0

    readonly property real tickSeconds: (firstTick + index) * stepSeconds

    x: tickSeconds * pxPerSecond
    width: stepSeconds * pxPerSecond
    height: rulerHeight

    Rectangle {
        x: 0
        y: parent.height - 10
        width: 1
        height: 8
        color: Qt.rgba(Theme.mutedForeground.r, Theme.mutedForeground.g,
                       Theme.mutedForeground.b, 0.28)
    }

    Text {
        x: 4
        y: 4
        text: tick.formatTick(tick.tickSeconds)
        color: Theme.mutedForeground
        font.pixelSize: Theme.fontSizeTick
        font.family: Theme.fontFamily
    }
}
