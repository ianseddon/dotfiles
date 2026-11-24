pragma ComponentBehavior: Bound

import QtQuick
import "../theme"

// Bar text: the UI font with tabular figures, so changing numbers don't shift.
Text {
    color: Theme.foreground
    font.family: Theme.fontSans
    font.pixelSize: Style.fontSize
    font.features: {
        "tnum": 1
    }
    verticalAlignment: Text.AlignVCenter
}
