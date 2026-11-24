pragma ComponentBehavior: Bound

import QtQuick
import "../theme"
import "../services"

// What's wrong, and where to look.
Popup {
    id: root

    Column {
        spacing: Style.spaceMd

        Repeater {
            model: Health.problems

            Row {
                id: problem

                required property var modelData

                spacing: Style.spaceSm

                Icon {
                    text: problem.modelData.severity === "critical" ? "\u{f0028}" : "\u{f0026}"
                    color: Theme.levelColour(problem.modelData.severity)
                }

                Column {
                    spacing: 2

                    Label {
                        text: problem.modelData.title
                        color: Theme.brightForeground
                        font.weight: Font.DemiBold
                    }

                    Label {
                        width: Math.min(implicitWidth, 360)
                        text: problem.modelData.detail
                        color: Theme.darkForeground
                        font.pixelSize: Style.fontSizeSmall
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }
}
