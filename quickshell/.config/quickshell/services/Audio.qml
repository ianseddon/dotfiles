pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// The default output and the outputs to choose from.
Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool ready: sink !== null && sink.ready && sink.audio !== null
    readonly property real volume: ready ? sink.audio.volume : 0
    readonly property bool muted: ready ? sink.audio.muted : false
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio !== null)

    function setVolume(value: real): void {
        if (ready) {
            sink.audio.muted = false;
            sink.audio.volume = Math.max(0, Math.min(1, value));
        }
    }

    function toggleMute(): void {
        if (ready)
            sink.audio.muted = !sink.audio.muted;
    }

    function useSink(node: PwNode): void {
        Pipewire.preferredDefaultAudioSink = node;
    }

    // Binds the nodes so their audio properties are live.
    PwObjectTracker {
        objects: [root.sink].concat(root.sinks)
    }
}
