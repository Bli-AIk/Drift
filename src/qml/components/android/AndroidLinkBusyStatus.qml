import QtQuick
import Drift

// Spinner plus the sentence for whichever wait the link import is in.
Row {
    id: row

    property string statusText: ""

    spacing: Theme.spacingLg

    IconGlyph {
        id: busyGlyph
        anchors.verticalCenter: parent.verticalCenter
        glyph: Theme.icons.spinner
        iconSize: Theme.iconSizeLg
        iconColor: Theme.mutedForeground

        RotationAnimator on rotation {
            running: busyGlyph.visible
            loops: Animation.Infinite
            from: 0
            to: 360
            duration: 900
        }
    }

    ThemedLabel {
        anchors.verticalCenter: parent.verticalCenter
        text: row.statusText
    }
}
