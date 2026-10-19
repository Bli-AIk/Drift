import QtQuick
import Drift

// Draws the active guide sets over the canvas. Positions arrive as fractions
// of the canvas, so this only has to fill the canvas rect.
Item {
    id: root

    visible: EditorState.preview.guidesEnabled

    Repeater {
        model: EditorState.guideItems

        GuideLayerMark {
            canvasWidth: root.width
            canvasHeight: root.height
        }
    }
}
