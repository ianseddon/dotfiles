import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

// The current palette and fonts, on the focused monitor: `qs ipc call theme preview`.
PanelWindow {
    id: root

    // Swatch rows, by palette.json key.
    readonly property var rows: [
        {
            label: "Backgrounds",
            keys: ["darker_background", "dark_background", "background", "lighter_background", "selection"]
        },
        {
            label: "Foregrounds",
            keys: ["muted", "dark_foreground", "foreground", "light_foreground", "bright_foreground"]
        },
        {
            label: "Colours",
            keys: ["accent", "red", "orange", "yellow", "green", "cyan", "blue", "magenta", "brown"]
        },
        {
            label: "Bright",
            keys: ["bright_red", "bright_yellow", "bright_green", "bright_cyan", "bright_blue", "bright_magenta"]
        }
    ]

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    color: "transparent"
    implicitWidth: card.implicitWidth
    implicitHeight: card.implicitHeight
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:theme-preview"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    Rectangle {
        id: card

        implicitWidth: content.implicitWidth + 2 * Style.spaceXl
        implicitHeight: content.implicitHeight + 2 * Style.spaceXl
        color: Theme.background
        radius: Style.radius
        border.width: Style.border
        border.color: Theme.muted

        focus: true
        Keys.onEscapePressed: Theme.previewOpen = false

        Column {
            id: content

            x: Style.spaceXl
            y: Style.spaceXl
            spacing: Style.spaceLg

            Text {
                text: Theme.name
                color: Theme.brightForeground
                font.family: Theme.fontSans
                font.pixelSize: Style.fontSizeLarge
                font.weight: Font.DemiBold
            }

            Repeater {
                model: root.rows

                Column {
                    id: row

                    required property var modelData

                    spacing: Style.spaceSm

                    Text {
                        text: row.modelData.label
                        color: Theme.darkForeground
                        font.family: Theme.fontSans
                        font.pixelSize: Style.fontSizeSmall
                    }

                    Row {
                        spacing: Style.spaceSm

                        Repeater {
                            model: row.modelData.keys

                            Rectangle {
                                id: swatch

                                required property string modelData
                                readonly property color fill: Theme.colour(modelData)

                                width: 112
                                height: 56
                                radius: Style.radiusSmall
                                color: fill
                                border.width: Style.border
                                border.color: Theme.muted

                                Column {
                                    anchors.left: parent.left
                                    anchors.bottom: parent.bottom
                                    anchors.margins: Style.spaceSm

                                    Text {
                                        text: swatch.modelData.replace(/_/g, " ")
                                        color: Theme.textOn(swatch.fill)
                                        font.family: Theme.fontSans
                                        font.pixelSize: Style.fontSizeSmall
                                    }

                                    Text {
                                        text: swatch.fill.toString()
                                        color: Theme.textOn(swatch.fill)
                                        font.family: Theme.fontMono
                                        font.pixelSize: Style.fontSizeSmall
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Column {
                spacing: Style.spaceXs

                Text {
                    text: `${Theme.fontMono}   The quick brown fox => {} != 0Oo1lI   \u{f0303} \u{e702}`
                    color: Theme.foreground
                    font.family: Theme.fontMono
                    font.pixelSize: Style.fontSize
                }

                Text {
                    text: `${Theme.fontSans}   The quick brown fox jumps over the lazy dog`
                    color: Theme.foreground
                    font.family: Theme.fontSans
                    font.pixelSize: Style.fontSize
                }
            }
        }
    }
}
