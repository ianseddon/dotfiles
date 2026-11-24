# Spec: app-themes — V1

Status: approved 2026-11-24. Module `app-themes` in the [capability map](README.md). The terminals (herdr-app and Ghostty), bat, delta and lualine shipped first, in [SPEC-fonts-and-terminals.md](SPEC-fonts-and-terminals.md). This spec covers the rest.

## Objective

Every terminal app follows the theme. Most of these apps also run on the M75q, in herdr panes: fish, fzf, nvim, gh-dash, tuicr, hunk, the herdr TUI, pi and Claude Code. Their configs are shared between the machines, and `theme` runs only on the desktop.

**Decision (2026-11-24): use terminal colours, not sync.** The theme is not copied to the M75q. Instead, each app draws with the terminal's 16 colours and its default foreground and background. herdr-app's palette comes from the theme, so these apps follow it on both machines, with no generated files, and they change live when the theme switches.

**nvim is the exception.** A good editor colour scheme needs more than 16 colours. On the desktop, nvim loads the theme's own colour scheme. On the M75q there is no theme state, so nvim keeps Kanagawa.

## The terminal palette these apps rely on

This mapping comes from [SPEC-fonts-and-terminals.md](SPEC-fonts-and-terminals.md):

| ANSI | Palette key | Typical use |
|---|---|---|
| 0 | `darker_background` | Panels and selected rows, a step darker than the background |
| 1 to 6 | `red`, `green`, `yellow`, `blue`, `magenta`, `cyan` | Accents |
| 7 | `foreground` | Text |
| 8 | `muted` | Dividers and faint text |
| 9 to 14 | the `bright_*` colours | Emphasis |
| 15 | `bright_foreground` | Strong text |

The default foreground and background (`-1` or `default`) are the theme's `foreground` and `background`.

## Changes per app

| App | Today | Change |
|---|---|---|
| **fish** | `conf.d/kanagawa.fish` sets syntax and pager colours as Kanagawa hex values. | Rename it to `conf.d/colors.fish` and use ANSI names (`blue`, `brblack`, ...) in the same roles. |
| **fzf** | `FZF_DEFAULT_OPTS` sets Kanagawa hex colours. | ANSI indices, with `-1` for the default foreground and background. |
| **gh-dash** | Theme colours are Kanagawa hex values. | ANSI indices (supported since 4.26) in the same roles. |
| **tuicr** | Local theme `kanagawa-wave.toml` plus its tmTheme. | Local theme `terminal.toml` using colour names. Syntax colours: first try bat's `ansi` tmTheme encoding. If tuicr doesn't render it, leave `syntax_theme` out, so tuicr uses its bundled dark syntax theme. Remove the Kanagawa files. |
| **hunk** | `theme = "kanagawa-wave"` | `theme = "terminal"` (built in). |
| **herdr TUI** | `[theme] name = "kanagawa"` | `name = "terminal"`. It was replaced earlier because bars were drawn in Ghostty's ANSI black, a navy. With ANSI 0 now `darker_background`, that problem is gone. |
| **pi** | `system` theme (the default), built from the terminal's palette. | No change. Confirm that no setting overrides it. pi reads the palette when it starts. |
| **Claude Code** | `"theme": "auto"` | `"dark-ansi"`: Claude Code's ANSI-only dark theme. Confirm the exact value first. |
| **nvim** | Kanagawa, with Pmenu and float overrides in `plugins/kanagawa.lua`. | See below. |

### nvim

**Loading the colour scheme.** `plugins/theme.lua` replaces `require("plugins.kanagawa")`:

- If `~/.local/state/theme/current/nvim.lua` exists (on the desktop), `dofile` it.
- Otherwise (on the M75q, or before the first `theme set`), load Kanagawa as today.

**Where `nvim.lua` comes from:**

- **Native ports.** Each shipped theme folder ships its own `nvim.lua`:
  - `kanagawa`: the current setup, including its overrides, moved from `plugins/kanagawa.lua`;
  - `tokyo-night`: `folke/tokyonight.nvim`, style `night`;
  - `gruvbox-material`: `sainnhe/gruvbox-material`, medium background and `material` foreground;
  - `oxocarbon`: `nyoom-engineering/oxocarbon.nvim`.
- **A template for every other theme** (for example a copied Omarchy theme): `nvim.lua.tpl` builds a colour scheme with `mini.base16`. The palette maps onto base16 one to one:

  | base16 | Palette key |
  |---|---|
  | `00` | `background` |
  | `01` | `lighter_background` |
  | `02` | `selection` |
  | `03` | `dark_foreground` |
  | `04` | `light_foreground` |
  | `05` | `foreground` |
  | `06` | `light_foreground` |
  | `07` | `bright_foreground` |
  | `08` | `red` |
  | `09` | `orange` |
  | `0A` | `yellow` |
  | `0B` | `green` |
  | `0C` | `cyan` |
  | `0D` | `blue` |
  | `0E` | `magenta` |
  | `0F` | `brown` |

**New plugins in `vim.pack.add`:** `tokyonight.nvim`, `gruvbox-material`, `oxocarbon.nvim` and `mini.base16`. The M75q installs them too, because the nvim config is shared. They are small, and unused there.

**Live reload.** A new hook, `50-nvim`, finds each running nvim's socket (`$XDG_RUNTIME_DIR/nvim.*`). It asks each nvim to re-run the file:

```sh
nvim --server <socket> --remote-expr "execute('lua dofile(...)')"
```

Each call has a 2-second timeout, so a busy nvim can't hang the switch. Because of that re-run, every `nvim.lua` must be safe to run again. lualine (`theme = "auto"`) and bufferline must follow the `ColorScheme` event; confirm both during implementation.

## Findings during implementation

- **tuicr's syntax colours:** tuicr ignores bat's `ansi` tmTheme encoding. With it, syntax colours stayed `#f59057` under both Kanagawa and Gruvbox Material. `terminal.toml` leaves `syntax_theme` out, so tuicr uses its bundled dark syntax theme. Its UI colours follow the theme live.
- **tuicr's diff backgrounds:** the 16 ANSI colours have no tinted backgrounds, so added and removed lines use the 256-colour palette's darkest green (22) and red (52). These are fixed, not from the theme.
- **hunk:** its `terminal` theme reads the terminal's colours when it starts, so it follows the theme after a restart, not live. Measured: a removed line's tint was `#605050` under Kanagawa and `#574c5b` under Tokyo Night.
- **Claude Code:** `"dark-ansi"` is the documented value ("the dark theme using only your terminal's ANSI color palette").
- **Not stowed on the desktop:** the tuicr and Claude Code packages. Their configs apply where they are stowed, which is the M75q.

## Success criteria

1. **Colours change live.** On the desktop, in herdr-app, for each of the four themes, `theme set` changes these to the theme's colours without restarting them:
   - fish highlighting;
   - an fzf list;
   - gh-dash;
   - tuicr;
   - hunk;
   - the herdr TUI;
   - a running nvim.
   
   Check each with a screenshot.
2. **Restart picks up the theme.** pi and Claude Code use the theme's colours after a restart.
3. **No Kanagawa values remain** in the configs of these apps, except nvim's Kanagawa fallback and the `kanagawa` theme folder.
4. **The M75q.** After the M75q pulls the dotfiles:
   - fish, fzf, gh-dash, tuicr, hunk, the herdr TUI and pi show the desktop's current theme through herdr-app;
   - nvim shows Kanagawa.
   
   Updating the M75q's checkout is a separate step, and I will ask first.
5. **Themes from outside.** A copied Omarchy theme gets a working nvim colour scheme from the `mini.base16` template.
6. **Checks pass.** Unit tests (including the `nvim.lua` template and the `50-nvim` hook), `ruff`, `basedpyright`, `shellcheck`, and `luac -p` on every `nvim.lua`.

## Boundaries

- **Ask first:** changing anything on the M75q itself, including pulling and stowing there.
- **Never:** keep a dead Kanagawa file around "just in case". Git history has it.
- **Everything else follows** [SPEC-theme.md](SPEC-theme.md).

## Out of scope (deferred)

- **Syncing the theme to the M75q**, rejected for now. It would give nvim the theme there too.
- **Native tmThemes for bat and delta.**
- **Theming Claude Code and pi beyond their terminal-colour modes.**
- **Light themes.** The terminal-colour approach supports them, but none ship yet.
