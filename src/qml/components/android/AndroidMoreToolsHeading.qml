import QtQuick
import Drift

// Just the heading's own height: the tiles carry their own top padding, and the
// old touch-target-tall band left a gap under the sheet title.
Item {
    id: heading

    property string title: ""
    property real sideInset: 0

    height: groupHeading.implicitHeight

    ThemedLabel {
        id: groupHeading
        anchors.left: parent.left
        anchors.leftMargin: Theme.pagePadding + heading.sideInset
        anchors.bottom: parent.bottom
        tone: "default"
        size: "sm"
        text: heading.title
    }
}
