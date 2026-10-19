import QtQuick
import Drift

// Vertical guide at the time a dragged clip snapped to.
Rectangle {
    id: guide

    property TimelinePanel panel
    visible: opacity > 0
    opacity: panel.snapGuideSeconds >= 0 ? 1 : 0
    x: panel.snapGuideSeconds * panel.pxPerSecond
    y: Theme.timelineRulerHeight + Theme.timelineBookmarkRowHeight
    width: Theme.c.timelineSnapGuide.borderWidth
    height: panel.totalTracksHeightCached
    color: Theme.c.timelineSnapGuide.foreground
    z: 6

    Behavior on opacity {
        NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
    }

    // Says what the clip snapped to, instead of leaving a bare
    // unexplained line on screen.
    TimelineSnapGuideLabel {
        panel: guide.panel
    }
}
