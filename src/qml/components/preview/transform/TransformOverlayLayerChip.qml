import QtQuick
import Drift

// "Name · n clips" over a selected layer's frame.
Rectangle {
    id: chip

    property string clipName: ""
    property int childCount: 0

    x: 0
    y: -height - Theme.spacingSm
    width: layerLabel.implicitWidth + Theme.spacingLg
    height: layerLabel.implicitHeight + Theme.spacingSm
    radius: Theme.radiusSm
    color: Theme.clipTransform

    Text {
        id: layerLabel
        anchors.centerIn: parent
        text: qsTr("%1 · %n clip(s)", "", chip.childCount)
                  .arg(chip.clipName || qsTr("Transform"))
        color: Theme.onMedia
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeXs
    }
}
