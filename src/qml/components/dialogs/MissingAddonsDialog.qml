import QtQuick
import QtQuick.Controls.Basic
import Drift

// Shown after opening a project whose bundle names addons this machine does not have. The project
// is already loaded — the effects those addons provide simply render as no-ops until installed.
ThemedDialog {
    id: root

    // id / name / version / kinds, as recorded when the project was saved.
    property var addons: []
    // id -> { fraction, phase }, mirroring AddonManagerDialog.
    property var transfers: ({})

    title: qsTr("Extra packs needed")
    acceptText: qsTr("Install all")
    rejectText: qsTr("Skip")
    preferredWidth: Theme.dialogWidthMd

    function openFor(list) {
        addons = list
        transfers = ({})
        // A stale index rejects installs with expired download tickets.
        Addons.refresh(false)
        open()
    }

    onAccepted: {
        for (var i = 0; i < addons.length; ++i)
            Addons.install(addons[i].id)
    }

    Connections {
        target: Addons
        function onProgressChanged(id, fraction, phase) {
            var next = Object.assign({}, root.transfers)
            next[id] = { fraction: fraction, phase: phase }
            root.transfers = next
        }
    }

    contentItem: Column {
        spacing: Theme.spacingLg
        width: parent ? parent.width : 400

        ThemedLabel {
            width: parent.width
            size: "sm"
            text: qsTr("This project was saved with extra packs you don't have. It has opened, but "
                       + "anything they provide will not show until they are installed.")
        }

        Repeater {
            model: root.addons

            MissingAddonsRow {
                transfers: root.transfers
            }
        }

        ThemedLabel {
            width: parent.width
            size: "xs"
            text: qsTr("Reopen the project once they finish installing.")
        }
    }
}
