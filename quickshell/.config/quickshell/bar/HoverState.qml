pragma ComponentBehavior: Bound

import QtQuick
import "../theme"

// Delayed hover: `revealed` turns on revealDelay after the pointer arrives and
// off hideDelay after it leaves, so brushing past the bar doesn't flicker.
QtObject {
    id: root

    property bool hovered: false
    property int showDelay: Style.revealDelay
    property int hideDelay: Style.hideDelay
    property bool revealed: false

    onHoveredChanged: {
        if (hovered) {
            hide.stop();
            show.restart();
        } else {
            show.stop();
            hide.restart();
        }
    }

    property Timer show: Timer {
        interval: root.showDelay
        onTriggered: root.revealed = true
    }

    property Timer hide: Timer {
        interval: root.hideDelay
        onTriggered: root.revealed = false
    }
}
