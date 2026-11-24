pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../theme"

// The bar's rounded surface. Its content is laid out in a row, centred
// vertically: items of different heights (icons, text, tray icons) line up. Simple pills
// react through hovered, clicked() and scrolled(); items with their own
// handlers inside take precedence.
Rectangle {
    id: root

    default property alias content: row.data
    property int padding: Style.spaceMd
    property alias spacing: row.spacing
    readonly property bool hovered: hover.hovered

    signal clicked(int button)
    signal scrolled(int delta)

    implicitWidth: row.implicitWidth + 2 * padding
    implicitHeight: Style.barHeight
    radius: height / 2
    color: Qt.alpha(Theme.background, Style.pillOpacity)
    border.width: Style.border
    border.color: Theme.lighterBackground

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Style.durationNormal
            easing.type: Style.easing
        }
    }

    HoverHandler {
        id: hover
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onTapped: (point, button) => root.clicked(button)
    }

    WheelHandler {
        onWheel: event => root.scrolled(event.angleDelta.y)
    }

    RowLayout {
        id: row

        anchors.centerIn: parent
        spacing: Style.spaceMd
    }
}
