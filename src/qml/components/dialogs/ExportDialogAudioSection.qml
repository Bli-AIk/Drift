import QtQuick
import Drift

// ---- Audio mode ----
Column {
    id: section
    required property ExportDialog dialog
    property alias audioOnlyCodecCombo: audioOnlyCodecCombo
    property alias audioOnlyBitrateCombo: audioOnlyBitrateCombo
    property alias tagTitleField: tagTitleField
    property alias tagArtistField: tagArtistField
    property alias tagAlbumField: tagAlbumField
    property alias tagCommentField: tagCommentField

    width: parent.width
    spacing: Theme.spacingXl
    visible: dialog.isAudioOnly
    height: visible ? implicitHeight : 0
    clip: true

    ThemedLabel {
        width: parent.width
        size: "sm"
        text: qsTr("Exports the timeline audio mix only — no video track.")
    }

    Column {
        width: parent.width
        spacing: Theme.spacingSm

        ThemedLabel {
            text: qsTr("Audio encoder")
            size: "sm"
        }

        ThemedComboBox {
            id: audioOnlyCodecCombo
            width: parent.width
            textRole: "label"
            valueRole: "id"
            model: dialog.audioCodecs
            onActivated: function (index) {
                var item = dialog.audioCodecs[index]
                if (!item || !item.available) {
                    currentIndex = Math.max(0, indexOfValue(dialog.audioCodecId))
                    return
                }
                dialog.audioCodecId = item.id
                dialog.refreshCodecMeta()
                if (dialog.audioCodecCombo)
                    dialog.audioCodecCombo.currentIndex = currentIndex
            }
        }
    }

    Column {
        width: parent.width
        spacing: Theme.spacingSm
        visible: !dialog.audioLossless

        ThemedLabel {
            text: qsTr("Bitrate")
            size: "sm"
        }

        ThemedComboBox {
            id: audioOnlyBitrateCombo
            width: parent.width
            textRole: "label"
            valueRole: "value"
            model: dialog.audioBitrateModel
            onActivated: function (index) {
                var item = dialog.audioBitrateModel[index]
                if (!item)
                    return
                dialog.applyAudioBitrateChoice(item.value)
                if (audioBitrateCombo)
                    audioBitrateCombo.currentIndex = currentIndex
            }
        }

        ThemedNumberField {
            width: parent.width
            visible: dialog.audioBitrateChoice === "custom"
            from: 32
            to: 512
            step: 16
            unit: qsTr("kbps")
            value: dialog.audioBitrateKbps
            onEdited: function (v) { dialog.audioBitrateKbps = Math.round(v) }
        }
    }

    Item {
        width: parent.width
        height: audioAdvancedHeader.implicitHeight

        Row {
            id: audioAdvancedHeader
            spacing: Theme.spacingSm
            anchors.left: parent.left

            IconGlyph {
                anchors.verticalCenter: parent.verticalCenter
                glyph: Theme.icons.chevronRight
                iconSize: Theme.iconSizeSm
                iconColor: Theme.c.exportDialogAudioSection.icon
                rotation: dialog.advancedOpen ? 90 : 0
                Behavior on rotation {
                    NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
                }
            }

            ThemedLabel {
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("Advanced")
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: dialog.advancedOpen = !dialog.advancedOpen
        }

        Accessible.role: Accessible.Button
        Accessible.name: qsTr("Advanced")
        Accessible.checkable: true
        Accessible.checked: dialog.advancedOpen
        Accessible.onPressAction: dialog.advancedOpen = !dialog.advancedOpen
    }

    Column {
        width: parent.width
        spacing: Theme.spacingLg
        visible: dialog.advancedOpen
        height: visible ? implicitHeight : 0
        clip: true

        ThemedLabel {
            text: qsTr("Tags")
            size: "sm"
        }

        Column {
            width: parent.width
            spacing: Theme.spacingSm

            ThemedLabel {
                text: qsTr("Title")
                size: "xs"
            }
            ThemedTextField {
                id: tagTitleField
                width: parent.width
            }
        }

        Column {
            width: parent.width
            spacing: Theme.spacingSm

            ThemedLabel {
                text: qsTr("Artist")
                size: "xs"
            }
            ThemedTextField {
                id: tagArtistField
                width: parent.width
            }
        }

        Column {
            width: parent.width
            spacing: Theme.spacingSm

            ThemedLabel {
                text: qsTr("Album")
                size: "xs"
            }
            ThemedTextField {
                id: tagAlbumField
                width: parent.width
            }
        }

        Column {
            width: parent.width
            spacing: Theme.spacingSm

            ThemedLabel {
                text: qsTr("Comment")
                size: "xs"
            }
            ThemedTextArea {
                id: tagCommentField
                width: parent.width
                height: 96
            }
        }
    }
    }
