import QtQuick
import QtQuick.Controls.Basic
import Drift

// The 64dp labelled row every phone bottom sheet is built from: icon tile, label, and a
// detail line that says what the thing does.
//
// The detail line is the point. On a phone an icon-only control has no hover, so every
// tooltip string in the editor was unreachable text; these rows are where those strings
// become visible body copy. Extracted from AndroidAddMenu once the project and more-tools
// sheets wanted the same shape.
AbstractButton {
    id: root

    property string label: ""
    property string detail: ""
    property string glyph: ""
    // A toggle shows its state as a switch and does not dismiss its sheet; an action does.
    property bool toggle: false
    property color tint: Theme.panelForeground
    // Landscape cutout / gesture-bar inset, passed down from the hosting sheet.
    property real sideInset: 0
    property real sideInsetRight: 0
    // Small destructive dot on the right — "this row has something outstanding".
    property bool marked: false

    height: Theme.androidAddRowHeight
    hoverEnabled: true

    Accessible.role: root.toggle ? Accessible.CheckBox : Accessible.Button
    Accessible.name: root.label
    Accessible.description: root.detail
    Accessible.checkable: root.toggle
    Accessible.checked: root.checked
    Accessible.onPressAction: root.clicked()

    scale: root.down ? Theme.pressScale : 1.0

    Behavior on scale {
        NumberAnimation { duration: Theme.durationPress; easing.type: Theme.easing }
    }

    background: Rectangle {
        color: root.down ? Theme.panelAccent : "transparent"

        Behavior on color {
            ColorAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
        }
    }

    contentItem: Item {
        anchors.fill: parent
        opacity: root.enabled ? 1 : 0.45

        AndroidSheetActionIconTile {
            id: iconTile
            anchors.left: parent.left
            anchors.leftMargin: Theme.pagePadding + root.sideInset
            anchors.verticalCenter: parent.verticalCenter
            glyph: root.glyph
            tint: root.tint
        }

        Column {
            anchors.left: iconTile.right
            anchors.leftMargin: Theme.spacing2xl - Theme.spacingSm
            anchors.right: trailing.left
            anchors.rightMargin: Theme.spacingLg
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            Text {
                width: parent.width
                text: root.label
                color: root.tint
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeBase
                font.weight: Font.Medium
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                visible: root.detail.length > 0
                text: root.detail
                color: Theme.mutedForeground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSm
                elide: Text.ElideRight
            }
        }

        Item {
            id: trailing
            anchors.right: parent.right
            anchors.rightMargin: Theme.pagePadding + root.sideInsetRight
            anchors.verticalCenter: parent.verticalCenter
            width: root.toggle ? switchTrack.width : (root.marked ? markDot.width : 0)
            height: parent.height

            // Drawn rather than a ThemedSwitch: the whole row is the target, and a real
            // switch nested inside a button either fights it for the press or has to be
            // disabled, which greys it out exactly when its state is what you came to read.
            AndroidSheetActionSwitch {
                id: switchTrack
                anchors.verticalCenter: parent.verticalCenter
                visible: root.toggle
                checked: root.checked
            }

            AndroidSheetActionMark {
                id: markDot
                anchors.verticalCenter: parent.verticalCenter
                visible: root.marked && !root.toggle
            }
        }
    }
}
