pragma ComponentBehavior: Bound
import QtQuick
import Drift

Rectangle {
    id: root

    required property var panel

    implicitHeight: Theme.controlHeightSm
    color: Theme.c.subtitleCueGrid.headerBackground

    component HeaderCell: Text {
        height: root.height
        verticalAlignment: Text.AlignVCenter
        color: Theme.c.subtitleCueGrid.headerForeground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeXs
        font.weight: Font.Medium
        elide: Text.ElideRight
    }

    Row {
        anchors.fill: parent
        leftPadding: Theme.c.subtitleCueGrid.markerWidth

        HeaderCell {
            width: root.panel.colNumberWidth
            rightPadding: Theme.spacingMd
            horizontalAlignment: Text.AlignRight
            text: qsTr("#")
        }
        HeaderCell {
            width: root.panel.colTimeWidth
            leftPadding: Theme.spacingMd
            text: qsTr("Start")
        }
        HeaderCell {
            width: root.panel.colTimeWidth
            leftPadding: Theme.spacingMd
            text: qsTr("End")
        }
        HeaderCell {
            width: root.panel.colDurationWidth
            leftPadding: Theme.spacingMd
            text: qsTr("Duration")
        }
        HeaderCell {
            width: root.width - root.panel.fixedColumnsWidth
            leftPadding: Theme.spacingMd
            text: qsTr("Text")
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: Theme.c.subtitleCueGrid.borderWidth
        color: Theme.c.subtitleCueGrid.border
    }
}
