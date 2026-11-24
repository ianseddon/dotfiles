# Spec: bar — V1

Status: approved 2026-11-24. Module `bar` in the [capability map](README.md). Builds on [SPEC-shell-core.md](SPEC-shell-core.md).

## Objective

A pill bar in Quickshell replaces Waybar. It should be **elegant and minimal at rest, and informative when needed**. The bar shows icons. Detail appears on hover or in a popup on click. Values and indicators appear by themselves only when something needs attention.

**Decisions (2026-11-24), after surveying Omarchy, Caelestia, Noctalia and DankMaterialShell:**

- **Layout:** workspaces on the left (as dots), the clock alone in the centre (time only), and status on the right.
- **Status area:** icons only. A value slides out on hover. A click opens a popup. A value shows by itself while it is abnormal: high CPU, memory or temperature, or muted audio.
- **Indicators that show only when needed:** dictation and "something's wrong" are in this module. "Agents waiting on you" was dropped.
- **Tray:** a drawer behind a chevron. Native Bluetooth and NetworkManager panels (mainly VPN) replacing the applets come later, in `connectivity`.
- **Moved out of this module** because each needs its own data work: GitHub reviews, weather and updates (`bar-info`). This module provides the slots they plug into.
- **No window title.**

## Layout

```
at rest
 ╭──────────╮                    ╭───────╮                  ╭──────────────╮ ╭──────────────╮ ╭───╮
 │ ● ━━━ ●  │                    │ 14:05 │                  │ ▶ Song – Art │ │ ‹  ◌  ◁   ⏻ │ │ ⏻ │
 ╰──────────╯                    ╰───────╯                  ╰──────────────╯ ╰──────────────╯ ╰───╯
 workspaces                        clock                      media           tray · system · volume

when something needs attention (examples)
                                                          ╭─────╮ ╭──────────────────────╮
                                                          │ ◉ ⚠ │ │ ‹  ◌ 97%  ◁ muted    │
                                                          ╰─────╯ ╰──────────────────────╯
                                                          dictation, something's wrong
```

- **One bar per monitor.** It is a transparent window along the top edge, holding separate pills.
- **On a portrait monitor** (DP-3 today, detected by height greater than width, not by name): only workspaces and the clock.
- **The media and indicator pills exist only while they have something to show.** They appear and disappear with a short width and opacity animation.

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
| Icons | 15 px, `Theme.darkForeground`; `Theme.foreground` on hover; `Symbols Nerd Font`, fixed so icons work with any mono font | `Style.fontIcons` |
| Values | `Theme.foreground`, `Theme.fontSans`, 13 px, tabular figures, so numbers don't jitter | |
| Attention colours | `Theme.yellow` (warning) and `Theme.red` (critical); never the accent | |
| Popups | the same fill, border and blur; radius `Style.radius`. Placed below their pill and centred on it, never off screen. | |
| Hover reveal | the value slides out after 150 ms; it hides 400 ms after the pointer leaves | |
| Motion | `Style.durationNormal` with `Style.easing`; no bounce | |

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
- **Hover:** the full date, for example "Tuesday, 24 November 2026".
- **Click:** a calendar popup below the clock:
  - weeks start on Monday, with ISO week numbers;
  - today is marked in `Theme.accent`;
  - scrolling, the arrow keys or the header chevrons change the month;
  - Esc or a click outside closes it.

**Media** (right, own pill):
- **Display:** a play or pause icon, then "Title – Artist", elided after 28 characters. Long titles scroll slowly on hover.
- **Player:** the MPRIS player that is playing, otherwise the first one.
- **Input:**
  - click: play or pause;
  - scroll: next or previous;
  - right-click: a popup with cover art, the full title and artist, a position bar, and previous, play/pause and next buttons.
- **Hidden** when no player exists.

**Indicators** (right, own pill, before the status pill). It exists only while at least one indicator is active:
- **Dictation** (voxtype):
  - **Source:** `voxtype status --follow --format json`, read as a stream; this is not polling.
  - **While recording:** a mic icon in `Theme.red`, with a soft pulse.
  - **While transcribing:** the icon in `Theme.yellow`, with a slow spin.
  - **Otherwise:** hidden.
- **Something's wrong:** a `Theme.yellow` warning icon (`Theme.red` if anything is critical). Click lists each problem with a short "why" and an action. Failed units are checked every 10 s, so they show quickly; the others every 60 s. Problems:
  - **Backup failed:** the last `borgmatic.service` result isn't `success`. Critical.
  - **Backup overdue:** the last success is more than 3 hours old (the timer runs hourly). Warning.
  - **Tailscale down:** `tailscale status --json` reports a `BackendState` other than `Running`. Warning.
  - **Wired network down:** NetworkManager reports no connected Ethernet device. Critical.
  - **Failed units:** any failed system or user unit, each named. Warning.
- **The slot is the extension point.** `bar-info` adds indicators and items here in the same way.

**Status** (right, own pill): the tray drawer, system, volume and power.
- **Tray drawer:**
  - **At rest:** a chevron. Hovering slides open the tray icons (16 px).
  - **Input:** click activates an icon; right-click opens the item's menu as a popup; middle-click is secondary activate.
  - **Hover:** the item's title.
  - **Closing:** the drawer closes 600 ms after the pointer leaves.
  - **Tray host:** Quickshell's system tray. Today the icons are nm-applet and blueman.
- **System:** one gauge icon.
  - **Readings:**
    - CPU %: the difference between two `/proc/stat` samples;
    - memory %: from `/proc/meminfo`;
    - CPU temperature: the `coretemp` sensor's "Package id 0", found by name under `/sys/class/hwmon`, because the `hwmon` number can change between boots.
    
    All polled every 2 s.
  - **Hover:** "12% · 41% · 52°".
  - **When a reading is high:** that reading shows by itself, coloured. Thresholds:

    | Reading | Yellow from | Red from |
    |---|---|---|
    | CPU (averaged over 3 samples, so short spikes don't flash) | 80% | 95% |
    | Memory | 80% | 90% |
    | Temperature | 80 °C | 90 °C |

  - **Click:** a popup with a meter per reading, the load average, used and total memory in GiB, and the sensor name.
- **Volume:** the default PipeWire sink.
  - **Icon:** shows the level; while muted, the icon is struck through and the word "muted" shows in `Theme.red`.
  - **Hover or scroll:** the percentage. Scrolling changes the volume by ±5%, capped at 100%.
  - **Right-click:** toggle mute.
  - **Click:** a popup with a volume slider and a list of output devices; choosing one makes it the default. `pavucontrol` is a link at the bottom of the popup.
- **Power:** an icon that turns `Theme.red` on hover. Click runs `hyprshutdown`, as today; the `power-menu` module replaces this later.

## Structure

```
quickshell/.config/quickshell/
  shell.qml                      # adds: Variants over Quickshell.screens -> Bar
  theme/Style.qml                # adds: barGap, fontIcons, iconSize, reveal timings
  bar/
    Bar.qml                      # PanelWindow per screen; full or portrait layout
    Pill.qml  Popup.qml  Reveal.qml   # shared: pill surface, popup surface, hover-reveal value
    Workspaces.qml  Clock.qml  Calendar.qml  Media.qml  MediaPopup.qml
    Indicators.qml  Dictation.qml  Health.qml  HealthPopup.qml
    Tray.qml  System.qml  SystemPopup.qml  Volume.qml  VolumePopup.qml  Power.qml
    logic.js                     # pure functions (see Testing)
    qmldir
  services/
    SystemStats.qml  Health.qml  Dictation.qml   # singletons: data, no UI
    qmldir
quickshell/tests/tst_bar.qml     # logic.js tests
hyprland/.config/hypr/looknfeel.lua   # layer rule: blur quickshell:bar and quickshell:popup
hyprland/.config/hypr/autostart.lua   # stops launching Waybar
```

Data lives in `services/`, as singletons, and the UI in `bar/`, so the coming modules can reuse the data. For example, `osd` will reuse the volume, and the launcher may reuse the media.

**Removed at cutover:**
- the `waybar` package directory and `hypr/scripts/launch-waybar.sh`, which remain in git history;
- Waybar's stow links.

The `waybar` pacman package stays installed until you remove it.

## Testing strategy

**Unit tests (`qmltestrunner`, `logic.js`):**
- CPU % from two `/proc/stat` samples, and the 3-sample average;
- memory % from `/proc/meminfo`;
- finding the temperature sensor;
- levels at and just below each threshold;
- volume icons, including mute;
- the media label: eliding, and a missing artist;
- calendar grids for months starting on each weekday, with Monday first and ISO week numbers;
- the dot list: filtering and sorting workspaces, without special workspaces;
- each health check's parsing and severity: borgmatic result and age, Tailscale state, failed units, wired network;
- parsing voxtype's status JSON.

**Lint:** `qmllint` and `qmlformat`, as in shell-core.

**End-to-end, in the session:**
- **Geometry:** screenshots of both monitors under two themes. Measure a 7 px top gap, and the outer pills aligned with window edges.
- **Hover reveal:** volume and system values slide out on hover and hide afterwards.
- **High CPU:** a short load (`yes > /dev/null` on every core, for 6 seconds) makes the CPU reading appear in yellow or red, then disappear.
- **Workspaces:** clicking a dot switches workspace; scrolling moves.
- **Volume:**
  - scrolling changes `wpctl get-volume` by 5%, then I restore it;
  - right-click mutes and shows "muted", then I unmute;
  - the popup lists the output devices.
- **Tray:** the drawer opens on hover and shows nm-applet and blueman after the cutover, and their menus open.
- **Clock:** the hover date and the calendar render, including week numbers, and the calendar closes on Esc.
- **Dictation:** the indicator appears while voxtype records (toggled with `voxtype record toggle`) and disappears afterwards.
- **Something's wrong:** a deliberately failed user unit (a test unit running `false`) shows the warning and lists the unit. Resetting the unit clears it.
- **Media:** with a player running, the pill and its popup work.
- **Live updates:** `theme set` and `theme font` restyle the bar live.
- **Log:** no new warnings, apart from the known Qt text-input one.

## Boundaries

- **Always:**
  - Waybar keeps running until the new bar passes its end-to-end checks; then cut over in one commit.
  - Every colour comes from `Theme`, and every size from `Style`.
  - Data services contain no UI, and UI components spawn no processes.
- **Ask first:**
  - uninstalling the `waybar` pacman package;
  - changing Hyprland `gaps_out`;
  - any check that needs `sudo`.
- **Never:**
  - poll faster than every 2 s;
  - spawn a process per poll when a file read works;
  - show a value permanently that is only interesting when abnormal.

## Success criteria

1. **Waybar is replaced.** It no longer starts, and the Quickshell bar shows on both monitors with the layouts above.
2. **Calm at rest.** With nothing abnormal, the bar shows only workspaces, the clock, an optional media pill and the status icons.
3. **Every module behaves as specified,** verified by the end-to-end checks.
4. **Pills line up with the window edges,** with 7 px gaps measured on DP-4.
5. **Theme and font changes are live.** `theme set` and `theme font` restyle the bar within half a second.
6. **Low CPU use.** At idle, the shell uses under 1% CPU (measured with `ps` over 30 s).
7. **Checks pass.** Tests, `qmllint` and `qmlformat` are clean, apart from the known findings in the README.

## Out of scope (deferred)

- **Agent usage quota:** only from CLIProxyAPI's reported quota (see the map's Deferred list). `bar-agents` was dropped.
- **`bar-info`:** GitHub review requests, weather and updates.
- **`connectivity`:** themed Bluetooth and network panels replacing nm-applet and blueman.
- **A per-app mixer in the volume popup.**
- **A btop-style system popup** (history graphs, GPU, network and disk rates, top processes): considered and skipped on 2026-11-24. Live graphs and a process list cost CPU and GPU time while open, and the gauge's meters are enough.
- **The notification indicator and do-not-disturb:** they belong to `notifications`.
- **The `flush` and `island` bar shapes:** `Style.barShape` exists, but V1 implements pills only.
