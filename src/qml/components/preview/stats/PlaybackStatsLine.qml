import QtQuick
import Drift

// One labelled playback counter.
Row {
    id: line

    required property string label
    required property string value
    required property color labelColor
    required property color valueColor
    required property color warnColor
    property bool warn: false

    spacing: Theme.spacingMd

    Text {
        width: 104
        font.family: Theme.monoFontFamily
        font.pixelSize: Theme.fontSizeXs
        color: line.labelColor
        text: line.label
    }
    Text {
        font.family: Theme.monoFontFamily
        font.pixelSize: Theme.fontSizeXs
        color: line.warn ? line.warnColor : line.valueColor
        text: line.value
    }
}
