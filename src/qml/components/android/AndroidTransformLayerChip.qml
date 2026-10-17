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
    radius: Theme.radiusSm
    color: Theme.clipTransform

    Text {
        id: label
        anchors.centerIn: parent
        text: qsTr("%1 · %n clip(s)", "", chip.childCount)
                  .arg(chip.layerName.length > 0 ? chip.layerName : qsTr("Transform"))
        color: Theme.onMedia
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeXs
    }
}
