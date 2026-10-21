import QtQuick
import Drift

Column {
    id: root

    property var row
    property int effectIndex: -1
    spacing: 4
    width: parent ? parent.width : implicitWidth
    visible: row && row.paramData.type === "curve"

    readonly property var points: {
        let v = row ? row.paramData.value : null
        if (typeof v === "string") {
            try {
                v = JSON.parse(v)
            } catch (e) {
                v = null
            }
        }
        return Array.isArray(v) && v.length >= 2
            ? v : [{x: 0, y: 0, ease: "spline"}, {x: 1, y: 1, ease: "spline"}]
    }

    Text {
        width: parent.width
        elide: Text.ElideRight
        text: root.row ? root.row.paramData.label : ""
        color: Theme.mutedForeground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeXs
    }

    CurveEditor {
        visible: root.visible
        width: Math.min(parent.width, 260)
        showTabs: false
        curves: ({ master: root.points, r: root.points, g: root.points, b: root.points })
        onBegan: EditorState.beginPreviewDrag(qsTr("Edit %1").arg(root.row.paramData.label))
        onChanged: (channel, json) => EditorState.previewSetEffectTextParam(
                       EditorState.selectedTrack, EditorState.selectedClip,
                       root.effectIndex, root.row.paramData.key, json)
        onEnded: EditorState.commitPreviewDrag()
    }
}
