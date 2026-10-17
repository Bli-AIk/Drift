import QtQuick
import Drift
// Split button: the left half imports files, the chevron opens the
// folder variant. Both halves share one bordered box so the header
// reads as two actions, not three competing buttons.
Rectangle {
    id: root

    property bool importing: false

    signal importFilesRequested()
    signal importFolderRequested()
    signal collectMediaRequested()

    width: importFilesHalf.width
           + (importMenuHalf.visible ? importSplitDivider.width + importMenuHalf.width : 0)
    height: Theme.controlHeight
    radius: Theme.radiusSm
    color: "transparent"
    border.width: Theme.borderWidth
    border.color: Theme.panelBorder
    opacity: importing ? 0.6 : 1

    Row {
        anchors.fill: parent
        spacing: 0

        ThemedButton {
            id: importFilesHalf
            text: qsTr("Import")
            variant: "ghost"
            flat: true
            radius: Theme.radiusXs
            glyph: Theme.icons.upload
            tooltip: qsTr("Import video, audio or image files")
            enabled: !root.importing
            height: parent.height - Theme.borderWidth * 2
            anchors.verticalCenter: parent.verticalCenter
            onClicked: root.importFilesRequested()
        }

        Rectangle {
            id: importSplitDivider
            width: Theme.borderWidth
            height: parent.height - Theme.spacingLg
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.panelBorder
            visible: importMenuHalf.visible
        }

        ThemedButton {
            id: importMenuHalf
            variant: "ghost"
            flat: true
            radius: Theme.radiusXs
            glyph: Theme.icons.chevronDown
            glyphSize: Theme.iconSizeSm
            leftPadding: Theme.spacingLg
            rightPadding: Theme.spacingLg
            tooltip: qsTr("More import options")
            enabled: !root.importing
            visible: !Theme.touchUi
            height: parent.height - Theme.borderWidth * 2
            anchors.verticalCenter: parent.verticalCenter
            onClicked: importMenu.popup(0, root.height + Theme.spacingSm)
        }
    }

    AssetsPanelImportMenu {
        id: importMenu
        collecting: EditorState.projectFile.collectingMedia
        onImportFilesRequested: root.importFilesRequested()
        onImportFolderRequested: root.importFolderRequested()
        onCollectMediaRequested: root.collectMediaRequested()
    }
}
