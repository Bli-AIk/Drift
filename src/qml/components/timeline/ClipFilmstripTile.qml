import QtQuick
import Drift

// One filmstrip tile: coarse strip frame, then the on-demand frame for its timestamp.
Item {
    property ClipFilmstrip strip
    id: tile
    required property int index
    readonly property int tileIndex: strip.firstVisibleTile + index

    x: strip.stripOriginX + tileIndex * strip.frameWidth
    width: strip.frameWidth
    height: strip.height

    // Coarse frame from the strip: already on disk, so it draws immediately.
    Image {
        id: frame
        anchors.fill: parent
        source: strip.coarseUrlForTile(tile.tileIndex)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        // Keep GPU textures small regardless of item layout.
        sourceSize.width: strip.frameWidth
        sourceSize.height: strip.frameHeight

        opacity: status === Image.Ready ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: Theme.durationBase; easing.type: Theme.easing }
        }

        onStatusChanged: {
            if (tile.index !== 0)
                return
            if (status === Image.Ready || status === Image.Error)
                strip.firstFrameReady = true
        }
    }

    // This tile's own timestamp, decoded on demand. Sits on top so it replaces the
    // repeated strip frame without a reload flicker once it arrives.
    Image {
        anchors.fill: parent
        source: strip.tileUrlForTile(tile.tileIndex)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize.width: strip.frameWidth
        sourceSize.height: strip.frameHeight

        opacity: status === Image.Ready ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: Theme.durationBase; easing.type: Theme.easing }
        }
    }
}
