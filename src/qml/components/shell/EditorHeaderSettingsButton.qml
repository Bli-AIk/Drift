import QtQuick
import Drift
import QtQuick.Window

// Workspace, theme and language were three header buttons of their own.
// They share one menu now, with the rest of the preferences a step further
// in behind "More settings…".
//
// Workspace: portrait projects default to the portrait arrangement, but the
// choice stays the user's — a tall canvas on an ultrawide display is still
// comfortable in the landscape workspace, and a portrait *display* suits the
// portrait one whatever the canvas is. Picking either explicitly stops the
// canvas from driving it; "Auto" hands it back.
Item {
    id: settingsButton
    signal languageRequested()
    implicitWidth: settingsBtn.implicitWidth
    implicitHeight: settingsBtn.implicitHeight
    width: implicitWidth
    height: implicitHeight
    anchors.verticalCenter: parent.verticalCenter

    IconButton {
        id: settingsBtn
        anchors.fill: parent
        glyph: Theme.icons.settings
        variant: "ghost"
        text: qsTr("Settings")
        active: settingsMenu.opened
        tooltip: qsTr("Workspace, theme, language and more")
        onClicked: settingsMenu.popup(0, settingsButton.height + Theme.spacingMd)
    }

    ThemedContextMenu {
        id: settingsMenu
        implicitWidth: 248

        ThemedMenuItem {
            sectionHeader: true
            text: qsTr("Workspace")
        }

        // The active entry swaps its own icon for a tick rather than
        // adding a trailing column — every row keeps a glyph, so the
        // labels stay aligned.
        ThemedMenuItem {
            text: qsTr("Auto (follow canvas)")
            icon.name: EditorState.preferences.workspaceLayoutOverridden ? Theme.icons.grid
                                                             : Theme.icons.check
            onTriggered: EditorState.preferences.clearWorkspaceLayoutPreference()
        }

        ThemedMenuItem {
            text: qsTr("Landscape")
            icon.name: EditorState.preferences.workspaceLayoutOverridden
                       && EditorState.preferences.workspaceLayoutPreferred === "landscape"
                       ? Theme.icons.check : Theme.icons.monitor
            onTriggered: EditorState.preferences.setWorkspaceLayoutPreference("landscape")
        }

        ThemedMenuItem {
            text: qsTr("Portrait")
            icon.name: EditorState.preferences.workspaceLayoutOverridden
                       && EditorState.preferences.workspaceLayoutPreferred === "portrait"
                       ? Theme.icons.check : Theme.icons.smartphone
            onTriggered: EditorState.preferences.setWorkspaceLayoutPreference("portrait")
        }

        ThemedMenuSeparator { }

        ThemedMenuItem {
            sectionHeader: true
            text: qsTr("Theme")
        }

        ThemedMenuItem {
            text: qsTr("System")
            icon.name: ThemeManager.selection === "system" ? Theme.icons.check : Theme.icons.monitor
            onTriggered: ThemeManager.select("system")
        }

        ThemedMenuItem {
            text: qsTr("Light")
            icon.name: Theme.darkMode ? Theme.icons.sun : Theme.icons.check
            onTriggered: Theme.setDarkMode(false)
        }

        ThemedMenuItem {
            text: qsTr("Dark")
            icon.name: Theme.darkMode ? Theme.icons.check : Theme.icons.moon
            onTriggered: Theme.setDarkMode(true)
        }

        ThemedMenuSeparator { }

        ThemedMenuItem {
            text: qsTr("Language…")
            icon.name: Theme.icons.languages
            onTriggered: settingsButton.languageRequested()
        }

        ThemedMenuItem {
            text: qsTr("Switch to mobile layout…")
            icon.name: Theme.icons.smartphone
            onTriggered: Window.window.switchShell("mobile")
        }

        ThemedMenuSeparator { }

        // Infrequent tools. They were icon-only header buttons of their own,
        // unlabelled and easy to hit by accident next to Export.
        ThemedMenuItem {
            text: qsTr("Multicam")
            icon.name: Theme.icons.shuffle
            onTriggered: Window.window.openMulticam()
        }

        ThemedMenuItem {
            text: qsTr("Debug info…")
            icon.name: Theme.icons.bug
            onTriggered: Window.window.openDebugInfo()
        }

        ThemedMenuSeparator { }

        ThemedMenuItem {
            text: qsTr("More settings…")
            icon.name: Theme.icons.sliders
            onTriggered: Window.window.openSettings()
        }
    }
}
