import QtQuick
import Drift

Rectangle {
    property var host
    anchors.verticalCenter: parent.verticalCenter
    x: host.xForSeconds(host.clipStart)
    width: Math.max(2, host.clipDuration * host.pxPerSecond)
    height: Theme.c.keyframeGraphValueAxis.borderWidth
    color: Theme.c.keyframeGraphValueAxis.border
}
