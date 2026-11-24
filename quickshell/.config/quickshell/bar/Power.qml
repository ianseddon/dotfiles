pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../theme"

// Ends the session. The power-menu module replaces this with a menu.
Icon {
    text: "\u{f0425}"
    color: pointer.hovered ? Theme.red : Theme.darkForeground

    HoverHandler {
        id: pointer

        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        onTapped: Quickshell.execDetached(["hyprshutdown"])
    }
}
