pragma Singleton

import QtQuick
import Quickshell

// Fixed design values for every shell component: change them here, and live
// reload shows the result. Logical pixels; Qt scales them per monitor.
Singleton {
    id: root

    // Spacing scale.
    readonly property int spaceXs: 4
    readonly property int spaceSm: 8
    readonly property int spaceMd: 12
    readonly property int spaceLg: 16
    readonly property int spaceXl: 24

    readonly property int radius: 10
    readonly property int radiusSmall: 6
    readonly property int border: 1

    readonly property int barHeight: 32
    // "pills" (groups of modules in rounded pills), "flush" (one strip along the
    // edge) or "island" (one rounded bar inset from the edges).
    readonly property string barShape: "pills"

    readonly property int fontSize: 13
    readonly property int fontSizeSmall: 11
    readonly property int fontSizeLarge: 16

    readonly property int durationFast: 120
    readonly property int durationNormal: 200
    readonly property int easing: Easing.OutCubic
}
