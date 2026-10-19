import QtQuick
import Drift

// Hairline between the gizmo tools and the view tools.
Rectangle {
    anchors.horizontalCenter: parent.horizontalCenter
    width: Theme.iconSizeBase
    height: Theme.c.preview3DToolsDivider.strokeWidth
    color: Theme.c.preview3DToolsDivider.background
}
