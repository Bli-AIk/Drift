import QtQuick
import Drift

// Clickable colour chip. The field that owns it opens the dialog.
Rectangle {
    id: root

    property string hex: "#ffffffff"
    property string tip: qsTr("Choose colour")
    signal activated()

    width: Theme.spacing3xl
    height: Theme.spacing3xl
    radius: Theme.radiusSm
    anchors.verticalCenter: parent.verticalCenter
    color: root.hex
    border.width: swatchMouse.containsMouse ? Theme.borderWidthFocus : Theme.borderWidth
    border.color: swatchMouse.containsMouse ? Theme.primary : Theme.panelBorder

    Behavior on border.color {
        ColorAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
    }

    ThemedToolTip {
        text: root.tip
        visible: swatchMouse.containsMouse
    }

    MouseArea {
        id: swatchMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
        onWheel: (wheel) => { wheel.accepted = false }
    }
}
