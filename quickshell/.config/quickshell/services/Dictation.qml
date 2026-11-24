pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "logic.js" as Logic

// voxtype's state, streamed: "idle", "recording", "transcribing", or "unknown"
// while voxtype isn't running.
Singleton {
    id: root

    property string state: "unknown"
    readonly property bool active: state === "recording" || state === "transcribing"

    Process {
        id: status

        running: true
        command: ["voxtype", "status", "--follow", "--format", "json"]
        stdout: SplitParser {
            onRead: line => root.state = Logic.dictationState(line)
        }
        onExited: {
            root.state = "unknown";
            restart.start();
        }
    }

    // voxtype may start after the shell, or restart: follow it again.
    Timer {
        id: restart

        interval: 10000
        onTriggered: status.running = true
    }
}
