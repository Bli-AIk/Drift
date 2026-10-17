import QtQuick
import Drift

// One recent project. Long-press and the corner button open the same menu;
// the button is the visible equivalent of the gesture.
Rectangle {
    id: card

    required property var modelData

    signal openRequested(string path)

    height: Theme.androidHomeRecentCardHeight
    radius: Theme.radiusMd
    color: Theme.panelBackground
    border.width: Theme.borderWidth
    border.color: Theme.panelBorder
    opacity: modelData.exists === false ? 0.55 : 1

    Accessible.role: Accessible.Button
    Accessible.name: card.projectLabel

    readonly property string projectLabel: {
        const n = card.modelData.name || ""
        return n.replace(/\.drift$/i, "") || qsTr("Untitled")
    }

    Column {
        anchors.fill: parent
        anchors.margins: Theme.spacingLg
        spacing: Theme.spacingSm

        Rectangle {
            width: parent.width
            height: 32
            radius: Theme.radiusSm
            color: Theme.panelAccent

            IconGlyph {
                anchors.centerIn: parent
                glyph: Theme.icons.film
                iconSize: 18
                iconColor: Theme.mutedForeground
            }

            // Same on-disk signal the desktop recents list carries;
            // the card's dimming alone did not say what was wrong.
            AndroidAttentionDot {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 4
                dotColor: card.modelData.exists === false
                          ? Theme.mutedForeground : Theme.constructive
            }
        }

        Text {
            width: parent.width
            text: card.projectLabel
            color: Theme.panelForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeXs
            font.weight: Font.Medium
            elide: Text.ElideMiddle
        }

        // Elided from the left: on a narrow card the tail — the folder
        // and file name — is the half that tells two projects apart.
        Text {
            width: parent.width
            text: card.modelData.path
            color: Theme.mutedForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeXs
            elide: Text.ElideLeft
        }
    }

    MouseArea {
        anchors.fill: parent
        pressAndHoldInterval: 450
        property bool heldMenu: false
        onPressed: heldMenu = false
        onPressAndHold: {
            heldMenu = true
            Haptics.pickUp()
            cardMenu.popup()
        }
        onClicked: {
            if (heldMenu)
                return
            if (card.modelData.exists === false) {
                Toasts.warning(qsTr("That project file is missing."))
                return
            }
            Haptics.select()
            card.openRequested(card.modelData.path)
        }
    }

    // Long-press was the only way to reach this, which is a gesture
    // with no visible equivalent — the one rule the rest of the rail
    // already follows. The button is the equivalent; the long-press
    // stays as an accelerator.
    IconButton {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Theme.spacingXs
        buttonSize: Theme.iconButtonSize
        iconSize: Theme.iconSizeMd
        glyph: Theme.icons.ellipsis
        variant: "text"
        tooltip: qsTr("Project actions")
        onClicked: cardMenu.popup()
    }

    ThemedContextMenu {
        id: cardMenu

        ThemedMenuItem {
            text: qsTr("Remove from recents")
            icon.name: Theme.icons.trash
            onTriggered: EditorState.projectFile.removeRecentProject(card.modelData.path)
        }
    }
}
