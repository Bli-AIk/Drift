import QtQuick
import QtQuick.Shapes
import Drift

// Dashed frame of the transform layer that contains the selected clip.
Shape {
    id: outline

    // The parent-frame item: quad (4 points) and corner(i) in overlay px.
    required property var frame

    anchors.fill: parent
    visible: outline.frame.quad.length === 4
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        strokeColor: Theme.clipTransform
        strokeWidth: Theme.borderWidthFocus
        strokeStyle: ShapePath.DashLine
        dashPattern: [4, 3]
        fillColor: "transparent"
        startX: outline.frame.corner(0).x
        startY: outline.frame.corner(0).y
        PathLine { x: outline.frame.corner(1).x; y: outline.frame.corner(1).y }
        PathLine { x: outline.frame.corner(2).x; y: outline.frame.corner(2).y }
        PathLine { x: outline.frame.corner(3).x; y: outline.frame.corner(3).y }
        PathLine { x: outline.frame.corner(0).x; y: outline.frame.corner(0).y }
    }
}
