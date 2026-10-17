import QtQuick
import Drift

// Honest rather than a row of greyed buttons — the timeline below never shifts
// because the toolbar keeps its height either way.
Text {
    text: qsTr("Tap a clip to edit")
    color: Theme.mutedForeground
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSizeSm
    elide: Text.ElideRight
}
