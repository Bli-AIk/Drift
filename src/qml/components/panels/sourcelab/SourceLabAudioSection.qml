import QtQuick
import Drift

SourceLabSection {
    id: root

    readonly property var lab: EditorState.sourceLab
    readonly property var recipe: root.lab.recipe
    readonly property real lufs: root.recipe.normalizeLufs ?? NaN
    readonly property bool normalizing: !isNaN(root.lufs)
    readonly property var presets: [
        { label: qsTr("-14 LUFS (streaming)"), value: -14 },
        { label: qsTr("-16 LUFS"), value: -16 },
        { label: qsTr("-23 LUFS (broadcast)"), value: -23 },
        { label: qsTr("Custom"), value: NaN }
    ]
    property bool customTarget: false
    readonly property int presetIndex: {
        if (!root.normalizing)
            return 0
        const i = root.presets.findIndex(p => p.value === root.lufs)
        return root.customTarget || i < 0 ? 3 : i
    }

    title: qsTr("Audio")
    dirty: (root.recipe.gainDb ?? 0) !== 0 || root.normalizing || (root.recipe.denoise ?? false)
    onResetRequested: {
        root.customTarget = false
        root.lab.resetRecipe("audio")
    }

    SourceLabSliderRow {
        label: qsTr("Gain")
        value: root.recipe.gainDb ?? 0
        from: -24
        to: 24
        decimals: 1
        step: 0.5
        unit: "dB"
        detents: [0]
        onMoved: v => root.lab.setRecipeValue("gainDb", v)
    }

    Row {
        width: parent.width
        spacing: Theme.spacingMd

        ThemedSwitch {
            id: normalizeSwitch
            anchors.verticalCenter: parent.verticalCenter
            text: qsTr("Normalize")
            checked: root.normalizing
            onToggled: {
                if (!checked)
                    root.customTarget = false
                root.lab.setRecipeValue("normalizeLufs", checked ? -14 : null)
            }
        }
        ThemedComboBox {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - normalizeSwitch.width - parent.spacing
            enabled: root.normalizing
            model: root.presets
            textRole: "label"
            currentIndex: root.presetIndex
            onActivated: index => {
                const preset = root.presets[index]
                root.customTarget = isNaN(preset.value)
                if (!root.customTarget)
                    root.lab.setRecipeValue("normalizeLufs", preset.value)
            }
        }
    }

    SourceLabSliderRow {
        visible: root.normalizing && root.presetIndex === 3
        label: qsTr("Target")
        value: root.normalizing ? root.lufs : -14
        from: -40
        to: -5
        decimals: 1
        step: 0.5
        unit: "LUFS"
        onMoved: v => root.lab.setRecipeValue("normalizeLufs", v)
    }

    ThemedSwitch {
        text: qsTr("Reduce noise")
        checked: root.recipe.denoise ?? false
        enabled: root.lab.denoiseAvailable
        tooltip: root.lab.denoiseAvailable ? "" : qsTr("The noise-removal model is not installed")
        onToggled: root.lab.setRecipeValue("denoise", checked)
    }
}
