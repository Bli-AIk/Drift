import QtQuick
import Drift

Row {
    id: actions
    signal newProjectRequested()
    signal openProjectRequested()
    width: parent.width
    spacing: Theme.spacingLg

    ThemedButton {
        variant: "primary"
        glyph: Theme.icons.plus
        text: qsTr("New Project")
        onClicked: actions.newProjectRequested()
    }

    ThemedButton {
        variant: "secondary"
        glyph: Theme.icons.folder
        text: qsTr("Open Project…")
        onClicked: actions.openProjectRequested()
    }
}
