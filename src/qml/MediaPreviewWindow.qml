import QtQuick
import QtQuick.Window
import Drift

Window {
    id: root

    function openFor(index) {
        view.openFor(index)
        root.show()
        root.raise()
        root.requestActivate()
    }

    function openClip(track, index) {
        view.openClip(track, index)
        root.show()
        root.raise()
        root.requestActivate()
    }

    width: 920
    height: 680
    minimumWidth: 640
    minimumHeight: 480
    title: view.clipId.length > 0
           ? (view.assetName.length > 0 ? qsTr("Crop — %1").arg(view.assetName) : qsTr("Crop"))
           : (view.assetName.length > 0 ? qsTr("Preview — %1").arg(view.assetName) : qsTr("Preview"))
    color: {
        const opacity = ThemeManager.window.backgroundOpacity
        const multiplier = (opacity === undefined || opacity === null) ? 1 : opacity
        return WindowBackdrop.windowBackground(Theme.c.mediaPreviewWindow.background, multiplier)
    }

    Component.onCompleted: WindowBackdrop.attach(root)

    onClosing: view.release()

    MediaPreviewView {
        id: view
        anchors.fill: parent
        onCloseRequested: root.close()
    }
}
