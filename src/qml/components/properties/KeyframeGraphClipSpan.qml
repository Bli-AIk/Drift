import QtQuick
import Drift

Rectangle {
    property var host
    x: host.xForSeconds(host.clipStart)
    width: Math.max(2, host.clipDuration * host.pxPerSecond)
    height: parent.height
    color: Theme.c.keyframeGraphClipSpan.background
    opacity: Theme.c.keyframeGraphClipSpan.opacity
    radius: Theme.c.keyframeGraphClipSpan.radius
}
