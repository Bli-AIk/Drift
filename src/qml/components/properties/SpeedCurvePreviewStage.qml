import QtQuick
import Drift

Rectangle {
    id: root
    property Item transportItem: null
    property Item stripItem: null
    property Item toolbarItem: null
    property Item graphItem: null
    width: parent.width
    height: parent.height - transportItem.height - stripItem.height - toolbarItem.height - graphItem.height
            - Theme.spacingMd * 4
    radius: Theme.radiusMd
    color: Theme.panelBackground

    Image {
        anchors.centerIn: parent
        width: Math.min(parent.width, parent.height * root.aspect)
        height: width / root.aspect
        fillMode: Image.PreserveAspectFit
        cache: false
        // The revision defeats QML's URL-keyed cache; the pixels behind this URL change
        // on every pump tick.
        source: EditorState.speedCurve.active
                ? "image://clippreview/frame?rev=" + EditorState.speedCurve.revision
                : ""
    }

    readonly property real aspect: EditorState.speedCurve.frameSize.height > 0
        ? EditorState.speedCurve.frameSize.width / EditorState.speedCurve.frameSize.height
        : 16 / 9

    ThemedLabel {
        anchors.centerIn: parent
        tone: "muted"
        visible: EditorState.speedCurve.frameSize.width <= 0
        text: qsTr("Audio only")
    }
}
