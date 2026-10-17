import QtQuick
import Drift

// One slot of the contextual clip toolbar, with the hairline that sets a
// destructive action off from the edits beside it.
Item {
    id: slot

    required property var modelData

    signal activated(string actionId)

    // Delete sits next to the two edits it cannot be undone from as easily;
    // the rule separating it is cheaper than the width a real gutter costs.
    Rectangle {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        visible: slot.modelData.gutter === true
        width: Theme.borderWidth
        height: Theme.spacing3xl
        color: Theme.panelBorder
    }

    NavRailButton {
        anchors.fill: parent
        entry: slot.modelData
        tint: slot.modelData.destructive === true ? Theme.destructive
                                                  : Theme.mutedForeground
        onClicked: {
            // Explicit rather than inherited: a signal handler declared on the
            // instance replaces the one in NavRailButton's own definition.
            if (slot.modelData.destructive === true)
                Haptics.confirm()
            else
                Haptics.select()
            slot.activated(slot.modelData.id)
        }
    }
}
