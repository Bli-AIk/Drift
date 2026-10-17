import QtQuick
import QtQuick.Controls.Basic
import Drift
// Effect stacks the user saved from the effects inspector or the timeline clip menu. Lives beside
// the built-in effect templates because those are multi-effect stacks too — and because a saved
// stack can span video *and* audio effects, which the video-only effects browser has no room for.
Item {
    id: root

    // A QVariantList from an invokable is not reactive, so the section is refreshed by poking this
    // counter from the controller's signal.
    property int presetsTick: 0
    readonly property var presets: {
        void root.presetsTick
        return EditorState.userEffectPresets()
    }

    Connections {
        target: EditorState
        function onUserEffectPresetsChanged() { root.presetsTick++ }
    }

    readonly property string stackFileFilter: qsTr("Drift effect stack (*.drifteffects)")

    function importStack() {
        const url = FileDialogs.openFile(qsTr("Import effect stack"), [root.stackFileFilter])
        if (url.toString().length > 0)
            EditorState.importUserEffectPreset(url)
    }

    function exportStack(preset) {
        const url = FileDialogs.saveFile(qsTr("Export effect stack"), [root.stackFileFilter],
                                         preset.label, "drifteffects")
        if (url.toString().length > 0)
            EditorState.exportUserEffectPreset(preset.id, url)
    }

    function applyStack(preset) {
        if (EditorState.selectedClip < 0)
            return
        EditorState.applyEffectPreset(EditorState.selectedTrack, EditorState.selectedClip, preset.id)
    }

    EmptyState {
        anchors.centerIn: parent
        width: Math.min(parent.width - Theme.spacing3xl, 260)
        visible: root.presets.length === 0
        compact: true
        glyph: Theme.icons.layers
        title: qsTr("No saved presets")
        hint: qsTr("Tune a clip's effects, then use “Save as preset…” in the properties Effects tab to keep them here.")
        actionText: qsTr("Import")
        onActionTriggered: root.importStack()
    }

    Flickable {
        id: stackFlick
        anchors.fill: parent
        visible: root.presets.length > 0
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        contentHeight: stackGrid.height + Theme.pagePadding * 2
        ScrollBar.vertical: AppScrollBar { }

        Grid {
            id: stackGrid
            width: stackFlick.width - Theme.pagePadding * 2
            x: Theme.pagePadding
            y: Theme.pagePadding
            // Columns fill the width: rounded to the nearest count at the nominal card size, the
            // cards stretched or squeezed to take up the slack.
            columns: Math.max(1, Math.round((width + Theme.assetCardGap)
                                            / (Theme.assetCardWidth + Theme.assetCardGap)))
            readonly property real cardSize: Math.floor((width + Theme.assetCardGap) / columns) - Theme.assetCardGap
            columnSpacing: Theme.assetCardGap
            rowSpacing: Theme.assetCardGap

            Repeater {
                model: root.presets
                delegate: EffectStackCard {
                    cardSize: stackGrid.cardSize
                    onApplyRequested: (preset) => root.applyStack(preset)
                    onExportRequested: (preset) => root.exportStack(preset)
                    onRenameRequested: (preset) => renameStackDialog.openFor(preset)
                    onDeleteRequested: (preset) => deleteStackDialog.openFor(preset)
                }
            }
        }
    }

    NameDialog {
        id: renameStackDialog

        property string presetId: ""

        function openFor(preset) {
            presetId = preset.id
            openWith(qsTr("Rename effect preset"), preset.label)
        }

        onSubmitted: name => EditorState.renameUserEffectPreset(renameStackDialog.presetId, name)
    }

    ThemedDialog {
        id: deleteStackDialog

        property string presetId: ""
        property string presetLabel: ""

        title: qsTr("Delete effect preset")
        acceptText: qsTr("Delete")
        acceptVariant: "destructive"
        preferredWidth: Theme.dialogWidthSm
        acceptOnReturn: false

        function openFor(preset) {
            presetId = preset.id
            presetLabel = preset.label
            open()
        }

        onAccepted: EditorState.deleteUserEffectPreset(deleteStackDialog.presetId)

        contentItem: Text {
            width: parent ? parent.width : 320
            wrapMode: Text.WordWrap
            text: qsTr("Remove “%1” from your saved presets? Clips already using it keep their effects.")
                      .arg(deleteStackDialog.presetLabel)
            color: Theme.panelForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSm
        }
    }
}
