pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "palette.js" as Palette

// The current theme's colours and fonts, for every shell component.
//
// Colours come from the palette `theme set` writes. Fonts are the families
// fontconfig resolves for monospace and sans-serif (`theme font`): Qt reads
// fontconfig's configuration once, at startup, so an alias would not follow a
// change until a restart, while the resolved names switch live. The theme hook
// calls reload() through IPC: `theme set` swaps a symlink, which a file watch can miss.
Singleton {
    id: root

    // The greeter points this at its own copy of the palette.
    property string palettePath: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/theme/current/palette.json"
    property bool previewOpen: false

    property var palette: Palette.fallback()
    readonly property string name: palette.name
    readonly property string mode: palette.mode
    readonly property var colourKeys: Palette.colourKeys

    readonly property color accent: palette.colours.accent
    readonly property color selection: palette.colours.selection
    readonly property color muted: palette.colours.muted
    readonly property color background: palette.colours.background
    readonly property color darkBackground: palette.colours.dark_background
    readonly property color darkerBackground: palette.colours.darker_background
    readonly property color lighterBackground: palette.colours.lighter_background
    readonly property color foreground: palette.colours.foreground
    readonly property color darkForeground: palette.colours.dark_foreground
    readonly property color lightForeground: palette.colours.light_foreground
    readonly property color brightForeground: palette.colours.bright_foreground
    readonly property color red: palette.colours.red
    readonly property color yellow: palette.colours.yellow
    readonly property color orange: palette.colours.orange
    readonly property color green: palette.colours.green
    readonly property color cyan: palette.colours.cyan
    readonly property color blue: palette.colours.blue
    readonly property color magenta: palette.colours.magenta
    readonly property color brown: palette.colours.brown

    property string fontMono: "monospace"
    property string fontSans: "sans-serif"

    // A palette colour by its palette.json key, such as "bright_red".
    function colour(key: string): color {
        return palette.colours[key];
    }

    // The colour for a level or severity: "warning", "critical", or anything else.
    function levelColour(level: string): color {
        if (level === "critical")
            return red;
        if (level === "warning")
            return yellow;
        return foreground;
    }

    // Text that reads well on a background colour.
    function textOn(background: color): color {
        return Palette.textOn(background.toString()) === "dark" ? darkerBackground : brightForeground;
    }

    function reload(): void {
        paletteFile.reload();
        monoFont.running = true;
        sansFont.running = true;
    }

    function apply(text: string): void {
        const parsed = Palette.parse(text);
        if (parsed === null)
            console.warn(`theme: ${palettePath} is not a complete palette; using neutral greys`);
        palette = parsed ?? Palette.fallback();
    }

    FileView {
        id: paletteFile

        path: root.palettePath
        onLoaded: root.apply(text())
        // FileView logs the failed read itself; one warning is enough.
        onLoadFailed: root.palette = Palette.fallback()
    }

    Process {
        id: monoFont

        command: ["fc-match", "-f", "%{family[0]}", "monospace"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.fontMono = text.trim() || "monospace"
        }
    }

    Process {
        id: sansFont

        command: ["fc-match", "-f", "%{family[0]}", "sans-serif"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.fontSans = text.trim() || "sans-serif"
        }
    }

    IpcHandler {
        target: "theme"

        // Re-read the palette and fonts (the `theme` hook calls this).
        function reload(): void {
            root.reload();
        }

        // Show or hide the theme preview.
        function preview(): void {
            root.previewOpen = !root.previewOpen;
        }
    }
}
