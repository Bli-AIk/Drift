import QtQuick
import Drift

// Background of the pinned ruler and bookmark strip.
ThemeSlot {
    slot: "TimelineRulerBackground"
    control: parent
    anchors.fill: parent
    fallback: Component {
        Rectangle {
            anchors.fill: parent
            color: Theme.c.timelineSeekStripFill.background
        }
    }
}
