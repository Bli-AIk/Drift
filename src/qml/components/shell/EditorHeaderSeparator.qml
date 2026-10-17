import QtQuick
import Drift

Item {
    width: Theme.spacingLg + Theme.borderWidth
    height: 32
    anchors.verticalCenter: parent.verticalCenter

    Rectangle {
        width: Theme.borderWidth
        height: 16
        anchors.centerIn: parent
        color: Theme.panelBorder
    }
}
