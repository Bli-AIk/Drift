import QtQuick
import Drift

// Foldable group title on an effect card (the relight package's lights).
Rectangle {
    id: root

    property bool groupOpen: false
    property string groupTitle: ""
    signal toggled()

    width: parent ? parent.width : implicitWidth
    height: groupLabel.implicitHeight + 8
    radius: Theme.radiusSm
    color: groupMouse.containsMouse ? Theme.panelAccent : "transparent"

    Text {
        id: groupLabel
        anchors.left: parent.left
        anchors.leftMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        text: (root.groupOpen ? "▾  " : "▸  ") + root.groupTitle
        color: Theme.panelForeground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeXs
        font.weight: Font.Medium
    }
    MouseArea {
        id: groupMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
