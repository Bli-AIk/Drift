import QtQuick
import Drift
import QtQuick.Window

SettingsSectionCard {
    title: qsTr("Interface")

    ThemedLabel {
        text: qsTr("Size")
    }

    ThemedComboBox {
        width: parent.width
        textRole: "label"
        valueRole: "id"
        model: [
            { id: 1.0,  label: qsTr("100% (system)") },
            { id: 1.25, label: "125%" },
            { id: 1.5,  label: "150%" },
            { id: 1.75, label: "175%" },
            { id: 2.0,  label: "200%" }
        ]
        tooltip: qsTr("Makes buttons, text, and icons larger. This is extra scale on top of the size already set in your display settings. Takes effect after restart.")
        currentIndex: {
            const opts = model
            for (var i = 0; i < opts.length; ++i) {
                if (Math.abs(opts[i].id - EditorState.preferences.uiScale) < 0.001)
                    return i
            }
            return 0
        }
        onActivated: {
            if (currentIndex >= 0 && currentIndex < model.length)
                EditorState.preferences.uiScale = model[currentIndex].id
        }
    }

    ThemedLabel {
        width: parent.width
        visible: EditorState.preferences.uiScaleNeedsRestart
        text: qsTr("Restart Drift to apply this size.")
        color: Theme.panelSecondaryForeground
    }

    ThemedLabel {
        text: qsTr("Layout")
    }

    ThemedComboBox {
        width: parent.width
        textRole: "label"
        valueRole: "id"
        model: [
            { id: "auto",    label: qsTr("Automatic") },
            { id: "desktop", label: qsTr("Desktop") },
            { id: "mobile",  label: qsTr("Mobile") }
        ]
        tooltip: qsTr("Desktop suits a mouse and keyboard, including tablets in desktop mode. Mobile is the touch layout made for phones. Takes effect after restart.")
        currentIndex: {
            const opts = model
            for (var i = 0; i < opts.length; ++i) {
                if (opts[i].id === EditorState.preferences.interfaceShell)
                    return i
            }
            return 0
        }
        onActivated: {
            if (currentIndex >= 0 && currentIndex < model.length)
                EditorState.preferences.interfaceShell = model[currentIndex].id
        }
    }

    ThemedLabel {
        width: parent.width
        visible: EditorState.preferences.interfaceShellNeedsRestart
        text: qsTr("Restart Drift to switch layouts.")
        color: Theme.panelSecondaryForeground
    }

    ThemedButton {
        visible: EditorState.preferences.interfaceShellNeedsRestart
                 && EditorState.preferences.canRestart
        variant: "secondary"
        text: qsTr("Restart now")
        onClicked: Window.window.restartToApplyShell()
    }

    ThemedSwitch {
        visible: !Theme.touchUi
        checked: EditorState.preferences.invertTimelineScroll
        text: qsTr("Horizontal mouse-wheel pan")
        tooltip: qsTr("Scroll pans left and right along the timeline. Shift+scroll moves between tracks. Middle-click drag also pans.")
        onToggled: EditorState.preferences.invertTimelineScroll = checked
    }

    ThemedSwitch {
        visible: Haptics.supported
        checked: Haptics.enabled
        text: qsTr("Haptic feedback")
        tooltip: qsTr("Vibrate on taps, snaps, and edits. Uses this device’s own haptic effects when it has them.")
        onToggled: Haptics.enabled = checked
    }

    ThemedLabel {
        visible: Theme.touchUi
        text: qsTr("Language")
    }

    ThemedComboBox {
        width: parent.width
        visible: Theme.touchUi
        textRole: "label"
        valueRole: "id"
        model: EditorState.preferences.uiLanguages
        tooltip: qsTr("Language for menus and labels. Takes effect immediately.")
        currentIndex: {
            const langs = EditorState.preferences.uiLanguages
            for (var i = 0; i < langs.length; ++i) {
                if (langs[i].id === EditorState.preferences.uiLanguage)
                    return i
            }
            return 0
        }
        onActivated: {
            const langs = EditorState.preferences.uiLanguages
            if (currentIndex >= 0 && currentIndex < langs.length)
                EditorState.preferences.uiLanguage = langs[currentIndex].id
        }
    }
}
