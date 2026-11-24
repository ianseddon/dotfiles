# Desktop shell: capability map

Status: approved 2026-11-24.

This replaces Waybar, Rofi, swaync and tuigreet with one Quickshell desktop shell, and it gives the whole desktop one colour scheme that a single command can switch. The goal is a shell that is minimal, looks good, and stays out of the way until it is needed. It is also a way to try new themes: Gruvbox Material, Tokyo Night and Oxocarbon to start.

Each module gets its own spec in this directory (`SPEC-<module id>.md`), written and approved in build order. This map is the index of what exists.

| Module id | Responsibility | Depends on |
|---|---|---|
| `theme` | Palette format, the `theme` command, templates, and the Hyprland, hyprlock, Quickshell and greeter targets. Ships the first palettes. | — |
| `app-themes` | Templates or native ports for herdr-app, Ghostty, nvim, fish, herdr, gh-dash, tuicr and bat. The terminal palette (herdr-app, Ghostty) shipped first, with fonts: [SPEC-fonts-and-terminals.md](SPEC-fonts-and-terminals.md). | `theme` |
| `shell-core` | The `quickshell` Stow package, `shell.qml`, one window per monitor, IPC, the systemd user service that replaces `launch-waybar.sh`, and shell style settings (radius, spacing, bar shape). Fonts come from fontconfig's `monospace` and `sans-serif` aliases, which `theme font` sets. | `theme` |
| `bar` | Pill bar: workspaces, window title, media, CPU, memory and temperature, volume, clock, tray, power button. DP-3 (vertical) keeps a minimal variant. | `theme`, `shell-core` |
| `launcher` | App search on `SUPER+SPACE`, replacing Rofi. | `theme`, `shell-core` |
| `notifications` | Notification server replacing swaync: popups, history, do not disturb. | `theme`, `shell-core` |
| `osd` | Volume popup on change. | `theme`, `shell-core` |
| `power-menu` | Lock, log out, suspend, reboot, shut down. Replaces `hyprshutdown`. | `theme`, `shell-core` |
| `greeter` | Quickshell login screen on greetd, replacing tuigreet. | `theme`; reuses components from `bar` and `power-menu` |

Build order: `theme` → `app-themes` → `shell-core` → `bar` → `launcher` → `notifications`, `osd`, `power-menu` (any order) → `greeter`.

## Decisions

- **Own shell, not a prebuilt one.** Noctalia, DankMaterialShell and Caelestia were rejected because they are too large, and each comes with a look of its own.
- **Theme design follows Omarchy, not its code.** Omarchy has theme folders with a `colors.toml` palette, one template per app, and generated files in `~/.local/state`. Its implementation is about 1,100 lines of Bash plus around 30 helpers, and it depends on the rest of Omarchy. See [SPEC-theme.md](SPEC-theme.md).
- **Desktop only.** The M75q runs no graphical session.
- **Old tools stay until replaced.** Waybar, Rofi, swaync and tuigreet are removed only after their replacements are verified.
- **Network and Bluetooth stay in the tray.** nm-applet and blueman-applet remain; there are no custom panels in V1.
- **No brightness popup.** Both monitors are external.

## Deferred

- **Lock screen in Quickshell.** Hyprlock gets the theme's colours, but not the greeter's layout.
- **Per-theme wallpapers.**
- **Light-mode variants.**
- **Brightness over DDC/CI.**
