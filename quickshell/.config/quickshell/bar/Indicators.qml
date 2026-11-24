pragma ComponentBehavior: Bound

import QtQuick
import "../theme"
import "../services"

// Indicators that exist only while they matter: dictation, and something's wrong.
Pill {
    id: root

    visible: Dictation.active || Health.problems.length > 0

    Icon {
        id: dictation

        visible: Dictation.active
        text: Dictation.state === "recording" ? "\u{f036c}" : "\u{f0772}"
        color: Dictation.state === "recording" ? Theme.red : Theme.yellow

        SequentialAnimation on opacity {
            running: Dictation.state === "recording"
            loops: Animation.Infinite
            onRunningChanged: if (!running)
                dictation.opacity = 1

            NumberAnimation {
                to: 0.4
                duration: 700
                easing.type: Easing.InOutSine
            }

            NumberAnimation {
                to: 1
                duration: 700
                easing.type: Easing.InOutSine
            }
        }

        RotationAnimation on rotation {
            running: Dictation.state === "transcribing"
            loops: Animation.Infinite
            from: 0
            to: 360
            duration: 1200
            onRunningChanged: if (!running)
                dictation.rotation = 0
        }
    }

    Icon {
        id: health

        visible: Health.problems.length > 0
        text: Health.severity === "critical" ? "\u{f0028}" : "\u{f0026}"
        color: Theme.levelColour(Health.severity)

        HoverHandler {
            cursorShape: Qt.PointingHandCursor
        }

        TapHandler {
            onTapped: problems.open = !problems.open
        }
    }

    HealthPopup {
        id: problems

        owner: health
    }
}
