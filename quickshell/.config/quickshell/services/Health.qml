pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import "logic.js" as Logic

// Problems worth showing in the bar: failed units (every 10 seconds), backups
// and Tailscale (every minute), and the wired network (live, from NetworkManager).
// Each problem is {severity: "warning" | "critical", title, detail}.
Singleton {
    id: root

    property var backup: []
    property var tailscale: []
    property var systemUnits: []
    property var userUnits: []

    readonly property var wired: {
        const devices = Networking.devices.values.filter(d => d.type === DeviceType.Wired);
        if (devices.length === 0 || devices.some(d => d.connected))
            return [];
        return [Logic.problem("critical", "Wired network is down", `${devices.map(d => d.name).join(", ")} is not connected. Check the cable, or run nmcli device.`)];
    }

    readonly property var problems: backup.concat(tailscale, wired, systemUnits, userUnits)
    readonly property string severity: Logic.worst(problems)

    // Failed units are cheap to list and worth knowing about quickly; backups
    // and Tailscale change slowly.
    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            systemUnitsCheck.running = true;
            userUnitsCheck.running = true;
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            backupCheck.running = true;
            tailscaleCheck.running = true;
        }
    }

    Process {
        id: backupCheck

        command: ["systemctl", "--user", "show", "--timestamp=unix", "-p", "Result", "-p", "ExecMainExitTimestamp", "borgmatic.service"]
        stdout: StdioCollector {
            onStreamFinished: root.backup = Logic.backupProblems(Logic.parseShow(text), Date.now() / 1000)
        }
    }

    Process {
        id: tailscaleCheck

        command: ["tailscale", "status", "--json"]
        stdout: StdioCollector {
            onStreamFinished: root.tailscale = Logic.tailscaleProblems(text)
        }
    }

    Process {
        id: systemUnitsCheck

        command: ["systemctl", "--failed", "--no-legend", "--plain"]
        stdout: StdioCollector {
            onStreamFinished: root.systemUnits = Logic.failedUnitProblems(text, "system")
        }
    }

    Process {
        id: userUnitsCheck

        command: ["systemctl", "--user", "--failed", "--no-legend", "--plain"]
        stdout: StdioCollector {
            onStreamFinished: root.userUnits = Logic.failedUnitProblems(text, "user")
        }
    }
}
