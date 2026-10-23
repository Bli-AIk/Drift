import QtQuick

QtObject {
    id: root

    property real pxPerSecond: 100
    property real contentX: 0
    property real viewportWidth: 600
    property real clipStart: 0
    property real clipDuration: 1

    readonly property real minPxPerSecond: 1
    readonly property real maxPxPerSecond: 5000

    function xFor(s) {
        return s * pxPerSecond - contentX
    }

    function secondsFor(x) {
        return (x + contentX) / pxPerSecond
    }

    function zoomAt(x, factor) {
        const anchor = secondsFor(x)
        pxPerSecond = Math.max(minPxPerSecond, Math.min(maxPxPerSecond, pxPerSecond * factor))
        contentX = anchor * pxPerSecond - x
    }

    function fitRange(s0, s1) {
        const span = Math.max(0.05, s1 - s0)
        const padded = span * 1.1
        pxPerSecond = Math.max(minPxPerSecond,
                               Math.min(maxPxPerSecond, Math.max(1, viewportWidth) / padded))
        contentX = (s0 - span * 0.05) * pxPerSecond
    }

    function fitClip() {
        fitRange(clipStart, clipStart + clipDuration)
    }
}
