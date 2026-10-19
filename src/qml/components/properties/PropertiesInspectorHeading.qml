import QtQuick
import Drift

// Desktop tab title. The phone strip already names the tab, so the parent hides this.
Text {
    id: root

    color: Theme.c.propertiesInspectorHeading.foregroundMuted
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSizeXs
    font.weight: Font.Medium
}
