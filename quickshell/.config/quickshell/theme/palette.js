.pragma library

// The palette the `theme` command writes to ~/.local/state/theme/current/palette.json:
// `name`, `mode` and these colours (Omarchy's colors.toml schema). Pure functions,
// tested with qmltestrunner (quickshell/tests).

const colourKeys = ["accent", "selection", "muted", "background", "dark_background", "darker_background", "lighter_background", "foreground", "dark_foreground", "light_foreground", "bright_foreground", "red", "yellow", "orange", "green", "cyan", "blue", "magenta", "brown", "bright_red", "bright_yellow", "bright_green", "bright_cyan", "bright_blue", "bright_magenta"];

const hexColour = /^#[0-9a-fA-F]{6}$/;

// {name, mode, colours} from palette.json's text, or null if it isn't a complete palette.
function parse(text) {
    let raw;
    try {
        raw = JSON.parse(text);
    } catch (error) {
        return null;
    }
    if (raw === null || typeof raw !== "object")
        return null;
    const colours = {};
    for (const key of colourKeys) {
        if (typeof raw[key] !== "string" || !hexColour.test(raw[key]))
            return null;
        colours[key] = raw[key];
    }
    return {
        name: String(raw.name || "unnamed"),
        mode: raw.mode === "light" ? "light" : "dark",
        colours: colours
    };
}

// Neutral greys for when no theme is set: readable, and obviously not a theme.
function fallback() {
    const greys = {
        darker_background: "#101010",
        dark_background: "#161616",
        background: "#1c1c1c",
        lighter_background: "#262626",
        selection: "#333333",
        muted: "#4a4a4a",
        dark_foreground: "#7a7a7a",
        foreground: "#c8c8c8",
        light_foreground: "#dadada",
        bright_foreground: "#eeeeee"
    };
    const colours = {};
    for (const key of colourKeys)
        colours[key] = greys[key] || "#9a9a9a";
    return {
        name: "fallback",
        mode: "dark",
        colours: colours
    };
}

// "dark" or "light": which text reads better on this background (WCAG relative
// luminance, with the usual 0.179 threshold between black and white text).
function textOn(hex) {
    const linear = channel => {
        const c = parseInt(hex.slice(channel, channel + 2), 16) / 255;
        return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
    };
    const luminance = 0.2126 * linear(1) + 0.7152 * linear(3) + 0.0722 * linear(5);
    return luminance > 0.179 ? "dark" : "light";
}
