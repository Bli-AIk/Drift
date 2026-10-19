import QtQuick
import Drift

Item {
    property string fontFamily: ""
    property real cellWidth: 40
    property real cellHeight: 40
    signal picked(string emoji, string name)
    id: cell
    required property var modelData
    width: cellWidth
    height: cellHeight

    Rectangle {
        anchors.fill: parent
        anchors.margins: 2
        radius: Theme.c.emojiGridCell.radius
        color: cellDrag.hovered ? Theme.c.emojiGridCell.backgroundHover : "transparent"

        Behavior on color {
            ColorAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
        }

        Text {
            anchors.centerIn: parent
            text: cell.modelData.emoji
            // The addon face, not the system one, so the grid shows what the
            // rasteriser will actually draw.
            font.family: fontFamily
            font.pixelSize: Math.round(cellWidth * 0.6)
        }
    }

    ThemedToolTip {
        text: cell.modelData.name
        visible: cellDrag.hovered && !cellDrag.active
    }

    // Draggable on the desktop; on the phone this grid is a modal popup, which a
    // lifted card cannot leave, so there it stays tap-to-add.
    AssetDragSource {
        id: cellDrag
        anchors.fill: parent
        kind: "emoji"
        payload: cell.modelData.emoji
        label: cell.modelData.name
        liftEnabled: false
        onTapped: cell.picked(cell.modelData.emoji, cell.modelData.name)
    }
}
