import QtQuick
import Drift

Rectangle {
    property var card
    property var inspector
    width: parent.width
    height: audioEffectHeader.implicitHeight + 8
    radius: Theme.radiusSm
    color: Theme.panelAccent

    Row {
        id: audioEffectHeader
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 8
        anchors.rightMargin: 4
        spacing: 2

        IconGlyph {
            anchors.verticalCenter: parent.verticalCenter
            glyph: card.effectData.icon || "audio-lines"
            iconSize: 14
            iconColor: Theme.mutedForeground
            opacity: card.effectEnabled ? 1 : 0.5
        }
        Text {
            text: card.effectData.missing
                  ? qsTr("%1 (not installed)").arg(card.effectData.label)
                  : card.effectData.label
            color: card.effectEnabled
                   ? Theme.panelForeground : Theme.mutedForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSm
            font.weight: Font.Medium
            width: parent.width - 22 * 5 - 20 - 8
            elide: Text.ElideRight
            anchors.verticalCenter: parent.verticalCenter
        }
        IconButton {
            glyph: Theme.icons.chevronUp
            variant: "ghost"
            buttonSize: 22
            iconSize: 12
            enabled: card.index > 0
            tooltip: qsTr("Move audio effect up")
            onClicked: EditorState.moveAudioEffect(
                           EditorState.selectedTrack, EditorState.selectedClip,
                           card.index, card.index - 1)
        }
        IconButton {
            glyph: Theme.icons.chevronDown
            variant: "ghost"
            buttonSize: 22
            iconSize: 12
            enabled: card.index < inspector.selectedAudioEffects.length - 1
            tooltip: qsTr("Move audio effect down")
            onClicked: EditorState.moveAudioEffect(
                           EditorState.selectedTrack, EditorState.selectedClip,
                           card.index, card.index + 1)
        }
        IconButton {
            glyph: card.effectEnabled ? Theme.icons.eye : Theme.icons.eyeOff
            variant: "ghost"
            buttonSize: 22
            iconSize: 12
            tooltip: card.effectEnabled
                     ? qsTr("Disable audio effect") : qsTr("Enable audio effect")
            onClicked: EditorState.setAudioEffectEnabled(
                           EditorState.selectedTrack, EditorState.selectedClip,
                           card.index, !card.effectEnabled)
        }
        IconButton {
            glyph: Theme.icons.copy
            variant: "ghost"
            buttonSize: 22
            iconSize: 12
            tooltip: qsTr("Copy this audio effect")
            onClicked: EditorState.copyAudioEffectToClipboard(
                           EditorState.selectedTrack, EditorState.selectedClip,
                           card.index)
        }
        IconButton {
            glyph: Theme.icons.x
            variant: "ghost"
            buttonSize: 22
            iconSize: 12
            tooltip: qsTr("Remove audio effect")
            onClicked: EditorState.removeAudioEffect(
                           EditorState.selectedTrack, EditorState.selectedClip,
                           card.index)
        }
    }
}
