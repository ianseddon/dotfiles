pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../theme"

// A popup below its owner, centred on it and kept on screen. Clicking outside
// or pressing Esc closes it; `interactive: false` makes a tooltip instead.
PopupWindow {
    id: root

    required property Item owner
    default property alias content: body.data
    property bool open: false
    property bool interactive: true
    property int padding: Style.spaceLg

    signal keyPressed(var event)

    anchor.item: owner
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.margins.top: Style.barGap
    anchor.adjustment: PopupAdjustment.Slide
    grabFocus: interactive
    visible: open
    onVisibleChanged: {
        if (!visible)
            open = false;
    }
    color: "transparent"
    implicitWidth: card.implicitWidth
    implicitHeight: card.implicitHeight

    Rectangle {
        id: card

        implicitWidth: body.implicitWidth + 2 * root.padding
        implicitHeight: body.implicitHeight + 2 * root.padding
        color: Qt.alpha(Theme.background, Style.popupOpacity)
        radius: Style.radius
        border.width: Style.border
        border.color: Theme.lighterBackground
        focus: true
        Keys.onEscapePressed: root.open = false
        Keys.onPressed: event => root.keyPressed(event)

        Item {
            id: body

            x: root.padding
            y: root.padding
            implicitWidth: childrenRect.width
            implicitHeight: childrenRect.height
        }
    }
}
