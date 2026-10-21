import QtQuick
import Drift

ThemedDialog {
    id: root

    title: qsTr("Customize timeline toolbar")
    acceptText: qsTr("Save")
    preferredWidth: Theme.dialogWidthSm

    onOpened: customizer.reload()
    onAccepted: customizer.save()

    contentItem: TimelineToolbarCustomizer {
        id: customizer
        width: parent ? parent.width : Theme.dialogWidthSm
        listMaxHeight: root.availableContentHeight - 120
    }
}
