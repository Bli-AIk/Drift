import QtQuick
import Drift

// The pill at the top of a phone sheet. It is the visible half of the drag affordance;
// the header behind it is what actually receives the gesture.
ThemeSlot {
    id: root
    slot: "AndroidSheetHandle"
    control: root
    width: 44
    height: 5
    fallback: Component {
        Rectangle {
            anchors.fill: parent
            radius: Theme.c.androidSheetHandle.radius
            color: Theme.c.androidSheetHandle.background
        }
    }
}
