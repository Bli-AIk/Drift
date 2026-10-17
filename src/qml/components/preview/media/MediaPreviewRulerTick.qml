import QtQuick
import Drift

// One tick and its timestamp on the source ruler.
Item {
    id: tick

    required property int index
    required property real rangeStart
    required property real step
    required property real pxPerSecond
    required property var formatTick
    readonly property string label: formatTick(tSeconds)

    readonly property real tSeconds: tick.rangeStart + tick.index * tick.step
    x: (tSeconds - tick.rangeStart) * tick.pxPerSecond
    width: 1
    height: parent.height

    Rectangle {
        anchors.bottom: parent.bottom
        width: 1
        height: 6
        color: Theme.c.mediaPreviewRulerTick.foreground
        opacity: Theme.c.mediaPreviewRulerTick.opacity
    }
    Text {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 8
        anchors.left: parent.left
        anchors.leftMargin: 2
        text: tick.label
        font.family: Theme.monoFontFamily
        font.pixelSize: Theme.fontSizeTick
        color: Theme.c.mediaPreviewRulerTick.foreground
    }
}
