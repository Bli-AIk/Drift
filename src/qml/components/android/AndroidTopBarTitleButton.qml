import QtQuick
import QtQuick.Controls.Basic
import Drift

// The project title is the affordance: a wide, self-labelling target in the middle of
// the bar rather than an unlabelled glyph in the corner.
AbstractButton {
    id: titleBtn

    // Clamped against what the right-hand cluster actually leaves, not a fixed 140:
    // the export pill is wider than the icon it replaced.
    property real maxTextWidth: 0
    property string projectName: ""
    property bool unsaved: false
    property bool updateAvailable: false

    signal requested()

    height: Theme.androidIconButtonSize
    hoverEnabled: true

    Accessible.role: Accessible.Button
    Accessible.name: titleText.text
    Accessible.description: qsTr("Project actions")

    scale: titleBtn.down ? Theme.pressScale : 1.0

    Behavior on scale {
        NumberAnimation { duration: Theme.durationPress; easing.type: Theme.easing }
    }

    background: Rectangle {
        radius: Theme.radiusSm
        color: titleBtn.down ? Theme.panelAccent : "transparent"

        Behavior on color {
            ColorAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
        }
    }

    contentItem: Row {
        spacing: Theme.spacingMd
        leftPadding: Theme.spacingMd
        rightPadding: Theme.spacingMd

        Text {
            id: titleText
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, Math.max(0, titleBtn.maxTextWidth))
            text: titleBtn.projectName.length > 0 ? titleBtn.projectName : qsTr("Untitled")
            color: Theme.foreground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSm
            font.weight: Font.Medium
            elide: Text.ElideRight
        }

        AndroidAttentionDot {
            anchors.verticalCenter: parent.verticalCenter
            dotColor: titleBtn.unsaved ? Theme.destructive : Theme.constructive
        }

        IconGlyph {
            anchors.verticalCenter: parent.verticalCenter
            glyph: Theme.icons.chevronDown
            iconSize: Theme.iconSizeMd
            iconColor: Theme.mutedForeground

            // The update row lives in the project sheet's App section.
            AndroidAttentionDot {
                visible: titleBtn.updateAvailable
                anchors.right: parent.right
                anchors.top: parent.top
            }
        }
    }

    onClicked: {
        Haptics.press()
        titleBtn.requested()
    }
}
