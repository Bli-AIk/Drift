import QtQuick
import Drift

// Playhead and duration readout on the toolbar.
Text {
    property var panel

    text: panel.formatTime(EditorState.playheadSeconds) + " / " + panel.formatTime(EditorState.durationSeconds)
    color: Theme.mutedForeground
    font.family: Theme.monoFontFamily
    font.pixelSize: Theme.fontSizeXs
    anchors.verticalCenter: parent.verticalCenter
}
