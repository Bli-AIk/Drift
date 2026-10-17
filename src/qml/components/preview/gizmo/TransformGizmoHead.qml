import QtQuick
import QtQuick.Shapes

// Arrow head or scale square at the end of a gizmo handle.
Shape {
    id: head

    required property var headPath
    required property color ink
    required property bool show

    visible: head.show
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        strokeColor: head.ink
        strokeWidth: 1
        fillColor: head.ink
        joinStyle: ShapePath.RoundJoin
        PathPolyline { path: head.headPath }
    }
}
