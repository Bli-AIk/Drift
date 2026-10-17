import QtQuick
import Drift

// Reading the replacement off disk is the one wait in the swap with
// nothing on screen to show for it. Scrims this card only, so the rest of
// the bin stays usable.
Rectangle {
    id: root

    property bool folder: false
    property int assetIndex: -1

    // Above the duration badge, which is a later sibling.
    z: 1
    anchors.fill: parent
    // Matches the thumbnail under it (Theme.radiusSm). Bound locally so this
    // overlay does not read a radius off a generic parent item.
    radius: Theme.radiusSm
    color: Theme.scrimStrong
    readonly property bool busy:
        !folder && EditorState.bin.replacingAssetId.length > 0
        && EditorState.bin.replacingAssetId === AssetLibrary.assetIdAt(assetIndex)
    visible: opacity > 0
    opacity: busy ? 1 : 0

    Behavior on opacity {
        NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
    }

    // Swallows taps and drags while the swap is in flight, so the card
    // cannot be added to the timeline against media that is changing.
    MouseArea {
        anchors.fill: parent
        enabled: root.busy
        acceptedButtons: Qt.AllButtons
    }

    CircularProgress {
        anchors.centerIn: parent
        indeterminate: true
        size: Theme.spacing3xl
        progressColor: Theme.onMedia
    }
}
