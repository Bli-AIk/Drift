import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Window
import Drift
// One built-in text style pack card.
Column {
    id: root
    required property var modelData
    required property real cardSize
    signal added()
    width: cardSize
    spacing: Theme.spacingSm

    opacity: packDrag.active ? 0.85 : 1
    scale: packDrag.active ? 1.04 : packDrag.pressed ? 0.97 : (packDrag.hovered ? 1.02 : 1.0)
    Behavior on scale {
        NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
    }

    TextStylePackThumb {
        width: parent.width
        height: Math.round(width * 0.55)
        presetId: root.modelData.id
        hovered: packDrag.hovered

        AssetDragSource {
            id: packDrag
            hasContextMenu: true
            onContextMenuRequested: cardMenu.popup()
            anchors.fill: parent
            kind: "textStyle"
            payload: root.modelData.id
            label: root.modelData.label
            glyph: Theme.icons.type
            onTapped: {
                EditorState.addTextClip("", -1, root.modelData.id)
                added()
            }
        }

        ThemedToolTip {
            text: qsTr("%1 — click to add at the playhead, or drag to the timeline. Double-click it on the preview to edit.").arg(root.modelData.label)
            visible: packDrag.hovered && !packDrag.active
        }

        ThemedContextMenu {
            id: cardMenu

            ThemedMenuItem {
                text: qsTr("Add at playhead")
                icon.name: Theme.icons.plus
                onTriggered: packDrag.tapped()
            }
        }
    }

    Text {
        width: parent.width
        text: root.modelData.label
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        color: packDrag.hovered ? Theme.panelForeground : Theme.mutedForeground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeXs

        Behavior on color {
            ColorAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
        }
    }
}
