pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "logic.js" as Logic

// CPU, memory and CPU temperature, read from /proc and /sys every 2 seconds.
Singleton {
    id: root

    readonly property int interval: 2000

    property int cpu: 0
    // CPU averaged over the last 3 samples, so short spikes don't flash in the bar.
    property int cpuAverage: 0
    property int memoryPercent: 0
    property real memoryUsedGiB: 0
    property real memoryTotalGiB: 0
    property real temperature: 0
    property string temperatureInput: ""
    property string load: ""

    readonly property string cpuLevel: Logic.level("cpu", cpuAverage)
    readonly property string memoryLevel: Logic.level("memory", memoryPercent)
    readonly property string temperatureLevel: temperatureInput ? Logic.level("temperature", temperature) : "normal"

    property var previousSample: null
    property var recent: []

    Timer {
        interval: root.interval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload();
            meminfo.reload();
            loadavg.reload();
            if (root.temperatureInput)
                temperatureFile.reload();
        }
    }

    FileView {
        id: stat

        path: "/proc/stat"
        onLoaded: {
            const sample = Logic.cpuSample(text());
            if (root.previousSample) {
                root.cpu = Logic.cpuPercent(root.previousSample, sample);
                root.recent = root.recent.concat([root.cpu]).slice(-3);
                root.cpuAverage = Logic.average(root.recent);
            }
            root.previousSample = sample;
        }
    }

    FileView {
        id: meminfo

        path: "/proc/meminfo"
        onLoaded: {
            const memory = Logic.memory(text());
            root.memoryPercent = memory.percent;
            root.memoryUsedGiB = memory.usedGiB;
            root.memoryTotalGiB = memory.totalGiB;
        }
    }

    FileView {
        id: loadavg

        path: "/proc/loadavg"
        onLoaded: root.load = text().split(" ").slice(0, 3).join(" ")
    }

    FileView {
        id: temperatureFile

        path: root.temperatureInput
        onLoaded: root.temperature = Number(text()) / 1000
    }

    // Finds the CPU package sensor once: hwmon numbers change between boots.
    Process {
        running: true
        command: ["sh", "-c", "for d in /sys/class/hwmon/hwmon*; do printf '%s\\t%s' \"$d\" \"$(cat $d/name)\"; for l in $d/temp*_label; do [ -f \"$l\" ] && printf '\\t%s=%s' \"$(basename $l _label)\" \"$(cat $l)\"; done; echo; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const sensors = text.trim().split("\n").map(line => {
                    const [path, name, ...labels] = line.split("\t");
                    const entries = {};
                    for (const label of labels) {
                        const at = label.indexOf("=");
                        entries[label.slice(0, at)] = label.slice(at + 1);
                    }
                    return {
                        path: path,
                        name: name,
                        labels: entries
                    };
                });
                root.temperatureInput = Logic.cpuTemperatureInput(sensors);
            }
        }
    }
}
