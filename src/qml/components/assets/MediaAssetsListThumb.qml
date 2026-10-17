import QtQuick
import QtQuick.Window
import Drift
// Small thumbnail at the left of a media list or tree row.
Rectangle {
    id: root

    property bool folder: false
    property string liveThumbnailPath: ""
    property string kind: ""
    property bool replaceBusy: false
    property bool showVfr: false

    width: 56
    height: 32
    radius: Theme.radiusSm
    color: Theme.panelBackground
    clip: true

    SkeletonBox {
        anchors.fill: parent
        radius: parent.radius
        visible: !root.folder && root.liveThumbnailPath.length > 0
                    && listThumb.status === Image.Loading
    }

    Image {
        id: listThumb
        anchors.fill: parent
        visible: !root.folder && root.liveThumbnailPath.length > 0 && status === Image.Ready
        source: !root.folder && root.liveThumbnailPath.length > 0
                ? EditorState.imageUrl(root.liveThumbnailPath) : ""
        fillMode: Image.PreserveAspectFit
        // Was missing, so list thumbnails decoded
        // on the UI thread and stalled scrolling.
        asynchronous: true
        sourceSize: Qt.size(Math.ceil(root.width * Screen.devicePixelRatio),
                             Math.ceil(root.height * Screen.devicePixelRatio))
    }

    IconGlyph {
        anchors.centerIn: parent
        visible: root.folder
                    || root.liveThumbnailPath.length === 0 || listThumb.status === Image.Error
        glyph: root.folder ? Theme.icons.folder
               : (kind === "audio" ? Theme.icons.music
                  : kind === "vector" ? Theme.icons.layers
                  : kind === "pdf" ? Theme.icons.fileText
                  : kind === "model3d" ? Theme.icons.box
                  : kind === "composite" ? Theme.icons.layers : Theme.icons.film)
        iconSize: Theme.iconSizeBase
        iconColor: Theme.mutedForeground
    }

    // Same busy treatment as the grid card, scaled to the row thumbnail.
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: Theme.scrimStrong
        visible: opacity > 0
        opacity: replaceBusy ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
        }

        CircularProgress {
            anchors.centerIn: parent
            indeterminate: true
            size: Theme.iconSizeBase
            strokeWidth: 2
            progressColor: Theme.onMedia
        }
    }

    VfrWarning {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 1
        size: Theme.iconSizeSm
        visible: root.showVfr
    }
}
