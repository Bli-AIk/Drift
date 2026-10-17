import QtQuick
import QtQuick.Controls.Basic
import Drift

// Full-overlay dim behind a blocking sheet. Opacity tracks how far the panel has
// risen between the dismiss detent and the expanded one, and fades with the panel
// when a lifted card makes the sheet step aside.
Rectangle {
    id: scrim

    required property var sheet

    visible: scrim.sheet.blocking
    color: Theme.c.androidSheetScrim.background
    opacity: {
        if (!scrim.sheet.opened || scrim.sheet.height <= 0)
            return 0
        const span = Math.max(1, scrim.sheet.expandedHeight - scrim.sheet.dismissHeight)
        const t = (scrim.sheet.panelHeight - scrim.sheet.dismissHeight) / span
        return (0.25 + 0.75 * Math.max(0, Math.min(1, t))) * scrim.sheet._asideFade
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        hoverEnabled: true
        preventStealing: true
        onClicked: scrim.sheet.dismiss()
    }

    readonly property int _stealHandlers: PointerHandler.CanTakeOverFromHandlersOfSameType
                                        | PointerHandler.CanTakeOverFromHandlersOfDifferentType

    TapHandler {
        acceptedButtons: Qt.AllButtons
        grabPermissions: scrim._stealHandlers
    }

    PinchHandler {
        target: null
        grabPermissions: scrim._stealHandlers
    }
}
