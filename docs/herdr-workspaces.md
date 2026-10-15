# herdr workspaces: navigation, layout, status

Snapshot: 2026-10-14 (herdr 0.9.4, tuicr 0.27.0). How herdr is set up for day-to-day work, beyond the tmux-style keys in `herdr/.config/herdr/config.toml`. PR review and agent hand-offs are in [pr-review.md](pr-review.md); why herdr at all is in [multiplexer-agent-review-dotfiles.md](multiplexer-agent-review-dotfiles.md).

## Keys

Prefix is `ctrl+space`.

| Key | Does |
|---|---|
| `ctrl+h/j/k/l` | Move to the pane left/down/up/right; inside nvim, move between splits and cross into herdr at an edge |
| `prefix+shift+l` | Apply the worktree layout to the current single-pane workspace |
| `prefix+a` | Pick an agent (fzf, with its recent output) and jump to it |
| `prefix+t` | Send the focused tuicr pane's comments to an agent ([pr-review.md](pr-review.md)) |
| `prefix+f` | Find a project: focus an open workspace, open a worktree, or open a repo ([below](#workspace-picker)) |
| `prefix+shift+g` | Switch to or create a worktree of the current repo, through worktrunk ([below](#worktrees-worktrunk)) |
| `prefix+ctrl+g` | Remove a worktree of the current repo |
| `prefix+shift+m` | Merge a worktree into its target branch, then remove it |

## Navigation

`ctrl+h/j/k/l` are bound to [vim-herdr-navigation](https://github.com/paulbkim-dev/vim-herdr-navigation), a port of vim-tmux-navigator. On each press the herdr plugin checks the focused pane's foreground process: for vim or nvim it forwards the key, and nvim moves between its splits and calls back into herdr at an edge; for anything else it moves herdr's focus. The nvim half is the same repo, loaded through `vim.pack` (`nvim/.config/nvim/lua/plugins/herdr-navigation.lua`). The herdr plugin is installed with `herdr plugin install paulbkim-dev/vim-herdr-navigation`; both are at commit `742db89`.

Costs, accepted:

- In panes that aren't nvim, herdr takes the keys. fish loses `ctrl+l` (clear screen) and `ctrl+k` (kill line); `ctrl+j` (Enter) and `ctrl+h` (back one char) have other keys. omp loses `ctrl+k` (delete to end of line) and `ctrl+j` (new line; shift+enter still works). Backspace is unaffected.
- herdr's native focus actions are unbound. Their defaults, `prefix+h/j/k/l`, would collide with `split_horizontal = prefix+h`.
- nvim's LSP `<C-k>` signature help is insert-mode only now; in normal mode it would override navigation in every buffer with a language server. In neo-tree, `<C-j>/<C-k>` still move its cursor.

Rejected: the previous `ctrl+alt+h/j/k/l` (disliked); zellij-nav.nvim (zellij is no longer the multiplexer, so it couldn't move between herdr panes).

## Sidebar: PR, CI, and review status

[herdr-git-status](https://github.com/ubuntudroid/herdr-git-status) runs a poller that publishes, for each workspace's branch, its CI state (checked against the exact commit), its PR number, its review state (conflict, changes requested, approved, awaiting a reviewer, required by branch protection, draft) and whether it will auto-merge or has merged. It only reads from GitHub (GraphQL queries, no writes) and starts again from a startup hook after a herdr restart. It's installed from a fork, [ianseddon/herdr-git-status](https://github.com/ianseddon/herdr-git-status) (`herdr plugin install ianseddon/herdr-git-status`, commit `b187fb7`), which adds one change: the `CI `/`R `/`M ` labels the upstream plugin puts in front of each badge can be turned off with `GST_LABEL_CI`/`_REVIEW`/`_MERGE`. The change defaults to the old labels and comes with tests, so it can go upstream as is; the working clone is `~/dev/contrib/herdr-git-status` (remote `upstream` points at ubuntudroid).

Badges appear as a third row under each workspace, bare glyphs with no labels, matching gh-dash's PR list (gh-dash v4.26.1 `internal/tui/constants/constants.go`) and coloured with the same theme colours as `gh-dash/.config/gh-dash/config.yml`:

| | Glyph | Colour |
|---|---|---|
| CI passing / failing / running | check in a circle / x in a circle / clock (gh-dash `SuccessIcon`, `FailureIcon`, `WaitingIcon`) | success / error / warning |
| CI waiting on a person / cancelled or skipped | warning / circle-slash (`ActionRequiredIcon`, `EmptyIcon`) | warning / faint |
| Review: approved, changes requested, awaiting, required | person (`PersonIcon`) for all four | success / error / warning / faint |
| Conflict / draft | `BlockedIcon` / `DraftIcon` | error / faint |
| Auto-merge armed / merged | `MergeQueueIcon` / `MergedIcon` | warning / oniViolet |

The CI badge always comes first, then the review badge, then the PR number (for example `✓ · 👤 · #606`). Reviews use the person icon rather than gh-dash's per-state review icons, so a review badge never looks like a CI badge (gh-dash shows a clock for both pending CI and pending review, and relies on separate columns). Glyphs are set in `herdr/.config/herdr/plugins/config/git-status/.env`, colours in `[ui.sidebar.spaces]` in herdr's config. A workspace with no PR shows two rows as before.

Why a third row: the branch stays readable on the second. The PR number fits now that the labels are gone; with them, worktrees nested under their repo were cut to `CI… · R… · #…` even at a 28-column sidebar. Why one token per state: herdr's token styles are static, so the plugin names a token per state and fills only one.

Not taken: bendrucker's layout, with status of at most two glyphs at the end of the workspace-name row (herdr truncates the name to keep custom tokens visible). Possible now that the labels can go; the third row was kept so long workspace names aren't shortened.

Rejected: wyattjoh/herdr-plugin-gh-pr (PR number and CI glyph only; needs Bun), mrolafsson/herdr-github (richest, but its PR picker overlaps gh-dash and it needs a Go build), a custom script like bendrucker's `herdr-workspace-status` (about 100 lines; the fork and rate-limit handling is the hard part this plugin already has). All candidates have small audiences (0–23 stars); if this one proves flaky, a custom script is the fallback.

## Worktrees: worktrunk

Worktrees are created through [worktrunk](https://worktrunk.dev) (`wt`), so each repo's setup and teardown hooks run: installing dependencies, copying `.env` files, and so on. Hooks live in the repo's own `.config/wt.toml`, or, for repos you can't commit to, under `[projects."github.com/<owner>/<repo>"]` in the worktrunk user config. worktrunk asks before running a project's hook commands the first time and after they change, and remembers approvals per machine in `~/.config/worktrunk/approvals.toml`.

- **Where:** checkouts live at `~/dev/github.com/<owner>/<repo>`, worktrees in a parallel tree at `~/dev/wt/<owner>/<repo>/<branch>` (`worktree-path` in `worktrunk/.config/worktrunk/config.toml`). worktrunk has no host variable, so the host isn't in the worktree path. Only `config.toml` is stowed; `~/.config/worktrunk` must be a real directory first (`mkdir -p`), or stow would link the whole directory and approvals would be written into this repo.
- **In herdr:** [herdr-worktrunk](https://github.com/devashish2203/herdr-worktrunk) (commit `f9df9ba`, config in `herdr/.config/herdr/plugins/config/worktrunk/config.toml`) opens a popup picker of the current repo's worktrees and branches. Enter on a match switches to it; typing a new name creates it from the default branch (worktrunk shortcuts like `pr:606` work too). It runs `wt switch` and then `herdr worktree open`, so every worktree it opens gets the [worktree layout](#worktree-layout). `prefix+shift+g` replaces herdr's own new-worktree dialog, which runs no hooks. Remove refuses worktrees with uncommitted changes or unmerged branches, closes the workspace, and deletes the branch once merged; it can leave an empty `~/dev/wt/<owner>/<repo>` directory behind.
- **Installed by:** the Nix flake on M75q (`worktrunk` input at a release tag, because nixpkgs trails releases and `wt config plugins omp` needs 0.78.0 or later); pacman on the desktop. `wt config shell install` and `wt config plugins omp install` are run once per machine.

Rejected: herdr's own worktrees (`herdr worktree create`): no hooks. worktrunk's default location (`<repo>.<branch>` next to the checkout): it would fill each owner directory with worktrees.

## Worktree layout

Every new git worktree workspace is laid out the same way, following [babarot's setup](https://github.com/babarot/dotfiles/blob/6d4b7528bc96312763a3da16a1a1e18ba21abb0f/nix/home-manager/tools/herdr/worktree-layout.nix):

```
┌───────────────────────┬───────────────────────┐
│ agent                 │ review                │
│ (omp, started)        │ (one-key menu)        │
├───────────────────────┴───────────────────────┤
│ shell                                         │
└───────────────────────────────────────────────┘
```

The local plugin `worktree-layout` (`herdr/.local/share/herdr-plugins/worktree-layout`, linked with `herdr plugin link`) applies it from `worktree.created` and `worktree.opened` hooks, whoever created the worktree: herdr's new-worktree dialog, the workspace picker, or the review scripts. `prefix+shift+l` applies it to any other single-pane workspace. A workspace that already has more than one pane is left alone, so reopening a workspace that kept its panes, or one you've arranged yourself, isn't disturbed.

- **Agent**: the kind is `agent` in `herdr/.config/herdr/plugins/config/worktree-layout/config.toml` (omp); empty leaves a plain shell. It's named after the workspace id, lowercased because herdr only accepts lowercase agent names, with each capital written as `_` plus the letter so names stay unique (`wW` → `agent-w_w`). A shell that's still starting up can refuse the agent as busy, so the hook retries that for up to 20 s; any other failure is logged and shown as a notification with herdr's message.
- **Review**: a menu (`bin/review-pane`) rather than tuicr itself, because a fresh worktree has nothing to diff and tuicr exits on an empty range. Enter reviews against the base branch: commits since the merge-base with the remote's default branch plus uncommitted changes (`tuicr -r <merge-base>..HEAD -w`). Other keys: `w` uncommitted only, `c` tuicr's own commit and session picker, `p` the branch's GitHub PR, `b` the base branch, `q` plain shell. tuicr returns to the menu when it exits. The base is as of your last fetch. tuicr started here defaults `prefix+t` to the agent beside it.
- **Shell**: the bottom 30%, full width.

Zoom (`prefix+z`) the review pane when the diff needs the whole screen.

For scripts: the pane labels `agent`, `review`, `shell` are set last, after the agent has started (or failed to), and `bin/layout-wait <workspace id>` waits for them and prints the three pane ids as JSON; check `herdr agent get <agent pane>` before prompting. A branch whose git config has `branch.<branch>.herdrReviewUrl` set to a PR URL is treated as a PR review: Enter opens `tuicr pr <url>`. The review scripts in [pr-review.md](pr-review.md) use both. Runs are logged to `~/.local/state/herdr/plugins/worktree-layout/layout.log`.

Decisions:

- **One tab, review beside the agent** (babarot), not review in a second tab (edmundmiller, lararosekelley) or a pane that follows you between tabs (bercail). Reviewing an agent's work is mostly a conversation with it; zoom covers the occasional full-width diff. Revisit if the side-by-side diff is too cramped in practice.
- **A hook, not only a key**: every worktree gets the layout without a second step, and the review scripts wait for it instead of building their own panes, so there's one owner of the layout. The cost is that the hook can't tell who created a worktree (the event doesn't say), hence the single-pane rule and `layout-wait`.
- **Base-branch review by default, not a review gate on every agent turn** (bercail's "agents stage, humans review"): whether a change needs that depends on the change; the menu makes the other scopes one key away.
- **Linux only** (`flock` for one layout run per workspace).

## Workspace picker

`prefix+f` opens workspace-pickr (`herdr/.local/share/herdr-plugins/workspace-pickr`, linked with `herdr plugin link`), a project picker in the same fzf layout as the agent picker:

- **Rows:** open workspaces first (●, coloured by agent status, `*` on the focused one); then git repos among your top 40 zoxide directories (○; a subdirectory counts as its repo); then those repos' linked worktrees that aren't open (◌). Worktrees come last so a repo with dozens of them stays searchable by branch without crowding the top.
- **Preview:** for an open workspace, its panes and agents; then `git status -sb` and the last eight commits.
- **Enter:** focuses an open workspace, opens a worktree with `herdr worktree open`, or creates a workspace for a repo labelled with its directory name. Worktrees opened or created this way get the [worktree layout](#worktree-layout); a plain repo workspace doesn't (`prefix+shift+l` adds it).
- **ctrl-n:** asks for a new branch name and runs `herdr worktree create` from that repo's main checkout, based on its local default branch, without fetching.

Basing new branches on `origin/main` was rejected: the branch would track it, which breaks a plain `git push`. herdr's own `prefix+w` picker stays, for open workspaces only. Listing takes about 0.2s with a real zoxide database. In a narrow popup the path and agent columns get cut first; label and branch are capped at 24 and 20 characters.
