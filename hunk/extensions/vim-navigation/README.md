# Vim navigation extension

An always-on Vim-style navigation extension for Hunk's review stream. This
local variant uses ordinary extension commands and user keybindings because
Hunk 0.24 does not expose automatic activation for session keyboard modes.

## Keys

| Key                 | Action                                                      |
| ------------------- | ----------------------------------------------------------- |
| `j` / `k`           | Move the current review line down/up                        |
| `[` / `]`           | Move to the previous/next hunk                              |
| `gg` / `G`          | Jump to the start/end of the review                         |
| `zt` / `zz` / `zb`  | Align the current line at the top/center/bottom             |
| `Ctrl-D` / `Ctrl-U` | Move down/up by half pages                                  |
| positive digits     | Prefix the next relative motion, for example `5j` or `3]` |
| `:`                 | Open Hunk's Vim command line                                |
| everything else     | Pass through to normal Hunk routing, including `a`          |

A bare `0` retains Hunk's automatic-layout shortcut. Other bare digits are
interpreted as Vim counts, replacing Hunk's explicit layout shortcuts.

## Ex commands

| Command   | Action                          |
| --------- | ------------------------------- |
| `:top`    | Jump to the start of the review |
| `:bottom` | Jump to the end of the review   |
| `:q`      | Quit Hunk                       |
| `:quit`   | Quit Hunk                       |

Unsupported commands produce an attributed warning. Absolute source-line
commands such as `:100` are unavailable because Hunk does not expose
source-line targeting as a public semantic command.
