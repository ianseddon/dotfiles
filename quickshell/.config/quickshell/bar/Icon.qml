pragma ComponentBehavior: Bound

import QtQuick
import "../theme"

// A glyph from the symbols font, at the bar's icon size.
Text {
    color: Theme.darkForeground
    font.family: Style.fontIcons
    font.pixelSize: Style.iconSize
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter

    Behavior on color {
        ColorAnimation {
            duration: Style.durationFast
        }
    }
}
