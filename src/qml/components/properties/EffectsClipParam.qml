import QtQuick
import Drift

Column {
    property var row
    property int effectIndex: -1
    property var inspector
    id: clipParam
    visible: row.paramData.type === "clip"
    width: parent.width
    spacing: 4
    readonly property var candidates: {
        void inspector.clipDataRevision
        return row.paramData.type === "clip"
            ? EditorState.effectClipCandidates(EditorState.selectedTrack,
                                               EditorState.selectedClip)
            : []
    }

    Text {
        width: parent.width
        elide: Text.ElideRight
        text: row.paramData.label
        color: Theme.c.effectsClipParam.foregroundMuted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeXs
    }
    ThemedComboBox {
        width: parent.width
        model: [qsTr("Automatic (clip beneath)")].concat(
                   clipParam.candidates.map(c => c.name))
        currentIndex: {
            const id = row.paramData.value || ""
            for (let i = 0; i < clipParam.candidates.length; i++) {
                if (clipParam.candidates[i].id === id)
                    return i + 1
            }
            return 0
        }
        onActivated: (index) => EditorState.setEffectClipParam(
            EditorState.selectedTrack, EditorState.selectedClip,
            effectIndex, row.paramData.key,
            index === 0 ? "" : clipParam.candidates[index - 1].id)
    }
}
