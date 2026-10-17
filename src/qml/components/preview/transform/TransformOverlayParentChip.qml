import QtQuick
import Drift
// Chip that selects the transform layer moving the selected clip.
Rectangle {
    id: chip

    // The parent-frame item: quad and corner(i) in overlay px.
    required property var frame
    required property string layerName

    visible: chip.frame.quad.length === 4
    x: chip.frame.corner(0).x
    y: chip.frame.corner(0).y - height - Theme.spacingSm
    width: parentChipLabel.implicitWidth + Theme.spacingLg
    height: parentChipLabel.implicitHeight + Theme.spacingSm
    radius: height / 2
    color: parentChipMouse.containsMouse ? Qt.lighter(Theme.clipTransform, 1.15) : Theme.clipTransform

    Text {
        id: parentChipLabel
        anchors.centerIn: parent
        text: qsTr("Select %1").arg(chip.layerName || qsTr("Transform"))
        color: Theme.onMedia
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeXs
    }

    MouseArea {
        id: parentChipMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: EditorState.selectTransformParent()
    }

    ThemedToolTip {
        visible: parentChipMouse.containsMouse
        text: qsTr("Select the transform layer moving this clip (%1)")
                  .arg(EditorState.shortcutFor("selectTransformLayer"))
    }
}
