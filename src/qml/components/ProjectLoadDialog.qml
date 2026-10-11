import QtQuick
import QtQuick.Controls.Basic
import Drift

// Modal for the whole of a project open: nothing else may touch the document until the load
// lands or fails, and there is no cancel.
ThemedDialog {
    id: root

    title: qsTr("Opening project")
    preferredWidth: 360
    showFooter: false
    closePolicy: Popup.NoAutoClose

    Connections {
        target: EditorState.projectFile
        function onProjectLoadPendingChanged() {
            if (EditorState.projectFile.projectLoadPending)
                root.open()
            else
                root.close()
        }
    }

    contentItem: Column {
        spacing: Theme.spacing2xl - Theme.spacingXs
        width: parent ? parent.width : 328

        LabelledProgressRing {
            width: parent.width
            value: EditorState.projectFile.projectLoadProgress
            indeterminate: EditorState.projectFile.projectLoadProgress <= 0
        }

        ThemedLabel {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            size: "xs"
            wrapMode: Text.WordWrap
            text: qsTr("Unpacking project media…")
            visible: EditorState.projectFile.projectLoadProgress > 0
        }
    }
}
