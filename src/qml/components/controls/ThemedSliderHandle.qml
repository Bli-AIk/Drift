import QtQuick
import QtQuick.Controls.Basic
import Drift

Rectangle {
    id: handleRect
    required property Slider slider
    x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
    y: slider.topPadding + slider.availableHeight / 2 - height / 2
    width: Theme.touchInput ? 20 : Theme.iconSizeMd
    height: width
    radius: width / 2
    color: slider.pressed ? Theme.panelSecondaryForeground
                        : (slider.hovered ? Qt.lighter(Theme.primary, 1.25) : Qt.lighter(Theme.primary, 1.15))
    border.width: Theme.borderWidthFocus
    border.color: slider.visualFocus ? Theme.focusRing : Theme.primaryForeground
    // Grows slightly on hover so the grab target is legible.
    scale: slider.pressed ? 1.1 : (slider.hovered || slider.visualFocus ? 1.05 : 1.0)

    Behavior on x {
        enabled: !slider.pressed && !EditorState.previewDragActive
        NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easingInOut }
    }
    Behavior on color {
        ColorAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
    }
    Behavior on scale {
        NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
    }
    }
