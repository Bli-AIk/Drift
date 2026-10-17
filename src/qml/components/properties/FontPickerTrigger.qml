import QtQuick
import Drift

Rectangle {
    id: root
    property string displayFamily: ""
    property string previewFamily: ""
    property bool fieldFocused: false
    property bool popupOpen: false
    signal toggled()
    anchors.fill: parent
    radius: Theme.radiusSm
    color: Theme.panelAccent
    border.width: (popupOpen || fieldFocused) ? 1 : 0
    border.color: fieldFocused ? Theme.primary : Theme.panelSecondaryBorder

    Text {
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.right: chevron.left
        anchors.rightMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        text: displayFamily
        // Preview the current selection in the face it actually is.
        font.family: previewFamily === "" ? Theme.fontFamily : previewFamily
        font.pixelSize: Theme.fontSizeSm
        color: Theme.panelForeground
        elide: Text.ElideRight
    }

    IconGlyph {
        id: chevron
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        glyph: Theme.icons.chevronDown
        iconSize: 12
        iconColor: Theme.mutedForeground
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
