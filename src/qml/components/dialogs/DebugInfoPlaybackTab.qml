import QtQuick
import Drift

Column {
    required property var dialog
    id: playbackTab
    width: parent.width
    spacing: Theme.spacingXl
    visible: dialog.activeTab === 1
    height: visible ? implicitHeight : 0

    Column {
        width: parent.width
        spacing: Theme.spacingSm

        ThemedLabel {
            width: parent.width
            size: "sm"
            tone: "default"
            text: qsTr("Playback")
            font.weight: Font.Medium
        }

        ThemedLabel {
            width: parent.width
            size: "xs"
            wrapMode: Text.WordWrap
            text: qsTr("Delivered well above displayed means frames are being "
                       + "produced that the display never shows — a cadence problem "
                       + "rather than a slow machine.")
        }

        // The counters only move during playback, and playback cannot run while
        // this dialog is up. So the switch outlives the dialog: turn it on, close
        // this, and watch the overlay on the preview while the timeline plays.
        ThemedSwitch {
            checked: EditorState.playback.stats.active
            text: qsTr("Show live stats on the preview")
            tooltip: qsTr("Stays on after this dialog closes, so you can watch the "
                          + "numbers while the timeline plays.")
            onToggled: EditorState.playback.stats.active = checked
        }

        Column {
            width: parent.width
            spacing: 0

            Repeater {
                model: dialog.playback.rows || []

                Item {
                    required property var modelData
                    required property int index

                    width: parent.width
                    height: Math.max(Theme.controlHeightSm,
                                     playRowValue.implicitHeight + Theme.spacingSm)

                    Rectangle {
                        anchors.fill: parent
                        color: index % 2 === 1 ? Theme.c.debugInfoPlaybackTab.stripe : "transparent"
                        radius: Theme.c.debugInfoPlaybackTab.stripeRadius
                    }

                    ThemedLabel {
                        width: Math.round(parent.width * 0.5)
                        anchors.verticalCenter: parent.verticalCenter
                        leftPadding: Theme.spacingLg
                        size: "xs"
                        text: modelData.label || ""
                    }

                    ThemedLabel {
                        id: playRowValue
                        x: Math.round(parent.width * 0.5)
                        width: parent.width - x
                        anchors.verticalCenter: parent.verticalCenter
                        rightPadding: Theme.spacingLg
                        size: "xs"
                        tone: "default"
                        wrapMode: Text.WordWrap
                        text: modelData.value || ""
                    }
                }
            }
        }
    }

    Column {
        width: parent.width
        spacing: Theme.spacingSm

        ThemedLabel {
            width: parent.width
            size: "sm"
            tone: "default"
            text: qsTr("Where the time goes")
            font.weight: Font.Medium
        }

        ThemedLabel {
            width: parent.width
            size: "xs"
            wrapMode: Text.WordWrap
            text: qsTr("Decodes a fixed 1080p60 clip, and the first clip on the "
                       + "timeline, through each stage of the preview. Takes a few "
                       + "seconds.")
        }

        ThemedButton {
            text: EditorState.playbackBenchmarkRunning ? qsTr("Measuring…")
                                                       : qsTr("Run test")
            variant: "secondary"
            enabled: !EditorState.playbackBenchmarkRunning
            onClicked: EditorState.startPlaybackBenchmark()
        }

        Repeater {
            model: [
                { key: "reference", title: qsTr("Reference clip (1080p60)") },
                { key: "timeline", title: qsTr("Timeline clip") }
            ]

            Column {
                id: benchSection
                required property var modelData
                readonly property var bench: dialog.benchmark[modelData.key] || null
                readonly property var b: bench || ({})

                width: parent.width
                spacing: Theme.spacingSm
                visible: !!bench
                height: visible ? implicitHeight : 0

                ThemedLabel {
                    width: parent.width
                    size: "xs"
                    tone: "default"
                    font.weight: Font.Medium
                    text: benchSection.modelData.title
                }

                ThemedLabel {
                    width: parent.width
                    size: "xs"
                    visible: !!benchSection.b.error
                    height: visible ? implicitHeight : 0
                    wrapMode: Text.WordWrap
                    text: benchSection.b.error || ""
                }

                Column {
                    width: parent.width
                    spacing: 0
                    visible: !!benchSection.bench && !benchSection.b.error
                    height: visible ? implicitHeight : 0

                    DebugInfoBenchRow {
                        label: qsTr("Source")
                        value: benchSection.b.source || "\u2014"
                    }
                    DebugInfoBenchRow {
                        label: qsTr("Decoder")
                        value: (benchSection.b.decoder || "\u2014")
                               + (benchSection.b.hardware ? qsTr(" (hardware)")
                                                          : qsTr(" (software)"))
                    }
                    DebugInfoBenchRow {
                        label: qsTr("Preview upload")
                        value: benchSection.b.uploadPath || "\u2014"
                    }
                    DebugInfoBenchRow {
                        label: qsTr("Decode")
                        value: dialog.ms(benchSection.b.decodePerFrameMs)
                    }
                    DebugInfoBenchRow {
                        label: qsTr("Readback to CPU costs")
                        value: dialog.ms(benchSection.b.readbackCostMs)
                    }
                    DebugInfoBenchRow {
                        label: qsTr("Compositing costs")
                        value: dialog.ms(benchSection.b.compositeCostMs)
                    }
                    DebugInfoBenchRow {
                        label: qsTr("Total per frame")
                        value: dialog.ms(benchSection.b.compositePerFrameMs)
                        emphasis: true
                    }
                    DebugInfoBenchRow {
                        label: qsTr("Budget at this frame rate")
                        value: dialog.ms(benchSection.b.frameBudgetMs)
                        emphasis: true
                    }
                }
            }
        }
    }

    Column {
        width: parent.width
        spacing: Theme.spacingLg
        visible: (dialog.playback.hints || []).length > 0
        height: visible ? implicitHeight : 0

        ThemedLabel {
            width: parent.width
            size: "sm"
            tone: "default"
            text: qsTr("Findings")
            font.weight: Font.Medium
        }

        Repeater {
            model: dialog.playback.hints || []

            Rectangle {
                required property var modelData

                width: parent.width
                implicitHeight: playHintCol.height + Theme.spacingLg * 2
                radius: Theme.c.debugInfoPlaybackTab.radius
                color: "transparent"
                border.width: Theme.c.debugInfoPlaybackTab.borderWidth
                border.color: Theme.c.debugInfoPlaybackTab.border

                Column {
                    id: playHintCol
                    x: Theme.spacingLg
                    y: Theme.spacingLg
                    width: parent.width - Theme.spacingLg * 2
                    spacing: Theme.spacingSm

                    ThemedLabel {
                        width: parent.width
                        size: "sm"
                        tone: "default"
                        font.weight: Font.Medium
                        text: modelData.title || ""
                    }

                    ThemedLabel {
                        width: parent.width
                        size: "sm"
                        wrapMode: Text.WordWrap
                        text: modelData.detail || ""
                    }
                }
            }
        }
    }

    ThemedLabel {
        width: parent.width
        size: "xs"
        wrapMode: Text.WordWrap
        visible: (dialog.playback.hints || []).length === 0
        height: visible ? implicitHeight : 0
        text: qsTr("Nothing stood out. Turn on the live stats above, play the "
                   + "timeline for a few seconds, then reopen this.")
    }
}
