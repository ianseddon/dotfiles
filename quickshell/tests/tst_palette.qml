// Run from the repo root: /usr/lib/qt6/bin/qmltestrunner -input quickshell/tests
import QtQuick
import QtTest
import "../.config/quickshell/theme/palette.js" as Palette

TestCase {
    name: "Palette"

    function validJson(overrides) {
        const values = {
            name: "tokyo-night",
            mode: "dark"
        };
        for (const key of Palette.colourKeys)
            values[key] = "#1a1b26";
        values.accent = "#7aa2f7";
        return JSON.stringify(Object.assign(values, overrides || {}));
    }

    function test_parses_a_valid_palette() {
        const palette = Palette.parse(validJson());
        verify(palette !== null);
        compare(palette.name, "tokyo-night");
        compare(palette.mode, "dark");
        compare(palette.colours.accent, "#7aa2f7");
        compare(Object.keys(palette.colours).length, Palette.colourKeys.length);
    }

    function test_rejects_invalid_json() {
        compare(Palette.parse("{ not json"), null);
        compare(Palette.parse(""), null);
    }

    function test_rejects_a_missing_or_malformed_colour() {
        const missing = JSON.parse(validJson());
        delete missing.muted;
        compare(Palette.parse(JSON.stringify(missing)), null);
        compare(Palette.parse(validJson({
            accent: "blue"
        })), null);
        compare(Palette.parse(validJson({
            accent: "#7aa2f"
        })), null);
    }

    function test_fallback_is_complete_neutral_and_named() {
        const fallback = Palette.fallback();
        compare(fallback.name, "fallback");
        compare(fallback.mode, "dark");
        for (const key of Palette.colourKeys)
            verify(/^#[0-9a-f]{6}$/.test(fallback.colours[key]), key);
        // Neutral: every channel of every colour is equal (a grey).
        for (const key of Palette.colourKeys) {
            const hex = fallback.colours[key];
            verify(hex.slice(1, 3) === hex.slice(3, 5) && hex.slice(3, 5) === hex.slice(5, 7), key);
        }
    }

    function test_text_on_a_swatch_is_dark_on_light_and_light_on_dark() {
        compare(Palette.textOn("#ffffff"), "dark");
        compare(Palette.textOn("#e0af68"), "dark");
        compare(Palette.textOn("#1a1b26"), "light");
        compare(Palette.textOn("#7e9cd8"), "dark");
        compare(Palette.textOn("#c34043"), "light");
    }
}
