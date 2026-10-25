import QtQuick
import Drift

// The phone's home for a keyframe segment's easing. The desktop opens EasingPickerPopup beside
// the key; here the picker takes the sheet, so the curve can be watched on the preview while
// it is chosen, the same way the fade sheet works.
AndroidBottomSheet {
    id: root

    title: qsTr("Easing")
    doneText: qsTr("Done")
    blocking: false
    onDoneRequested: root.dismiss()

    property int trackIndex: -1
    property int clipIndex: -1
    property string propKey: ""
    property string propLabel: ""
    property real keySeconds: 0

    function openFor(track, clip, prop, label, seconds) {
        trackIndex = track
        clipIndex = clip
        propKey = prop
        propLabel = label
        keySeconds = seconds
        if (!opened)
            open()
    }

    Connections {
        target: EditorState
        function onSelectionChanged() {
            if (EditorState.selectedTrack !== root.trackIndex || EditorState.selectedClip !== root.clipIndex)
                root.dismiss()
        }
    }

    EasingPicker {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: Theme.pagePadding + root.safeLeft
        anchors.rightMargin: Theme.pagePadding + root.safeRight
        anchors.topMargin: Theme.spacingLg
        trackIndex: root.trackIndex
        clipIndex: root.clipIndex
        propKey: root.propKey
        propLabel: root.propLabel
        keySeconds: root.keySeconds
        onCloseRequested: root.dismiss()
    }
}
