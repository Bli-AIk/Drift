import QtQuick
import Drift

// Video Attributes Section
Column {
    required property PasteAttributesDialog dialog
    width: parent.width
    spacing: Theme.spacingSm

    ThemedLabel {
        text: qsTr("Video Attributes")
        size: "xs"
        color: Theme.c.pasteAttributesVideoSection.foreground
        font.weight: Font.DemiBold
    }

    ThemedCheckBox {
        width: parent.width
        text: qsTr("Transform (motion, position, scale, opacity)")
        checked: dialog.pasteTransform
        enabled: dialog.clipAttrs.hasTransform !== false
        onToggled: dialog.pasteTransform = checked
    }

    ThemedCheckBox {
        width: parent.width
        text: {
            if (dialog.clipAttrs.hasSpeed) {
                const spd = (dialog.clipAttrs.speed || 1.0).toFixed(2)
                const rev = dialog.clipAttrs.reverse ? qsTr(", reverse") : ""
                const curve = dialog.clipAttrs.hasSpeedCurve ? qsTr(", speed curve") : ""
                return qsTr("Speed / Retime (%1x%2%3)").arg(spd).arg(rev).arg(curve)
            }
            return qsTr("Speed / Retime")
        }
        checked: dialog.pasteSpeed
        enabled: dialog.clipAttrs.isAudioOrVideo !== false
        onToggled: dialog.pasteSpeed = checked
    }

    ThemedCheckBox {
        id: videoEffectsCheck
        width: parent.width
        text: {
            const count = dialog.clipAttrs.effectCount || 0
            return count > 0
                ? qsTr("Video Effects (%n effect(s))", "", count)
                : qsTr("Video Effects (none)")
        }
        checked: dialog.pasteEffects
        enabled: (dialog.clipAttrs.effectCount || 0) > 0
        onToggled: dialog.pasteEffects = checked
    }
}
