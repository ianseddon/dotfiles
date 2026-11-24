pragma ComponentBehavior: Bound

import QtQuick
import "../theme"
import "../services"

// A gauge; CPU, memory, and temperature slide out on hover, or by themselves
// while high. Click for detail.
Row {
    id: root

    readonly property string level: [SystemStats.cpuLevel, SystemStats.memoryLevel, SystemStats.temperatureLevel].includes("critical") ? "critical" : [SystemStats.cpuLevel, SystemStats.memoryLevel, SystemStats.temperatureLevel].includes("warning") ? "warning" : "normal"

    spacing: Style.spaceSm

    HoverHandler {
        id: pointer

        cursorShape: Qt.PointingHandCursor
    }

    HoverState {
        id: hover

        hovered: pointer.hovered && !popup.open
    }

    TapHandler {
        onTapped: popup.open = !popup.open
    }

    Icon {
        text: "\u{f029a}"
        color: root.level !== "normal" ? Theme.levelColour(root.level) : pointer.hovered ? Theme.foreground : Theme.darkForeground
    }

    Reading {
        shown: hover.revealed || SystemStats.cpuLevel !== "normal"
        glyph: "\u{f061a}"
        value: `${SystemStats.cpuAverage}%`
        level: SystemStats.cpuLevel
    }

    Reading {
        shown: hover.revealed || SystemStats.memoryLevel !== "normal"
        glyph: "\u{f035b}"
        value: `${SystemStats.memoryPercent}%`
        level: SystemStats.memoryLevel
    }

    Reading {
        shown: (hover.revealed || SystemStats.temperatureLevel !== "normal") && SystemStats.temperatureInput !== ""
        glyph: "\u{f050f}"
        value: `${Math.round(SystemStats.temperature)}°`
        level: SystemStats.temperatureLevel
    }

    SystemPopup {
        id: popup

        owner: root
    }

    component Reading: Reveal {
        id: reading

        property string glyph
        property string value
        property string level

        Icon {
            text: reading.glyph
            font.pixelSize: Style.fontSizeSmall + 1
            color: reading.level !== "normal" ? Theme.levelColour(reading.level) : Theme.darkForeground
        }

        Label {
            text: reading.value
            color: Theme.levelColour(reading.level)
        }
    }
}
