import QtQuick
import Drift
import QtQuick.Window

Column {
    required property DebugInfoDialog dialog
    id: systemTab
    width: parent.width
    spacing: Theme.spacingXl
    visible: dialog.activeTab === 0
    height: visible ? implicitHeight : 0

    Repeater {
        model: [
            {
                title: qsTr("Video decoders"),
                headers: [qsTr("Codec Name"), qsTr("Software Decoding"), qsTr("Hardware Decoding")],
                rows: dialog.info.codecs || [],
                softwareKey: "softwareDecoder",
                hardwareKey: "hardwareDecoder"
            },
            {
                title: qsTr("Video encoders"),
                headers: [qsTr("Codec Name"), qsTr("Software Encoding"), qsTr("Hardware Encoding")],
                rows: dialog.info.encoders || [],
                softwareKey: "softwareEncoder",
                hardwareKey: "hardwareEncoder"
            }
        ]

        Column {
            id: tableBlock
            required property var modelData

            width: parent.width
            spacing: Theme.spacingLg

            ThemedLabel {
                width: parent.width
                size: "sm"
                tone: "default"
                text: tableBlock.modelData.title
                font.weight: Font.Medium
            }

            Rectangle {
                width: parent.width
                height: tableCol.height
                radius: Theme.c.debugInfoSystemTab.radius
                color: "transparent"
                border.width: Theme.c.debugInfoSystemTab.borderWidth
                border.color: Theme.c.debugInfoSystemTab.border
                clip: true

                Column {
                    id: tableCol
                    width: parent.width
                    spacing: 0

                    Row {
                        width: parent.width
                        height: Theme.controlHeightSm

                        Repeater {
                            model: tableBlock.modelData.headers

                            Rectangle {
                                required property int index
                                required property string modelData

                                width: tableCol.width / 3
                                height: Theme.controlHeightSm
                                color: Theme.c.debugInfoSystemTab.stripe

                                Rectangle {
                                    anchors.right: parent.right
                                    width: Theme.c.debugInfoSystemTab.borderWidth
                                    height: parent.height
                                    color: Theme.c.debugInfoSystemTab.border
                                    visible: index < 2
                                }

                                ThemedLabel {
                                    anchors.fill: parent
                                    anchors.leftMargin: Theme.spacingLg
                                    anchors.rightMargin: Theme.spacingLg
                                    size: "xs"
                                    tone: "default"
                                    font.weight: Font.DemiBold
                                    wrapMode: Text.NoWrap
                                    elide: Text.ElideRight
                                    verticalAlignment: Text.AlignVCenter
                                    text: modelData
                                }
                            }
                        }
                    }

                    Repeater {
                        model: tableBlock.modelData.rows

                        Row {
                            id: codecRow
                            required property var modelData
                            required property int index

                            width: parent.width
                            height: Theme.controlHeight

                            readonly property bool striped: index % 2 === 1
                            readonly property var row: modelData

                            Rectangle {
                                width: tableCol.width / 3
                                height: parent.height
                                color: codecRow.striped ? Theme.c.debugInfoSystemTab.stripe : "transparent"

                                Rectangle {
                                    anchors.right: parent.right
                                    width: Theme.c.debugInfoSystemTab.borderWidth
                                    height: parent.height
                                    color: Theme.c.debugInfoSystemTab.border
                                }

                                Rectangle {
                                    anchors.top: parent.top
                                    width: parent.width
                                    height: Theme.c.debugInfoSystemTab.borderWidth
                                    color: Theme.c.debugInfoSystemTab.border
                                }

                                ThemedLabel {
                                    anchors.fill: parent
                                    anchors.leftMargin: Theme.spacingLg
                                    anchors.rightMargin: Theme.spacingLg
                                    size: "xs"
                                    tone: "default"
                                    font.weight: Font.DemiBold
                                    wrapMode: Text.NoWrap
                                    elide: Text.ElideRight
                                    verticalAlignment: Text.AlignVCenter
                                    text: codecRow.row.name || ""

                                    HoverHandler { id: codecHover }
                                    ThemedToolTip {
                                        visible: codecHover.hovered && text.length > 0
                                        text: {
                                            const parts = []
                                            const sw = codecRow.row[tableBlock.modelData.softwareKey]
                                            const hw = codecRow.row[tableBlock.modelData.hardwareKey]
                                            if (sw)
                                                parts.push(qsTr("Software: %1").arg(sw))
                                            if (hw)
                                                parts.push(qsTr("Hardware: %1").arg(hw))
                                            return parts.join("\n")
                                        }
                                    }
                                }
                            }

                            Repeater {
                                model: [
                                    dialog.cellState(codecRow.row, false),
                                    dialog.cellState(codecRow.row, true)
                                ]

                                Rectangle {
                                    required property int index
                                    required property string modelData

                                    width: tableCol.width / 3
                                    height: codecRow.height
                                    color: dialog.cellFill(modelData, codecRow.striped)

                                    Rectangle {
                                        anchors.right: parent.right
                                        width: Theme.c.debugInfoSystemTab.borderWidth
                                        height: parent.height
                                        color: Theme.c.debugInfoSystemTab.border
                                        visible: index === 0
                                    }

                                    Rectangle {
                                        anchors.top: parent.top
                                        width: parent.width
                                        height: Theme.c.debugInfoSystemTab.borderWidth
                                        color: Theme.c.debugInfoSystemTab.border
                                    }

                                    Text {
                                        anchors.fill: parent
                                        anchors.leftMargin: Theme.spacingLg
                                        anchors.rightMargin: Theme.spacingLg
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeXs
                                        font.weight: Font.Medium
                                        color: dialog.cellTextColor(modelData)
                                        wrapMode: Text.NoWrap
                                        elide: Text.ElideRight
                                        verticalAlignment: Text.AlignVCenter
                                        text: dialog.cellLabel(modelData)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Column {
        width: parent.width
        spacing: Theme.spacingLg
        visible: (dialog.info.hints || []).length > 0
        height: visible ? implicitHeight : 0

        ThemedLabel {
            width: parent.width
            size: "sm"
            tone: "default"
            text: qsTr("Checks")
            font.weight: Font.Medium
        }

        Repeater {
            model: dialog.info.hints || []

            Rectangle {
                required property var modelData

                width: parent.width
                implicitHeight: hintCol.height + Theme.spacingLg * 2
                radius: Theme.c.debugInfoSystemTab.radius
                color: "transparent"
                border.width: Theme.c.debugInfoSystemTab.borderWidth
                border.color: Theme.c.debugInfoSystemTab.border

                Column {
                    id: hintCol
                    x: Theme.spacingLg
                    y: Theme.spacingLg
                    width: parent.width - Theme.spacingLg * 2
                    spacing: Theme.spacingSm

                    ThemedLabel {
                        width: parent.width
                        size: "sm"
                        tone: "default"
                        font.weight: Font.Medium
                        text: modelData.title || ""
                    }

                    ThemedLabel {
                        width: parent.width
                        size: "sm"
                        text: modelData.detail || ""
                    }

                    ThemedLabel {
                        width: parent.width
                        size: "xs"
                        tone: "default"
                        visible: !!(modelData.command)
                        height: visible ? implicitHeight : 0
                        font.family: Theme.monoFontFamily
                        wrapMode: Text.WrapAnywhere
                        text: modelData.command || ""
                    }

                    ThemedButton {
                        visible: modelData.action === "addons"
                        height: visible ? implicitHeight : 0
                        text: qsTr("Open Add-ons")
                        variant: "secondary"
                        onClicked: {
                            dialog.close()
                            if (typeof Window !== "undefined" && Window.window
                                    && Window.window.openAddonManager)
                                Window.window.openAddonManager("onnxruntime")
                        }
                    }
                }
            }
        }
    }

    ThemedLabel {
        width: parent.width
        size: "sm"
        tone: "default"
        text: qsTr("System")
        font.weight: Font.Medium
    }

    Column {
        width: parent.width
        spacing: 0

        Repeater {
            model: dialog.info.system || []

            Item {
                required property var modelData
                required property int index

                width: parent.width
                height: Math.max(Theme.controlHeightSm,
                                 valueLabel.implicitHeight + Theme.spacingSm)

                Rectangle {
                    anchors.fill: parent
                    color: index % 2 === 1 ? Theme.c.debugInfoSystemTab.stripe : "transparent"
                    radius: Theme.c.debugInfoSystemTab.stripeRadius
                }

                ThemedLabel {
                    width: Math.round(parent.width * 0.34)
                    anchors.verticalCenter: parent.verticalCenter
                    leftPadding: Theme.spacingLg
                    size: "xs"
                    text: modelData.label || ""
                }

                ThemedLabel {
                    id: valueLabel
                    x: Math.round(parent.width * 0.34)
                    width: parent.width - x
                    anchors.verticalCenter: parent.verticalCenter
                    rightPadding: Theme.spacingLg
                    size: "xs"
                    tone: "default"
                    wrapMode: Text.WordWrap
                    text: modelData.value || ""
                }
            }
        }
    }
}
