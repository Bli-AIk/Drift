import QtQuick
import Drift

Rectangle {
    property string selectedFamily: ""
    property real rowWidth: 0
    signal familyChosen(string familyName)
    signal removeRequested(string familyName)
    id: row
    required property string name
    required property string previewFamily
    required property bool removable

    width: rowWidth
    height: 34
    color: rowMouse.containsMouse ? Theme.c.fontPickerFamilyRow.backgroundHover
                                  : (row.name === selectedFamily ? Theme.c.fontPickerFamilyRow.backgroundSelected
                                                              : "transparent")

    Behavior on color {
        ColorAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
    }

    Text {
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.right: removeButton.visible ? removeButton.left : parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        text: row.name
        font.family: row.previewFamily
        font.pixelSize: 18
        color: Theme.c.fontPickerFamilyRow.foreground
        elide: Text.ElideRight
    }

    MouseArea {
        id: rowMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: row.familyChosen(row.name)
    }

    IconButton {
        id: removeButton
        visible: row.removable
        anchors.right: parent.right
        anchors.rightMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        glyph: Theme.icons.x
        variant: "ghost"
        buttonSize: 24
        iconSize: 12
        tooltip: qsTr("Remove font")
        onClicked: row.removeRequested(row.name)
    }
}
