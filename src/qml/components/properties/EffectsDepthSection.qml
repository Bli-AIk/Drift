import QtQuick
import Drift

Column {
    property int clipDataRevision: 0
    id: depthSection
    visible: depthSection.usesDepthEffect
    width: parent.width
    spacing: Theme.spacingSm

    readonly property var hostData: {
        void clipDataRevision
        return EditorState.selectedClipData || ({})
    }
    readonly property bool usesDepthEffect: {
        void clipDataRevision
        const effects = EditorState.selectedClipEffects || []
        for (let i = 0; i < effects.length; i++) {
            if (effects[i].needsDepth === true)
                return true
        }
        return false
    }

    Text {
        width: parent.width
        text: qsTr("Depth")
        color: Theme.c.effectsDepthSection.foregroundMuted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeXs
    }

    EffectsDepthPanel {
        width: parent.width
        // The media clip the depth belongs to; the selection may be the adjustment pinned
        // to it, which depth estimation redirects through.
        targetTrack: EditorState.selectedTrack
        targetClip: EditorState.selectedClip
        targetId: depthSection.hostData.depthClipId || ""
        hasDepth: depthSection.hostData.hasDepth === true
        canDepth: depthSection.hostData.canDepth === true
        cannotText: qsTr("Depth effects follow one clip's depth. Add this to a clip rather than to an adjustment layer.")
        missingText: qsTr("These effects need the clip's depth, so it has to be estimated first. It runs in the background and takes roughly half a second per frame.")
    }
}
