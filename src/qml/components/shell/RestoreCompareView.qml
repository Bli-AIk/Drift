import QtQuick
import Drift

// ----- Before / after ---------------------------------------------------------------
Column {
    required property RestoreWindow tool
    property real sidebarWidth
    property alias stage: stage
    property alias frameSlider: frameSlider
    width: parent.width - sidebarWidth - Theme.spacingLg
    height: parent.height
    spacing: Theme.spacingMd

    Item {
        id: stage
        width: parent.width
        height: parent.height - scrubRow.height - Theme.spacingMd
        clip: true

        readonly property real frameW: tool.preview.width || 16
        readonly property real frameH: tool.preview.height || 9
        readonly property real aspect: frameW / frameH
        readonly property real fitW: Math.min(width, height * aspect)
        readonly property real fitH: fitW / aspect

        // Zoom 1 is the letterboxed fit. The cap reaches a few screen pixels per pixel of
        // the enhanced frame, which is where the difference between the two shows.
        property real zoom: 1
        readonly property real maxZoom: Math.max(8, 4 * Math.max(tool.preview.enhancedWidth || 0, frameW) / Math.max(1, fitW))
        property real panX: 0
        property real panY: 0
        // Divider position, 0..1 of the stage width.
        property real split: 0.5

        readonly property real viewX: (width - fitW * zoom) / 2 + panX
        readonly property real viewY: (height - fitH * zoom) / 2 + panY
        readonly property real splitX: split * width

        function resetView() {
            zoom = 1
            panX = 0
            panY = 0
        }

        // Zooms about a stage point, keeping the frame pixel under it in place.
        function zoomAt(px, py, factor) {
            const next = Math.max(1, Math.min(maxZoom, zoom * factor))
            const fx = (px - viewX) / zoom
            const fy = (py - viewY) / zoom
            zoom = next
            panX = px - fx * next - (width - fitW * next) / 2
            panY = py - fy * next - (height - fitH * next) / 2
            if (next === 1) {
                panX = 0
                panY = 0
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Theme.panelBackground
            radius: Theme.radiusMd
        }

        Image {
            x: stage.viewX
            y: stage.viewY
            width: stage.fitW * stage.zoom
            height: stage.fitH * stage.zoom
            fillMode: Image.Stretch
            cache: false
            smooth: true
            // The revision defeats QML's URL-keyed image cache.
            source: tool.preview.width > 0
                    ? "image://segment/restore-original?rev=" + tool.preview.revision
                    : ""
        }

        // Right of the divider: the enhanced frame laid over the same rectangle, so both
        // halves line up pixel for pixel at any zoom.
        Item {
            x: stage.splitX
            width: stage.width - stage.splitX
            height: stage.height
            clip: true
            visible: tool.hasEnhanced

            Image {
                x: stage.viewX - stage.splitX
                y: stage.viewY
                width: stage.fitW * stage.zoom
                height: stage.fitH * stage.zoom
                fillMode: Image.Stretch
                cache: false
                smooth: true
                source: tool.hasEnhanced
                        ? "image://segment/restore-enhanced?rev=" + tool.preview.revision
                        : ""
            }
        }

        MouseArea {
            anchors.fill: parent
            property real lastX: 0
            property real lastY: 0
            cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
            onPressed: function (mouse) {
                lastX = mouse.x
                lastY = mouse.y
            }
            onPositionChanged: function (mouse) {
                if (stage.zoom <= 1)
                    return
                stage.panX += mouse.x - lastX
                stage.panY += mouse.y - lastY
                lastX = mouse.x
                lastY = mouse.y
            }
            onDoubleClicked: stage.resetView()
            onWheel: function (wheel) {
                stage.zoomAt(wheel.x, wheel.y, wheel.angleDelta.y > 0 ? 1.25 : 0.8)
            }
        }

        // Divider.
        Rectangle {
            x: stage.splitX - width / 2
            width: 2
            height: stage.height
            color: Theme.primary
            visible: tool.hasEnhanced

            Rectangle {
                anchors.centerIn: parent
                width: 24
                height: 24
                radius: 12
                color: Theme.primary

                IconGlyph {
                    anchors.centerIn: parent
                    glyph: "move-horizontal"
                    iconSize: 14
                    iconColor: Theme.primaryForeground
                }
            }

            MouseArea {
                anchors.fill: parent
                anchors.leftMargin: -10
                anchors.rightMargin: -10
                cursorShape: Qt.SplitHCursor
                onPositionChanged: function (mouse) {
                    const p = mapToItem(stage, mouse.x, mouse.y)
                    stage.split = Math.max(0, Math.min(1, p.x / stage.width))
                }
            }
        }

        ThemedChip {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.margins: Theme.spacingMd
            text: qsTr("Original")
            variant: "secondary"
            visible: tool.preview.width > 0
        }

        ThemedChip {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Theme.spacingMd
            text: tool.previewedWith !== tool.chosenModels
                  ? qsTr("Enhanced — out of date, preview again")
                  : qsTr("Enhanced %1 × %2").arg(tool.preview.enhancedWidth).arg(tool.preview.enhancedHeight)
            visible: tool.hasEnhanced
        }

        Rectangle {
            anchors.centerIn: parent
            visible: !frameSlider.pressed
                     && (tool.preview.loading || (!tool.hasEnhanced && tool.preview.width > 0) || tool.running)
            width: stageLabel.width + Theme.spacingXl
            height: stageLabel.height + Theme.spacingLg
            radius: Theme.radiusMd
            color: Theme.scrimStrong

            ThemedLabel {
                id: stageLabel
                anchors.centerIn: parent
                tone: "default"
                text: tool.preview.loading ? qsTr("Loading this frame…")
                      : tool.running ? (tool.job.status || qsTr("Working…"))
                      : qsTr("Choose models, then Preview to compare this frame")
            }
        }
    }

    Row {
        id: scrubRow
        width: parent.width
        spacing: Theme.spacingMd

        ThemedLabel {
            anchors.verticalCenter: parent.verticalCenter
            text: qsTr("Frame")
        }

        ThemedSlider {
            id: frameSlider
            label: qsTr("Frame")
            width: parent.width - 300
            anchors.verticalCenter: parent.verticalCenter
            from: 0
            to: Math.max(0.001, tool.rangeSeconds)
            enabled: !tool.running
            onMoved: EditorState.restore.setPreviewFrame(tool.targetId, value)
        }

        ThemedLabel {
            anchors.verticalCenter: parent.verticalCenter
            text: frameSlider.value.toFixed(2) + qsTr("s")
        }

        ThemedButton {
            anchors.verticalCenter: parent.verticalCenter
            variant: "ghost"
            text: qsTr("Fit")
            enabled: stage.zoom > 1
            onClicked: stage.resetView()
        }
    }
}
