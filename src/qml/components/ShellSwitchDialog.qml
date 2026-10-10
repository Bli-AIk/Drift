import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Window
import Drift

// Confirms a switch between the desktop and mobile layouts. Shell.qml only builds a shell at
// startup, so switching means a restart; the choice is stored first, so "Later" still applies it
// on the next launch. Shared by the menu entries in both shells and the Android mouse prompt.
ThemedDialog {
    id: root

    // "desktop" or "mobile"
    property string target: "desktop"
    // Set for the mouse prompt, which offers the switch rather than confirming one already asked for.
    property bool offered: false

    title: target === "mobile" ? qsTr("Switch to the mobile layout?")
                               : qsTr("Switch to the desktop layout?")
    acceptText: EditorState.preferences.canRestart ? qsTr("Restart now") : qsTr("Switch")
    rejectText: offered ? qsTr("Not now") : qsTr("Later")
    preferredWidth: 420

    function openFor(shell, isOffer) {
        target = shell
        offered = !!isOffer
        open()
    }

    onAccepted: {
        EditorState.preferences.interfaceShell = target
        if (EditorState.preferences.canRestart)
            root.contentItem.Window.window.restartToApplyShell()
        else
            Toasts.info(qsTr("Restart Drift to switch layouts."))
    }
    onRejected: {
        if (!offered)
            EditorState.preferences.interfaceShell = target
    }

    contentItem: ThemedLabel {
        width: parent ? parent.width : 380
        size: "sm"
        wrapMode: Text.WordWrap
        text: {
            if (root.offered)
                return qsTr("A mouse is connected. The desktop layout has full menus, panels and precise timeline editing. Drift restarts to switch, and your project is kept.")
            if (root.target === "mobile")
                return qsTr("The mobile layout is the touch interface made for phones. Drift restarts to switch.")
            return qsTr("The desktop layout suits a mouse and keyboard. Drift restarts to switch.")
        }
    }
}
