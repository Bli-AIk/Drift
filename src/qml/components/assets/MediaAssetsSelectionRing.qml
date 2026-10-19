import QtQuick
import Drift

// A dedicated overlay for the selection ring, painted above the
// thumbnail image and busy scrim (both earlier siblings) so it
// is never covered by them. Square corners on purpose — a
// rounded ring here reads chunkier than the thumbnail's own
// radius at this border width.
Item {
    id: root

    property bool selected: false

    z: 2
    anchors.fill: parent

    ThemeSlot {
        anchors.fill: parent
        slot: "MediaAssetsSelectionRing"
        control: root
        fallback: Component {
            Rectangle {
                anchors.fill: parent
                radius: Theme.c.mediaAssetsSelectionRing.radius
                color: "transparent"
                border.width: root.selected ? Theme.c.mediaAssetsSelectionRing.borderWidth : 0
                border.color: Theme.c.mediaAssetsSelectionRing.border

                Behavior on border.width {
                    NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
                }
            }
        }
    }
}
