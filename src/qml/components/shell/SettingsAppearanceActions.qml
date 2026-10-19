import QtQuick
import Drift

// Import, export, and the hot-reload switch. Folder import is desktop-only;
// Android's picker has no directory mode.
Column {
    id: root

    width: parent ? parent.width : 0
    spacing: Theme.spacingMd

    readonly property bool userThemeSelected: ThemeManager.selection !== "system"
                                               && ThemeManager.selection !== "dark"
                                               && ThemeManager.selection !== "light"

    function importUrl(url) {
        if (!url || String(url) === "")
            return ""
        const id = ThemeManager.importTheme(url)
        if (!id) {
            Toasts.error(ThemeManager.lastError || qsTr("Could not import that theme."))
            return ""
        }
        Toasts.success(qsTr("Imported “%1”.").arg(id))
        return id
    }

    Flow {
        width: parent.width
        spacing: Theme.spacingMd

        ThemedButton {
            text: qsTr("Import theme…")
            onClicked: {
                const url = FileDialogs.openFile(qsTr("Import Theme"),
                                                  [qsTr("Themes (*.json *.zip)")])
                const id = root.importUrl(url)
                if (id)
                    root.imported(id)
            }
        }

        ThemedButton {
            visible: FileDialogs.supportsDirectoryPicker()
            text: qsTr("Import folder…")
            onClicked: {
                const url = FileDialogs.openDirectory(qsTr("Import Theme Folder"),
                                                       ThemeManager.themesFolderUrl())
                const id = root.importUrl(url)
                if (id)
                    root.imported(id)
            }
        }

        ThemedButton {
            text: qsTr("Open themes folder")
            variant: "secondary"
            onClicked: Qt.openUrlExternally(ThemeManager.themesFolderUrl())
        }

        ThemedButton {
            text: qsTr("Export current theme…")
            variant: "secondary"
            onClicked: {
                const url = FileDialogs.saveFile(qsTr("Export Theme"),
                                                  [qsTr("JSON theme (*.json)")],
                                                  ThemeManager.currentTheme,
                                                  "json")
                if (!url || String(url) === "")
                    return
                if (!ThemeManager.exportTheme(url))
                    Toasts.error(ThemeManager.lastError || qsTr("Could not export this theme."))
                else
                    Toasts.success(qsTr("Exported the current theme."))
            }
        }

        ThemedButton {
            enabled: root.userThemeSelected
            text: qsTr("Remove")
            variant: "destructive"
            onClicked: confirmRemove.open()
        }
    }

    ThemedSwitch {
        checked: ThemeManager.hotReload
        text: qsTr("Reload themes when files change")
        tooltip: qsTr("Watches the selected user theme and applies edits when its files change. Built-in themes are not watched.")
        onToggled: ThemeManager.hotReload = checked
    }

    Text {
        width: parent.width
        visible: root.userThemeSelected === false && ThemeManager.hotReload
        text: qsTr("Hot reload applies the next time a user theme is selected.")
        color: Theme.c.settingsAppearanceActions.foreground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeXs
        wrapMode: Text.WordWrap
    }

    signal imported(string themeId)

    Item {
        visible: false
        ThemedDialog {
            id: confirmRemove
            title: qsTr("Remove theme?")
            acceptText: qsTr("Remove")
            acceptVariant: "destructive"
            rejectText: qsTr("Cancel")
            preferredWidth: Theme.dialogWidthSm
            onAccepted: {
                const name = ThemeManager.selection
                if (!ThemeManager.removeTheme(name))
                    Toasts.error(ThemeManager.lastError || qsTr("Could not remove that theme."))
                else
                    Toasts.success(qsTr("Removed “%1”.").arg(name))
            }

            contentItem: ThemedLabel {
                width: parent ? parent.width : Theme.dialogWidthSm
                wrapMode: Text.WordWrap
                size: "sm"
                text: qsTr("Remove “%1” from this device? Its files are deleted.")
                      .arg(ThemeManager.selection)
            }
        }
    }
}
