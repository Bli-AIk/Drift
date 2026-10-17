import QtQuick
import QtQuick.Layouts
import Drift

Rectangle {
    id: root
    signal addRequested()
    Layout.fillWidth: true
    Layout.preferredHeight: 34
    color: addMouse.containsMouse ? Theme.c.fontPickerAddRow.backgroundHover : "transparent"

    Text {
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        text: qsTr("Add font file…")
        color: Theme.c.fontPickerAddRow.foregroundAccent
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSm
        elide: Text.ElideRight
    }

    MouseArea {
        id: addMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.addRequested()
    }
}
