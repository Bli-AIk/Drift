import QtQuick
import Drift

SettingsSectionCard {
    title: qsTr("App")

    ThemedSwitch {
        checked: EditorState.preferences.reopenLastProject
        text: qsTr("Reopen last project on startup")
        tooltip: qsTr("Automatically restore the last open project on startup. Closing still asks you to save; a crash snapshot never overwrites your save file.")
        onToggled: EditorState.preferences.reopenLastProject = checked
    }

    Column {
        width: parent.width
        spacing: Theme.spacingLg
        visible: Updates.supported

        Rectangle {
            width: parent.width
            height: Theme.c.settingsAppSection.borderWidth
            color: Theme.c.settingsAppSection.divider
        }

        ThemedLabel {
            text: qsTr("Updates")
        }

        ThemedSwitch {
            checked: Updates.enabled
            text: qsTr("Check on startup")
            tooltip: qsTr("Once a day, check whether a newer Drift has been released")
            onToggled: Updates.enabled = checked
        }

        Row {
            width: parent.width
            spacing: Theme.spacingMd

            ThemedButton {
                id: checkNowButton
                variant: "secondary"
                glyph: Theme.icons.refresh
                text: Updates.checking ? qsTr("Checking…")
                      : Updates.downloading ? qsTr("Downloading…")
                      : qsTr("Check now")
                enabled: !Updates.checking && !Updates.downloading && !Updates.preparing
                onClicked: Updates.checkNow()
            }

            ThemedLabel {
                width: Math.max(0, parent.width - checkNowButton.width - parent.spacing)
                anchors.verticalCenter: parent.verticalCenter
                text: Updates.status.length > 0
                      ? Updates.status
                      : qsTr("Drift %1").arg(Updates.currentVersion)
            }
        }
    }

    Rectangle {
        width: parent.width
        height: Theme.c.settingsAppSection.borderWidth
        color: Theme.c.settingsAppSection.divider
    }

    ThemedLabel {
        text: qsTr("Extra packs")
    }

    ThemedSwitch {
        checked: Addons.remindEssential
        text: qsTr("Remind about essential packs")
        tooltip: qsTr("Pulse the Extras icon when the video, transitions, and audio packs are not installed")
        onToggled: Addons.remindEssential = checked
    }

    ThemedSwitch {
        checked: Addons.remindUpdates
        text: qsTr("Remind about pack updates")
        tooltip: qsTr("Pulse the Extras icon when updates are available for packs you already have installed")
        onToggled: Addons.remindUpdates = checked
    }

    Rectangle {
        width: parent.width
        height: Theme.c.settingsAppSection.borderWidth
        color: Theme.c.settingsAppSection.divider
    }

    ThemedLabel {
        text: qsTr("Agent access")
    }

    // Shared with the header's AgentAccessDialog rather than restated: the
    // cut-down copy that lived here offered only the Claude command, so a
    // switch turned on from this pane could not be connected from Cursor.
    AgentAccessControls {
        width: parent.width
        showIntro: false
    }

    Rectangle {
        width: parent.width
        height: Theme.c.settingsAppSection.borderWidth
        color: Theme.c.settingsAppSection.divider
    }

    Rectangle {
        width: parent.width
        height: Theme.c.settingsAppSection.borderWidth
        color: Theme.c.settingsAppSection.divider
    }

    ThemedLabel {
        text: qsTr("Network")
    }

    Column {
        id: proxyColumn
        width: parent.width
        spacing: Theme.spacingMd

        function saveProxy() {
            EditorState.preferences.setNetworkProxy(proxyModeCombo.model[proxyModeCombo.currentIndex].id,
                                                    proxyHostField.text, parseInt(proxyPortField.text) || 0,
                                                    proxyUserField.text, proxyPasswordField.text)
        }

        ThemedComboBox {
            id: proxyModeCombo
            width: parent.width
            textRole: "label"
            valueRole: "id"
            model: [
                { id: "system", label: qsTr("System proxy") },
                { id: "none", label: qsTr("No proxy") },
                { id: "http", label: qsTr("HTTP proxy") },
                { id: "socks5", label: qsTr("SOCKS5 proxy") }
            ]
            tooltip: qsTr("How Drift reaches the internet for downloads, updates, and online services. Applies immediately.")
            currentIndex: {
                for (var i = 0; i < model.length; ++i) {
                    if (model[i].id === EditorState.preferences.networkProxyMode)
                        return i
                }
                return 0
            }
            onActivated: proxyColumn.saveProxy()
        }

        Column {
            width: parent.width
            spacing: Theme.spacingMd
            visible: proxyModeCombo.model[proxyModeCombo.currentIndex].id === "http"
                     || proxyModeCombo.model[proxyModeCombo.currentIndex].id === "socks5"

            Row {
                width: parent.width
                spacing: Theme.spacingMd

                ThemedTextField {
                    id: proxyHostField
                    width: parent.width - proxyPortField.width - parent.spacing
                    placeholderText: qsTr("Proxy host")
                    text: EditorState.preferences.networkProxyHost
                    onEditingFinished: proxyColumn.saveProxy()
                }

                ThemedTextField {
                    id: proxyPortField
                    width: 96
                    placeholderText: qsTr("Port")
                    text: EditorState.preferences.networkProxyPort > 0 ? String(EditorState.preferences.networkProxyPort) : ""
                    onEditingFinished: proxyColumn.saveProxy()
                }
            }

            ThemedTextField {
                id: proxyUserField
                width: parent.width
                placeholderText: qsTr("Username (optional)")
                text: EditorState.preferences.networkProxyUser
                onEditingFinished: proxyColumn.saveProxy()
            }

            ThemedTextField {
                id: proxyPasswordField
                width: parent.width
                echoMode: TextInput.Password
                placeholderText: qsTr("Password (optional)")
                text: EditorState.preferences.networkProxyPassword
                onEditingFinished: proxyColumn.saveProxy()
            }
        }
    }

    ThemedLabel {
        text: qsTr("Settings file")
    }

    Row {
        width: parent.width
        spacing: Theme.spacingMd

        ThemedButton {
            variant: "secondary"
            text: qsTr("Export settings…")
            onClicked: {
                const url = FileDialogs.saveFile(qsTr("Export Settings"), [qsTr("JSON document (*.json)")],
                                                 "drift-settings", "json", "", ["application/json"])
                if (url == "")
                    return
                const error = EditorState.preferences.exportSettings(url)
                EditorState.setLastMessage(error || qsTr("Settings exported"), error ? "error" : "success")
            }
        }

        ThemedButton {
            variant: "secondary"
            text: qsTr("Import settings…")
            onClicked: {
                const url = FileDialogs.openFile(qsTr("Import Settings"), [qsTr("JSON document (*.json)")],
                                                 ["application/json"])
                if (url == "")
                    return
                const error = EditorState.preferences.importSettings(url)
                if (error)
                    EditorState.setLastMessage(error, "error")
            }
        }
    }
}
