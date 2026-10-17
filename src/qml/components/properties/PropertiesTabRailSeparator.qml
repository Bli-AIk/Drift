import QtQuick
import Drift

// Hairline between desktop rail groups. Collapses completely when hidden so
// contextual tabs leave no gap.
Item {
    id: root

    property bool shown: false

    visible: shown
    width: parent ? parent.width : implicitWidth
    height: visible ? Theme.spacingLg + Theme.borderWidth : 0

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.iconSizeSm
        height: Theme.borderWidth
        radius: height / 2
        color: Theme.panelBorder
        opacity: 0.85
    }
}
