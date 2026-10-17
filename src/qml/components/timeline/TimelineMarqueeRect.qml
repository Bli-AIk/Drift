import QtQuick
import Drift

// CapCut-style selection box drawn while marquee-dragging.
Rectangle {
    id: marqueeRect

    property TimelinePanel panel
    visible: panel.marqueeActive
             && (panel.marqueeWidth > 2 || panel.marqueeHeight > 2)
    x: panel.marqueeLeft
    y: Theme.timelineRulerHeight + Theme.timelineBookmarkRowHeight
       + panel.marqueeTop
    width: panel.marqueeWidth
    height: panel.marqueeHeight
    z: 8
    color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
    border.width: Theme.borderWidth
    border.color: Theme.primary
}
