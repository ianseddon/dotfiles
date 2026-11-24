pragma ComponentBehavior: Bound

import QtQuick
import "../theme"
import "../services"

// A meter per reading, with the details behind it.
Popup {
    id: root

    Column {
        spacing: Style.spaceMd

        Meter {
            glyph: "\u{f061a}"
            title: "CPU"
            value: SystemStats.cpuAverage
            text: `${SystemStats.cpuAverage}%   load ${SystemStats.load}`
            level: SystemStats.cpuLevel
        }

        Meter {
            glyph: "\u{f035b}"
            title: "Memory"
            value: SystemStats.memoryPercent
            text: `${SystemStats.memoryUsedGiB.toFixed(1)} of ${SystemStats.memoryTotalGiB.toFixed(1)} GiB`
            level: SystemStats.memoryLevel
        }

        Meter {
            visible: SystemStats.temperatureInput !== ""
            glyph: "\u{f050f}"
            title: "Temperature"
            value: SystemStats.temperature
            text: `${Math.round(SystemStats.temperature)} °C   CPU package`
            level: SystemStats.temperatureLevel
        }
    }

    component Meter: Row {
        id: meter

        property string glyph
        property string title
        property real value
        property string text
        property string level

        spacing: Style.spaceMd

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            text: meter.glyph
            color: meter.level !== "normal" ? Theme.levelColour(meter.level) : Theme.darkForeground
        }

        Column {
            spacing: Style.spaceXs

            Row {
                spacing: Style.spaceSm

                Label {
                    text: meter.title
                    color: Theme.brightForeground
                    font.weight: Font.DemiBold
                }

                Label {
                    text: meter.text
                    color: Theme.darkForeground
                }
            }

            Rectangle {
                width: 240
                height: 4
                radius: 2
                color: Theme.lighterBackground

                Rectangle {
                    width: parent.width * Math.min(1, meter.value / 100)
                    height: parent.height
                    radius: 2
                    color: meter.level !== "normal" ? Theme.levelColour(meter.level) : Theme.accent

                    Behavior on width {
                        NumberAnimation {
                            duration: Style.durationNormal
                        }
                    }
                }
            }
        }
    }
}
