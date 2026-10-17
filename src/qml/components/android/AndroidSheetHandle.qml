import QtQuick
import Drift

// The pill at the top of a phone sheet. It is the visible half of the drag affordance;
// the header behind it is what actually receives the gesture.
Rectangle {
    width: 44
    height: 5
    radius: 2.5
    color: Theme.sheetHandle
}
