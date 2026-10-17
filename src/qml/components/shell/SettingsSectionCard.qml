import QtQuick
import Drift

Rectangle {
    id: section
    property string title: ""
    default property alias content: body.data

    width: parent ? parent.width : 0
    implicitHeight: cardCol.implicitHeight
    height: implicitHeight
    radius: Theme.radiusMd
    color: Theme.darkMode ? Theme.panelAccent : Theme.appBackground
    border.width: Theme.borderWidth
    border.color: Theme.panelBorder

    Column {
        id: cardCol
        x: Theme.spacingXl
        width: parent.width - Theme.spacingXl * 2
        topPadding: Theme.spacingXl
        bottomPadding: Theme.spacingXl
        spacing: Theme.spacingLg

        Text {
            width: parent.width
            text: section.title
            color: Theme.panelForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSm
            font.weight: Font.DemiBold
        }

        Rectangle {
            width: parent.width
            height: Theme.borderWidth
            color: Theme.panelBorder
        }

        Column {
            id: body
            width: parent.width
            spacing: Theme.spacingLg
        }
    }
}
