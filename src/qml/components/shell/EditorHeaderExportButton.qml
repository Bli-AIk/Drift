import QtQuick
import Drift

// Primary CTA. Kept as a bespoke gradient button (the documented
// exception to Themed* chrome), but it now has the hover, pressed and
// disabled states every other control has.
Item {
    id: exportButton
    signal exportRequested()

    readonly property bool busy: EditorState.exportInProgress

    width: exportRow.implicitWidth + Theme.spacing3xl
    height: 32
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
        radius: Theme.c.editorHeaderExportButton.radius
        color: Theme.c.editorHeaderExportButton.glow
    }

    ThemeSlot {
        anchors.fill: parent
        anchors.margins: 2
        // Brightens on hover, darkens on press. Label sits in this opacity group
        // so it fades with the fill, matching the previous nested rectangle.
        opacity: exportButton.busy ? 1
                 : (exportMouse.pressed ? 0.85 : (exportMouse.containsMouse ? 1 : 0.94))
        slot: "EditorHeaderExportButtonBackground"
        control: exportButton
        fallback: Component {
            Rectangle {
                anchors.fill: parent
                radius: Theme.c.editorHeaderExportButton.radius - 2
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Theme.c.editorHeaderExportButton.gradientTop }
                    GradientStop { position: 1.0; color: Theme.c.editorHeaderExportButton.gradientBottom }
                }
            }
        }

        Behavior on opacity {
            NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
        }

        Row {
            id: exportRow
            anchors.centerIn: parent
            spacing: Theme.spacingMd
            z: 1

            IconGlyph {
                glyph: Theme.icons.upload
                iconSize: Theme.iconSizeMd
                iconColor: Theme.c.editorHeaderExportButton.icon
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: qsTr("Export")
                color: Theme.c.editorHeaderExportButton.foreground
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
                color: Theme.c.editorHeaderExportButton.foreground
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
