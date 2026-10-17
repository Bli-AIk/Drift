import QtQuick
import Drift

Rectangle {
    property var host
    x: host.xForSeconds(host.clipStart)
    width: Math.max(2, host.clipDuration * host.pxPerSecond)
    height: parent.height
    color: Theme.panelAccent
    opacity: 0.55
    radius: 2
}
