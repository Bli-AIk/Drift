import QtQuick
import QtQuick.Controls.Basic
import Drift

// The app-level Settings menu: shell, the infrequent project tools, and the full Settings dialog.
// None of it needs a project, so the editor header and the start screen both offer it; each wires
// the signals to its own window.
ThemedContextMenu {
    id: root
    implicitWidth: 248

    // Multicam acts on the open timeline; the start screen has none.
    property bool projectTools: true

    signal mobileLayoutRequested()
    signal multicamRequested()
    signal moreSettingsRequested()

    // Infrequent tools. They were icon-only header buttons of their own,
    // unlabelled and easy to hit by accident next to Export.
    ThemedMenuItem {
        visible: root.projectTools
        text: qsTr("Multicam")
        icon.name: Theme.icons.shuffle
        onTriggered: root.multicamRequested()
    }

    ThemedMenuItem {
        text: qsTr("Switch to mobile layout…")
        icon.name: Theme.icons.smartphone
        onTriggered: root.mobileLayoutRequested()
    }

    ThemedMenuSeparator { }

    ThemedMenuItem {
        text: qsTr("Settings…")
        icon.name: Theme.icons.sliders
        onTriggered: root.moreSettingsRequested()
    }
}
