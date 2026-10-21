import QtQuick
import QtQuick.Window
import Drift

// Under the Overlay, over the page. Overlay popups stay interactive; the editor cannot.
MouseArea {
    id: overlayInputGuard
    anchors.fill: parent
    z: 11
    visible: Theme.touchInput && (ShellBridge.main?.overlayModalCount ?? 0) > 0
    acceptedButtons: Qt.AllButtons
    hoverEnabled: true
    preventStealing: true
    onPressed: (mouse) => { mouse.accepted = true }
    onWheel: (wheel) => { wheel.accepted = true }

    readonly property int _stealHandlers: PointerHandler.CanTakeOverFromHandlersOfSameType
                                        | PointerHandler.CanTakeOverFromHandlersOfDifferentType

    TapHandler {
        acceptedButtons: Qt.AllButtons
        grabPermissions: overlayInputGuard._stealHandlers
    }

    PinchHandler {
        target: null
        grabPermissions: overlayInputGuard._stealHandlers
    }

    DragHandler {
        target: null
        grabPermissions: overlayInputGuard._stealHandlers
    }
}
