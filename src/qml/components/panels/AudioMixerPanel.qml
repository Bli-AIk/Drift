import QtQuick
import QtQuick.Controls.Basic
import Drift

PanelFrame {
    id: root

    readonly property bool hasClip: EditorState.selectedTrack >= 0 && EditorState.selectedClip >= 0
    property string loudnessText: qsTr("Loudness: not measured")
    property bool loudnessIsError: false

    Connections {
        target: EditorState
        function onSelectionChanged() {
            root.loudnessText = qsTr("Loudness: not measured")
            root.loudnessIsError = false
        }
    }

    function showResult(result, text) {
        loudnessIsError = !result.ok
        loudnessText = result.ok ? text : (result.detail ?? result.error ?? qsTr("Failed"))
    }

    function analyze() {
        const result = EditorState.analyzeFocusedClipLoudness()
        showResult(result, qsTr("Loudness: %1 LUFS, true peak %2 dBTP")
                           .arg(result.lufs?.toFixed(1)).arg(result.true_peak_db?.toFixed(1)))
    }

    function normalize() {
        const target = targetBox.currentValue
        const result = EditorState.normalizeFocusedClipLoudness(target)
        showResult(result, result.clipping
                           ? qsTr("Normalized to %1 LUFS, but peaks clip").arg(target)
                           : qsTr("Normalized to %1 LUFS").arg(target))
    }

    AssetsPanelHeader {
        id: header
        width: parent.width
        height: Theme.panelHeaderHeight
        title: qsTr("Audio Mixer")
    }

    Rectangle {
        id: footer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: footerCol.implicitHeight + Theme.spacingMd * 2
        color: Theme.c.audioMixerStrip.background

        Rectangle {
            anchors.top: parent.top
            width: parent.width
            height: 1
            color: Theme.c.audioMixerStrip.border
        }

        Column {
            id: footerCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Theme.spacingMd
            anchors.rightMargin: Theme.spacingMd
            spacing: Theme.spacingSm

            Row {
                width: parent.width
                spacing: Theme.spacingSm

                Text {
                    width: Math.max(0, parent.width - analyzeBtn.width - parent.spacing)
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.loudnessText
                    elide: Text.ElideRight
                    color: root.loudnessIsError ? Theme.c.audioMixerStrip.destructive
                                                : Theme.c.audioMixerStrip.foreground
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeXs
                }

                ThemedButton {
                    id: analyzeBtn
                    anchors.verticalCenter: parent.verticalCenter
                    text: qsTr("Analyze")
                    variant: "secondary"
                    glyph: Theme.icons.audioLines
                    tooltip: root.hasClip ? qsTr("Measure loudness of the selected clip")
                                          : qsTr("Select a clip first")
                    enabled: root.hasClip
                    onClicked: root.analyze()
                }
            }

            Row {
                spacing: Theme.spacingSm

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: qsTr("Normalize to")
                    color: Theme.c.audioMixerStrip.foreground
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeXs
                }

                ThemedComboBox {
                    id: targetBox
                    anchors.verticalCenter: parent.verticalCenter
                    width: 110
                    enabled: root.hasClip
                    model: [
                        { label: qsTr("-14 LUFS"), value: -14 },
                        { label: qsTr("-16 LUFS"), value: -16 },
                        { label: qsTr("-23 LUFS"), value: -23 }
                    ]
                    textRole: "label"
                    valueRole: "value"
                }

                ThemedButton {
                    anchors.verticalCenter: parent.verticalCenter
                    text: qsTr("Normalize")
                    variant: "secondary"
                    glyph: Theme.icons.gauge
                    tooltip: root.hasClip ? qsTr("Set the selected clip's volume to the chosen loudness")
                                          : qsTr("Select a clip first")
                    enabled: root.hasClip
                    onClicked: root.normalize()
                }
            }
        }
    }

    AudioMixerStrip {
        anchors.top: header.bottom
        anchors.bottom: footer.top
        width: parent.width
        resizing: true
        embedded: true
    }
}
