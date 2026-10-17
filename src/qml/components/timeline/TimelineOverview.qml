import QtQuick
import Drift

// Resolve-style project overview: the entire timeline compressed to fit this
// strip's width, with a rectangle marking what the zoomed track view below
// currently shows. Click or drag anywhere to recenter that view on the
// clicked point — the equivalent of dragging the minimap in Resolve/Premiere.
//
// Can be switched off (EditorState.preferences.timelineOverviewVisible) on a timeline long
// enough that repainting every clip on every edit is felt.
Item {
    id: overview

    // Owning TimelinePanel; reads pxPerSecond/timelineViewX/timelineViewW and
    // calls scrollToX to move the zoomed view.
    property var panel

    height: Theme.timelineOverviewHeight

    readonly property real duration: Math.max(EditorState.durationSeconds, 1)
    readonly property real overviewPxPerSecond: width / duration

    // Matches drift::ClipType's order, which is what timelineOverviewBlocks() emits.
    function blockColor(typeCode) {
        switch (typeCode) {
        case 1: return Theme.clipAudio       // audio
        case 3: return Theme.clipText        // text
        case 4: return Theme.clipSubtitle    // subtitle
        case 6: return Theme.clipEffect      // adjustment
        case 2:                              // image
        case 5:                              // shape
        case 7:                              // vector
        case 8: return Theme.clipGraphic     // 3D model
        default: return Theme.clipVideoOverview
        }
    }

    function xToSeconds(x) {
        return Math.max(0, Math.min(duration, x / overviewPxPerSecond))
    }

    // Recenter the zoomed view on `x` (overview-local coordinate), clamped to
    // the content range so the viewport rectangle never runs past either end.
    function recenterOn(x) {
        const targetSeconds = xToSeconds(x)
        const viewSeconds = panel.timelineViewW / panel.pxPerSecond
        const maxContentX = Math.max(0, panel.timelineContentWidth - panel.timelineViewW)
        const newContentX = Math.max(0, Math.min(maxContentX,
            (targetSeconds - viewSeconds / 2) * panel.pxPerSecond))
        panel.scrollToX(newContentX)
    }

    TimelineOverviewBackground { }

    TimelineOverviewEdge { }

    TimelineOverviewMap {
        host: overview
        panel: overview.panel
    }

    // Viewport indicator: the slice of the project the zoomed track view below is currently
    // showing. Drawn as a window rather than a tint — the strip is full of colour now, and a
    // translucent fill over it read as nothing at all.
    QtObject {
        id: viewport
        readonly property real viewStartSeconds: panel ? panel.timelineViewX / panel.pxPerSecond : 0
        readonly property real viewEndSeconds: panel ? (panel.timelineViewX + panel.timelineViewW) / panel.pxPerSecond : 0
        // Clamp both edges independently: the visible range can run past
        // `duration` into the Flickable's trailing end pad (always present,
        // and often the whole pad at Fit zoom), which this strip's scale
        // does not otherwise account for — unclamped, the indicator would
        // draw wider than the strip itself.
        readonly property real startX: Math.max(0, Math.min(overview.width, viewStartSeconds * overview.overviewPxPerSecond))
        readonly property real endX: Math.max(0, Math.min(overview.width, viewEndSeconds * overview.overviewPxPerSecond))
    }

    TimelineOverviewShade {
        spanX: 0
        spanWidth: viewport.startX
    }

    TimelineOverviewShade {
        spanX: viewport.endX
        spanWidth: Math.max(0, overview.width - viewport.endX)
    }

    TimelineOverviewFrame {
        spanX: viewport.startX
        spanWidth: viewport.endX - viewport.startX
    }

    TimelineOverviewPlayhead {
        host: overview
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        preventStealing: true
        onPressed: (mouse) => overview.recenterOn(mouse.x)
        onPositionChanged: (mouse) => { if (pressed) overview.recenterOn(mouse.x) }
    }
}
