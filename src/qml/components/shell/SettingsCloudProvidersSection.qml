import QtQuick
import Drift

Column {
    width: parent.width
    spacing: Theme.spacingXl

    ThemedLabel {
        width: parent.width
        wrapMode: Text.Wrap
        color: Theme.c.settingsCloudProvidersSection.foregroundMuted
        text: qsTr("Keys are stored unencrypted in Drift's settings. ELEVENLABS_API_KEY and FISH_API_KEY in the environment take precedence. Use is billed to your own account.")
    }

    Repeater {
        model: [
            { id: "elevenlabs", name: "ElevenLabs",
              uses: qsTr("Transcription (Scribe), voiceover, sound effects") },
            { id: "fish", name: "Fish Audio", uses: qsTr("Voiceover") }
        ]

        delegate: Column {
            id: provider
            required property var modelData
            readonly property var cloud: EditorState.cloudProviders
            readonly property int rev: cloud.revision
            property string testMessage: ""

            width: parent.width
            spacing: Theme.spacingMd

            Rectangle {
                width: parent.width
                height: Theme.c.settingsCloudProvidersSection.borderWidth
                color: Theme.c.settingsCloudProvidersSection.divider
            }

            ThemedLabel {
                width: parent.width
                text: provider.modelData.name + " — " + provider.modelData.uses
            }

            ThemedLabel {
                width: parent.width
                color: Theme.c.settingsCloudProvidersSection.foregroundMuted
                text: {
                    void provider.rev
                    if (!provider.cloud.configured(provider.modelData.id))
                        return qsTr("No key")
                    if (provider.cloud.keyFromEnvironment(provider.modelData.id))
                        return qsTr("Key from the environment")
                    return qsTr("Key %1").arg(provider.cloud.maskedKey(provider.modelData.id))
                }
            }

            Row {
                width: parent.width
                spacing: Theme.spacingMd

                ThemedTextField {
                    id: keyField
                    width: parent.width - saveKey.width - testKey.width - clearKey.width - 3 * parent.spacing
                    echoMode: TextInput.Password
                    placeholderText: qsTr("Paste API key")
                }
                ThemedButton {
                    id: saveKey
                    variant: "secondary"
                    text: qsTr("Save")
                    enabled: keyField.text.trim().length > 0
                    onClicked: {
                        provider.cloud.setApiKey(provider.modelData.id, keyField.text)
                        keyField.text = ""
                        provider.testMessage = ""
                    }
                }
                ThemedButton {
                    id: testKey
                    variant: "ghost"
                    text: qsTr("Test")
                    enabled: { void provider.rev; return provider.cloud.configured(provider.modelData.id) }
                    onClicked: {
                        provider.testMessage = qsTr("Checking…")
                        provider.cloud.testKey(provider.modelData.id)
                    }
                }
                ThemedButton {
                    id: clearKey
                    variant: "ghost"
                    text: qsTr("Clear")
                    enabled: { void provider.rev; return provider.cloud.configured(provider.modelData.id)
                                                 && !provider.cloud.keyFromEnvironment(provider.modelData.id) }
                    onClicked: {
                        provider.cloud.setApiKey(provider.modelData.id, "")
                        provider.testMessage = ""
                    }
                }
            }

            ThemedLabel {
                width: parent.width
                visible: provider.testMessage.length > 0
                text: provider.testMessage
                color: Theme.c.settingsCloudProvidersSection.foregroundMuted
            }

            Connections {
                target: provider.cloud
                function onKeyTested(id, ok, message) {
                    if (id === provider.modelData.id)
                        provider.testMessage = message
                }
            }

            ThemedSwitch {
                checked: { void provider.rev; return provider.cloud.consent(provider.modelData.id) }
                text: qsTr("Allow sending audio and text to %1").arg(provider.modelData.name)
                tooltip: qsTr("Needed before Drift or a connected agent can transcribe or generate audio with this service")
                onToggled: provider.cloud.setConsent(provider.modelData.id, checked)
            }

            ThemedTextField {
                width: parent.width
                placeholderText: qsTr("Default voice id")
                text: { void provider.rev; return provider.cloud.setting(provider.modelData.id, "voice") }
                onEditingFinished: provider.cloud.setSetting(provider.modelData.id, "voice", text)
            }

            ThemedTextField {
                width: parent.width
                placeholderText: qsTr("Voice model")
                text: { void provider.rev; return provider.cloud.setting(provider.modelData.id, "tts_model") }
                onEditingFinished: provider.cloud.setSetting(provider.modelData.id, "tts_model", text)
            }

            ThemedTextField {
                width: parent.width
                visible: provider.modelData.id === "elevenlabs"
                placeholderText: qsTr("Transcription model")
                text: { void provider.rev; return provider.cloud.setting(provider.modelData.id, "stt_model") }
                onEditingFinished: provider.cloud.setSetting(provider.modelData.id, "stt_model", text)
            }
        }
    }
}
