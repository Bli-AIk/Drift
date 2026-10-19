import QtQuick
import Drift
// Position of a vertical or horizontal guide, as a percent of the canvas.
Row {
    id: line

    required property var item
    signal edited(real fraction)

    spacing: Theme.spacingSm
    visible: line.item.kind === "v" || line.item.kind === "h"

    ThemedLabel {
        anchors.verticalCenter: parent.verticalCenter
        text: line.item.kind === "v" ? qsTr("From left") : qsTr("From top")
    }
    GuidesPopoverPercentField {
        to: 100
        fraction: line.item.pos
        onCommitted: f => line.edited(f)
    }
}
