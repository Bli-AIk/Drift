import QtQuick
import Drift

SourceLabSection {
    id: root

    readonly property var lab: EditorState.sourceLab

    title: qsTr("Stabilize")
    dirty: root.lab.recipe.stabilize ?? false
    onResetRequested: root.lab.resetRecipe("stabilize")

    ThemedSwitch {
        text: qsTr("Smooth camera shake")
        checked: root.lab.recipe.stabilize ?? false
        enabled: root.lab.stabilizeAvailable
        tooltip: root.lab.stabilizeAvailable ? "" : qsTr("This build of Drift has no video stabilization support")
        onToggled: root.lab.setRecipeValue("stabilize", checked)
    }
}
