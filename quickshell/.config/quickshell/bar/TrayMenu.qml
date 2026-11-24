pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../theme"

// A tray item's menu, drawn in the theme.
Popup {
    id: root

    property var handle: null

    padding: Style.spaceSm

    QsMenuOpener {
        id: opener

        menu: root.handle
    }

    Column {
        Repeater {
            model: opener.children

            MenuEntry {
                required property QsMenuEntry modelData

                entry: modelData
                onActivated: root.open = false
            }
        }
    }
}
