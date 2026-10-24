import QtQuick
import Drift

// Audio Attributes Section
Column {
    required property var dialog
    width: parent.width
    spacing: Theme.spacingSm

    ThemedLabel {
        text: qsTr("Audio Attributes")
        size: "xs"
        color: Theme.c.pasteAttributesAudioSection.foreground
        font.weight: Font.DemiBold
    }

    ThemedCheckBox {
        width: parent.width
        text: qsTr("Volume & Fades (volume keyframes, in/out ramps)")
        checked: dialog.pasteVolume
        enabled: dialog.clipAttrs.isAudioOrVideo !== false
        onToggled: dialog.pasteVolume = checked
    }

    ThemedCheckBox {
        id: audioEffectsCheck
        width: parent.width
        text: {
            const count = dialog.clipAttrs.audioEffectCount || 0
            return count > 0
                ? qsTr("Audio Effects (%n effect(s))", "", count)
                : qsTr("Audio Effects (none)")
        }
        checked: dialog.pasteAudioEffects
        enabled: (dialog.clipAttrs.audioEffectCount || 0) > 0
        onToggled: dialog.pasteAudioEffects = checked
    }
}
