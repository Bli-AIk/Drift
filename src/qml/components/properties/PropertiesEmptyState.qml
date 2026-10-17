import QtQuick
import Drift

// Empty inspector: icon, title, and the sheet-vs-desktop hint.
Column {
    id: root

    property bool sheetMode: false
    property real panelWidth: 260

    width: Math.min(260, panelWidth - 32)
    spacing: 16

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        width: 48
        height: 48
        radius: Theme.radiusMd
        color: "transparent"
        border.width: 1
        border.color: Theme.panelBorder

        IconGlyph {
            anchors.centerIn: parent
            glyph: Theme.icons.sliders
            iconSize: 22
            iconColor: Theme.mutedForeground
        }
    }

    Text {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: qsTr("It's empty here")
        color: Theme.panelForeground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeBase
        font.weight: Font.Medium
    }

    Text {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        text: root.sheetMode
              ? qsTr("Tap a clip on the timeline to edit its properties")
              : qsTr("Click a clip on the timeline to edit its properties")
        color: Theme.mutedForeground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeXs
    }
}
