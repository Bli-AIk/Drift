import QtQuick
import Drift

Item {
    id: section
    property string title: ""
    default property alias content: body.data

    width: parent ? parent.width : 0
    implicitHeight: cardCol.implicitHeight
    height: implicitHeight

    ThemeSlot {
        anchors.fill: parent
        slot: "SettingsSectionCardBackground"
        control: section
        fallback: Component {
            Rectangle {
                anchors.fill: parent
                radius: Theme.c.settingsSectionCard.radius
                color: Theme.c.settingsSectionCard.background
                border.width: Theme.c.settingsSectionCard.borderWidth
                border.color: Theme.c.settingsSectionCard.border
            }
        }
    }

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
            color: Theme.c.settingsSectionCard.foreground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSm
            font.weight: Font.DemiBold
        }

        Rectangle {
            width: parent.width
            height: Theme.c.settingsSectionCard.borderWidth
            color: Theme.c.settingsSectionCard.divider
        }

        Column {
            id: body
            width: parent.width
            spacing: Theme.spacingLg
        }
    }
}
