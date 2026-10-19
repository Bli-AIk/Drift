import QtQuick
import Drift
IconButton {
    glyph: Theme.icons.grid
    variant: "text"
    tooltip: qsTr("Toggle guides")
    active: EditorState.preview.guidesEnabled
    onClicked: EditorState.preview.guidesEnabled = !EditorState.preview.guidesEnabled
}
