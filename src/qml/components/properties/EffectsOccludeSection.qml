import QtQuick
import Drift

Column {
    property var card
    property var inspector
    id: occludeSection
    readonly property bool isOcclude: card.effectData.catalogId === "depth.occlude"
    visible: isOcclude
    width: parent.width
    spacing: Theme.spacingSm
    opacity: card.effectEnabled ? 1 : 0.45
    readonly property var target: {
        void inspector.clipDataRevision
        if (!occludeSection.isOcclude)
            return ({})
        void EditorState.inspectorPlayheadSeconds
        return EditorState.effectClipTarget(EditorState.selectedTrack,
                                            EditorState.selectedClip,
                                            card.index, "target")
    }
    readonly property string targetName: target.name || ""

    Text {
        width: parent.width
        wrapMode: Text.WordWrap
        visible: !!occludeSection.target.id
        text: occludeSection.target.explicit
              ? qsTr("Anything in “%1” nearer than Distance passes in front of this layer.")
                    .arg(occludeSection.targetName)
              : qsTr("Anything in “%1” (the clip beneath at the playhead) nearer than Distance passes in front of this layer.")
                    .arg(occludeSection.targetName)
        color: Theme.c.effectsOccludeSection.foregroundMuted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeXs
    }

    EffectsDepthPanel {
        width: parent.width
        targetTrack: occludeSection.target.track !== undefined ? occludeSection.target.track : -1
        targetClip: occludeSection.target.clip !== undefined ? occludeSection.target.clip : -1
        targetId: occludeSection.target.id || ""
        hasDepth: occludeSection.target.hasDepth === true
        canDepth: !!occludeSection.target.id
        cannotText: qsTr("Place this layer above a video or image clip. It goes behind whatever in that clip is nearer than Distance.")
        missingText: qsTr("“%1” needs its depth estimated before anything in it can pass in front. It runs in the background and takes roughly half a second per frame.")
                         .arg(occludeSection.targetName)
    }
}
