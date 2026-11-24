pragma ComponentBehavior: Bound

import QtQuick
import "../theme"
import "../services/logic.js" as Logic

// A month grid, Monday first, with ISO week numbers. Scroll, the arrow keys or
// the chevrons change the month.
Popup {
    id: root

    property date today
    property int year: today.getFullYear()
    property int month: today.getMonth()
    readonly property int cell: 28

    readonly property var cells: {
        const result = [];
        for (const week of Logic.calendar(year, month)) {
            result.push({
                kind: "week",
                text: String(week.week)
            });
            for (const day of week.days)
                result.push({
                    kind: "day",
                    text: String(day.day),
                    inMonth: day.inMonth,
                    today: day.date.toDateString() === root.today.toDateString()
                });
        }
        return result;
    }

    function step(delta: int): void {
        const first = new Date(year, month + delta, 1);
        year = first.getFullYear();
        month = first.getMonth();
    }

    onOpenChanged: {
        if (open) {
            year = today.getFullYear();
            month = today.getMonth();
        }
    }
    onKeyPressed: event => {
        if (event.key === Qt.Key_Left)
            step(-1);
        else if (event.key === Qt.Key_Right)
            step(1);
    }

    Column {
        spacing: Style.spaceSm

        WheelHandler {
            onWheel: event => root.step(event.angleDelta.y > 0 ? -1 : 1)
        }

        Item {
            width: grid.width
            height: Style.barHeight - Style.spaceSm

            Icon {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "\u{f0141}"
                color: previous.hovered ? Theme.foreground : Theme.darkForeground

                HoverHandler {
                    id: previous

                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    onTapped: root.step(-1)
                }
            }

            Label {
                anchors.centerIn: parent
                text: Qt.formatDate(new Date(root.year, root.month, 1), "MMMM yyyy")
                color: Theme.brightForeground
                font.weight: Font.DemiBold
            }

            Icon {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: "\u{f0142}"
                color: next.hovered ? Theme.foreground : Theme.darkForeground

                HoverHandler {
                    id: next

                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    onTapped: root.step(1)
                }
            }
        }

        Grid {
            id: grid

            columns: 8

            Repeater {
                model: ["Wk", "Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

                Label {
                    required property string modelData

                    width: root.cell
                    height: root.cell
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    color: Theme.darkForeground
                    font.pixelSize: Style.fontSizeSmall
                }
            }

            Repeater {
                model: root.cells

                Item {
                    id: cellItem

                    required property var modelData

                    width: root.cell
                    height: root.cell

                    Rectangle {
                        anchors.centerIn: parent
                        width: root.cell - 4
                        height: width
                        radius: width / 2
                        color: Theme.accent
                        visible: cellItem.modelData.kind === "day" && cellItem.modelData.today
                    }

                    Label {
                        anchors.centerIn: parent
                        text: cellItem.modelData.text
                        font.pixelSize: cellItem.modelData.kind === "week" ? Style.fontSizeSmall : Style.fontSize
                        color: cellItem.modelData.kind === "week" ? Theme.muted : cellItem.modelData.today ? Theme.textOn(Theme.accent) : cellItem.modelData.inMonth ? Theme.foreground : Theme.muted
                    }
                }
            }
        }
    }
}
