import QtQuick
import Drift

CollapsibleSection {
    id: root
    property var inspector
    width: parent.width
    title: qsTr("Advanced")
    expanded: false
    visible: inspector.animation.custom === true

    Text {
        width: parent.width
        wrapMode: Text.WordWrap
        text: qsTr("Custom animator (set via MCP). Preset controls are disabled.")
        color: Theme.mutedForeground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeXs
    }
    ThemedButton {
        variant: "secondary"
        glyph: Theme.icons.reset
        text: qsTr("Revert to preset")
        tooltip: qsTr("Drop the custom animators and go back to picking presets")
        onClicked: inspector.revertCustomAnimation()
    }
}
