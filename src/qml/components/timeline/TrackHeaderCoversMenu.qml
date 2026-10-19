import QtQuick
import Drift

// Span choices for a transform layer. A submenu cannot be hidden per row, so this opens on its own.
ThemedContextMenu {
    id: coversMenu

    property TrackHeaderColumn column
    property int trackIndex: -1
    property bool transformLayer: false

    title: qsTr("Covers")
    enabled: transformLayer
    readonly property int layerIndex: trackIndex
    property var options: []
    onAboutToShow: options = EditorState.transformSpanOptions(layerIndex)

    Instantiator {
        model: coversMenu.options
        delegate: ThemedMenuItem {
            required property var modelData
            text: coversMenu.column.spanOptionLabel(modelData)
            icon.name: modelData.current ? Theme.icons.check : ""
            onTriggered: EditorState.setTransformSpan(coversMenu.layerIndex, modelData.endId)
        }
        onObjectAdded: (i, object) => coversMenu.insertItem(i, object)
        onObjectRemoved: (i, object) => coversMenu.removeItem(object)
    }
}
