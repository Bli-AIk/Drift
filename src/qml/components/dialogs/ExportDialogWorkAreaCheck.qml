import QtQuick
import Drift

ThemedCheckBox {
    required property var dialog
    width: parent.width
    visible: EditorState.workAreaActive
    text: qsTr("Export work area only (%1 – %2)")
          .arg(dialog.formatWorkAreaTime(EditorState.workAreaInSeconds))
          .arg(dialog.formatWorkAreaTime(EditorState.workAreaOutSeconds))
    checked: dialog.exportWorkAreaOnly
    tooltip: qsTr("Encode only the marked In/Out range instead of the full timeline")
    onToggled: dialog.exportWorkAreaOnly = checked
    }
