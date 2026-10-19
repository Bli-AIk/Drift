import QtQuick
import Drift

// One edit action in the toolbar's More menu.
ThemedMenuItem {
    property var host
    property string actionId

    text: host.actionMeta[actionId].shortcut
          ? host.withShortcut(host.actionMeta[actionId].label, host.actionMeta[actionId].shortcut)
          : host.actionMeta[actionId].label
    icon.name: host.actionMeta[actionId].glyph
    enabled: host.actionEnabled(actionId)
    onTriggered: host.triggerAction(actionId)
}
