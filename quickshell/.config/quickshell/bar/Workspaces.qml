pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../theme"

// One dot per workspace on this monitor; the active one stretches into a bar.
Pill {
    id: root

    required property ShellScreen screen
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
    readonly property var workspaces: Hyprland.workspaces.values.filter(w => w.id > 0 && w.monitor === root.monitor).sort((a, b) => a.id - b.id)

    // Hyprland's Lua mode takes dispatchers as Lua expressions.
    function focusWorkspace(target: string): void {
        Hyprland.dispatch(Hyprland.usingLua ? `hl.dsp.focus({ workspace = "${target}" })` : `workspace ${target}`);
    }

    spacing: Style.spaceSm
    onScrolled: direction => focusWorkspace(direction > 0 ? "e-1" : "e+1")

    Repeater {
        model: root.workspaces

        Item {
            id: dot

            required property HyprlandWorkspace modelData

            implicitWidth: modelData.active ? 24 : 8
            implicitHeight: Style.barHeight

            Behavior on implicitWidth {
                NumberAnimation {
                    duration: Style.durationNormal
                    easing.type: Style.easing
                }
            }

            Rectangle {
                anchors.centerIn: parent
                width: parent.width
                height: 8
                radius: 4
                color: dot.modelData.active ? Theme.accent : dot.modelData.urgent ? Theme.red : hover.hovered ? Theme.foreground : Theme.darkForeground

                Behavior on color {
                    ColorAnimation {
                        duration: Style.durationNormal
                    }
                }
            }

            HoverHandler {
                id: hover

                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                onTapped: root.focusWorkspace(String(dot.modelData.id))
            }
        }
    }
}
