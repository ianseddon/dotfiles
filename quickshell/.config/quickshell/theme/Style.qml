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
    // Space between the screen edge and the pills. Equal to Hyprland's gaps_out
    // (hyprland/.config/hypr/looknfeel.lua), so pills line up with window edges.
    readonly property int barGap: 7
    readonly property real pillOpacity: 0.85
    readonly property real popupOpacity: 0.95
    // "pills" (groups of modules in rounded pills), "flush" (one strip along the
    // edge) or "island" (one rounded bar inset from the edges).
    readonly property string barShape: "pills"

    readonly property int fontSize: 13
    readonly property int fontSizeSmall: 11
    readonly property int fontSizeLarge: 16

    // Icons come from the symbols font, so they work whatever mono font is chosen.
    readonly property string fontIcons: "Symbols Nerd Font"
    readonly property int iconSize: 15
    readonly property int trayIconSize: 16

    readonly property int durationFast: 120
    readonly property int durationNormal: 200
    readonly property int easing: Easing.OutCubic

    // Hover reveal: a value slides out after revealDelay and hides hideDelay after
    // the pointer leaves; the tray drawer closes after drawerDelay.
    readonly property int revealDelay: 150
    readonly property int hideDelay: 400
    readonly property int drawerDelay: 600
}
