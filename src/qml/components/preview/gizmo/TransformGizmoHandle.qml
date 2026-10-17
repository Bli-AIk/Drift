import QtQuick
import Drift

// One gizmo axis: back strokes, front strokes, and the head.
Item {
    id: handleItem

    required property var modelData
    required property var host

    readonly property bool hot: handleItem.host.dragging === modelData.id
                                || (handleItem.host.dragging === "" && handleItem.host.hovered === modelData.id)
    readonly property color ink: hot ? Theme.gizmoHot : handleItem.host.colorFor(modelData.id)
    readonly property real lineWidth: (hot ? 3 : 2) * (handleItem.host.touch ? 1.25 : 1)
    // While one handle is dragged the others step back, so the one in use reads clearly.
    opacity: handleItem.host.dragging === "" || hot ? 1 : 0.35

    // The far half of a ring, behind the clip.
    Repeater {
        model: handleItem.modelData.back
        delegate: TransformGizmoStroke {
            ink: handleItem.ink
            thickness: handleItem.lineWidth
            fade: 0.3
        }
    }

    Repeater {
        model: handleItem.modelData.front
        delegate: TransformGizmoStroke {
            ink: handleItem.ink
            thickness: handleItem.lineWidth
            fade: 1
        }
    }

    TransformGizmoHead {
        headPath: handleItem.modelData.head
        ink: handleItem.ink
        show: handleItem.modelData.head.length > 0
    }
}
