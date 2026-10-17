import QtQuick
import Drift

Column {
    property var host
    id: colorRow
    property string prop: "fill"
    property string label: ""
    readonly property string slotKey: host.svgSlotKey(prop)
    readonly property string keyframeKey: "vector." + slotKey
    readonly property bool animated: ["r", "g", "b", "a"].some(c => host.svgKeyframeList(prop, c).length > 0)
    readonly property bool keysEnabled: {
        void host.clipDataRevision
        return !animated || EditorState.clipPropertyKeyframesEnabled(EditorState.selectedTrack, EditorState.selectedClip,
                                                                     keyframeKey + ".r")
    }
    readonly property bool overridden: host.svgSlots[slotKey] !== undefined
    readonly property string hex: {
        void host.clipDataRevision
        if (animated) {
            const t = EditorState.inspectorPlayheadSeconds
            const ch = c => EditorState.propertyValueAt(EditorState.selectedTrack, EditorState.selectedClip,
                                                        keyframeKey + "." + c, t, 0)
            return Qt.rgba(ch("r"), ch("g"), ch("b"), ch("a")).toString()
        }
        if (overridden)
            return String(host.svgSlots[slotKey])
        const own = host.svgDocumentValue(prop)
        return own.length > 0 && own !== "none" && own.indexOf("url(") < 0 ? own : "#ff000000"
    }
    width: parent.width
    spacing: 4

    function commit(value) {
        if (colorRow.animated || EditorState.autoKeyEnabled) {
            EditorState.showKeyframeGraphProperty(colorRow.keyframeKey + ".r")
            EditorState.setClipColorKeyframe(EditorState.selectedTrack, EditorState.selectedClip, colorRow.keyframeKey,
                                             EditorState.playheadSeconds, value)
        } else {
            host.setSlot(colorRow.slotKey, value)
        }
    }

    Row {
        width: parent.width
        spacing: 4
        KeyframeDiamond {
            anchors.verticalCenter: parent.verticalCenter
            accentColor: Theme.keyframeCurveColor(colorRow.keyframeKey)
            animated: colorRow.animated
            keysEnabled: colorRow.keysEnabled
            tooltip: colorRow.animated ? qsTr("Toggle %1's keyframes").arg(colorRow.label)
                                       : qsTr("Key %1 at the playhead").arg(colorRow.label)
            onToggled: {
                if (colorRow.animated) {
                    for (const c of ["r", "g", "b", "a"])
                        EditorState.toggleClipPropertyKeyframesEnabled(EditorState.selectedTrack, EditorState.selectedClip,
                                                                       colorRow.keyframeKey + "." + c)
                } else {
                    EditorState.setClipColorKeyframe(EditorState.selectedTrack, EditorState.selectedClip,
                                                     colorRow.keyframeKey, EditorState.playheadSeconds, colorRow.hex)
                }
            }
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: colorRow.label
            color: colorRow.overridden || colorRow.animated ? Theme.panelForeground : Theme.mutedForeground
            font.pixelSize: Theme.fontSizeXs
            font.family: Theme.fontFamily
        }
        Item { width: 1; height: 1 }
    }
    Row {
        width: parent.width
        spacing: 4
        ColorSwatchField {
            width: parent.width - resetButton.width - parent.spacing
            hex: colorRow.hex
            tooltip: qsTr("Override the %1 colour").arg(colorRow.label.toLowerCase())
            onEdited: value => colorRow.commit(value)
        }
        IconButton {
            id: resetButton
            glyph: Theme.icons.x
            variant: "ghost"
            buttonSize: Theme.controlHeightSm
            iconSize: 12
            anchors.verticalCenter: parent.verticalCenter
            enabled: colorRow.overridden || colorRow.animated
            tooltip: qsTr("Back to the drawing's own %1").arg(colorRow.label.toLowerCase())
            onClicked: host.setSlot(colorRow.slotKey, null)
        }
    }
}
