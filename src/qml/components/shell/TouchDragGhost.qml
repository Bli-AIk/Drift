import QtQuick
import Drift

// The lifted card following the finger during a TouchDrag. The owner decides
// where it lives and when it may show; it also needs TouchDrag.active.
Item {
    id: ghost
    enabled: false
    readonly property real ghostSize: Math.round(Theme.assetCardWidth * 0.62)
    width: ghostSize
    height: ghostSize
    // Lifted clear of the fingertip, or the thing being placed is under the
    // hand placing it.
    x: parent.mapFromItem(null, TouchDrag.sceneX, TouchDrag.sceneY).x - width / 2
    y: parent.mapFromItem(null, TouchDrag.sceneX, TouchDrag.sceneY).y
       - height - Theme.spacingLg
    scale: visible ? 1 : 0.8

    Behavior on scale {
        NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.c.touchDragGhost.radius
        color: Theme.c.touchDragGhost.background
        clip: true
        border.width: TouchDrag.overTarget ? Theme.c.touchDragGhost.borderWidthOver
                                           : Theme.c.touchDragGhost.borderWidth
        border.color: TouchDrag.overTarget ? Theme.c.touchDragGhost.borderOver
                                           : Theme.c.touchDragGhost.border
        opacity: 0.94

        Behavior on border.width {
            NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
        }
        Behavior on border.color {
            ColorAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
        }

        Image {
            id: ghostImage
            anchors.fill: parent
            visible: TouchDrag.thumbnail.length > 0 && status === Image.Ready
            source: TouchDrag.thumbnail.length > 0
                    ? EditorState.imageUrl(TouchDrag.thumbnail) : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }

        IconGlyph {
            anchors.centerIn: parent
            visible: !ghostImage.visible && TouchDrag.glyph.length > 0
            glyph: TouchDrag.glyph
            iconSize: Theme.iconSizeXl
            iconColor: Theme.c.touchDragGhost.icon
        }

        Text {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Theme.spacingXs
            visible: !ghostImage.visible && TouchDrag.label.length > 0
            text: TouchDrag.label
            color: Theme.c.touchDragGhost.foreground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeXs
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }
    }
}
