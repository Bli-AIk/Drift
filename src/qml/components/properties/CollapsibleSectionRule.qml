import QtQuick
import Drift

// Hairline above a collapsible inspector section.
Rectangle {
    id: root
    property bool shown: true
    width: parent ? parent.width : implicitWidth
    height: Theme.c.collapsibleSectionRule.borderWidth
    visible: shown
    color: Theme.c.collapsibleSectionRule.border
}
