pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.Mpris
import "../theme"
import "../services" as Services
import "../services/logic.js" as Logic

// Now playing: click plays or pauses, scroll skips, right-click shows more.
Pill {
    id: root

    readonly property MprisPlayer player: Services.Media.player

    visible: player !== null
    onClicked: button => {
        if (button === Qt.RightButton)
            popup.open = !popup.open;
        else if (player.canTogglePlaying)
            player.togglePlaying();
    }
    onScrolled: direction => {
        if (direction > 0 && player.canGoPrevious)
            player.previous();
        else if (direction < 0 && player.canGoNext)
            player.next();
    }

    Icon {
        text: root.player?.isPlaying ? "\u{f03e4}" : "\u{f040a}"
        color: root.hovered ? Theme.foreground : Theme.darkForeground
    }

    Label {
        text: root.player ? Logic.mediaLabel(root.player.trackTitle, root.player.trackArtist, 28) : ""
    }

    MediaPopup {
        id: popup

        owner: root
        player: root.player
    }
}
