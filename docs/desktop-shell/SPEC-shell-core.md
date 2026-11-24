# Spec: shell-core — V1

Status: implemented 2026-11-24. Module `shell-core` in the [capability map](README.md).

## Objective

The foundation that the bar, launcher, notifications, OSD and power menu are built on:

- the Quickshell package;
- shared theme and style values;
- IPC (commands other programs can send to the running shell);
- a service that starts the shell with the session;
- the development and test loop.

The module has no bar yet. To be verifiable on its own, and useful while you compare themes, it ships one small feature: a **theme preview**. This floating panel shows the current palette and fonts and updates live when the theme or font changes.

Waybar keeps running until the `bar` module replaces it, so the desktop looks the same after this module.

## Tech stack

- **Quickshell 0.3.2**, from Arch `extra` (`pkexec pacman -S quickshell`, which you approve). Its Qt 6 dependencies are already installed.
- **QML and JavaScript** only. Shell commands run through Quickshell's `Process` type, never through a separate helper script.
- **Qt tools** from `qt6-declarative`, already installed: `qmllint`, `qmlformat`, `qmltestrunner`.

## Commands

```sh
qs -p ~/dotfiles/quickshell/.config/quickshell     # development: a second instance that reloads on save
systemctl --user restart quickshell                # the session's instance
journalctl --user -u quickshell -f                 # its log
qs ipc show                                        # the IPC commands the running shell offers
qs ipc call theme preview                          # toggle the theme preview
qs ipc call theme reload                           # re-read the palette and fonts (the theme hook does this)

# Checks, from the repo root
/usr/lib/qt6/bin/qmllint -I /usr/lib/qt6/qml quickshell/.config/quickshell/**/*.qml
/usr/lib/qt6/bin/qmlformat --dry-run ...           # or -i to format in place
/usr/lib/qt6/bin/qmltestrunner -input quickshell/tests
```

## Project structure

```
quickshell/                                    # Stow package, desktop only (--no-folding)
  .stow-local-ignore                           # keeps tests/ out of $HOME
  .config/quickshell/
    shell.qml                                  # entry point: ShellRoot with each module
    theme/
      Theme.qml                                # singleton: palette + resolved fonts
      Style.qml                                # singleton: spacing, radius, sizes, motion, bar shape
      ThemePreview.qml                         # the preview panel
      qmldir
  .config/systemd/user/quickshell.service
  tests/
    tst_*.qml                                  # qmltestrunner tests for pure logic
theme/.config/theme/hooks/60-quickshell        # tells the running shell to reload
hyprland/...                                   # unchanged in this module
```

Later modules add sibling folders, such as `bar/` and `launcher/`. Each imports `theme`, and `shell.qml` instantiates it.

## Design

### Theme (singleton)

- **Palette.** `FileView` reads `~/.local/state/theme/current/palette.json` and exposes every key as a `color` property (`Theme.background`, `Theme.accent`, ...), plus `name` and `mode`.
  - The path is a property, so the greeter can point the same component at `/var/lib/greeter-theme/palette.json`.
  - A missing or invalid palette logs one warning and falls back to neutral greys, rather than failing to start. There is no second copy of any palette.
- **Fonts.** `fc-match -f '%{family[0]}' monospace` and `sans-serif` resolve the families, through `Process`, at start and on every reload. `Theme.fontMono` and `Theme.fontSans` hold those exact family names.
  - Qt reads fontconfig's configuration only once, at startup, so an alias like `monospace` in QML would not follow `theme font` until a restart.
  - Exact names switch live, and fontconfig stays the single source.
- **Reload.** `IpcHandler { target: "theme" }` provides:
  - `reload()`, which re-reads the palette and fonts;
  - `preview()`, which toggles the preview.
  
  The palette is not watched for file changes: `theme set` replaces `current` by swapping a symlink, which file watchers can miss. The hook calls `reload()` explicitly instead.
- **Derived colours** come from pure JavaScript helpers, tested with `qmltestrunner`. One example is a colour at an alpha level, for translucent surfaces.

### Style (singleton)

- **What it holds.** Fixed design values, written in QML:
  - a spacing scale: 4, 8, 12, 16 and 24 px;
  - corner radius;
  - bar height;
  - font sizes;
  - animation durations and easing;
  - `barShape: "pills"` (alternatives: `"flush"` and `"island"`).
- **How they change.** These change by editing the file. Live reload shows the result immediately. They are not part of the theme.
- **Sizes** are in logical pixels. Qt scales them for DP-4's 1.25× factor.

### Theme preview

- **Layout.** A floating, centred panel containing:
  - the palette as labelled swatches in four rows: backgrounds, foregrounds, accents, and ANSI colours;
  - a sample line in the mono and sans fonts, with the family names;
  - the theme's name.
- **Behaviour.** Esc or the toggle command closes it. It takes keyboard focus only while open.
- **Purpose.** It is the visible check that `Theme` and `Style` work, and a tool for judging palettes, such as Oxocarbon's dim secondary text.

### Service

`quickshell.service` follows the `hyprpaper.service` pattern:

```ini
[Unit]
Description=Quickshell desktop shell
PartOf=graphical-session.target
Requires=graphical-session.target
After=graphical-session.target
ConditionEnvironment=WAYLAND_DISPLAY

[Service]
ExecStart=/usr/bin/qs
Slice=session.slice
Restart=on-failure

[Install]
WantedBy=graphical-session.target
```

The service is enabled in this module: `systemctl --user enable --now quickshell`. Until the bar exists, it shows nothing unless the preview is open.

### Theme hook

`60-quickshell` runs `qs ipc call theme reload` when an instance is running. No instance is not a failure. The call has a timeout of 2 seconds.

## Code style

```qml
pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // The current theme's palette (`theme set`); the greeter points this at its own copy.
    property string palettePath: Quickshell.env("XDG_STATE_HOME") + "/theme/current/palette.json"

    readonly property color background: palette.colour("background")
    // ...

    function reload(): void {
        paletteFile.reload();
        fonts.running = true;
    }
}
```

**Conventions:**
- Four-space indentation, as `qmlformat` produces.
- `id: root` at the top of each file.
- Typed functions, which `IpcHandler` requires anyway.
- Properties are `readonly` unless something sets them.
- No `import "root:/..."`, which the Quickshell docs say breaks the language server and singletons.
- Comments say why, not what.

## Testing strategy

- **Unit tests (`qmltestrunner`):** the colour helpers, and palette parsing, including the fallback for a missing or invalid file.
- **Lint:** `qmllint` against the installed Quickshell type information. Findings that come from Quickshell's own types are listed in the README with the reason. There are no inline suppressions.
- **The theme hook:** tested like the other hooks, in `theme/tests`, with a fake `qs`.
- **End-to-end, in the session:**
  - **Service:** it starts with the session, restarts cleanly, and logs no warnings, except Qt's text-input warning (see Findings).
  - **Preview:** for each of the four themes, the preview's swatches match `palette.json` exactly (checked by pixel), and `theme set` updates it live.
  - **Fonts:** `theme font mono "FiraCode Nerd Font"` changes the preview's mono sample live, with no restart.
  - **Scaling:** the preview renders crisply on DP-4 (1.25×) and DP-3 (rotated).
  - **IPC:** `qs ipc show` lists the `theme` target.

## Boundaries

- **Always:**
  - QML-only components;
  - fonts and colours come from `Theme` only;
  - sizes come from `Style`, never a raw number in a component;
  - run lint and the tests before each commit.
- **Ask first:**
  - installing anything beyond `quickshell`;
  - turning off Waybar, which belongs to the `bar` module;
  - Hyprland layer rules that change other windows.
- **Never:**
  - start a second always-on instance;
  - hard-code a palette;
  - write to the theme state from the shell.

## Findings during implementation

- **Qt's text-input warning:** closing a surface that had keyboard focus logs `qt.qpa.wayland.textinput: … Trying to disable … but 0x0 is focused`. Hiding the window instead of destroying it logs it too, so the cause is focus leaving the surface. It is a known Qt Wayland bug that other Qt apps and Quickshell shells also log, and it is documented in the README rather than filtered out.
- **`qs list --all --json` with no instances** prints "No running instances." as plain text, so the theme hook checks for a JSON array before parsing.
- **`qmllint` needs absolute paths:** with relative ones it misreads `theme/qmldir`. Its only remaining finding is Quickshell's `PanelWindow` "is not creatable", which comes from Quickshell's type information.
- **Plain stow, not `--no-folding`:** Quickshell writes nothing next to its config, so `~/.config/quickshell` links to the package as a whole.
- **Hyprland's Lua mode:** `hyprctl dispatch focusmonitor DP-3` fails there, because dispatchers are Lua expressions. Note this for scripts in later modules.

## Success criteria

1. **Installed and running:** `quickshell` is installed and listed in the README's packages. The service is enabled and survives `systemctl --user restart`.
2. **Theme preview:** `qs ipc call theme preview` opens the preview. It shows the current theme exactly, and updates within half a second of `theme set` and `theme font`.
3. **Safe with no palette:** removing `~/.local/state/theme/current` and restarting gives neutral colours and one warning, not a crash.
4. **Desktop unchanged:** apart from the shell process, the desktop looks the same. Waybar is untouched.
5. **Checks pass:** `qmllint`, the `qmltestrunner` tests, the `theme` tests and `shellcheck` are clean.

## Out of scope (deferred)

- **The bar, launcher, notifications, OSD and power menu:** their own modules.
- **Blur and other layer rules for shell surfaces:** they come with the first surface that needs them (`bar`).
- **A theme picker:** the preview only shows the current theme. Choosing one belongs to a later launcher mode.
