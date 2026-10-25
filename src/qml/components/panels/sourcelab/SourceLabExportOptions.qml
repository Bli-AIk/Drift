import QtQuick
import Drift

// File, container, codec and quality for "Export file". `options` is the map the controller's
// plan() and apply() take.
Column {
    id: root

    readonly property var lab: EditorState.sourceLab
    property bool isVideo: true
    // Whether the recipe is only a trim, which is all a stream copy can do.
    property bool canStreamCopy: false

    property string path: ""
    property string container: root.isVideo ? "mp4" : "m4a"
    property string codec: root.codecs[0] ?? "h264"
    property int qualityIndex: 1
    property int customCrf: 20
    property int maxHeight: 0
    property int audioBitrate: 192
    property bool streamCopy: false

    readonly property var codecs: root.lab.availableVideoCodecs()
    readonly property var qualities: [
        { label: qsTr("High"), crf: 16 },
        { label: qsTr("Standard"), crf: 18 },
        { label: qsTr("Small"), crf: 23 },
        { label: qsTr("Custom"), crf: -1 }
    ]
    readonly property var containers: root.isVideo
        ? [{ label: "MP4", value: "mp4" }, { label: "MOV", value: "mov" }, { label: "MKV", value: "mkv" },
           { label: qsTr("M4A (audio only)"), value: "m4a" }, { label: qsTr("WAV (audio only)"), value: "wav" },
           { label: qsTr("FLAC (audio only)"), value: "flac" }]
        : [{ label: "M4A", value: "m4a" }, { label: "WAV", value: "wav" }, { label: "FLAC", value: "flac" }]
    readonly property var heights: [
        { label: qsTr("Source"), value: 0 }, { label: "2160p", value: 2160 }, { label: "1440p", value: 1440 },
        { label: "1080p", value: 1080 }, { label: "720p", value: 720 }, { label: "480p", value: 480 }
    ]
    readonly property var bitrates: [128, 192, 256, 320].map(v => ({ label: qsTr("%1 kbps").arg(v), value: v }))
    readonly property bool audioOnly: ["m4a", "wav", "flac"].indexOf(root.container) >= 0
    readonly property bool copying: root.streamCopy && root.canStreamCopy
    readonly property bool lossless: root.container === "wav" || root.container === "flac"
    readonly property string displayPath: root.path.replace(/^file:\/\//, "")
    readonly property var options: ({
        path: root.path,
        container: root.container,
        videoCodec: root.codec,
        crf: root.qualityIndex === 3 ? root.customCrf : root.qualities[root.qualityIndex].crf,
        maxHeight: root.maxHeight,
        audioBitrateKbps: root.audioBitrate,
        streamCopy: root.copying
    })

    function choosePath() {
        const name = root.lab.name.replace(/\.[^.]*$/, "")
        const url = FileDialogs.saveFile(qsTr("Export"), [qsTr("%1 file (*.%2)").arg(root.container.toUpperCase()).arg(root.container)],
                                         name, root.container)
        if (!url || url.toString() === "")
            return false
        let text = url.toString()
        if (!/\.[A-Za-z0-9]{2,4}$/.test(text))
            text += "." + root.container
        root.path = text
        return true
    }

    onContainersChanged: {
        if (!root.containers.some(c => c.value === root.container))
            root.container = root.containers[0].value
    }

    spacing: Theme.spacingMd

    Row {
        width: parent.width
        spacing: Theme.spacingSm

        ThemedTextField {
            width: parent.width - chooseButton.width - parent.spacing
            readOnly: true
            text: root.displayPath
            placeholderText: qsTr("Choose where to save")
        }
        ThemedButton {
            id: chooseButton
            variant: "secondary"
            text: qsTr("Choose...")
            onClicked: root.choosePath()
        }
    }

    ThemedSwitch {
        visible: root.isVideo
        text: qsTr("Fast trim (stream copy)")
        checked: root.copying
        enabled: root.canStreamCopy
        tooltip: root.canStreamCopy ? qsTr("Cut without re-encoding. Starts at the previous keyframe.")
                                    : qsTr("Only a plain trim can be copied without re-encoding")
        onToggled: root.streamCopy = checked
    }

    Grid {
        width: parent.width
        columns: 2
        columnSpacing: Theme.spacingMd
        rowSpacing: Theme.spacingSm
        enabled: !root.copying

        ThemedLabel { text: qsTr("Container"); height: containerBox.height; verticalAlignment: Text.AlignVCenter }
        ThemedComboBox {
            id: containerBox
            width: (root.width - Theme.spacingMd) * 0.6
            model: root.containers
            textRole: "label"
            currentIndex: Math.max(0, root.containers.findIndex(c => c.value === root.container))
            onActivated: index => root.container = root.containers[index].value
        }

        ThemedLabel {
            visible: !root.audioOnly
            text: qsTr("Codec"); height: codecBox.height; verticalAlignment: Text.AlignVCenter
        }
        ThemedComboBox {
            id: codecBox
            visible: !root.audioOnly
            width: containerBox.width
            model: root.codecs
            currentIndex: Math.max(0, root.codecs.indexOf(root.codec))
            onActivated: index => root.codec = root.codecs[index]
        }

        ThemedLabel {
            visible: !root.audioOnly
            text: qsTr("Quality"); height: qualityBox.height; verticalAlignment: Text.AlignVCenter
        }
        Row {
            visible: !root.audioOnly
            spacing: Theme.spacingSm
            ThemedComboBox {
                id: qualityBox
                width: root.qualityIndex === 3 ? containerBox.width - crfField.width - parent.spacing : containerBox.width
                model: root.qualities
                textRole: "label"
                currentIndex: root.qualityIndex
                onActivated: index => root.qualityIndex = index
            }
            ThemedNumberField {
                id: crfField
                visible: root.qualityIndex === 3
                width: 64
                from: 0
                to: 51
                value: root.customCrf
                onEdited: v => root.customCrf = v
            }
        }

        ThemedLabel {
            visible: !root.audioOnly
            text: qsTr("Max height"); height: heightBox.height; verticalAlignment: Text.AlignVCenter
        }
        ThemedComboBox {
            id: heightBox
            visible: !root.audioOnly
            width: containerBox.width
            model: root.heights
            textRole: "label"
            currentIndex: Math.max(0, root.heights.findIndex(h => h.value === root.maxHeight))
            onActivated: index => root.maxHeight = root.heights[index].value
        }

        ThemedLabel {
            visible: !root.lossless
            text: qsTr("Audio"); height: audioBox.height; verticalAlignment: Text.AlignVCenter
        }
        ThemedComboBox {
            id: audioBox
            visible: !root.lossless
            width: containerBox.width
            model: root.bitrates
            textRole: "label"
            currentIndex: Math.max(0, root.bitrates.findIndex(b => b.value === root.audioBitrate))
            onActivated: index => root.audioBitrate = root.bitrates[index].value
        }
    }
}
