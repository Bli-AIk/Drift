import QtQuick
import Drift
// Audio has no picture, so the stage shows the name instead.
Column {
    id: placeholder

    required property string assetName

    spacing: Theme.spacingLg

    IconGlyph {
        anchors.horizontalCenter: parent.horizontalCenter
        glyph: Theme.icons.music
        iconSize: Theme.iconSizeXl * 2
        iconColor: Theme.mutedForeground
    }
    ThemedLabel {
        anchors.horizontalCenter: parent.horizontalCenter
        text: placeholder.assetName
        tone: "default"
        size: "sm"
    }
}
