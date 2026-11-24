pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.Mpris
import Quickshell.Widgets
import "../theme"

// Cover art, the full title, position, and transport controls.
Popup {
    id: root

    property MprisPlayer player
    readonly property int art: 96

    function time(seconds: real): string {
        const total = Math.max(0, Math.floor(seconds));
        return `${Math.floor(total / 60)}:${String(total % 60).padStart(2, "0")}`;
    }

    // MPRIS doesn't push position changes: ask while the popup shows.
    Timer {
        interval: 1000
        running: root.open && root.player?.isPlaying
        repeat: true
        onTriggered: root.player.positionChanged()
    }

    Row {
        spacing: Style.spaceLg

        ClippingRectangle {
            width: root.art
            height: root.art
            radius: Style.radiusSmall
            color: Theme.lighterBackground

            Image {
                anchors.fill: parent
                source: root.player ? root.player.trackArtUrl : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }

        Column {
            width: 240
            spacing: Style.spaceXs

            Label {
                width: parent.width
                text: root.player?.trackTitle ?? ""
                color: Theme.brightForeground
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Label {
                width: parent.width
                text: root.player?.trackArtist ?? ""
                color: Theme.darkForeground
                elide: Text.ElideRight
            }

            Item {
                width: parent.width
                height: Style.spaceMd
            }

            Rectangle {
                width: parent.width
                height: 4
                radius: 2
                color: Theme.lighterBackground
                visible: root.player?.lengthSupported ?? false

                Rectangle {
                    width: root.player && root.player.length > 0 ? parent.width * Math.min(1, root.player.position / root.player.length) : 0
                    height: parent.height
                    radius: 2
                    color: Theme.accent
                }
            }

            Label {
                text: root.player ? `${root.time(root.player.position)} / ${root.time(root.player.length)}` : ""
                color: Theme.darkForeground
                font.pixelSize: Style.fontSizeSmall
                visible: root.player?.lengthSupported ?? false
            }

            Row {
                spacing: Style.spaceLg

                Repeater {
                    model: [
                        {
                            glyph: "\u{f04ae}",
                            action: "previous"
                        },
                        {
                            glyph: root.player?.isPlaying ? "\u{f03e4}" : "\u{f040a}",
                            action: "toggle"
                        },
                        {
                            glyph: "\u{f04ad}",
                            action: "next"
                        }
                    ]

                    Icon {
                        id: control

                        required property var modelData

                        text: modelData.glyph
                        font.pixelSize: Style.fontSizeLarge + 4
                        color: controlHover.hovered ? Theme.accent : Theme.foreground

                        HoverHandler {
                            id: controlHover

                            cursorShape: Qt.PointingHandCursor
                        }

                        TapHandler {
                            onTapped: {
                                if (control.modelData.action === "previous")
                                    root.player.previous();
                                else if (control.modelData.action === "next")
                                    root.player.next();
                                else
                                    root.player.togglePlaying();
                            }
                        }
                    }
                }
            }
        }
    }
}
