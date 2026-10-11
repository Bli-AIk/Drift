import QtQuick
import Drift

// The home screen: a launcher for projects and nothing else. App-level actions (Extras,
// settings, updates, downloads) live in the editor, where the desktop shell also keeps them.
AndroidProjectsPage {
    id: root

    signal enterEditor()
}
