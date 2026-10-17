import QtQuick
import Drift

SettingsSectionCard {
    title: qsTr("Preview")

    ThemedSwitch {
        checked: EditorState.preview.guidesEnabled
        text: qsTr("Show guides")
        tooltip: qsTr("Show alignment guides over the preview")
        onToggled: EditorState.preview.guidesEnabled = checked
    }

    Repeater {
        model: EditorState.preview.guidesEnabled ? EditorState.guideSets : []

        ThemedCheckBox {
            required property var modelData
            width: parent.width
            text: modelData.name
            checked: modelData.active
            onToggled: EditorState.setGuideSetActive(modelData.id, checked)
        }
    }

    ThemedLabel {
        text: qsTr("Background")
    }

    ThemedComboBox {
        id: bgKindCombo
        width: parent.width
        textRole: "label"
        valueRole: "id"
        model: [
            { id: "color", label: qsTr("Solid color") },
            { id: "blur", label: qsTr("Blur") },
            { id: "transparent", label: qsTr("Transparent") }
        ]
        tooltip: qsTr("Fill behind clips that don’t cover the whole screen")
        currentIndex: {
            for (var i = 0; i < model.length; ++i) {
                if (model[i].id === EditorState.projectFile.background.kind)
                    return i
            }
            return 0
        }
        onActivated: EditorState.projectFile.setBackground({ kind: model[currentIndex].id })
    }

    ColorSwatchField {
        visible: EditorState.projectFile.background.kind === "color"
        hex: EditorState.projectFile.background.color || "#ff000000"
        tooltip: qsTr("Choose background colour")
        onEdited: value => EditorState.projectFile.setBackground({ kind: "color", color: value })
    }

    Column {
        width: parent.width
        spacing: Theme.spacingSm
        visible: EditorState.projectFile.background.kind === "blur"

        ThemedSlider {
            width: parent.width
            label: qsTr("Blur strength")
            from: 1
            to: 100
            stepSize: 1
            valueFormatter: function (v) { return Math.round(v) }
            value: EditorState.projectFile.background.blurStrength || 20
            onPressedChanged: {
                if (!pressed)
                    EditorState.projectFile.setBackground({ kind: "blur", blurStrength: value })
            }
        }
    }

    ThemedSwitch {
        checked: EditorState.playback.useProxies
        text: qsTr("Use proxies for preview")
        tooltip: qsTr("Play clips from their low-resolution proxies where one exists. Export always uses the original media.")
        onToggled: EditorState.playback.useProxies = checked
    }

    ThemedLabel {
        text: qsTr("Proxy resolution")
    }

    ThemedComboBox {
        width: parent.width
        textRole: "label"
        valueRole: "id"
        model: [
            { id: 360, label: qsTr("360p") },
            { id: 540, label: qsTr("540p") },
            { id: 720, label: qsTr("720p") },
            { id: 1080, label: qsTr("1080p") }
        ]
        tooltip: qsTr("Size of new proxies. Proxies made at another size are not used until you create them again.")
        currentIndex: {
            for (var i = 0; i < model.length; ++i) {
                if (model[i].id === EditorState.playback.proxySize)
                    return i
            }
            return 2
        }
        onActivated: EditorState.playback.proxySize = model[currentIndex].id
    }

    ThemedLabel {
        text: qsTr("Proxy name patterns")
    }

    ThemedLabel {
        width: parent.width
        wrapMode: Text.WordWrap
        text: qsTr("Linking a proxy teaches Drift its name pattern. Proxies next to your media that match a pattern below link automatically.")
        color: Theme.c.settingsPreviewSection.foreground
    }

    Repeater {
        model: EditorState.preferences.proxyNamePatterns

        Row {
            id: patternRow
            required property string modelData
            width: parent.width
            spacing: Theme.spacingSm

            ThemedLabel {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - removePattern.width - parent.spacing
                text: patternRow.modelData
                font.family: Theme.monoFontFamily
                elide: Text.ElideMiddle
            }
            ThemedButton {
                id: removePattern
                anchors.verticalCenter: parent.verticalCenter
                variant: "ghost"
                glyph: Theme.icons.x
                tooltip: qsTr("Remove pattern")
                onClicked: EditorState.preferences.proxyNamePatterns =
                    EditorState.preferences.proxyNamePatterns.filter(p => p !== patternRow.modelData)
            }
        }
    }

    ThemedButton {
        variant: "secondary"
        text: qsTr("Reset to defaults")
        onClicked: EditorState.preferences.resetProxyNamePatterns()
    }

    ThemedSwitch {
        visible: EditorState.preferences.vaapiZeroCopySupported
        checked: EditorState.preferences.vaapiZeroCopy
        text: qsTr("Faster preview (experimental)")
        tooltip: qsTr("Can make playback smoother by keeping video on the graphics card. Turn it off if the picture looks wrong. Takes effect after restart.")
        onToggled: EditorState.preferences.vaapiZeroCopy = checked
    }

    // Same wording as the VAAPI switch above: only one of the two is ever visible,
    // since each is supported on exactly the platform the other is not.
    ThemedSwitch {
        visible: EditorState.preferences.mediaCodecZeroCopySupported
        checked: EditorState.preferences.mediaCodecZeroCopy
        text: qsTr("Faster preview (experimental)")
        tooltip: qsTr("Can make playback smoother by keeping video on the graphics card. Turn it off if the picture looks wrong. Takes effect after restart.")
        onToggled: EditorState.preferences.mediaCodecZeroCopy = checked
    }

    ThemedLabel {
        visible: EditorState.preferences.gpuPreferenceSupported
        text: qsTr("Graphics card")
    }

    ThemedComboBox {
        visible: EditorState.preferences.gpuPreferenceSupported
        width: parent.width
        textRole: "label"
        valueRole: "id"
        model: [
            { id: "auto", label: qsTr("Windows default") },
            { id: "integrated", label: qsTr("Power saving (integrated GPU)") },
            { id: "discrete", label: qsTr("High performance (discrete GPU)") }
        ]
        tooltip: qsTr("Which graphics card Drift runs on. High performance keeps video decoded on an NVIDIA card on that card; power saving uses less battery. Takes effect after restart.")
        currentIndex: {
            for (var i = 0; i < model.length; ++i) {
                if (model[i].id === EditorState.preferences.preferredGpu)
                    return i
            }
            return 0
        }
        onActivated: EditorState.preferences.preferredGpu = model[currentIndex].id
    }

    ThemedLabel {
        visible: EditorState.preferences.gpuPreferenceInSystemSettings
        text: qsTr("Graphics card")
    }

    ThemedLabel {
        visible: EditorState.preferences.gpuPreferenceInSystemSettings
        width: parent.width
        text: qsTr("Choose which graphics card Drift runs on in Windows Settings, under "
                   + "Display > Graphics. Takes effect after restart.")
    }

    ThemedButton {
        visible: EditorState.preferences.gpuPreferenceInSystemSettings
        variant: "secondary"
        text: qsTr("Open graphics settings")
        onClicked: Qt.openUrlExternally("ms-settings:display-advancedgraphics")
    }
}
