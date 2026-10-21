import QtQuick
import QtQuick.Window
import Drift

// Android's stand-in for MediaPreviewWindow: filling the window, over the editor.
Item {
    property alias loader: androidMediaPreviewLoader
    anchors.fill: parent
    z: 10
    visible: ShellBridge.main?.mediaPreviewPage !== null

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
    }

    Loader {
        id: androidMediaPreviewLoader
        anchors.fill: parent
        active: false
        sourceComponent: Component {
            AndroidMediaPreview {
                onClosed: {
                    ShellBridge.main.mediaPreviewPage = null
                    Qt.callLater(function () { androidMediaPreviewLoader.active = false })
                }
            }
        }
    }
}
