import QtQuick
import Drift

// One track-type row in the new-track menu.
Rectangle {
    property NewTrackMenu menu
    id: trackTypeRow
    required property var modelData
    required property int index

    width: parent.width
    height: Theme.controlHeight + Theme.spacingXs
    radius: Theme.c.newTrackMenuEntry.radius
    color: itemMouse.containsMouse || menu.highlightIndex === index
           ? Theme.c.newTrackMenuEntry.backgroundHover : "transparent"

    Behavior on color {
        ColorAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
    }

    Row {
        anchors.fill: parent
        anchors.leftMargin: Theme.spacingLg
        anchors.rightMargin: Theme.spacingLg
        spacing: Theme.spacingLg + Theme.spacingXs

        IconGlyph {
            anchors.verticalCenter: parent.verticalCenter
            glyph: trackTypeRow.modelData.icon
            iconSize: Theme.iconSizeMd
            iconColor: Theme.c.newTrackMenuEntry.icon
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: trackTypeRow.modelData.label
            color: Theme.c.newTrackMenuEntry.foreground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSm
        }
    }

    MouseArea {
        id: itemMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: menu.highlightIndex = trackTypeRow.index
        onClicked: {
            // Adding a track rebuilds trackTypes and destroys this delegate,
            // so close first while root is still reachable.
            Haptics.confirm()
            menu.close()
            menu.addTrackOfType(trackTypeRow.modelData.type)
        }
    }
}
