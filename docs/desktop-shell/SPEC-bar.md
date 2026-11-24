# Spec: bar — V1

Status: proposed. Module `bar` in the [capability map](README.md). Builds on [SPEC-shell-core.md](SPEC-shell-core.md).

## Objective

A pill bar in Quickshell replaces Waybar. It should be minimal and quiet, show what matters at a glance, and use the theme and fonts like everything else.

**Decisions (2026-11-24):**
- **Modules:** workspaces, the clock, media, system stats, volume, the tray and a power button. No window title.
- **Layout:** the clock alone in the centre.
- **Workspaces:** dots.
- **Clock:** time only.

## Layout

```
 ╭──────────╮               ╭───────╮               ╭──────────────╮ ╭─────────────────────────╮ ╭─────╮ ╭───╮
 │ ● ━━━ ●  │               │ 14:05 │               │ ▶ Artist – … │ │ 12%  41%  52°   ◁ 42%  │ │ ⌁ ᛒ │ │ ⏻ │
 ╰──────────╯               ╰───────╯               ╰──────────────╯ ╰─────────────────────────╯ ╰─────╯ ╰───╯
 workspaces                   clock                     media          stats · volume             tray   power
```

- **One bar per monitor.** It is a transparent window along the top edge, holding separate pills.
- **On a portrait monitor** (DP-3 today, detected by height greater than width, not by name): only workspaces and the clock.
- **The media and tray pills hide** when they have nothing to show.

## Visual design

| Element | Value | Source |
|---|---|---|
| Pill height | 32 px | `Style.barHeight` |
| Gap from the screen edge to the pills | 7 px, equal to Hyprland's `gaps_out`, so pills line up with window edges | `Style.barGap`, with a comment linking it to `looknfeel.lua` |
| Gap between pills | 8 px | `Style.spaceSm` |
| Pill shape | fully rounded (radius = height / 2) | |
| Padding inside a pill | 12 px horizontal; 12 px between items | `Style.spaceMd` |
| Pill fill | `Theme.background` at 85% opacity, blurred by a Hyprland layer rule | |
| Pill border | 1 px, `Theme.lighterBackground` | |
| Text | `Theme.foreground`, `Theme.fontSans`, 13 px, tabular figures, so numbers don't jitter | |
| Icons | `Theme.darkForeground`, `Symbols Nerd Font` (fixed, so icons work with any mono font) | `Style.fontIcons` |
| Popups (tooltips, calendar, tray menus) | same fill, border and blur; radius `Style.radius` | |
| Motion | `Style.durationNormal` with `Style.easing` | |

**Window gaps.** Windows start `gaps_out` below the pills, so there are 7 px both above and below the pills. The bar's reserved height is 7 + 32 = 39 px.

## Modules

**Workspaces** (left):
- **Dots:** one per workspace on this monitor (normal workspaces only, in id order):
  - the active workspace: a 24 × 8 px bar in `Theme.accent`;
  - the others: 8 px dots in `Theme.darkForeground`;
  - an urgent workspace: a `Theme.red` dot.
  
  Width and colour animate.
- **Input:** clicking a dot focuses its workspace; scrolling the pill moves to the next or previous workspace (`e+1` / `e-1`, like the keybindings).
- **Dispatch:** Hyprland's Lua syntax, `hl.dsp.focus({ workspace = n })`.

**Clock** (centre):
- **Display:** `HH:mm`, 24-hour, updated each minute.
- **Tooltip:** the full date, for example "Tuesday, 24 November 2026".
- **Click:** a month calendar below the clock. Weeks start on Monday, today is marked in `Theme.accent`, and scrolling or the arrow keys change the month. Esc or clicking outside closes it.

**Media** (right):
- **Display:** a play or pause icon, then "Artist – Title", elided after 32 characters.
- **Player:** the MPRIS player that is playing, otherwise the first one.
- **Input:** click to play or pause; scroll for next or previous.
- **Hidden** when no player exists.

**System stats** (right, in one pill with volume):
- **Readings:** CPU %, memory % and CPU temperature (°C), polled every 2 s.
  - **Sources:** `/proc/stat`, the difference between two samples; `/proc/meminfo`; and the `coretemp` sensor's "Package id 0", found by name under `/sys/class/hwmon`.
- **Colour only when high:**

  | Reading | Yellow from | Red from |
  |---|---|---|
  | CPU | 80% | 95% |
  | Memory | 80% | 90% |
  | Temperature | 80 °C | 90 °C |

- **Tooltip:** the details: load average, used and total GiB, and the sensor name.

**Volume** (right):
- **Source:** the default PipeWire sink (`Quickshell.Services.Pipewire`).
- **Display:** an icon by level or mute, then the percentage.
- **Input:**
  - scroll: ±5%, capped at 100%;
  - click: `pavucontrol`;
  - right-click: toggle mute.

**Tray** (right):
- **Display:** the `StatusNotifierItem` icons at 16 px, through Quickshell's system tray, which also acts as the tray host. Today that means nm-applet and blueman.
- **Input:**
  - click: activate;
  - right-click: the item's menu, styled as a popup;
  - middle-click: secondary activate.
- **Tooltip:** the item's title.

**Power** (right):
- **Display:** a round button; its icon turns `Theme.red` on hover.
- **Click:** `hyprshutdown`, as today. The `power-menu` module replaces this later.

## Structure

```
quickshell/.config/quickshell/
  shell.qml                     # adds: Variants over Quickshell.screens -> Bar
  theme/Style.qml               # adds: barGap, fontIcons
  bar/
    Bar.qml                     # PanelWindow per screen; picks full or portrait layout
    Pill.qml                    # the shared pill surface
    Popup.qml                   # the shared popup surface (tooltip, calendar, menus)
    Workspaces.qml  Clock.qml  Calendar.qml  Media.qml  Stats.qml  Volume.qml  Tray.qml  Power.qml
    logic.js                    # pure functions: stats parsing, levels, icons, labels, calendar grid
    qmldir
quickshell/tests/tst_bar.qml    # tests for logic.js
hyprland/.config/hypr/looknfeel.lua   # layer rule: blur quickshell:bar and quickshell:popup
hyprland/.config/hypr/autostart.lua   # stops launching Waybar
```

**Removed at cutover:**
- the `waybar` package directory and `hypr/scripts/launch-waybar.sh`, which remain in git history;
- Waybar's stow links.

The `waybar` pacman package stays installed until you remove it.

## Testing strategy

**Unit tests (`qmltestrunner`, `logic.js`):**
- CPU % from two `/proc/stat` samples;
- memory % from `/proc/meminfo`;
- finding the temperature sensor;
- levels at and just below each threshold;
- volume icons, including mute;
- the media label: eliding, and a missing artist;
- calendar grids for months starting on each weekday, with Monday first;
- the dot list: filtering and sorting workspaces, without special workspaces.

**Lint:** `qmllint` and `qmlformat`, as in shell-core.

**End-to-end, in the session:**
- **Screenshots** of both monitors under two themes. Measure the pill geometry: a 7 px top gap, and the outer pills aligned with window edges.
- **Workspaces:** clicking a dot switches workspace; scrolling moves.
- **Volume:** scrolling changes `wpctl get-volume` by 5%, then I restore it. Right-click mutes and unmutes.
- **Tray:** nm-applet and blueman icons appear after the cutover, and their menus open.
- **Clock:** its tooltip and calendar render, and the calendar closes on Esc.
- **Stats:** a short CPU load (`yes > /dev/null` on every core, for 5 seconds) turns the CPU reading yellow or red. It returns to normal afterwards.
- **Media:** with a player running (`mpv` on a test tone, if available), the pill shows and play/pause works.
- **Live updates:** `theme set` and `theme font` restyle the bar live.
- **Log:** no new warnings, apart from the known Qt text-input one.

## Boundaries

- **Always:**
  - Waybar keeps running until the new bar passes its end-to-end checks; then cut over in one commit.
  - Every colour comes from `Theme`, and every size from `Style`.
- **Ask first:** uninstalling the `waybar` pacman package; changing Hyprland `gaps_out`.
- **Never:** poll faster than every 2 s; spawn a process per poll when a file read works.

## Success criteria

1. Waybar no longer starts. The Quickshell bar shows on both monitors with the layouts above.
2. Every module behaves as specified, verified by the end-to-end checks.
3. Pills line up with the window edges (7 px gaps), measured from screenshots on DP-4.
4. `theme set` and `theme font` restyle the bar within half a second.
5. Idle CPU use of the shell stays under 1% (`ps` over 30 s).
6. Tests, `qmllint` and `qmlformat` are clean, except the known findings documented in the README.

## Out of scope (deferred)

- **Window title.** It was left out on purpose.
- **Network and Bluetooth panels.** The tray covers them.
- **Notification indicator.** It belongs to `notifications`.
- **Battery and brightness.** This is a desktop with external monitors.
- **Voxtype dictation indicator.** `docs/speech-to-text.md` describes a Waybar module for it.
- **The `flush` and `island` bar shapes.** The `Style.barShape` value exists, but V1 implements pills only.
- **Opening a system monitor from the stats pill.**
