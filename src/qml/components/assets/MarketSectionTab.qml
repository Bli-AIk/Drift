import QtQuick
import Drift

// One text tab in the Market: Assets, SFX, or a stock source.
Item {
    required property var modelData
    property string section: ""
    signal sectionSelected(string id)
    readonly property bool active: section === modelData.id
    width: tabLabel.implicitWidth
    height: tabLabel.implicitHeight + Theme.spacingLg + 2
    Accessible.role: Accessible.PageTab
    Accessible.name: tabLabel.text
    Accessible.checked: active

    Text {
        id: tabLabel
        anchors.top: parent.top
        anchors.topMargin: Theme.spacingSm
        text: modelData.label || modelData.id
        color: parent.active || tabHover.hovered ? Theme.panelForeground : Theme.mutedForeground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSm
        font.weight: parent.active ? Font.DemiBold : Font.Medium
    }
    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 2
        radius: 1
        color: Theme.primary
        opacity: parent.active ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.durationBase; easing.type: Theme.easing } }
    }
    HoverHandler { id: tabHover; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: sectionSelected(modelData.id) }
}
