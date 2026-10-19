import QtQuick
import QtQuick.Controls.Basic
import Drift

// Phone inspector tab: glyph stacked over the label. Not a ThemedChip — that
// one's contentItem is a single Text, and this needs two rows.
AbstractButton {
    id: tabChip

    required property int index
    required property var modelData

    property int activeTab: -1
    property real chipHeight: 58

    signal tabActivated(int index)

    readonly property bool current: activeTab === index

    anchors.verticalCenter: parent.verticalCenter
    height: chipHeight
    implicitWidth: Math.max(Theme.controlHeight + Theme.spacing2xl,
                            tabChipLabel.implicitWidth + Theme.spacingXl * 2)
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus

    Accessible.role: Accessible.PageTab
    Accessible.name: tabChip.modelData.label
    Accessible.checked: tabChip.current

    scale: tabChip.down ? Theme.pressScale : 1.0

    Behavior on scale {
        NumberAnimation { duration: Theme.durationPress; easing.type: Theme.easing }
    }

    onClicked: {
        Haptics.select()
        tabChip.tabActivated(tabChip.index)
    }

    background: Rectangle {
        radius: Theme.c.propertiesSheetTabChip.radius
        color: tabChip.current
               ? Theme.c.propertiesSheetTabChip.backgroundSelected
               : (tabChip.down ? Theme.c.propertiesSheetTabChip.backgroundPressed : Theme.c.propertiesSheetTabChip.background)
        border.width: Theme.c.propertiesSheetTabChip.borderWidth
        border.color: tabChip.current ? Theme.c.propertiesSheetTabChip.borderSelected : Theme.c.propertiesSheetTabChip.border

        Behavior on color {
            ColorAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
        }
        Behavior on border.color {
            ColorAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            border.width: Theme.c.propertiesSheetTabChip.borderWidthFocus
            border.color: Theme.c.propertiesSheetTabChip.borderFocus
            visible: tabChip.visualFocus
        }
    }

    // Wrapped in an Item so the two rows sit centred in the pill; a bare Column
    // would stack them against its top.
    contentItem: Item {
        Column {
            anchors.centerIn: parent
            spacing: Theme.spacingSm

            IconGlyph {
                anchors.horizontalCenter: parent.horizontalCenter
                glyph: tabChip.modelData.icon
                iconSize: Theme.iconSizeLg
                iconColor: tabChip.current ? Theme.c.propertiesSheetTabChip.iconOnAccent
                                           : Theme.c.propertiesSheetTabChip.icon
            }

            Text {
                id: tabChipLabel
                anchors.horizontalCenter: parent.horizontalCenter
                text: tabChip.modelData.label
                color: tabChip.current ? Theme.c.propertiesSheetTabChip.foregroundOnAccent
                                       : Theme.c.propertiesSheetTabChip.foreground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeXs
                font.weight: tabChip.current ? Font.Medium : Font.Normal
            }
        }
    }
}
