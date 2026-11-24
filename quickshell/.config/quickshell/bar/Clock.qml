pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../theme"

// The time; the date on hover; a calendar on click.
Pill {
    id: root

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    HoverState {
        id: hover

        hovered: root.hovered && !calendar.open
    }

    onClicked: calendar.open = !calendar.open

    Label {
        text: Qt.formatTime(clock.date, "HH:mm")
    }

    Popup {
        owner: root
        interactive: false
        open: hover.revealed
        padding: Style.spaceSm

        Label {
            text: Qt.formatDate(clock.date, "dddd, d MMMM yyyy")
        }
    }

    Calendar {
        id: calendar

        owner: root
        today: clock.date
    }
}
