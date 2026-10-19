import QtQuick
import Drift

Row {
    property var row
    property int effectIndex: -1
    property var inspector
    id: hueRow
    visible: row.paramData.type === "float"
             && row.paramData.hue === true
    width: parent.width
    spacing: 8

    function currentHue() {
        const data = row.paramData
        const keys = (data.keyframes && data.keyframes.points) || []
        const deg = keys.length === 0
            ? Number(data.value)
            : EditorState.propertyValueAt(
                  EditorState.selectedTrack, EditorState.selectedClip,
                  data.prop, EditorState.playheadSeconds, data.value)
        return isNaN(deg) ? 0 : deg
    }

    Text {
        width: parent.width - 148
        elide: Text.ElideRight
        text: qsTr("Pick %1").arg(row.paramData.label)
        color: Theme.c.effectsHueParam.foregroundMuted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeXs
        anchors.verticalCenter: parent.verticalCenter
    }
    ColorSwatchField {
        anchors.verticalCenter: parent.verticalCenter
        hex: inspector.hueToHex(hueRow.currentHue())
        tooltip: qsTr("Choose %1").arg(row.paramData.label)
        onEyedropperStarted: inspector.bypassForEyedropper(effectIndex)
        onEyedropperEnded: EditorState.cancelPreviewDrag()
        onEdited: value => {
            const deg = inspector.hexToHue(value)
            // Grey has no hue; and the hex field re-emits its own
            // value on focus-out, which must not become an undo step.
            if (isNaN(deg) || Math.abs(deg - hueRow.currentHue()) < 0.01)
                return
            EditorState.beginPreviewDrag(
                qsTr("Edit %1").arg(row.paramData.label))
            EditorState.previewSetClipKeyframe(
                EditorState.selectedTrack, EditorState.selectedClip,
                row.paramData.prop, EditorState.playheadSeconds, deg)
            EditorState.commitPreviewDrag()
        }
    }
}
