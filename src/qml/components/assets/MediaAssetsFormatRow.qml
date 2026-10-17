import QtQuick
import Drift

// One supported-format line on the media bin's first-run screen.
Row {
    id: root

    required property var modelData
    required property real columnWidth

    width: columnWidth
    spacing: Theme.spacingMd

    IconGlyph {
        anchors.verticalCenter: parent.verticalCenter
        glyph: root.modelData.glyph
        iconSize: Theme.iconSizeSm
        iconColor: Theme.mutedForeground
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        width: 48
        text: root.modelData.label
        color: Theme.panelForeground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeXs
        elide: Text.ElideRight
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        width: root.columnWidth - Theme.iconSizeSm - 48 - Theme.spacingMd * 2
        text: root.modelData.formats
        color: Theme.mutedForeground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeTiny
        elide: Text.ElideRight
    }
}
