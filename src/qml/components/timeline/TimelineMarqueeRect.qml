import QtQuick
import Drift

// CapCut-style selection box drawn while marquee-dragging.
Rectangle {
    id: marqueeRect

    property var panel
    visible: panel.marqueeActive
             && (panel.marqueeWidth > 2 || panel.marqueeHeight > 2)
    x: panel.marqueeLeft
    y: Theme.timelineRulerHeight + Theme.timelineBookmarkRowHeight
       + panel.marqueeTop
    width: panel.marqueeWidth
    height: panel.marqueeHeight
    z: 8
    color: Qt.rgba(Theme.c.timelineMarqueeRect.background.r, Theme.c.timelineMarqueeRect.background.g, Theme.c.timelineMarqueeRect.background.b, 0.12)
    border.width: Theme.c.timelineMarqueeRect.borderWidth
    border.color: Theme.c.timelineMarqueeRect.border
}
