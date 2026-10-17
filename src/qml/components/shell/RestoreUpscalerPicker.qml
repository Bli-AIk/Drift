import QtQuick
import QtQuick.Controls.Basic
import Drift

Rectangle {
    id: picker
    required property RestoreWindow tool
    property real sidebarWidth
    visible: false
    x: Theme.spacingLg
    y: Theme.spacingLg
    width: tool.width - sidebarWidth - Theme.spacingLg * 3
    height: tool.height - Theme.spacingLg * 2
    radius: Theme.radiusMd
    color: Theme.appBackground
    border.width: 1
    border.color: Theme.panelBorder

    property string filter: ""
    // Only the content types something installed is made for.
    readonly property var filters: {
        const order = ["anime", "live", "cg", "general"]
        const seen = {}
        for (const m of tool.upscaleModel)
            for (const c of (m.content || []))
                seen[c] = true
        return order.filter(c => seen[c])
    }
    readonly property var labels: ({
        anime: qsTr("Anime and drawings"),
        live: qsTr("Live action"),
        cg: qsTr("3D animation and games"),
        general: qsTr("General")
    })
    readonly property var shown: tool.upscaleModel.filter(
        m => !picker.filter || !m.value || (m.content || []).indexOf(picker.filter) >= 0)

    onVisibleChanged: if (visible) filter = ""

    Column {
        id: pickerHeader
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Theme.spacingLg
        spacing: Theme.spacingMd

        Item {
            width: parent.width
            height: closePicker.height

            ThemedLabel {
                anchors.verticalCenter: parent.verticalCenter
                size: "base"
                tone: "default"
                text: qsTr("Choose an upscaler")
            }

            IconButton {
                id: closePicker
                anchors.right: parent.right
                glyph: Theme.icons.x
                tooltip: qsTr("Close")
                onClicked: picker.visible = false
            }
        }

        Flow {
            width: parent.width
            spacing: Theme.spacingSm
            visible: picker.filters.length > 1

            ThemedChip {
                text: qsTr("All")
                selected: picker.filter === ""
                onClicked: picker.filter = ""
            }

            Repeater {
                model: picker.filters
                delegate: ThemedChip {
                    required property string modelData
                    text: picker.labels[modelData]
                    selected: picker.filter === modelData
                    onClicked: picker.filter = modelData
                }
            }
        }
    }

    GridView {
        id: grid
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: pickerHeader.bottom
        anchors.bottom: pickerFooter.top
        anchors.margins: Theme.spacingMd
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        readonly property int columns: Math.max(2, Math.floor(width / 240))
        cellWidth: Math.floor(width / columns)
        // Thumbnail plus name, content, two lines of summary and the speed meter.
        cellHeight: Math.round((cellWidth - Theme.spacingSm * 4) * 9 / 16) + 128
        model: picker.shown

        delegate: Item {
            required property var modelData
            width: grid.cellWidth
            height: grid.cellHeight

            UpscaleModelCard {
                anchors.fill: parent
                anchors.margins: Theme.spacingSm
                model: parent.modelData
                selected: parent.modelData.value === tool.upscaleId
                speedLevel: tool.speedLevel(parent.modelData.spm || 0)
                perFrameText: parent.modelData.spm > 0
                              ? tool.formatPerFrame(tool.secondsPerFrame(parent.modelData.spm)) : ""
                onClicked: {
                    tool.upscaleId = parent.modelData.value
                    picker.visible = false
                }
            }
        }

        ScrollBar.vertical: AppScrollBar { }
    }

    Column {
        id: pickerFooter
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Theme.spacingLg
        spacing: Theme.spacingSm

        ThemedLabel {
            width: parent.width
            visible: tool.runtimeReady
            wrapMode: Text.WordWrap
            text: qsTr("Speeds are per frame of this clip. Custom models are experimental and may not work. Drop an ONNX export (fp32 or fp16, RGB, 1x/2x/4x) into the folder; put the scale in the file name, e.g. \"2x_Name.onnx\".")
        }

        Flow {
            width: parent.width
            spacing: Theme.spacingSm

            ThemedButton {
                variant: "ghost"
                text: tool.runtimeReady ? qsTr("Get models (openmodeldb.info)") : qsTr("Install AI engine first")
                onClicked: {
                    if (tool.runtimeReady) {
                        Qt.openUrlExternally("https://openmodeldb.info")
                    } else {
                        // The manager opens in the main window, which this one would cover.
                        tool.host.openAddonManager("onnxruntime")
                        tool.close()
                    }
                }
            }

            ThemedButton {
                variant: "ghost"
                text: qsTr("Open custom models folder")
                visible: tool.runtimeReady
                onClicked: Qt.openUrlExternally("file://" + EditorState.restore.modelsFolder())
            }

            ThemedButton {
                variant: "ghost"
                text: qsTr("Refresh model list")
                visible: tool.runtimeReady
                onClicked: tool.refreshModels()
            }
        }
    }
}
