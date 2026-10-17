import QtQuick
import QtQuick.Controls.Basic
import Drift

// Quick edit or New project: a full-width home tile.
AbstractButton {
    id: tile

    required property var modelData

    signal triggered(string tileId)

    height: Theme.androidHomeTileHeight
    hoverEnabled: true

    Accessible.role: Accessible.Button
    Accessible.name: modelData.label
    Accessible.description: modelData.detail

    scale: tile.down ? Theme.pressScale : 1.0
    Behavior on scale {
        NumberAnimation { duration: Theme.durationPress; easing.type: Theme.easing }
    }

    onClicked: {
        Haptics.select()
        tile.triggered(modelData.id)
    }

    background: Rectangle {
        radius: Theme.radiusMd
        color: tile.modelData.primary
               ? (tile.down ? Qt.darker(Theme.primary, 1.15) : Theme.primary)
               : (tile.down ? Theme.panelMuted : Theme.panelBackground)
        border.width: tile.modelData.primary ? 0 : Theme.borderWidth
        border.color: Theme.panelBorder
    }

    contentItem: Row {
        spacing: Theme.spacingLg
        leftPadding: Theme.spacingXl
        rightPadding: Theme.spacingXl

        IconGlyph {
            anchors.verticalCenter: parent.verticalCenter
            glyph: tile.modelData.icon
            iconSize: Theme.iconSizeLg
            iconColor: tile.modelData.primary
                       ? Theme.primaryForeground : Theme.panelForeground
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                text: tile.modelData.label
                color: tile.modelData.primary
                       ? Theme.primaryForeground : Theme.panelForeground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeBase
                font.weight: Font.Medium
            }

            Text {
                text: tile.modelData.detail
                color: tile.modelData.primary
                       ? Theme.primaryForeground : Theme.mutedForeground
                opacity: tile.modelData.primary ? 0.85 : 1
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeXs
            }
        }
    }
}
