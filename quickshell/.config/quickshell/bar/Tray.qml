pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "../theme"

// Tray icons behind a chevron; hovering slides them out.
RowLayout {
    id: root

    property var menuItem: null

    spacing: Style.spaceSm
    visible: SystemTray.items.values.length > 0

    HoverHandler {
        id: pointer
    }

    HoverState {
        id: drawer

        hovered: pointer.hovered || menu.open
        showDelay: 0
        hideDelay: Style.drawerDelay
    }

    Icon {
        text: drawer.revealed ? "\u{f0142}" : "\u{f0141}"
        color: pointer.hovered ? Theme.foreground : Theme.darkForeground
    }

    Reveal {
        shown: drawer.revealed

        Repeater {
            model: SystemTray.items

            Item {
                id: trayItem

                required property SystemTrayItem modelData

                implicitWidth: Style.trayIconSize + Style.spaceSm
                implicitHeight: Style.barHeight

                IconImage {
                    anchors.centerIn: parent
                    implicitSize: Style.trayIconSize
                    source: trayItem.modelData.icon
                }

                HoverHandler {
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                    // Click (left or right) opens the item's menu: libayatana items,
                    // such as nm-applet and Spotify, implement no Activate, and a
                    // failed Activate isn't reported to the shell. Middle-click
                    // opens the app itself (Activate).
                    onTapped: (point, button) => {
                        const item = trayItem.modelData;
                        if (button === Qt.MiddleButton || !item.hasMenu) {
                            item.activate();
                        } else {
                            root.menuItem = trayItem;
                            menu.open = true;
                        }
                    }
                }
            }
        }
    }

    TrayMenu {
        id: menu

        owner: root.menuItem ?? root
        // The item may go away while remembered (an app quits, or a reload).
        handle: root.menuItem?.modelData?.menu ?? null
        onOpenChanged: {
            if (!open)
                root.menuItem = null;
        }
    }
}
