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
    radius: Theme.c.fontPickerTrigger.radius
    color: Theme.c.fontPickerTrigger.background
    border.width: (popupOpen || fieldFocused) ? Theme.c.fontPickerTrigger.borderWidth : 0
    border.color: fieldFocused ? Theme.c.fontPickerTrigger.borderFocus : Theme.c.fontPickerTrigger.borderSecondary

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
        color: Theme.c.fontPickerTrigger.foreground
        elide: Text.ElideRight
    }

    IconGlyph {
        id: chevron
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        glyph: Theme.icons.chevronDown
        iconSize: 12
        iconColor: Theme.c.fontPickerTrigger.icon
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
