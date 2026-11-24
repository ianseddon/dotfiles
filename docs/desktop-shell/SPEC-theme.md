# Spec: theme — V1

Status: implemented 2026-11-24. Module `theme` in the [capability map](README.md). Changed since by [SPEC-fonts-and-terminals.md](SPEC-fonts-and-terminals.md): `theme font`, and hooks that sync the palette and fonts to each app.

## Objective

One command changes the colour scheme of the whole desktop: `theme set tokyo-night`. A theme is a small palette file. Switching themes never edits a tracked file, so you can try themes freely and `git status` stays clean.

This module provides:

- the palette format;
- the `theme` command;
- the template mechanism;
- the first targets: Hyprland, hyprlock, Quickshell and the greeter.

Later modules add their own targets (`app-themes` for the terminal and TUI apps, `shell-core` for the shell) by adding a template and, where needed, a reload hook. They do not change the command.

V1 ships four themes:

| Theme | Upstream source of the palette |
|---|---|
| `kanagawa` | `rebelot/kanagawa.nvim`, Wave. This is the current look, kept as the starting point and as the way back. |
| `gruvbox-material` | `sainnhe/gruvbox-material`, dark, medium background, `material` foreground. |
| `tokyo-night` | `folke/tokyonight.nvim`, `night` style. |
| `oxocarbon` | `nyoom-engineering/oxocarbon.nvim`, dark. |

## Tech stack

- **Python 3.14**, standard library only. `tomllib` reads the palettes. Arch provides `/usr/bin/python3`.
- **Linters:** `ruff` and `basedpyright` from the Nix profile. `shellcheck` checks the hook scripts.
- **Hyprland 0.57 Lua config:** `dofile` loads the generated file. Omarchy uses the same call.
- **hyprlock:** `source =` includes the generated variables.

## Commands

```sh
theme list              # theme names; the current one is marked
theme current           # print the current theme's name
theme set <name>        # validate, render, switch, run reload hooks
theme check [<name>]    # validate and render to a temp dir without switching; all themes if no name

python3 -m unittest discover -s theme/tests              # unit tests (from the repo root)
ruff check theme && ruff format --check theme
basedpyright theme/.local/bin/theme theme/tests
shellcheck theme/.config/theme/hooks/*
```

**Exit codes:**

- **0:** success.
- **1:** validation or render failure. Nothing changed.
- **2:** the theme was switched, but at least one reload hook failed. Each failed hook is named on stderr.

## Palette format

The palette format is Omarchy's `colors.toml` schema, unchanged. Being compatible means Omarchy's own themes and its community themes can be copied in and tried with no conversion.

```toml
# Tokyo Night (night). Source: folke/tokyonight.nvim <commit>, lua/tokyonight/colors/.
# Role mapping: accent = blue, selection = bg_visual, muted = terminal_black, ...
mode = "dark"

accent = "#7aa2f7"
selection = "#283457"
muted = "#414868"

background = "#1a1b26"
dark_background = "#16161e"
darker_background = "#0c0e14"
lighter_background = "#292e42"

foreground = "#c0caf5"
dark_foreground = "#565f89"
light_foreground = "#a9b1d6"
bright_foreground = "#c8d3f5"

red = "#f7768e"
# ... yellow, orange, green, cyan, blue, magenta, brown
# ... bright_red, bright_yellow, bright_green, bright_cyan, bright_blue, bright_magenta
```

**Rules:**

- **Required keys:** `mode` (`"dark"` or `"light"`) and the 25 colour keys shown above.
- **Omarchy's fallbacks:** if `orange` is missing it uses `yellow`; if `brown` is missing it is `orange` mixed 50% with black. Three of Omarchy's own themes rely on these.
- **Colour values:** `#rrggbb`.
- **Extra keys:** allowed, and usable in templates.
- **Theme names:** lowercase kebab-case, the same as the folder name.
- **Source note:** the header comment records the upstream source and commit, and how the upstream colours map to Omarchy's roles. The example values above are placeholders. The real values are taken from upstream during implementation.

## Templates

A template is the output file with `.tpl` appended, for example `hyprland.lua.tpl` renders to `hyprland.lua`.

**Placeholders**, for `accent = "#7aa2f7"`:

| Placeholder | Output |
|---|---|
| `{{ accent }}` | `#7aa2f7` |
| `{{ accent_strip }}` | `7aa2f7` |
| `{{ accent_rgb }}` | `122,162,247` |

**Rendering rules:**

- Spaces inside the braces are optional.
- An unknown key fails the render. The error names the template, the line and the key.
- `{{ mode }}` and any string-valued extra key render as is.

**Theme files:** every other file at the top level of a theme folder is copied into the render as is. A template renders only the outputs the folder does not already provide. For example, `themes/tokyo-night/nvim.lua` replaces the output of `nvim.lua.tpl`. This is how a theme picks a native port, or ships a file that has no template. `name` and `palette.json` are generated, so a theme folder may not contain them. Subfolders are ignored.

**`palette.json`:** this file is always written, with every key in the palette, whether or not a template exists. Quickshell and the greeter read it.

**V1 templates:**

| Template | Consumed by | Contents |
|---|---|---|
| `hyprland.lua.tpl` | `hyprland.lua` loads it with `pcall(dofile, ...)`. If it is missing, Hyprland uses its defaults and logs nothing. | `general.col.active_border` = accent. `inactive_border` stays transparent, as today. Group borders match. |
| `hyprlock.conf.tpl` | `hyprlock.conf` uses `source =` | `$accent`, `$background`, `$foreground` and related variables, used by the input field and the date label. The layout is unchanged. |

## State and switching

```
~/.local/state/theme/
  current -> renders/tokyo-night.k3x9  # relative symlink; replaced atomically
  renders/tokyo-night.k3x9/
    name                               # "tokyo-night"
    palette.json
    hyprland.lua
    hyprlock.conf
```

`theme set <name>` does the following:

1. Validate the palette and render every template into a new folder under `renders/`. On any error, delete that folder, exit 1, and leave `current` as it was.
2. Point a temporary symlink at the new folder, then `os.replace` it onto `current`. Readers therefore see either the old theme or the new one, never a mix.
3. Delete the older folders under `renders/`.
4. Run each executable in `~/.config/theme/hooks/` in name order, passing the theme name as the argument. Collect failures, report them, and exit 2 if any hook failed.

**V1 hooks:**

| Hook | Does | When it is skipped |
|---|---|---|
| `10-hyprland` | `hyprctl reload` | Hyprland is not running (`HYPRLAND_INSTANCE_SIGNATURE` is unset). Skipping is not a failure. |
| `90-greeter` | Copies `palette.json` and `name` into `/var/lib/greeter-theme/` | The directory does not exist. It prints a one-line notice; this is not a failure. |

hyprlock needs no hook, because it reads its config each time it starts.

**One-time greeter setup.** Ian runs this by hand, and it is documented in the README. `theme` never runs `sudo`.

```sh
sudo install -d -o ian -g greeter -m 0750 /var/lib/greeter-theme
```

## Project structure

```
theme/                                   # Stow package (desktop only)
  .stow-local-ignore                     # keeps tests/ out of $HOME
  .local/bin/theme                       # the command; one Python file
  .config/theme/
    themes/<name>/colors.toml            # palettes, plus optional override files
    templates/<output>.tpl
    hooks/NN-<target>                    # small POSIX sh scripts
  tests/
    test_theme.py
hyprland/.config/hypr/hyprland.lua       # adds the dofile line; the border colours leave looknfeel.lua
hyprland/.config/hypr/hyprlock.conf      # sources the generated variables
README.md                                # theme section: usage, adding a theme, greeter setup
```

Stow: `stow --no-folding --target="$HOME" theme`. `--no-folding` keeps `~/.config/theme` a real directory, so local experimental themes can sit next to the stowed ones without being written into the repo.

## Code style

```python
def render(template: str, palette: Palette, *, source: Path) -> str:
    """Replace every {{ key }} placeholder, or fail naming the first unknown key."""

    def substitute(match: re.Match[str]) -> str:
        token = match.group(1)
        value = palette.resolve(token)
        if value is None:
            line = template.count("\n", 0, match.start()) + 1
            raise RenderError(f"{source}:{line}: unknown palette key '{token}'")
        return value

    return PLACEHOLDER.sub(substitute, template)
```

**Conventions:**

- Type hints everywhere, and `basedpyright` must report no errors.
- Small, pure functions for parsing and rendering. File system and process side effects are kept in `main` and the switch step.
- Error messages name the file and the cause.
- `THEME_CONFIG_DIR` and `XDG_STATE_HOME` override the paths, so tests never touch real state.

## Testing strategy

**Unit tests** (`unittest`, temporary directories) cover:

- **Palette validation:** a missing key, a bad hex value, a bad mode, extra keys, a bad name.
- **Rendering:** each placeholder form, optional spaces, the unknown-key error naming file and line, a file with no placeholders.
- **Overrides:** an override file wins over the template output.
- **Switching:** a render failure leaves `current` and its target unchanged; a successful switch leaves exactly one folder under `renders/`.
- **Hooks:** hooks run in name order with the theme name; a failing hook gives exit 2 and is named; the other hooks still run.
- **`list`, `current` and `check`** output.
- **The shipped themes:** every palette in `theme/.config/theme/themes/` passes `theme check`.

**End-to-end checks** on the desktop, in the real session, for each of the four themes:

- `theme set <name>` exits 0.
- `hyprctl getoption general:col.active_border` reports the theme's accent.
- A screenshot (`grim`) shows the new border on both monitors.
- hyprlock started by hand shows the theme's colours. Ian checks this visually; the agent cannot unlock the session.
- `git -C ~/dotfiles status --porcelain` is empty afterwards.

## Boundaries

- **Always:** use the standard library only; validate before switching; switch atomically; keep generated files outside the repo; run the linters and tests before each commit.
- **Ask first:** adding a dependency; changing the palette schema in a way that breaks Omarchy compatibility; adding a system-level step besides the one-time greeter directory.
- **Never:** run `sudo` from `theme`; write outside `~/.local/state/theme` and `/var/lib/greeter-theme`; edit a tracked file during `theme set`.

## Success criteria

1. `theme set` works for each of the four themes, and the E2E checks above pass for all of them.
2. `theme set` on the desktop completes in under 1 second, including the hooks.
3. An invalid palette or template leaves the desktop exactly as it was, and the error names the file and the problem.
4. After stowing the package and running `theme set kanagawa`, the desktop looks as it does today. The one deliberate change: the Hyprland border and hyprlock move from Everforest green to the Kanagawa accent.
5. An Omarchy palette (for example `themes/nord/colors.toml` from the Omarchy repo) copied into `~/.config/theme/themes/nord/` works with `theme set nord` unchanged.
6. The unit tests, `ruff` and `basedpyright` all pass with no suppressions.

## Out of scope (deferred)

- **Ghostty, nvim, fish, herdr, gh-dash, tuicr and bat:** these are the `app-themes` module.
- **Theming Waybar and Rofi:** both are being replaced. They keep their current colours until the `bar` and `launcher` modules land.
- **A theme picker UI:** a later launcher mode can call `theme list` and `theme set`.
- **`theme install <git url>` for community themes:** copying a folder by hand works in V1.
- **Older Omarchy themes that define only `color0` to `color15`:** all 23 current first-party themes use the named keys and work.
- **Placeholders that mix colours** (Omarchy's `mix`): add them when a template needs them.
- **Contrast checks on palettes.**
- **Per-theme wallpapers and light mode.**

## Resolved questions

1. **Gruvbox Material:** the medium background with the `material` foreground, the upstream defaults.
2. **Tokyo Night:** `night`.
3. **Command name:** `theme`.
