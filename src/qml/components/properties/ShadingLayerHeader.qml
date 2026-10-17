import QtQuick
import Drift

Rectangle {
    property var shading
    width: parent.width
    height: Math.max(Theme.controlHeightSm, header.implicitHeight + 8)
    radius: Theme.radiusSm
    color: Theme.panelAccent

    Row {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 2
        anchors.rightMargin: 4
        spacing: 2

        IconButton {
            glyph: shading.expanded ? Theme.icons.chevronDown : Theme.icons.chevronRight
            variant: "ghost"
            buttonSize: 22
            iconSize: 12
            anchors.verticalCenter: parent.verticalCenter
            tooltip: shading.expanded ? qsTr("Collapse layer") : qsTr("Expand layer")
            onClicked: shading.toggleRequested()
        }
        IconGlyph {
            glyph: shading.kindGlyphs[shading.kind] || Theme.icons.layers
            iconSize: 12
            iconColor: shading.layerEnabled ? Theme.panelForeground : Theme.mutedForeground
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: (shading.kindLabels[shading.kind] || shading.kind) + " · " + (shading.paintLabels[shading.paintKind] || shading.paintKind)
            color: shading.layerEnabled ? Theme.panelForeground : Theme.mutedForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSm
            font.weight: Font.Medium
            width: Math.max(20, parent.width - 22 * 6 - 12 - 4 - parent.spacing * 7)
            elide: Text.ElideRight
            anchors.verticalCenter: parent.verticalCenter

            MouseArea {
                anchors.fill: parent
                onClicked: shading.toggleRequested()
            }
        }
        IconButton {
            glyph: Theme.icons.chevronUp
            variant: "ghost"
            buttonSize: 22
            iconSize: 12
            enabled: shading.position > 0
            tooltip: qsTr("Bring forward")
            onClicked: EditorState.moveStyleLayer(EditorState.selectedTrack, EditorState.selectedClip,
                                                 shading.layerId, shading.storedIndex + 1)
        }
        IconButton {
            glyph: Theme.icons.chevronDown
            variant: "ghost"
            buttonSize: 22
            iconSize: 12
            enabled: shading.position < shading.count - 1
            tooltip: qsTr("Send backward")
            onClicked: EditorState.moveStyleLayer(EditorState.selectedTrack, EditorState.selectedClip,
                                                 shading.layerId, shading.storedIndex - 1)
        }
        IconButton {
            glyph: shading.layerEnabled ? Theme.icons.eye : Theme.icons.eyeOff
            variant: "ghost"
            buttonSize: 22
            iconSize: 12
            tooltip: shading.layerEnabled ? qsTr("Hide layer") : qsTr("Show layer")
            onClicked: shading.setLayer({ "enabled": !shading.layerEnabled })
        }
        IconButton {
            glyph: Theme.icons.copy
            variant: "ghost"
            buttonSize: 22
            iconSize: 12
            tooltip: qsTr("Duplicate layer")
            onClicked: EditorState.duplicateStyleLayer(EditorState.selectedTrack, EditorState.selectedClip,
                                                      shading.layerId)
        }
        IconButton {
            glyph: Theme.icons.x
            variant: "ghost"
            buttonSize: 22
            iconSize: 12
            tooltip: qsTr("Remove layer")
            onClicked: EditorState.removeStyleLayer(EditorState.selectedTrack, EditorState.selectedClip,
                                                   shading.layerId)
        }
    }
}
