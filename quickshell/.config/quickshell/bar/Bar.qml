pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../theme"

// One bar per screen: pills along the top edge, 7 px from it (Style.barGap).
// Portrait screens show only workspaces and the clock.
PanelWindow {
    id: root

    required property ShellScreen modelData
    readonly property bool portrait: modelData.height > modelData.width

    screen: modelData
    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Style.barGap + Style.barHeight
    exclusiveZone: implicitHeight
    color: "transparent"
    WlrLayershell.namespace: "quickshell:bar"
    WlrLayershell.layer: WlrLayer.Top

    Workspaces {
        x: Style.barGap
        y: Style.barGap
        screen: root.modelData
    }

    Clock {
        anchors.horizontalCenter: parent.horizontalCenter
        y: Style.barGap
    }

    Row {
        anchors.right: parent.right
        anchors.rightMargin: Style.barGap
        y: Style.barGap
        spacing: Style.spaceSm
        visible: !root.portrait

        Media {}

        Indicators {}

        Status {}
    }
}
