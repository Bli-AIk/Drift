import QtQuick
import Drift

// The "!" on media with a variable frame rate, which can drift out of sync with its audio until
// it is converted to an edit-friendly format. Reused for other media warnings by overriding its tip
// and colours.
Rectangle {
    id: root

    property real size: Theme.iconSizeBase
    property string tip: qsTr("Variable frame rate. This clip can drift out of sync with its audio. Right-click it and choose Convert to edit-friendly format.")
    property color background: Theme.c.vfrWarning.background
    property color foreground: Theme.c.vfrWarning.foreground
    property real cornerRadius: Theme.c.vfrWarning.radius

    width: size
    height: size
    radius: root.cornerRadius
    color: root.background

    Text {
        anchors.centerIn: parent
        text: "!"
        color: root.foreground
        font.pixelSize: root.size * 0.75
        font.family: Theme.fontFamily
        font.weight: Font.Bold
    }

    HoverHandler { id: hover }
    // Built only while hovered: this badge sits on every VFR clip and bin card.
    Loader {
        active: hover.hovered
        sourceComponent: ThemedToolTip {
            visible: true
            text: root.tip
        }
    }
}
