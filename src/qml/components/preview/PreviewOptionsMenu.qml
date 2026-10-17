import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Drift

// The preview's less-used settings, behind the OSD's "⋯": preview quality, playback speed, how
// video is decoded, and keeping mask handles up.
Popup {
    id: root

    // Open, or with the decode explanation up: either way the OSD should stay put.
    readonly property bool busy: opened || decodeGpuDialog.visible

    padding: Theme.spacingLg
    // Not modal, and pressing the parent button does not count as outside, so that button can
    // toggle the menu instead of closing and reopening it.
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

    background: Rectangle {
        color: Theme.panelBackground
        border.width: Theme.borderWidth
        border.color: Theme.panelBorder
        radius: Theme.radiusMd
    }

    contentItem: GridLayout {
        columns: 2
        columnSpacing: Theme.spacingLg
        rowSpacing: Theme.spacingMd

        PreviewOptionsRowLabel { text: qsTr("Quality") }
        ThemedComboBox {
            id: qualityCombo
            Layout.fillWidth: true
            Layout.minimumWidth: widestContentWidth + leftPadding + rightPadding
            implicitHeight: Theme.controlHeightSm
            leftPadding: Theme.spacingMd
            rightPadding: Theme.spacing2xl
            font.pixelSize: Theme.fontSizeXs
            // Display is capitalised; the engine stores the lowercase value.
            readonly property var values: ["full", "half", "quarter", "auto"]
            model: [qsTr("Full"), qsTr("Half"), qsTr("Quarter"), qsTr("Auto")]
            tooltip: qsTr("Preview quality — lower is smoother while editing.\n"
                          + "Full, Half and Quarter are fixed fractions of the project resolution: "
                          + "Full composites exactly what an export would.\n"
                          + "Auto renders only as many pixels as the preview actually shows, and "
                          + "lowers that further while playback cannot keep up.")
            currentIndex: Math.max(0, values.indexOf(EditorState.playback.previewQuality))
            onActivated: EditorState.playback.previewQuality = values[currentIndex]
        }

        PreviewOptionsRowLabel { text: qsTr("Speed") }
        ThemedComboBox {
            Layout.fillWidth: true
            Layout.minimumWidth: widestContentWidth + leftPadding + rightPadding
            implicitHeight: Theme.controlHeightSm
            leftPadding: Theme.spacingMd
            rightPadding: Theme.spacing2xl
            font.pixelSize: Theme.fontSizeXs
            readonly property var values: [0.25, 0.5, 1.0, 1.5, 2.0, 4.0]
            model: ["0.25×", "0.5×", "1×", "1.5×", "2×", "4×"]
            tooltip: qsTr("Playback speed")
            currentIndex: Math.max(0, values.indexOf(EditorState.playback.playbackRate))
            onActivated: EditorState.playback.playbackRate = values[currentIndex]
        }

        PreviewOptionsRowLabel { text: qsTr("Decode") }
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingSm

            ThemedComboBox {
                id: decodeCombo
                Layout.fillWidth: true
                Layout.minimumWidth: widestContentWidth + leftPadding + rightPadding
                implicitHeight: Theme.controlHeightSm
                leftPadding: Theme.spacingMd
                rightPadding: Theme.spacing2xl
                font.pixelSize: Theme.fontSizeXs
                // Populated from the engine: the hardware entries are the backends whose device
                // actually opens here, so anything listed is something that runs. Rows carry
                // `warn`/`note` for a backend that decodes on a GPU other than the one drawing,
                // which the delegate marks and the dialog below explains.
                readonly property var modes: EditorState.playback.decodeModes
                readonly property var values: modes.map(function (m) { return m.id })
                model: modes
                textRole: "label"
                tooltip: qsTr("How video is decoded for preview.\n"
                              + "Auto picks per clip: hardware for high-quality 4K, software otherwise.\n"
                              + "Software is smoother for most clips. It uses more CPU.\n"
                              + "Hardware is better for high-quality 4K, and forces one GPU decoder.\n"
                              + "If playback stutters, try another.")
                currentIndex: Math.max(0, values.indexOf(EditorState.playback.decodeMode))
                onActivated: {
                    const mode = modes[currentIndex]
                    if (mode && mode.warn)
                        decodeGpuDialog.confirm(mode)
                    else
                        EditorState.playback.decodeMode = mode.id
                }
            }

            // The combo's list is shut most of the time, so the chosen row's warning needs
            // somewhere to live on the closed control too.
            PreviewOptionsDecodeWarning {
                mode: decodeCombo.modes[decodeCombo.currentIndex]
            }
        }

        ThemedSwitch {
            Layout.columnSpan: 2
            Layout.fillWidth: true
            text: qsTr("Keep mask handles up")
            tooltip: qsTr("Keep mask handles on the preview while another clip is selected")
            checked: EditorState.preview.maskEditMode
            onToggled: EditorState.preview.maskEditMode = checked
        }
    }

    // Picking a decoder that runs on the other GPU is a legitimate choice — some codecs only the
    // discrete card decodes — so this explains the cost rather than blocking it, and offers the
    // change that would actually fix it where Drift can make one.
    PreviewOptionsDecodeDialog {
        id: decodeGpuDialog
        onRestoreSelection: decodeCombo.currentIndex =
            Math.max(0, decodeCombo.values.indexOf(EditorState.playback.decodeMode))
    }
}
