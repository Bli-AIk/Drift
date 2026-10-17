import QtQuick
import Drift

// "Name · n clips" over a selected layer's frame.
Rectangle {
    id: chip

    property string layerName: ""
    property int childCount: 0

    y: -height - Theme.spacingSm
    width: label.implicitWidth + Theme.spacingLg
    height: label.implicitHeight + Theme.spacingSm
    radius: Theme.c.androidTransformLayerChip.radius
    color: Theme.c.androidTransformLayerChip.background

    Text {
        id: label
        anchors.centerIn: parent
        text: qsTr("%1 · %n clip(s)", "", chip.childCount)
                  .arg(chip.layerName.length > 0 ? chip.layerName : qsTr("Transform"))
        color: Theme.c.androidTransformLayerChip.foreground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeXs
    }
}
