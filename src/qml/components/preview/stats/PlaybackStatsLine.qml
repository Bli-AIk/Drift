import QtQuick
import Drift

// One labelled playback counter.
Row {
    id: line

    required property string label
    required property string value
    property bool warn: false

    spacing: Theme.spacingMd

    Text {
        width: 104
        font.family: Theme.monoFontFamily
        font.pixelSize: Theme.fontSizeXs
        color: Theme.c.playbackStatsLine.foreground
        text: line.label
    }
    Text {
        font.family: Theme.monoFontFamily
        font.pixelSize: Theme.fontSizeXs
        color: line.warn ? Theme.c.playbackStatsLine.foregroundWarn : Theme.c.playbackStatsLine.foregroundValue
        text: line.value
    }
}
