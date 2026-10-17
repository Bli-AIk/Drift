import QtQuick
import Drift

Column {
    property real tileWidth: 64
    property var host
    signal menuRequested()
    id: propTile
    required property var modelData
    readonly property bool selected: modelData.modelPath === host.modelPath
    width: tileWidth
    spacing: 2

    Rectangle {
        width: parent.width
        height: width
        radius: Theme.radiusSm
        color: tileMouse.containsMouse ? Theme.popoverHover : Theme.panelAccent
        border.width: propTile.selected ? Theme.borderWidthFocus : 0
        border.color: Theme.primary
        clip: true

        Image {
            id: propImage
            anchors.fill: parent
            anchors.margins: 4
            visible: !!propTile.modelData.thumbnailPath
            source: propTile.modelData.thumbnailPath
                    ? EditorState.imageUrl(propTile.modelData.thumbnailPath) : ""
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            // A re-import replaces the file at the same path.
            cache: false
            sourceSize.width: 128
            sourceSize.height: 128
        }

        IconGlyph {
            anchors.centerIn: parent
            visible: !propTile.modelData.thumbnailPath || propImage.status === Image.Error
            glyph: Theme.icons.package
            iconSize: Theme.iconSizeLg
            iconColor: Theme.mutedForeground
        }

        ThemedToolTip {
            text: propTile.modelData.description
                  ? propTile.modelData.name + "\n" + propTile.modelData.description
                  : propTile.modelData.name
            visible: tileMouse.containsMouse
        }

        MouseArea {
            id: tileMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            pressAndHoldInterval: 450
            property bool heldMenu: false
            property bool pressedByTouch: false

            function openMenu() {
                if (!propTile.modelData.removable)
                    return
                host.menuPropId = propTile.modelData.id
                host.menuPropName = propTile.modelData.name
                propTile.menuRequested()
            }

            onPressed: (mouse) => {
                heldMenu = false
                pressedByTouch = mouse.source !== Qt.MouseEventNotSynthesized
            }
            onPressAndHold: {
                if (!pressedByTouch)
                    return
                heldMenu = true
                openMenu()
            }
            onClicked: (mouse) => {
                if (mouse.button === Qt.RightButton) {
                    openMenu()
                    return
                }
                if (heldMenu)
                    return
                Haptics.select()
                const track = EditorState.selectedTrack
                const clip = EditorState.selectedClip
                const effect = host.effectIndex
                const propId = propTile.modelData.id
                Qt.callLater(() => EditorState.applyFaceProp(track, clip, effect, propId))
            }
        }
    }

    Text {
        width: parent.width
        text: propTile.modelData.name
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        color: propTile.selected ? Theme.primary : Theme.mutedForeground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeXs
    }
}
