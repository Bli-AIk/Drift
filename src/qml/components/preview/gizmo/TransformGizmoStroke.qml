import QtQuick
import QtQuick.Shapes

// One polyline of a gizmo handle: the far half of a ring, or the near half.
Shape {
    id: stroke

    required property var modelData
    required property color ink
    required property real thickness
    property real fade: 1

    opacity: stroke.fade
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        strokeColor: stroke.ink
        strokeWidth: stroke.thickness
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap
        joinStyle: ShapePath.RoundJoin
        PathPolyline { path: stroke.modelData }
    }
}
