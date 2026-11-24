pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "../theme"
import "../services"
import "../services/logic.js" as Logic

// The level, the output device, and a way to the full mixer.
Popup {
    id: root

    Column {
        spacing: Style.spaceMd

        Row {
            spacing: Style.spaceMd

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                text: Logic.volumeIcon(Audio.volume, Audio.muted)
                color: Audio.muted ? Theme.red : Theme.foreground

                TapHandler {
                    onTapped: Audio.toggleMute()
                }
            }

            Item {
                id: slider

                anchors.verticalCenter: parent.verticalCenter
                width: 220
                height: 16

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 4
                    radius: 2
                    color: Theme.lighterBackground

                    Rectangle {
                        width: parent.width * Audio.volume
                        height: parent.height
                        radius: 2
                        color: Audio.muted ? Theme.muted : Theme.accent
                    }
                }

                Rectangle {
                    x: slider.width * Audio.volume - width / 2
                    anchors.verticalCenter: parent.verticalCenter
                    width: 12
                    height: 12
                    radius: 6
                    color: Theme.brightForeground
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onPressed: mouse => Audio.setVolume(mouse.x / width)
                    onPositionChanged: mouse => {
                        if (pressed)
                            Audio.setVolume(mouse.x / width);
                    }
                }
            }

            Label {
                anchors.verticalCenter: parent.verticalCenter
                width: 40
                text: `${Math.round(Audio.volume * 100)}%`
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.lighterBackground
        }

        Label {
            text: "Output"
            color: Theme.darkForeground
            font.pixelSize: Style.fontSizeSmall
        }

        Repeater {
            model: Audio.sinks

            Row {
                id: sinkRow

                required property PwNode modelData
                readonly property bool current: modelData === Audio.sink

                spacing: Style.spaceSm

                Icon {
                    text: sinkRow.current ? "\u{f043e}" : "\u{f043d}"
                    color: sinkRow.current ? Theme.accent : Theme.darkForeground
                }

                Label {
                    text: sinkRow.modelData.description || sinkRow.modelData.nickname || sinkRow.modelData.name
                    color: sinkRow.current ? Theme.foreground : sinkHover.hovered ? Theme.foreground : Theme.darkForeground
                }

                HoverHandler {
                    id: sinkHover

                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    onTapped: Audio.useSink(sinkRow.modelData)
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.lighterBackground
        }

        Label {
            text: "Open the mixer (pavucontrol)"
            color: mixerHover.hovered ? Theme.accent : Theme.darkForeground
            font.pixelSize: Style.fontSizeSmall

            HoverHandler {
                id: mixerHover

                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                onTapped: {
                    Quickshell.execDetached(["pavucontrol"]);
                    root.open = false;
                }
            }
        }
    }
}
