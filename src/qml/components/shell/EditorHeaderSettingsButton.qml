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

    AppSettingsMenu {
        id: settingsMenu
        onLanguageRequested: settingsButton.languageRequested()
        onMobileLayoutRequested: Window.window.switchShell("mobile")
        onMulticamRequested: Window.window.openMulticam()
        onDebugInfoRequested: Window.window.openDebugInfo()
        onMoreSettingsRequested: Window.window.openSettings()
    }
}
