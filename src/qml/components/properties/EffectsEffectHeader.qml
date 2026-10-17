import QtQuick
import Drift

Rectangle {
    property var card
    property var inspector
    width: parent.width
    height: effectHeader.implicitHeight + 8
    radius: Theme.c.effectsEffectHeader.radius
    color: Theme.c.effectsEffectHeader.background

    // Save-as-preset lives here rather than in the header row: a fifth ghost
    // button already crowds a 22px row at panel width, and a sixth would leave
    // the label permanently elided.
    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: effectCardMenu.popup()
    }
    TapHandler {
        acceptedDevices: PointerDevice.TouchScreen
        onLongPressed: effectCardMenu.popup(parent, point.position.x, point.position.y)
    }
    ThemedContextMenu {
        id: effectCardMenu
        ThemedMenuItem {
            text: qsTr("Copy this effect")
            icon.name: Theme.icons.copy
            onTriggered: EditorState.copyEffectToClipboard(
                             EditorState.selectedTrack, EditorState.selectedClip,
                             card.index)
        }
        ThemedMenuItem {
            text: qsTr("Save as preset…")
            icon.name: Theme.icons.save
            onTriggered: inspector.saveEffectPresetRequested(card.index)
        }
    }

    Row {
        id: effectHeader
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 8
        anchors.rightMargin: 4
        spacing: 2

        Text {
            // An effect from an addon that is not installed has no catalog entry,
            // so it renders with no params at all; saying so beats a blank card.
            text: card.effectData.missing
                  ? qsTr("%1 (not installed)").arg(card.effectData.label)
                  : card.effectData.label
            color: card.effectEnabled
                   ? Theme.c.effectsEffectHeader.foreground : Theme.c.effectsEffectHeader.foregroundDisabled
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSm
            font.weight: Font.Medium
            width: parent.width - 22 * 5 - 8
            elide: Text.ElideRight
            anchors.verticalCenter: parent.verticalCenter
        }
        IconButton {
            glyph: Theme.icons.chevronUp
            variant: "ghost"
            buttonSize: 22
            iconSize: 12
            enabled: card.index > 0
            tooltip: qsTr("Move effect up")
            onClicked: EditorState.moveEffect(
                           EditorState.selectedTrack, EditorState.selectedClip,
                           card.index, card.index - 1)
        }
        IconButton {
            glyph: Theme.icons.chevronDown
            variant: "ghost"
            buttonSize: 22
            iconSize: 12
            enabled: card.index < inspector.selectedEffects.length - 1
            tooltip: qsTr("Move effect down")
            onClicked: EditorState.moveEffect(
                           EditorState.selectedTrack, EditorState.selectedClip,
                           card.index, card.index + 1)
        }
        IconButton {
            glyph: card.effectEnabled ? Theme.icons.eye : Theme.icons.eyeOff
            variant: "ghost"
            buttonSize: 22
            iconSize: 12
            tooltip: card.effectEnabled
                     ? qsTr("Disable effect") : qsTr("Enable effect")
            onClicked: EditorState.setEffectEnabled(
                           EditorState.selectedTrack, EditorState.selectedClip,
                           card.index, !card.effectEnabled)
        }
        IconButton {
            glyph: Theme.icons.copy
            variant: "ghost"
            buttonSize: 22
            iconSize: 12
            tooltip: qsTr("Copy this effect")
            onClicked: EditorState.copyEffectToClipboard(
                           EditorState.selectedTrack, EditorState.selectedClip,
                           card.index)
        }
        IconButton {
            glyph: Theme.icons.x
            variant: "ghost"
            buttonSize: 22
            iconSize: 12
            tooltip: qsTr("Remove effect")
            onClicked: EditorState.removeEffect(
                           EditorState.selectedTrack, EditorState.selectedClip,
                           card.index)
        }
    }
}
