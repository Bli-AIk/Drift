import QtQuick
import QtQuick.Shapes
import Drift

// Miniature of an easing curve over the unit square. Y is padded so overshoot
// (Back, Elastic) stays visible instead of clipping at the frame.
Item {
    id: root

    property var samples: []
    property bool selected: false
    property bool hovered: false
    property bool showBackground: true
    property color curveColor: Theme.c.easingPicker.curve

    readonly property real _pad: 3
    readonly property real _yMin: -0.35
    readonly property real _yMax: 1.35

    clip: true

    Rectangle {
        anchors.fill: parent
        visible: root.showBackground
        radius: Theme.c.easingPicker.radius
        color: root.selected ? Theme.c.easingPicker.tileBackgroundSelected
                             : (root.hovered ? Theme.c.easingPicker.tileBackgroundHover
                                             : Theme.c.easingPicker.tileBackground)
        border.width: Theme.c.easingPicker.borderWidth
        border.color: root.selected ? Theme.c.easingPicker.tileBorderSelected : "transparent"
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: Theme.c.easingPicker.gridLine
            strokeWidth: Theme.c.easingPicker.borderWidth
            fillColor: "transparent"
            PathPolyline {
                path: [
                    Qt.point(root._pad, root.height - root._pad),
                    Qt.point(root.width - root._pad, root._pad)
                ]
            }
        }

        ShapePath {
            strokeColor: root.curveColor
            strokeWidth: Theme.c.easingPicker.curveWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathPolyline { path: root.curvePath }
        }
    }

    readonly property var curvePath: {
        void width
        void height
        const out = []
        const n = root.samples ? root.samples.length : 0
        const span = root._yMax - root._yMin
        const w = root.width - root._pad * 2
        const h = root.height - root._pad * 2
        for (let i = 0; i < n; ++i) {
            const p = root.samples[i]
            out.push(Qt.point(root._pad + p.x * w,
                              root._pad + (1 - (p.y - root._yMin) / span) * h))
        }
        return out
    }
}
