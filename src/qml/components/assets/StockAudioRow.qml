import QtQuick
import QtQuick.Controls.Basic
import QtMultimedia
import Drift
// One stock audio result: preview, title, creator and download progress.
Rectangle {
    id: root

    property var previewPlayer: null
    signal openRequested(var item)

    required property var modelData
    readonly property bool isPlaying: previewPlayer.itemId === modelData.id
                                      && previewPlayer.playbackState === MediaPlayer.PlayingState
    readonly property var job: {
        void Market.downloadsRevision
        return Market.downloadInfo(modelData.id)
    }
    width: ListView.view ? ListView.view.width : 0
    height: Theme.touchUi ? Theme.androidMinTouchTarget + Theme.spacingLg : Theme.controlHeight + Theme.spacingLg
    radius: Theme.radiusSm
    color: rowHover.hovered ? Theme.popoverHover : "transparent"

    HoverHandler { id: rowHover; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: openRequested(root.modelData) }

    IconButton {
        id: playButton
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        glyph: root.isPlaying ? Theme.icons.pause : Theme.icons.play
        enabled: !!root.modelData.preview_url
        tooltip: root.isPlaying ? qsTr("Pause") : qsTr("Play preview")
        onClicked: {
            if (root.isPlaying) {
                previewPlayer.pause()
                return
            }
            if (previewPlayer.itemId !== root.modelData.id) {
                previewPlayer.itemId = root.modelData.id
                previewPlayer.source = root.modelData.preview_url
            }
            previewPlayer.play()
        }
    }

    Column {
        anchors.left: playButton.right
        anchors.right: trailing.left
        anchors.leftMargin: Theme.spacingMd
        anchors.rightMargin: Theme.spacingMd
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2
        Text {
            width: parent.width
            text: root.modelData.title || ""
            color: Theme.panelForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSm
            elide: Text.ElideRight
        }
        Text {
            width: parent.width
            visible: text.length > 0
            text: root.modelData.creator ? (root.modelData.creator.name || "") : ""
            color: Theme.mutedForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeXs
            elide: Text.ElideRight
        }
        // Playback position of the row that is playing.
        Rectangle {
            width: parent.width
            height: 2
            radius: 1
            color: Theme.panelMuted
            visible: previewPlayer.itemId === root.modelData.id && previewPlayer.duration > 0
            Rectangle {
                width: parent.width * Math.min(1, previewPlayer.position / Math.max(1, previewPlayer.duration))
                height: parent.height
                radius: 1
                color: Theme.primary
            }
        }
    }

    Item {
        id: trailing
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(durationText.implicitWidth, ring.width)
        height: parent.height

        Text {
            id: durationText
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            visible: !ring.visible
            text: {
                const n = Math.round(Number(root.modelData.duration_ms || 0) / 1000)
                return n > 0 ? Math.floor(n / 60) + ":" + (n % 60 < 10 ? "0" : "") + (n % 60) : ""
            }
            color: Theme.mutedForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeXs
        }
        CircularProgress {
            id: ring
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            visible: ["waiting", "queued", "processing", "downloading", "importing"].indexOf(root.job.status) >= 0
            value: Number(root.job.progress || 0)
            indeterminate: Number(root.job.progress || 0) <= 0
            size: Theme.spacing2xl + Theme.spacingSm
        }
    }
}
