import QtQuick
import Drift
// One detected shot: filmstrip frame, time range, and motion/loudness bars.
Rectangle {
    id: root

    property int tileRevision: 0
    width: ListView.view ? ListView.view.width : 0
    height: 56
    radius: Theme.radiusSm
    color: rowMouse.containsMouse ? Theme.panelMuted : "transparent"
    border.width: Theme.borderWidth
    border.color: rowMouse.containsMouse ? Theme.panelBorder : "transparent"

    required property var modelData

    Row {
        anchors.fill: parent
        anchors.margins: Theme.spacingXs
        spacing: Theme.spacingMd

        Rectangle {
            width: 80
            height: parent.height
            radius: Theme.radiusXs
            color: Theme.skeletonColor
            clip: true

            Image {
                anchors.fill: parent
                // A recycled row keeps its old frame until the new one decodes.
                visible: status === Image.Ready
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                // Level 0 tiles cover one source second each, so the tile index is
                // simply the whole second the representative frame falls in.
                source: {
                    root.tileRevision // re-evaluate when a decode lands
                    return EditorState.scenes.clipPath === ""
                        ? ""
                        : EditorState.filmstripTileUrl(
                              EditorState.scenes.clipPath, 0,
                              Math.floor(root.modelData.thumbnailSeconds),
                              EditorState.scenes.clipRotationCorrection)
                }
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                text: qsTr("Scene %1").arg(root.modelData.index + 1)
                color: Theme.foreground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeXs
                font.bold: true
            }

            Text {
                text: qsTr("%1 – %2  ·  %3s")
                    .arg(Number(root.modelData.sourceStart).toFixed(2))
                    .arg(Number(root.modelData.sourceEnd).toFixed(2))
                    .arg(Number(root.modelData.duration).toFixed(2))
                color: Theme.mutedForeground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeXs
            }

            Text {
                visible: (root.modelData.labels || []).length > 0
                text: (root.modelData.labels || []).slice(0, 4).join(", ")
                color: Theme.mutedForeground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeXs
                elide: Text.ElideRight
                width: Math.max(0, root.width - 200)
            }
        }
    }

    // Signal bars, right-aligned: movement over loudness. Kept separate rather
    // than folded into one number so the ranking is explainable at a glance.
    Column {
        anchors.right: parent.right
        anchors.rightMargin: Theme.spacingMd
        anchors.verticalCenter: parent.verticalCenter
        spacing: 3

        Repeater {
            model: [
                { value: root.modelData.motion, tint: Theme.primary },
                { value: root.modelData.loudness, tint: Theme.beatOnsetColor }
            ]
            Rectangle {
                required property var modelData
                width: 48
                height: 4
                radius: 2
                color: Theme.panelMuted

                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, parent.modelData.value))
                    height: parent.height
                    radius: parent.radius
                    color: parent.modelData.tint
                }
            }
        }
    }

    MouseArea {
        id: rowMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            Haptics.select()
            EditorState.scenes.seekTo(root.modelData.index)
        }
    }
}
