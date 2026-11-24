pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../theme"

// One menu entry: a separator, an action, a check box or radio, or a submenu
// that expands in place.
Column {
    id: root

    required property QsMenuEntry entry
    property int depth: 0
    property bool expanded: false

    signal activated

    Rectangle {
        visible: root.entry.isSeparator
        width: Math.max(parent.width, 200)
        height: 1 + 2 * Style.spaceXs
        color: "transparent"

        Rectangle {
            anchors.centerIn: parent
            width: parent.width - 2 * Style.spaceSm
            height: 1
            color: Theme.lighterBackground
        }
    }

    Rectangle {
        visible: !root.entry.isSeparator
        width: Math.max(row.implicitWidth + 2 * Style.spaceSm, 200)
        height: Style.barHeight - 4
        radius: Style.radiusSmall
        color: hover.hovered && root.entry.enabled ? Theme.lighterBackground : "transparent"

        Row {
            id: row

            x: Style.spaceSm + root.depth * Style.spaceLg
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.spaceSm

            Icon {
                visible: root.entry.buttonType !== QsMenuButtonType.None
                text: root.entry.checkState === Qt.Checked ? (root.entry.buttonType === QsMenuButtonType.RadioButton ? "\u{f043e}" : "\u{f0135}") : (root.entry.buttonType === QsMenuButtonType.RadioButton ? "\u{f043d}" : "\u{f0131}")
                color: root.entry.checkState === Qt.Checked ? Theme.accent : Theme.darkForeground
            }

            Label {
                // DBus menus mark mnemonics with "_"; "__" is a literal underscore.
                text: root.entry.text.replace(/__/g, "\u0000").replace(/_/g, "").replace(/\u0000/g, "_")
                color: root.entry.enabled ? Theme.foreground : Theme.muted
            }

            Icon {
                visible: root.entry.hasChildren
                text: root.expanded ? "\u{f0140}" : "\u{f0142}"
            }
        }

        HoverHandler {
            id: hover

            cursorShape: root.entry.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        }

        TapHandler {
            enabled: root.entry.enabled
            onTapped: {
                if (root.entry.hasChildren) {
                    root.expanded = !root.expanded;
                } else {
                    root.entry.triggered();
                    root.activated();
                }
            }
        }
    }

    QsMenuOpener {
        id: submenu

        menu: root.expanded ? root.entry : null
    }

    Repeater {
        model: root.expanded ? submenu.children : null

        Loader {
            required property QsMenuEntry modelData

            source: "MenuEntry.qml"
            onLoaded: {
                const child = item as MenuEntry;
                child.entry = modelData;
                child.depth = root.depth + 1;
                child.activated.connect(root.activated);
            }
        }
    }
}
