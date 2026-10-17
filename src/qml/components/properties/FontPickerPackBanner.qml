import QtQuick
import Drift

Rectangle {
    id: root
    property bool shown: false
    property real rowWidth: 0
    signal packRequested()
    width: rowWidth
    height: shown ? 40 : 0
    visible: shown
    color: Theme.panelSecondaryBg

    Text {
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        // The count was baked into the translated string, so it could
        // not be updated or pluralised.
        text: qsTr("Install the font pack for curated families →")
        color: Theme.primary
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSm
        elide: Text.ElideRight
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.packRequested()
    }
}
