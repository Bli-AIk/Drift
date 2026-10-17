import QtQuick
import Drift

// Lane backdrop, aligned under the timeline.
Item {
    id: root
    anchors.fill: parent

    ThemeSlot {
        anchors.fill: parent
        slot: "KeyframeGraphFrame"
        control: root
        fallback: Component {
            Rectangle {
                anchors.fill: parent
                color: Theme.c.keyframeGraphFrame.background
                border.width: Theme.c.keyframeGraphFrame.borderWidth
                border.color: Theme.c.keyframeGraphFrame.border
            }
        }
    }
}
