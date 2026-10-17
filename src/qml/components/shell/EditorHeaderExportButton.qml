import QtQuick
import Drift

// Primary CTA. Kept as a bespoke gradient button (the documented
// exception to Themed* chrome), but it now has the hover, pressed and
// disabled states every other control has.
Rectangle {
    id: exportButton
    signal exportRequested()

    readonly property bool busy: EditorState.exportInProgress

    width: exportRow.implicitWidth + Theme.spacing3xl
    height: 32
    radius: Theme.radiusMd
    color: Theme.exportGlow
    anchors.verticalCenter: parent.verticalCenter
    opacity: busy ? 0.55 : 1
    scale: exportMouse.pressed && !busy ? 0.97 : 1

    Behavior on opacity {
        NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
    }
    Behavior on scale {
        NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
    }

    Accessible.role: Accessible.Button
    Accessible.name: qsTr("Export video")

    Rectangle {
        anchors.fill: parent
        anchors.margins: 2
        radius: parent.radius - 2
        // Brightens on hover, darkens on press.
        opacity: exportButton.busy ? 1
                 : (exportMouse.pressed ? 0.85 : (exportMouse.containsMouse ? 1 : 0.94))

        Behavior on opacity {
            NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
        }

        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Theme.exportGradientTop }
            GradientStop { position: 1.0; color: Theme.exportGradientBottom }
        }

        Row {
            id: exportRow
            anchors.centerIn: parent
            spacing: Theme.spacingMd

            IconGlyph {
                glyph: Theme.icons.upload
                iconSize: Theme.iconSizeMd
                iconColor: Theme.primaryForeground
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: qsTr("Export")
                color: Theme.primaryForeground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSm
                font.weight: Font.Medium
                anchors.verticalCenter: parent.verticalCenter
            }

            // Fixed-width so ticking percentages do not resize the
            // button and jolt the whole header row.
            Text {
                visible: exportButton.busy
                width: visible ? 34 : 0
                text: Math.round(EditorState.exportProgress * 100) + "%"
                color: Theme.primaryForeground
                font.family: Theme.monoFontFamily
                font.pixelSize: Theme.fontSizeSm
                horizontalAlignment: Text.AlignRight
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    ThemedToolTip {
        visible: exportMouse.containsMouse
        text: exportButton.busy ? qsTr("Export already in progress")
                                : qsTr("Export video")
    }

    MouseArea {
        id: exportMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: exportButton.busy ? Qt.ArrowCursor : Qt.PointingHandCursor
        onClicked: if (!exportButton.busy) exportButton.exportRequested()
    }
}
