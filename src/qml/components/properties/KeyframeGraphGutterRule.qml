import QtQuick
import Drift

// Vertical rule between the property gutter and the curves.
Rectangle {
    anchors.right: parent.right
    width: Theme.c.keyframeGraphGutterRule.borderWidth
    height: parent.height
    color: Theme.c.keyframeGraphGutterRule.border
}
