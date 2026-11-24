# Spec delta: fonts, and the terminal palette

Status: approved 2026-11-24. This changes [SPEC-theme.md](SPEC-theme.md) and delivers the first part of the `app-themes` module.

## Objective

Two changes:

1. **Fonts.** Fonts become switchable in the same way as colours, but separately from them, so any font can be paired with any theme. The desktop gets one source of truth for fonts: fontconfig's `monospace` and `sans-serif` aliases.
2. **The terminal palette.** The two terminals, herdr-app and Ghostty, take their palette from the theme. Apps that draw with ANSI colours then follow the theme without per-app work. This fixes the remaining inconsistencies: lualine and delta still use Everforest, and herdr-app uses its own default theme.

## Current behaviour

- **Fonts are set in many places.**
  - `fontconfig/fonts.conf` prefers Mononoki Nerd Font and Inter.
  - Ghostty, hyprlock and Waybar ask for `monospace`, so they follow it.
  - GTK4 and libadwaita apps read gsettings instead: `Adwaita Mono 11` and `Adwaita Sans 11`.
  - herdr-app uses its bundled JetBrains Mono and Geist, because it does not read fontconfig's aliases.
  - Rofi names its fonts directly. It is being replaced, so this is out of scope.
- **Colours are inconsistent.**
  - Ghostty hard-codes `theme = Kanagawa Wave`.
  - herdr-app has no theme set, so it uses its default, `graphite`.
  - lualine uses the `everforest` theme while nvim is on Kanagawa.
  - bat and delta use `everforest-dark`.

## New behaviour

### Fonts

```sh
theme font                          # print the mono and sans families in use
theme font mono "JetBrains Mono"    # switch the monospace family
theme font sans "Geist"             # switch the UI family
```

- **Validation:** the family must be installed (`fc-list : family`). If it is not, exit 1 and change nothing.
- **Where the choice goes:** `~/.local/state/theme/fonts.conf`, a fontconfig file that prefers the chosen family for that alias. The tracked `fonts.conf` includes it *before* its own defaults, and in fontconfig the earlier preference wins. Deleting the state file therefore returns to the tracked defaults.
- **Icons:** `Symbols Nerd Font` follows every monospace choice, so a font without a Nerd Font build still shows icons.
- **Apps:** after the change, `theme font` runs the same reload hooks as `theme set`. Hooks bring each app in line with the current state (palette and fonts), and every hook is idempotent.
- **Apps that do not read fontconfig's aliases** get the resolved family name from a hook: `fc-match monospace` and `fc-match sans-serif`. Fontconfig stays the single source.

### Hooks

Hooks receive the current theme name as `$1`, which may be empty before the first `theme set`, and `THEME_CURRENT`. Each hook syncs everything it owns.

| Hook | Does |
|---|---|
| `10-hyprland` | Unchanged. |
| `20-desktop` | Sets the gsettings `monospace-font-name` and `font-name` to the generic `Monospace 11` and `Sans 11`, so GTK follows fontconfig. Sets `color-scheme` to `prefer-dark` or `prefer-light` from the palette's `mode`. Each key is written only when its value differs. |
| `30-herdr-app` | Writes the palette to `~/.config/herdr-app/themes/current.json`, then runs `herdr-app do app.theme` with `current` if the app is running. Writes `font` and `ui_font` (the resolved families) into its `settings.json`, keeping every other key; the app reloads that file live. Skipped if `~/.config/herdr-app` does not exist. |
| `40-ghostty` | Sends `SIGUSR2` to running Ghostty processes, which reload their config. |
| `90-greeter` | Unchanged. |

### Terminal palette

- **New templates:** `herdr-app.json.tpl` and `ghostty.conf.tpl`. Both map the palette to the 16 ANSI colours in the same way:

  | ANSI | Palette key |
  |---|---|
  | 0 | `darker_background` |
  | 1–6 | `red`, `green`, `yellow`, `blue`, `magenta`, `cyan` |
  | 7 | `foreground` |
  | 8 | `muted` |
  | 9–14 | the `bright_*` colours |
  | 15 | `bright_foreground` |

  ANSI 0 is not `background`, unlike Omarchy, because text or bars drawn in black would be invisible.
- **Ghostty:** its config drops `theme = Kanagawa Wave` and includes `?~/.local/state/theme/current/ghostty.conf`.
- **lualine:** `theme = "auto"`, so it follows nvim's colour scheme.
- **bat and delta:** syntax theme `ansi`, which follows the terminal palette.
  - Native tmThemes per theme are deferred to the rest of `app-themes`.

## Success criteria

1. **Font switch:** `theme font mono "<installed family>"` changes `fc-match monospace` and Ghostty after its reload. It also updates herdr-app's `font` setting. No tracked file changes.
2. **Fallback:** `theme font mono "Nonexistent"` exits 1 and changes nothing.
3. **Icons:** after switching to a font without Nerd Font glyphs, `fc-match 'monospace:charset=f015'` still resolves to a Nerd Font, and icons render in Ghostty.
4. **Terminal palette:** for all four themes, `theme set` re-themes herdr-app and Ghostty live. Screenshots of both show the theme's background and ANSI colours.
5. **GTK:** `gsettings` shows the generic font names and the colour scheme that matches the theme's mode.
6. **No Everforest is left:** nothing outside Waybar and Rofi refers to it.
7. **Checks pass:** unit tests, `ruff`, `basedpyright` and `shellcheck`.

## Boundaries

- **Never edit tracked files from a command.** herdr-app's `settings.json` is app state and is not tracked, so it may be edited. Write it atomically and keep its other keys.
- **Ask first** before changing herdr-app layouts or mods.
- **Everything else follows** [SPEC-theme.md](SPEC-theme.md).

## Out of scope (deferred)

- nvim colour schemes per theme.
- fish and fzf colours. These are still Kanagawa hex values.
- tuicr, gh-dash and the herdr TUI.
- Native bat tmThemes.

All of these belong to the rest of `app-themes`.
