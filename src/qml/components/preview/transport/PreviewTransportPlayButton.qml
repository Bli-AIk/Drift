import QtQuick
import Drift
IconButton {
    anchors.verticalCenter: parent.verticalCenter
    glyph: EditorState.playing ? Theme.icons.pause : Theme.icons.play
    variant: "text"
    tooltip: EditorState.playing ? qsTr("Pause") : qsTr("Play")
    onClicked: EditorState.togglePlayback()
}
