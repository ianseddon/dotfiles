pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../theme"

// Content that slides out while `shown`, and takes no space otherwise.
Item {
    id: root

    property bool shown: false
    default property alias content: row.data

    implicitWidth: shown ? row.implicitWidth : 0
    implicitHeight: row.implicitHeight
    visible: implicitWidth > 0
    clip: true
    opacity: shown ? 1 : 0

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Style.durationNormal
            easing.type: Style.easing
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: Style.durationNormal
        }
    }

    RowLayout {
        id: row

        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.spaceXs
    }
}
