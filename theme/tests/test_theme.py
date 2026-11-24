"""Tests for the `theme` command (docs/desktop-shell/SPEC-theme.md).

Run from the repo root: python3 -m unittest discover -s theme/tests
"""

import json
import os
import re
import subprocess
import sys
import tempfile
import textwrap
import unittest
from importlib.machinery import SourceFileLoader
from importlib.util import module_from_spec, spec_from_loader
from pathlib import Path
from types import ModuleType
from typing import final, override

PACKAGE = Path(__file__).resolve().parent.parent
SCRIPT = PACKAGE / ".local" / "bin" / "theme"
SHIPPED_CONFIG = PACKAGE / ".config" / "theme"


def load_script() -> ModuleType:
    # Bytecode next to the script would be stowed into ~/.local/bin.
    sys.dont_write_bytecode = True
    loader = SourceFileLoader("theme_cli", str(SCRIPT))
    spec = spec_from_loader("theme_cli", loader)
    assert spec is not None
    module = module_from_spec(spec)
    loader.exec_module(module)
    return module


theme = load_script()

COLOURS = {
    "accent": "#7aa2f7",
    "selection": "#283457",
    "muted": "#414868",
    "background": "#1a1b26",
    "dark_background": "#16161e",
    "darker_background": "#0c0e14",
    "lighter_background": "#292e42",
    "foreground": "#c0caf5",
    "dark_foreground": "#565f89",
    "light_foreground": "#a9b1d6",
    "bright_foreground": "#c8d3f5",
    "red": "#f7768e",
    "yellow": "#e0af68",
    "orange": "#ff9e64",
    "green": "#9ece6a",
    "cyan": "#7dcfff",
    "blue": "#7aa2f7",
    "magenta": "#bb9af7",
    "brown": "#75493d",
    "bright_red": "#ff7a93",
    "bright_yellow": "#ffc777",
    "bright_green": "#b9f27c",
    "bright_cyan": "#b4f9f8",
    "bright_blue": "#7da6ff",
    "bright_magenta": "#c0a8f7",
}


def palette_toml(mode: str = "dark", **overrides: str | None) -> str:
    values: dict[str, str | None] = {"mode": mode, **COLOURS, **overrides}
    return "".join(f'{key} = "{value}"\n' for key, value in values.items() if value is not None)


@final
class Sandbox:
    """A config dir and state dir in a temp directory, wired up through the env overrides."""

    def __init__(self) -> None:
        self._tmp: tempfile.TemporaryDirectory[str] = tempfile.TemporaryDirectory()
        root = Path(self._tmp.name)
        self.config: Path = root / "config"
        self.state_home: Path = root / "state"
        self.state: Path = self.state_home / "theme"
        (self.config / "themes").mkdir(parents=True)
        (self.config / "templates").mkdir()
        (self.config / "hooks").mkdir()
        self.env: dict[str, str] = {
            **os.environ,
            "THEME_CONFIG_DIR": str(self.config),
            "XDG_STATE_HOME": str(self.state_home),
        }

    def cleanup(self) -> None:
        self._tmp.cleanup()

    def add_theme(self, name: str, toml: str | None = None, **files: str) -> Path:
        folder = self.config / "themes" / name
        folder.mkdir()
        (folder / "colors.toml").write_text(palette_toml() if toml is None else toml)
        for filename, content in files.items():
            (folder / filename).write_text(content)
        return folder

    def add_template(self, output: str, content: str) -> None:
        (self.config / "templates" / f"{output}.tpl").write_text(content)

    def add_hook(self, name: str, script: str) -> None:
        hook = self.config / "hooks" / name
        hook.write_text("#!/bin/sh\n" + textwrap.dedent(script))
        hook.chmod(0o755)

    def run(self, *args: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, str(SCRIPT), *args],
            env=self.env,
            capture_output=True,
            text=True,
            check=False,
        )


class SandboxTestCase(unittest.TestCase):
    box: Sandbox

    @override
    def setUp(self) -> None:
        self.box = Sandbox()
        self.addCleanup(self.box.cleanup)


class PaletteValidationTest(SandboxTestCase):
    def load(self, name: str = "tokyo-night", toml: str | None = None):
        return theme.load_palette(self.box.add_theme(name, toml))

    def test_valid_palette_loads_every_key(self) -> None:
        palette = self.load()
        self.assertEqual(palette.name, "tokyo-night")
        self.assertEqual(palette.values["mode"], "dark")
        self.assertEqual(palette.values["accent"], "#7aa2f7")

    def test_missing_key_is_named(self) -> None:
        with self.assertRaisesRegex(theme.ThemeError, r"colors\.toml: missing key 'muted'"):
            self.load(toml=palette_toml(muted=None))

    def test_bad_hex_is_named(self) -> None:
        with self.assertRaisesRegex(theme.ThemeError, r"'accent' must be #rrggbb, got '#7aa2f'"):
            self.load(toml=palette_toml(accent="#7aa2f"))

    def test_bad_mode(self) -> None:
        with self.assertRaisesRegex(theme.ThemeError, r"'mode' must be 'dark' or 'light'"):
            self.load(toml=palette_toml(mode="dim"))

    def test_extra_string_keys_are_kept(self) -> None:
        palette = self.load(toml=palette_toml(hyprland_border="#123456", variant="night"))
        self.assertEqual(palette.values["hyprland_border"], "#123456")
        self.assertEqual(palette.values["variant"], "night")

    def test_orange_and_brown_fall_back_like_omarchy(self) -> None:
        palette = self.load(toml=palette_toml(orange=None, brown=None, yellow="#e0af68"))
        self.assertEqual(palette.values["orange"], "#e0af68")
        self.assertEqual(palette.values["brown"], "#705834")  # orange mixed 50% with black

    def test_brown_falls_back_from_the_theme_orange(self) -> None:
        palette = self.load(toml=palette_toml(brown=None, orange="#ff9e64"))
        self.assertEqual(palette.values["brown"], "#804f32")

    def test_non_string_extra_key_is_rejected(self) -> None:
        with self.assertRaisesRegex(theme.ThemeError, r"'opacity' must be a string"):
            self.load(toml=palette_toml() + "opacity = 0.9\n")

    def test_reserved_key_name_is_rejected(self) -> None:
        with self.assertRaisesRegex(theme.ThemeError, r"'name' is reserved"):
            self.load(toml=palette_toml(name="other"))

    def test_bad_theme_name(self) -> None:
        with self.assertRaisesRegex(theme.ThemeError, r"'Tokyo_Night' must be lowercase kebab-case"):
            self.load(name="Tokyo_Night")

    def test_invalid_toml_names_the_file(self) -> None:
        with self.assertRaisesRegex(theme.ThemeError, r"colors\.toml: invalid TOML"):
            self.load(toml="accent = \n")

    def test_missing_colors_toml(self) -> None:
        folder = self.box.config / "themes" / "empty"
        folder.mkdir()
        with self.assertRaisesRegex(theme.ThemeError, r"empty/colors\.toml: not found"):
            theme.load_palette(folder)


class RenderTest(SandboxTestCase):
    palette: object  # theme.Palette; the script is loaded at run time, so it has no static type

    @override
    def setUp(self) -> None:
        super().setUp()
        self.palette = theme.load_palette(self.box.add_theme("tokyo-night"))

    def render(self, template: str) -> str:
        return theme.render(template, self.palette, source=Path("test.tpl"))

    def test_placeholder_forms(self) -> None:
        self.assertEqual(
            self.render("{{ accent }} {{ accent_strip }} {{ accent_rgb }}"),
            "#7aa2f7 7aa2f7 122,162,247",
        )

    def test_spaces_inside_braces_are_optional(self) -> None:
        self.assertEqual(self.render("{{accent}}|{{   accent   }}"), "#7aa2f7|#7aa2f7")

    def test_string_keys_render_as_is(self) -> None:
        self.assertEqual(self.render("mode={{ mode }}"), "mode=dark")

    def test_unknown_key_names_file_and_line(self) -> None:
        with self.assertRaisesRegex(theme.RenderError, r"test\.tpl:3: unknown palette key 'acent'"):
            self.render("one\ntwo\n{{ acent }}\n")

    def test_strip_of_a_non_colour_is_unknown(self) -> None:
        with self.assertRaisesRegex(theme.RenderError, r"unknown palette key 'mode_rgb'"):
            self.render("{{ mode_rgb }}")

    def test_text_without_placeholders_is_unchanged(self) -> None:
        text = "general { border = 2 }\n"
        self.assertEqual(self.render(text), text)


class RenderThemeTest(SandboxTestCase):
    def render_into(self, folder: Path) -> Path:
        out = Path(self.box.state_home) / "out"
        out.mkdir(parents=True)
        theme.render_theme(theme.load_palette(folder), self.box.config / "templates", out)
        return out

    def test_templates_render_and_palette_json_is_written(self) -> None:
        self.box.add_template("hyprland.lua", 'local accent = "{{ accent_strip }}"\n')
        out = self.render_into(self.box.add_theme("tokyo-night"))
        self.assertEqual((out / "hyprland.lua").read_text(), 'local accent = "7aa2f7"\n')
        self.assertEqual((out / "name").read_text(), "tokyo-night\n")
        palette = json.loads((out / "palette.json").read_text())
        self.assertEqual(palette["name"], "tokyo-night")
        self.assertEqual(palette["mode"], "dark")
        self.assertEqual(palette["accent"], "#7aa2f7")

    def test_theme_file_overrides_template_output(self) -> None:
        self.box.add_template("nvim.lua", "-- generated {{ accent }}\n")
        out = self.render_into(self.box.add_theme("tokyo-night", **{"nvim.lua": "-- native port\n"}))
        self.assertEqual((out / "nvim.lua").read_text(), "-- native port\n")

    def test_theme_files_without_a_template_are_copied(self) -> None:
        out = self.render_into(self.box.add_theme("tokyo-night", **{"bat.tmTheme": "<plist/>\n"}))
        self.assertEqual((out / "bat.tmTheme").read_text(), "<plist/>\n")
        self.assertFalse((out / "colors.toml").exists())

    def test_reserved_theme_file_is_rejected(self) -> None:
        folder = self.box.add_theme("tokyo-night", **{"palette.json": "{}"})
        with self.assertRaisesRegex(theme.ThemeError, r"palette\.json is generated"):
            self.render_into(folder)


class CheckCommandTest(SandboxTestCase):
    def test_check_all_themes(self) -> None:
        self.box.add_template("hyprland.lua", "{{ accent }}\n")
        self.box.add_theme("oxocarbon")
        self.box.add_theme("tokyo-night")
        result = self.box.run("check")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "ok oxocarbon\nok tokyo-night\n")

    def test_check_reports_every_failure_and_exits_1(self) -> None:
        self.box.add_template("hyprland.lua", "{{ acent }}\n")
        self.box.add_theme("tokyo-night")
        result = self.box.run("check", "tokyo-night")
        self.assertEqual(result.returncode, 1)
        self.assertIn("hyprland.lua.tpl:1: unknown palette key 'acent'", result.stderr)

    def test_check_unknown_theme(self) -> None:
        result = self.box.run("check", "nope")
        self.assertEqual(result.returncode, 1)
        self.assertIn("no theme named 'nope'", result.stderr)

    def test_check_does_not_touch_state(self) -> None:
        self.box.add_theme("tokyo-night")
        self.box.run("check")
        self.assertFalse(self.box.state.exists())


class SetCommandTest(SandboxTestCase):
    @override
    def setUp(self) -> None:
        super().setUp()
        self.box.add_template("hyprland.lua", "{{ accent }}\n")
        self.box.add_theme("tokyo-night")
        self.box.add_theme("oxocarbon", palette_toml(accent="#ff7eb6"))

    @property
    def current(self) -> Path:
        return self.box.state / "current"

    def test_set_switches_current(self) -> None:
        result = self.box.run("set", "tokyo-night")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(self.current.is_symlink())
        self.assertEqual((self.current / "name").read_text(), "tokyo-night\n")
        self.assertEqual((self.current / "hyprland.lua").read_text(), "#7aa2f7\n")

    def test_link_is_relative_so_the_state_dir_can_move(self) -> None:
        self.box.run("set", "tokyo-night")
        self.assertFalse(self.current.readlink().is_absolute())

    def test_switching_again_keeps_exactly_one_render(self) -> None:
        self.box.run("set", "tokyo-night")
        self.box.run("set", "oxocarbon")
        self.assertEqual((self.current / "hyprland.lua").read_text(), "#ff7eb6\n")
        renders = list((self.box.state / "renders").iterdir())
        self.assertEqual([r.resolve() for r in renders], [self.current.resolve()])

    def test_render_failure_changes_nothing(self) -> None:
        self.box.run("set", "tokyo-night")
        before = self.current.resolve()
        self.box.add_template("broken.conf", "{{ nope }}\n")
        result = self.box.run("set", "oxocarbon")
        self.assertEqual(result.returncode, 1)
        self.assertIn("broken.conf.tpl:1: unknown palette key 'nope'", result.stderr)
        self.assertEqual(self.current.resolve(), before)
        self.assertEqual((self.current / "name").read_text(), "tokyo-night\n")
        self.assertEqual(list((self.box.state / "renders").iterdir()), [before])

    def test_unknown_theme(self) -> None:
        result = self.box.run("set", "nope")
        self.assertEqual(result.returncode, 1)
        self.assertIn("no theme named 'nope'", result.stderr)
        self.assertFalse(self.current.exists())

    def test_hooks_run_in_name_order_with_theme_name_and_current_dir(self) -> None:
        log = self.box.state_home / "hooks.log"
        for name in ("20-second", "10-first"):
            self.box.add_hook(name, f'echo "{name} $1 $THEME_CURRENT" >> "{log}"\n')
        result = self.box.run("set", "oxocarbon")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            log.read_text().splitlines(),
            [f"10-first oxocarbon {self.current}", f"20-second oxocarbon {self.current}"],
        )

    def test_failing_hook_exits_2_names_the_hook_and_others_still_run(self) -> None:
        marker = self.box.state_home / "ran"
        self.box.add_hook("10-broken", "echo reload failed >&2\nexit 3\n")
        self.box.add_hook("20-fine", f'touch "{marker}"\n')
        result = self.box.run("set", "tokyo-night")
        self.assertEqual(result.returncode, 2)
        self.assertIn("reload failed", result.stderr)
        self.assertIn("hook 10-broken failed (exit 3)", result.stderr)
        self.assertTrue(marker.exists())
        self.assertEqual((self.current / "name").read_text(), "tokyo-night\n")

    def test_non_executable_hooks_are_skipped(self) -> None:
        marker = self.box.state_home / "ran"
        self.box.add_hook("10-off", f'touch "{marker}"\n')
        (self.box.config / "hooks" / "10-off").chmod(0o644)
        result = self.box.run("set", "tokyo-night")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(marker.exists())


class ListAndCurrentTest(SandboxTestCase):
    @override
    def setUp(self) -> None:
        super().setUp()
        self.box.add_theme("tokyo-night")
        self.box.add_theme("oxocarbon")
        (self.box.config / "themes" / "not-a-theme").mkdir()

    def test_list_before_any_set(self) -> None:
        result = self.box.run("list")
        self.assertEqual(result.stdout, "  oxocarbon\n  tokyo-night\n")

    def test_list_marks_current(self) -> None:
        self.box.run("set", "tokyo-night")
        self.assertEqual(self.box.run("list").stdout, "  oxocarbon\n* tokyo-night\n")

    def test_current(self) -> None:
        self.box.run("set", "oxocarbon")
        result = self.box.run("current")
        self.assertEqual((result.returncode, result.stdout), (0, "oxocarbon\n"))

    def test_current_before_any_set(self) -> None:
        result = self.box.run("current")
        self.assertEqual(result.returncode, 1)
        self.assertIn("no theme set yet", result.stderr)


class FontCommandTest(SandboxTestCase):
    """`theme font`, with fake fc-list and fc-match on PATH so the tests don't depend on installed fonts."""

    @override
    def setUp(self) -> None:
        super().setUp()
        bin_dir = self.box.state_home.parent / "bin"
        bin_dir.mkdir()
        self.write_tool(bin_dir / "fc-list", "printf 'Inter\\nJetBrains Mono,JetBrains Mono NL\\nGeist\\n'")
        self.write_tool(
            bin_dir / "fc-match", 'case "$*" in *monospace*) echo "JetBrains Mono";; *) echo Inter;; esac'
        )
        self.box.env["PATH"] = f"{bin_dir}:{self.box.env['PATH']}"

    @staticmethod
    def write_tool(path: Path, body: str) -> None:
        path.write_text(f"#!/bin/sh\n{body}\n")
        path.chmod(0o755)

    @property
    def fonts_conf(self) -> Path:
        return self.box.state / "fonts.conf"

    def test_show_prints_what_fontconfig_resolves(self) -> None:
        result = self.box.run("font")
        self.assertEqual((result.returncode, result.stdout), (0, "mono: JetBrains Mono\nsans: Inter\n"))

    def test_set_mono_writes_a_fontconfig_preference_with_the_icon_fallback(self) -> None:
        result = self.box.run("font", "mono", "JetBrains Mono")
        self.assertEqual(result.returncode, 0, result.stderr)
        conf = self.fonts_conf.read_text()
        mono = conf.index("<family>monospace</family>")
        self.assertLess(mono, conf.index("<family>JetBrains Mono</family>"))
        self.assertLess(conf.index("JetBrains Mono"), conf.index("<family>Symbols Nerd Font</family>"))
        self.assertNotIn("sans-serif", conf)

    def test_setting_sans_keeps_the_mono_choice(self) -> None:
        self.box.run("font", "mono", "JetBrains Mono")
        self.box.run("font", "sans", "Geist")
        conf = self.fonts_conf.read_text()
        self.assertIn("<family>JetBrains Mono</family>", conf)
        self.assertIn("<family>Geist</family>", conf)

    def test_family_match_ignores_case_and_writes_the_installed_name(self) -> None:
        self.box.run("font", "mono", "jetbrains mono nl")
        self.assertIn("<family>JetBrains Mono NL</family>", self.fonts_conf.read_text())

    def test_missing_family_exits_1_and_changes_nothing(self) -> None:
        self.box.run("font", "mono", "JetBrains Mono")
        before = self.fonts_conf.read_text()
        result = self.box.run("font", "mono", "Comic Mono")
        self.assertEqual(result.returncode, 1)
        self.assertIn("no installed font family 'Comic Mono'", result.stderr)
        self.assertEqual(self.fonts_conf.read_text(), before)

    def test_names_are_xml_escaped(self) -> None:
        self.write_tool(self.box.state_home.parent / "bin" / "fc-list", "echo 'A&B <Mono>'")
        self.box.run("font", "mono", "A&B <Mono>")
        self.assertIn("<family>A&amp;B &lt;Mono&gt;</family>", self.fonts_conf.read_text())

    def test_hooks_run_with_the_current_theme(self) -> None:
        self.box.add_theme("tokyo-night")
        self.box.run("set", "tokyo-night")
        log = self.box.state_home / "hooks.log"
        self.box.add_hook("10-log", f'echo "[$1]" >> "{log}"\n')
        result = self.box.run("font", "mono", "Geist")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(log.read_text(), "[tokyo-night]\n")

    def test_hooks_get_an_empty_name_before_any_theme_is_set(self) -> None:
        log = self.box.state_home / "hooks.log"
        self.box.add_hook("10-log", f'echo "[$1]" >> "{log}"\n')
        self.box.run("font", "mono", "Geist")
        self.assertEqual(log.read_text(), "[]\n")


def run_shipped_hook(name: str, env: dict[str, str]) -> subprocess.CompletedProcess[str]:
    hook = SHIPPED_CONFIG / "hooks" / name
    return subprocess.run([hook, "tokyo-night"], env=env, capture_output=True, text=True, check=False)


class ShippedTargetsTest(unittest.TestCase):
    """The templates and hooks that ship with the package, rendered with a shipped theme."""

    out: Path

    @override
    def setUp(self) -> None:
        scratch = tempfile.TemporaryDirectory()
        self.addCleanup(scratch.cleanup)
        self.out = Path(scratch.name) / "current"
        self.out.mkdir()
        palette = theme.load_palette(SHIPPED_CONFIG / "themes" / "tokyo-night")
        theme.render_theme(palette, SHIPPED_CONFIG / "templates", self.out)

    def test_hyprland_lua_is_valid_lua_with_the_accent_border(self) -> None:
        lua = self.out / "hyprland.lua"
        subprocess.run(["luac", "-p", lua], check=True)
        self.assertRegex(lua.read_text(), r'\bactive_border\s*=\s*"rgba\(7aa2f7ee\)"')

    def test_hyprlock_conf_defines_the_variables_hyprlock_conf_uses(self) -> None:
        def variables(text: str) -> tuple[set[str], set[str]]:
            """(defined, used) hyprlang variables, ignoring comment lines."""
            lines = [line for line in text.splitlines() if not line.lstrip().startswith("#")]
            defined = {m.group(1) for line in lines if (m := re.match(r"\s*\$(\w+)\s*=", line))}
            used = {m for line in lines for m in re.findall(r"\$(\w+)", line.split("=", 1)[-1])}
            return defined, used

        generated = (self.out / "hyprlock.conf").read_text()
        hyprlock = (PACKAGE.parent / "hyprland" / ".config" / "hypr" / "hyprlock.conf").read_text()
        from_theme, _ = variables(generated)
        local, used = variables(hyprlock)
        self.assertEqual(used - local - {"HOME"}, from_theme)
        self.assertIn("$accent = rgba(7aa2f7ff)", generated)

    def test_hyprland_hook_skips_outside_hyprland(self) -> None:
        env = {k: v for k, v in os.environ.items() if k != "HYPRLAND_INSTANCE_SIGNATURE"}
        result = run_shipped_hook("10-hyprland", env)
        self.assertEqual((result.returncode, result.stderr), (0, ""))

    def test_greeter_hook_copies_the_palette(self) -> None:
        greeter = self.out.parent / "greeter"
        greeter.mkdir()
        env = {**os.environ, "THEME_CURRENT": str(self.out), "THEME_GREETER_DIR": str(greeter)}
        result = run_shipped_hook("90-greeter", env)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(sorted(p.name for p in greeter.iterdir()), ["name", "palette.json"])
        self.assertEqual((greeter / "name").read_text(), "tokyo-night\n")

    def test_greeter_hook_without_its_directory_is_a_notice_not_a_failure(self) -> None:
        env = {**os.environ, "THEME_CURRENT": str(self.out), "THEME_GREETER_DIR": str(self.out / "absent")}
        result = run_shipped_hook("90-greeter", env)
        self.assertEqual(result.returncode, 0)
        self.assertIn("does not exist", result.stderr)


class ShippedThemesTest(unittest.TestCase):
    def test_every_shipped_theme_passes_check(self) -> None:
        with tempfile.TemporaryDirectory() as state:
            env = {**os.environ, "THEME_CONFIG_DIR": str(SHIPPED_CONFIG), "XDG_STATE_HOME": state}
            result = subprocess.run(
                [sys.executable, str(SCRIPT), "check"], env=env, capture_output=True, text=True, check=False
            )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            result.stdout.split(),
            ["ok", "gruvbox-material", "ok", "kanagawa", "ok", "oxocarbon", "ok", "tokyo-night"],
        )


if __name__ == "__main__":
    unittest.main()
