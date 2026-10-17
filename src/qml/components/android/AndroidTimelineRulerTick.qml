import QtQuick
import Drift

// One labelled tick on the phone timeline ruler.
Item {
    id: tick

    required property int index
    property int firstVisibleTick: 0
    property real tickStepSeconds: 1
    property real pxPerSecond: 1
    property var formatTick: function(seconds) { return "" }

    readonly property real tickSeconds: (tick.firstVisibleTick + tick.index) * tick.tickStepSeconds

    x: tick.tickSeconds * tick.pxPerSecond
    width: tick.tickStepSeconds * tick.pxPerSecond
    height: parent ? parent.height : 0

    Rectangle {
        x: 0
        y: parent.height - 10
        width: 1
        height: 8
        color: Qt.rgba(Theme.mutedForeground.r,
                       Theme.mutedForeground.g,
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
