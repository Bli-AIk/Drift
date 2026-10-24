import QtQuick
import Drift

// Insertion line while reordering tracks.
Rectangle {
    property var column
    visible: column.draggingTrackSlot >= 0 && column.draggingTrackTo >= 0
             && column.draggingTrackFrom !== column.draggingTrackTo
    width: parent.width - 8
    height: 2
    radius: Theme.c.trackHeaderInsertLine.radius
    x: 4
    color: Theme.c.trackHeaderInsertLine.foreground
    z: 10
    // Drawn at the insertion boundary itself, in the same frame as the
    // header rows — without -contentY it drifts off the boundary as soon as
    // the tracks are scrolled.
    y: {
        const slot = column.draggingTrackSlot
        if (slot < 0)
            return 0
        if (slot >= column.tracks.length) {
            var last = column.tracks.length - 1
            while (last > 0 && !column.trackOccupiesARow(last))
                last--
            return column.trackRowTop(last) + column.trackHeight(last)
                   - column.contentY - 1
        }
        return column.trackRowTop(slot) - column.contentY - 1
    }
}
