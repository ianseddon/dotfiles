pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../theme"
import "../services"
import "../services/logic.js" as Logic

// Volume: the level slides out on hover or scroll; "muted" stays while muted.
// Scroll changes it by 5%, right-click mutes, click opens the mixer.
RowLayout {
    id: root

    spacing: Style.spaceSm

    HoverHandler {
        id: pointer

        cursorShape: Qt.PointingHandCursor
    }

    HoverState {
        id: hover

        hovered: (pointer.hovered || scrolling.running) && !popup.open
    }

    Timer {
        id: scrolling

        interval: 1500
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onTapped: (point, button) => {
            if (button === Qt.RightButton)
                Audio.toggleMute();
            else
                popup.open = !popup.open;
        }
    }

    WheelHandler {
        onWheel: event => {
            const step = event.angleDelta.y > 0 ? 0.05 : -0.05;
            Audio.setVolume(Math.round((Audio.volume + step) * 20) / 20);
            scrolling.restart();
        }
    }

    Icon {
        text: Logic.volumeIcon(Audio.volume, Audio.muted)
        color: Audio.muted ? Theme.red : pointer.hovered ? Theme.foreground : Theme.darkForeground
    }

    Reveal {
        shown: hover.revealed || Audio.muted

        Label {
            text: Audio.muted ? "muted" : `${Math.round(Audio.volume * 100)}%`
            color: Audio.muted ? Theme.red : Theme.foreground
        }
    }

    VolumePopup {
        id: popup

        owner: root
    }
}
