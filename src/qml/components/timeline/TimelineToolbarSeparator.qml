import QtQuick
import Drift

// Hairline between toolbar groups.
Rectangle {
    width: Theme.c.timelineToolbarSeparator.borderWidth
    height: Theme.spacing3xl
    color: Theme.c.timelineToolbarSeparator.foreground
    anchors.verticalCenter: parent.verticalCenter
}
