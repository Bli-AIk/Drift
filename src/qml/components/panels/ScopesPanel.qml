pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Drift

PanelFrame {
    id: root

    property bool shown: false
    property bool held: false
    property string mode: "all"

    readonly property var scopes: EditorState.color.scopes
    readonly property var modes: [
        { id: "all", label: qsTr("All") },
        { id: "histogram", label: qsTr("Histogram") },
        { id: "waveform", label: qsTr("Waveform") },
        { id: "parade", label: qsTr("Parade") },
        { id: "vectorscope", label: qsTr("Vectorscope") }
    ]
    readonly property var visibleKinds: {
        if (mode === "all")
            return ["histogram", "waveform", "vectorscope"]
        return [mode]
    }
    readonly property bool showParade: mode === "parade"

    function syncHeld() {
        if (root.shown && !root.held) {
            scopes.acquire()
            root.held = true
        } else if (!root.shown && root.held) {
            scopes.release()
            root.held = false
        }
    }

    onShownChanged: syncHeld()
    Component.onCompleted: syncHeld()
    Component.onDestruction: {
        if (held)
            scopes.release()
    }

    function applyParade() {
        const want = mode === "parade"
        if (scopes.parade !== want)
            scopes.parade = want
    }
    onModeChanged: applyParade()

    AssetsPanelHeader {
        id: header
        width: parent.width
        height: Theme.panelHeaderHeight
        title: qsTr("Scopes")
    }

    Flow {
        id: selector
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Theme.spacingMd
        spacing: Theme.spacingSm

        Repeater {
            model: root.modes
            delegate: ThemedChip {
                required property var modelData
                text: modelData.label
                selected: root.mode === modelData.id
                onClicked: root.mode = modelData.id
            }
        }
    }

    GridLayout {
        anchors.top: selector.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Theme.spacingMd
        columns: root.mode === "all" && width > height * 1.5 ? 3 : 1
        rowSpacing: Theme.spacingMd
        columnSpacing: Theme.spacingMd

        Repeater {
            model: root.visibleKinds
            delegate: Rectangle {
                id: tile
                required property string modelData
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 60
                radius: Theme.radiusMd
                color: Theme.c.scopes.background
                clip: true

                Image {
                    anchors.fill: parent
                    anchors.margins: Theme.spacingSm
                    source: "image://color/scope/" + (root.showParade ? "waveform" : tile.modelData)
                            + "?s=" + root.scopes.serial
                    cache: false
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }

                Text {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.margins: Theme.spacingSm
                    visible: root.mode === "all"
                    text: tile.modelData === "histogram" ? qsTr("Histogram")
                          : tile.modelData === "waveform" ? qsTr("Waveform") : qsTr("Vectorscope")
                    color: Theme.c.scopes.label
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeXs
                }
            }
        }
    }
}
