import QtQuick
import Drift

Column {
    property var row
    property int effectIndex: -1
    property var inspector
    id: faceChoice
    readonly property bool isFace: row.paramData.type === "float"
                                   && row.paramData.key === "faceIndex"
    readonly property int current: Math.round(Number(row.paramData.value) || 0)
    readonly property int count: {
        void inspector.clipDataRevision
        const data = EditorState.selectedClipData
        const faces = data ? (data.faceTrackFaceCount || 0) : 0
        const most = Math.round(row.paramData.max || 0) + 1
        return Math.min(most, Math.max(faces, current + 1))
    }
    visible: isFace && count > 1
    width: parent.width
    spacing: 4
    Text {
        text: row.paramData.label
        color: Theme.mutedForeground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeXs
    }
    Flow {
        width: parent.width
        spacing: 6
        Repeater {
            model: faceChoice.isFace ? faceChoice.count : 0
            delegate: ThemedChip {
                required property int index
                text: String(index + 1)
                variant: "outline"
                selected: faceChoice.current === index
                tooltip: qsTr("Face %1").arg(index + 1)
                onClicked: EditorState.setEffectParam(
                               EditorState.selectedTrack, EditorState.selectedClip,
                               effectIndex, row.paramData.key, index)
            }
        }
    }
}
