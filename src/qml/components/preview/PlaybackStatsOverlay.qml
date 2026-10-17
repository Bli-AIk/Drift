import QtQuick
import Drift

// Live playback counters drawn over the preview.
//
// This exists because the most common cause of "the preview stutters" leaves no trace in a
// static report: frames are produced on time and the display still cannot show them evenly.
// Delivered against displayed is what makes that visible, and it is only visible while
// playing — hence an overlay rather than another row in a dialog.
Rectangle {
    id: root

    readonly property var stats: EditorState.playback.stats

    visible: stats && stats.active
    width: column.width + Theme.spacingLg * 2
    height: column.height + Theme.spacingLg * 2
    radius: Theme.radiusSm
    // Deliberately opaque-ish: it sits over video, and a translucent panel over moving
    // pictures is unreadable exactly when the numbers matter.
    color: Qt.rgba(0, 0, 0, 0.72)
    border.width: Theme.borderWidth
    border.color: Qt.rgba(1, 1, 1, 0.14)

    // Reads well against any footage, and never inherits the theme's foreground — the
    // overlay is over video, not over the panel.
    readonly property color labelColor: Qt.rgba(1, 1, 1, 0.62)
    readonly property color valueColor: Qt.rgba(1, 1, 1, 0.95)
    readonly property color warnColor: "#ffb454"

    // Frames produced but never shown. A little is normal; a lot is the cadence problem.
    readonly property bool deliveryMismatch: {
        if (!stats || stats.displayedFps <= 0 || stats.deliveredFps <= 0)
            return false
        return Math.abs(stats.deliveredFps - stats.displayedFps) > stats.displayedFps * 0.15
    }

    function hz(v) { return (v > 0 ? v.toFixed(1) : "—") + " Hz" }
    function ms(v) { return (v > 0 ? v.toFixed(1) : "—") + " ms" }

    Column {
        id: column
        x: Theme.spacingLg
        y: Theme.spacingLg
        spacing: 2

        PlaybackStatsLine {
            labelColor: root.labelColor
            valueColor: root.valueColor
            warnColor: root.warnColor
            label: "delivered"
            value: root.stats ? root.hz(root.stats.deliveredFps) : "—"
            warn: root.deliveryMismatch
        }
        PlaybackStatsLine {
            labelColor: root.labelColor
            valueColor: root.valueColor
            warnColor: root.warnColor
            label: "displayed"
            value: root.stats ? root.hz(root.stats.displayedFps) : "—"
            warn: root.deliveryMismatch
        }
        PlaybackStatsLine {
            labelColor: root.labelColor
            valueColor: root.valueColor
            warnColor: root.warnColor
            label: "refresh"
            value: root.stats ? root.hz(root.stats.refreshRate) : "—"
        }
        PlaybackStatsLine {
            labelColor: root.labelColor
            valueColor: root.valueColor
            warnColor: root.warnColor
            // Spread of the interval between delivered frames. Even when the average rate is
            // right, a high figure here is what the eye reads as stutter.
            label: "jitter"
            value: root.stats ? root.ms(root.stats.jitterMs) : "—"
            warn: root.stats && root.stats.jitterMs > 4.0
        }
        PlaybackStatsLine {
            labelColor: root.labelColor
            valueColor: root.valueColor
            warnColor: root.warnColor
            label: "composite"
            value: root.stats ? root.ms(root.stats.compositeP95Ms) + " p95" : "—"
        }
        PlaybackStatsLine {
            labelColor: root.labelColor
            valueColor: root.valueColor
            warnColor: root.warnColor
            label: "decode wait"
            value: root.stats ? root.ms(root.stats.decodeWaitMedianMs) : "—"
        }
        PlaybackStatsLine {
            labelColor: root.labelColor
            valueColor: root.valueColor
            warnColor: root.warnColor
            label: "dropped"
            value: root.stats ? String(root.stats.droppedFrames) : "—"
            warn: root.stats && root.stats.droppedFrames > 0
        }
        PlaybackStatsLine {
            labelColor: root.labelColor
            valueColor: root.valueColor
            warnColor: root.warnColor
            label: "coalesced"
            value: root.stats ? String(root.stats.coalescedRequests) : "—"
        }
        PlaybackStatsLine {
            labelColor: root.labelColor
            valueColor: root.valueColor
            warnColor: root.warnColor
            label: "in flight"
            value: root.stats ? String(root.stats.inFlightPeak) + " peak" : "—"
        }
        PlaybackStatsLine {
            labelColor: root.labelColor
            valueColor: root.valueColor
            warnColor: root.warnColor
            label: "scale"
            value: root.stats ? Math.round(root.stats.adaptiveScale * 100) + "%" : "—"
            warn: root.stats && root.stats.adaptiveScale < 0.99
        }
        PlaybackStatsLine {
            labelColor: root.labelColor
            valueColor: root.valueColor
            warnColor: root.warnColor
            label: "upload"
            value: root.stats && root.stats.uploadPath ? root.stats.uploadPath : "—"
            warn: root.stats && root.stats.uploadPath === "cpu-roundtrip"
        }
    }
}
