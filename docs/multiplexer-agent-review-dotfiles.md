# Multiplexer, agents, and review: what other people's dotfiles do

Research snapshot: 2026-10-14. Goal: a cohesive TUI development environment covering the whole development cycle (plan, code, test, debug, review, CI, operate), and evidence for herdr versus tmux versus zellij. Method: five parallel read-only researchers (tmux, zellij, herdr, review tooling, the rest of the cycle) read public dotfiles at pinned commits, plus the tools' own repos and docs. GitHub code search was not available to them, so discovery went through repo and topic search, READMEs, and web search; small configs that are never mentioned in a README will have been missed. Claims about this repo were re-checked locally, and the most decision-relevant external claim (martintrojer's herdr evaluation) was re-read at source. Nothing was installed or changed.

## Conclusion

**Stay on herdr.** The richest public setups that combine a multiplexer, agents, and a review loop are on herdr (babarot, edmundmiller, bercail, bendrucker, aviralmansingka, lararosekelley). tmux and zellij users rebuild what herdr ships: agent state and attention (tmux bell hooks, zellij pipe plugins), prompt delivery between panes (zellij-wrangler copies herdr's socket API by name; zj-agent-mob is "inspired by herdr"), and worktree-per-task workspaces (workmux, worktrunk). The one careful tmux holdout, martintrojer, ported herdr's state model into tmux scripts rather than disputing it.

The case against herdr is real but specific:

- **Maturity.** It is v0.x with one maintainer and fast churn. Five public repos reverted from herdr to tmux in July–September 2026. Most give no detailed reason ("didn't work out in practice"). One cites timing workarounds needed to start nvim in a fresh pane. One cites nesting conflicts with tmux. One calls herdr "proprietary", which is wrong: herdr is Apache 2.0.
- **Missing pieces people hit.** There is no startup-layout config, so everyone writes a plugin or script. There is no re-layout of live panes. There is no tmux-navigator equivalent built in, though a community `vim-herdr-navigation` exists. Floating panes can't be backgrounded, which zellij does better. The sidebar can't be moved. The plugin ecosystem is young next to TPM.
- **Fleet economics.** martintrojer found that with one or two agents herdr's agent panel "show[s] you what you already know". He names 4–6 agents across 3+ workspaces as the honest test of whether it pays for itself, and records that test as not yet run; it is his trigger to reconsider, not a measurement.

Reconsider tmux if herdr churn starts costing more than its features save, or if you need one view over agents on several machines. Neither herdr nor tmux has that natively; martintrojer built `murmur` for it. zellij is the weakest fit for this workflow: no public dotfiles found wire a review tool beside an agent in zellij, and its plugin API has documented limits for agent status (below).

**Ideas most worth adopting, in order:**

1. **Fix editor↔pane navigation.** `nvim/.config/nvim/lua/plugins/zellij.lua` still binds `<C-h/j/k/l>` to `zellij-nav`, which cannot move between herdr panes. herdr's own focus keys are `ctrl+alt+h/j/k/l`. lararosekelley uses `vim-herdr-navigation` for prefix-free `ctrl+hjkl` across nvim and herdr; martintrojer names losing tmux-navigator as his first herdr cost. Cheap, and it's the most-used key in the setup.
2. **PR, CI, and review state in herdr's sidebar per workspace.** bendrucker's [`herdr-workspace-status`](https://github.com/bendrucker/dotfiles/blob/c0477ac6fb33cdabb034b1d3995ee249994c4947/herdr/bin/herdr-workspace-status) reports dirty/unpushed state and PR state (draft/merged/closed/stacked, check colours) as workspace tokens every 30s. This is the "status of my branch's PR" flow, and it complements the gh-dash fix actions being built now.
3. **A layout for your own worktrees, not only PR reviews.** babarot, edmundmiller, and bercail apply a fixed layout (agent, review tool, shell) from a `worktree.created` event hook. `review-worktree` already builds one imperatively for PRs; the same shape for your own agent worktrees would give every task workspace an agent with tuicr `-w` beside it.
4. **Agents stage, you review before commit.** bercail's rule is "agents stage, humans review; committed work is treated as already reviewed". When the agent goes `done`, its plugin opens `tuicr -w` on the uncommitted diff, and a [review skill](https://github.com/simoncrypta/bercail/blob/243f5e135f8bd37161a3576ab34fb36bc4be0a6f/skills/review/SKILL.md) waits for your tuicr comments with defined exit codes. This is the self-review loop your PR flow doesn't cover yet; `tuicr-send` already handles the delivery half.
5. **A workspace picker.** Agents have one (`prefix+a`); projects don't. GustavoGJesus's zoxide-ranked picker focuses an open workspace or creates one with the agent started; babarot's `prefix+f` adds git marks. It's the herdr equivalent of `sesh`/`tmux-sessionizer`.
6. **Close the debugging gap.** There's no debugger in the nvim config. LazyVim's [`dap.core`](https://github.com/LazyVim/LazyVim/blob/999700997f72227187d49d8b92667183dc7fc809/lua/lazyvim/plugins/extras/dap/core.lua) key scheme plus the neotest dap strategy makes your existing vitest tests debuggable. Add `neotest.watch.toggle` while there.
7. **One popup convention for operations tools, and a key reference.** lazydocker, btop, and k9s or lnav when relevant, as herdr `type = "popup"` commands at one size (royzah uses 90%×90% for every tool). Add a keybinding cheat sheet: edmundmiller has a command palette plus which-key; babarot comments every key with its reason and uses `prefix+?`.

## Your setup against peers

| Phase | You have | Recurs in strong setups | Gap |
|---|---|---|---|
| Plan / issues | gh-dash (PRs only); Atlassian MCP in agents | gh-dash issue and notification tabs (omerxx); issue → worktree + agent (edmundmiller `prefix+I`, GustavoGJesus Linear, bercail beads) | Jira has no terminal client in any setup found; jira-cli or jiratui in a popup would be untested ground |
| Code | nvim, herdr, omp + others | Worktree-per-task with a fixed layout from an event hook (herdr setups); project-agnostic `dev`/`build` runners (joshmedeski) | Layout for non-PR worktrees; nvim↔herdr navigation |
| Test | neotest + vitest | neotest watch and debug-nearest (LazyVim); `just test` harnesses | Watch toggle; dap strategy |
| Debug | none | nvim-dap + dap-ui (LazyVim extra, omerxx) | Debugger |
| Review | gh-dash `t`/`T`, pickr Ctrl+click, tuicr, review-worktree, tuicr-send | tuicr shared session (aviralmansingka, pabloimrik17, bercail); reviewr or hunk "send to agent"; daemon reviews on commit (obra's roborev) | Self-review of your own agents' uncommitted work |
| CI | gh-enhance | `gh run watch` → notification (joshmedeski [`gh-watch-action`](https://github.com/joshmedeski/dotfiles/blob/51df80b13e0682519d1baec7c7314c9869f2a94d/.config/bin/gh-watch-action)); PR/check tokens in the sidebar (bendrucker) | Notification on CI completion; sidebar status |
| Operate | Docker (rootless) | lazydocker / btop / k9s as same-size popups (royzah, omarchy) | Popups |
| Git | lazygit + delta | lazygit popup in the current directory | — |
| Launching | rofi (desktop apps only), herdr keys | One menu for TUIs (omarchy generates `.desktop` entries per TUI); command palette + which-key (edmundmiller) | TUIs aren't launchable from rofi; no key cheat sheet |

## What makes a setup cohesive

Observed across the strongest setups, not invented:

1. **One identity string everywhere.** Session or worktree name flows into the tab title, the agent's `--name`, and the status line (schuettc; Veraticus's `DEV_CONTEXT` read by prompt, terminal title, tmux, and phone notifications). Your `<repo>#<N>` label and `pr-<N>` branch are the start of this.
2. **One keymap grammar, documented in place.** omarchy mirrors tmux and herdr key for key with prefix `ctrl+space`, which is your prefix. babarot lists which herdr defaults he took over and why.
3. **Transient tools are popups of one size;** persistent tools get a named tab or pane (royzah, omerxx, zide).
4. **Push, don't poll, for agent state.** Every zellij and tmux setup that polled got burned (a zellij smart-tabs postmortem logged 35,225 plugin timeouts). herdr gives you this natively.
5. **Destructive actions are explicit and re-checked.** Sweeps refuse dirty worktrees (micahkepe); GitHub submission stays human (edmundmiller's Review Box prints the approve command but never runs it).
6. **Decisions are written down with reconsider triggers** (martintrojer's `DECISIONS.md`, bercail's README, babarot's `docs/`). You already do this.
7. **Theme parity.** One palette across the terminal, multiplexer, git TUI, gh-dash, and the agent's own TUI (GustavoGJesus maps his theme token by token). You've done this with Kanagawa.

## Setups

### herdr

- **[babarot/dotfiles](https://github.com/babarot/dotfiles/tree/6d4b7528bc96312763a3da16a1a1e18ba21abb0f)** (782★). One workspace per worktree, laid out by a [local plugin](https://github.com/babarot/dotfiles/blob/6d4b7528bc96312763a3da16a1a1e18ba21abb0f/nix/home-manager/tools/herdr/worktree-layout.nix) as agent top-left, reviewr top-right, shell below. hunk "review" and "send review to agent" keys; tuicr through its agent skill. `prefix+a` jumps to the notified pane; fzf space switcher with git marks. Carries 10 patches to herdr (toast persistence, mark-as-unread, worktree tokens), so it pays a rebase every release. [Config](https://github.com/babarot/dotfiles/blob/6d4b7528bc96312763a3da16a1a1e18ba21abb0f/home/.config/herdr/config.toml), [workflow doc](https://github.com/babarot/dotfiles/blob/6d4b7528bc96312763a3da16a1a1e18ba21abb0f/docs/concepts/workflow.md).
- **[edmundmiller/dotfiles](https://github.com/edmundmiller/dotfiles/tree/64238f3626b80779bfe24b37b5fc7d89c0490663)** (81★, omp + pi). Declarative [workspace layouts](https://github.com/edmundmiller/dotfiles/blob/64238f3626b80779bfe24b37b5fc7d89c0490663/config/herdr/workspace-manager.yml) for linked worktrees. **Review Box**: pick a PR, get one workspace with hunk, critique, an omp review, and an approve tab that prints `gh` commands but never runs them ([doc](https://github.com/edmundmiller/dotfiles/blob/64238f3626b80779bfe24b37b5fc7d89c0490663/docs/review-box.md)). Issue→worktree keys, command palette + which-key, about 20 plugins pinned in Nix. His [AGENTS.md](https://github.com/edmundmiller/dotfiles/blob/64238f3626b80779bfe24b37b5fc7d89c0490663/config/herdr/AGENTS.md) warns that launcher fallbacks to tmux create nesting loops.
- **[simoncrypta/bercail](https://github.com/simoncrypta/bercail/tree/243f5e135f8bd37161a3576ab34fb36bc4be0a6f)** (7★). An agent environment built on herdr, prefix `ctrl+space`: a sticky agent pane, tuicr opened on the uncommitted diff when the agent is done, a review skill that waits for your comments, beads issues as jobs. The README spells out who owns what (herdr panes, plugin layout, worktrunk worktrees). [Keymap](https://github.com/simoncrypta/bercail/blob/243f5e135f8bd37161a3576ab34fb36bc4be0a6f/config/herdr/config.toml), [layout plugin](https://github.com/simoncrypta/bercail/blob/243f5e135f8bd37161a3576ab34fb36bc4be0a6f/plugins/agentic-layout/herdr-plugin.toml).
- **[lararosekelley/dotfiles](https://github.com/lararosekelley/dotfiles/tree/2c526fb9caac139257998896e424d070442f97d7)** (52★). A Python plugin rebuilds a tmux-style startup layout (shell/agents/editor/git/review/prs/system tabs), because herdr has no startup-layout option. **rehydrate** relaunches pane processes after reboot, which herdr leaves as bare shells except for resumable agents. Uses `vim-herdr-navigation` for `ctrl+hjkl`. [Plugin README](https://github.com/lararosekelley/dotfiles/blob/2c526fb9caac139257998896e424d070442f97d7/content/.config/herdr/local-plugins/default-session/README.md), [config](https://github.com/lararosekelley/dotfiles/blob/2c526fb9caac139257998896e424d070442f97d7/content/.config/herdr/config.toml).
- **[bendrucker/dotfiles](https://github.com/bendrucker/dotfiles/tree/c0477ac6fb33cdabb034b1d3995ee249994c4947)** (9★). Every tool is a herdr plugin under one prefix. Sidebar reporters: [`herdr-agent-state`](https://github.com/bendrucker/dotfiles/blob/c0477ac6fb33cdabb034b1d3995ee249994c4947/herdr/bin/herdr-agent-state) (blocked / done-unseen / stale) and `herdr-workspace-status` (PR and checks). reviewr with send-to-agent; herdr-annotate for non-diff feedback; a [background-agent launcher](https://github.com/bendrucker/dotfiles/blob/c0477ac6fb33cdabb034b1d3995ee249994c4947/bin/claude-launch). CI enforces a startup-time budget for the dotfiles themselves.
- **[aviralmansingka/dotfiles](https://github.com/aviralmansingka/dotfiles/tree/b9925a5567ca7f164b2ce66c0786e82dda3605b0)** (3★). Closest to your flow: gh-dash `C` runs tuicr; `O` runs [`gh-dash-open-pr`](https://github.com/aviralmansingka/dotfiles/blob/b9925a5567ca7f164b2ce66c0786e82dda3605b0/gh-dash/.local/bin/gh-dash-open-pr), which makes a `pr/<N>` herdr worktree. It records ownership in git config (`branch.pr/N.ghDashPr`) and refuses to reuse branches it didn't create. A pi extension (`tuicr_reply`, [PR #246](https://github.com/aviralmansingka/dotfiles/pull/246)) posts the agent's answers back into the tuicr session as `pi-agent`, with an anti-loop guard.
- Also: [GustavoGJesus](https://github.com/GustavoGJesus/dotfiles/tree/efe3f56dc1819bb50255c0bcf2f9e2da116d2a55) (zoxide project picker that starts an agent; Linear issue → worktree); [olimorris](https://github.com/olimorris/dotfiles/blob/869c018bca25d4ad36ed57e8eaeb745c8f684f6d/.config/herdr/config.toml) (macOS-native chords instead of a prefix; sesh, worktrunk); [omarchy](https://github.com/omacom/omarchy/blob/84cfb93959f4fe0bbb71de71593b36647d2ba78d/config/herdr/config.toml) (herdr and tmux configs mirrored key for key under `ctrl+space`).

### tmux

- **[schuettc/dotfiles](https://github.com/schuettc/dotfiles/tree/f08e9d1f5f6020fe93087c9ae5850b310a372f82)** (3★). The most cohesive tmux setup. One identity (`<project>/<work>`) for session, window title, and agent `--name`. Claude hooks ring the bell in the exact pane by walking process ancestry, because hooks run without `$TMUX` ([claude-notify.sh](https://github.com/schuettc/dotfiles/blob/f08e9d1f5f6020fe93087c9ae5850b310a372f82/config/claude/claude-notify.sh)). A status-line banner lists sessions that need you. An agent message bus nudges idle agents. A read-only pi [reviewer subagent](https://github.com/schuettc/dotfiles/blob/f08e9d1f5f6020fe93087c9ae5850b310a372f82/config/pi/agents/reviewer.md).
- **[raine/workmux](https://github.com/raine/workmux/tree/dba84b18ac98b9fb6717e94563bb218cf91cc4e6)** (2,836★; a tool, not dotfiles). Worktree per task with a mux window each; detects omp and pi among others. A dashboard popup with agent status and preview, diff view with hunk staging, typing into the selected agent, PR and checks status. `workmux add --pr <n>` does what `review-worktree` does. If you ever move to tmux, this is the piece that replaces most of what herdr gives you.
- **[joshmedeski/dotfiles](https://github.com/joshmedeski/dotfiles/tree/51df80b13e0682519d1baec7c7314c9869f2a94d)** (467★). One key per tool as named tmux windows (lazygit, gh-dash, dev, build, ai); `sesh` for sessions; a per-repo gh-dash config wrapper ([`ghd`](https://github.com/joshmedeski/dotfiles/blob/51df80b13e0682519d1baec7c7314c9869f2a94d/.config/bin/ghd)); `gh-watch-action`; worktree scripts. Strong keymap discipline, but no agent awareness.
- **[Veraticus/nix-config](https://github.com/Veraticus/nix-config/tree/4c359f7e422ba22dd27bf5cf59c67230fd5c7b26)** (837★). One `DEV_CONTEXT` variable read by every surface; agent attention pushed to the phone via ntfy with priorities; the tmux server as a systemd unit so config switches don't kill live work ([reaper](https://github.com/Veraticus/nix-config/blob/4c359f7e422ba22dd27bf5cf59c67230fd5c7b26/home-manager/tmux/scripts/tmux-orphan-reaper.sh)).
- **[martintrojer/dotfiles](https://github.com/martintrojer/dotfiles/tree/cd119f55e52c357c7dc7914c71a211ef604423e5)** (3★). Evaluated herdr three times and stayed on tmux. Recorded in [`docs/DECISIONS.md`](https://github.com/martintrojer/dotfiles/blob/cd119f55e52c357c7dc7914c71a211ef604423e5/docs/DECISIONS.md) § Agent state awareness and [`herdr/README.md`](https://github.com/martintrojer/dotfiles/blob/cd119f55e52c357c7dc7914c71a211ef604423e5/herdr/README.md):
  - Kept herdr's state vocabulary (working/blocked/done/crashed, done = unseen), ported to tmux.
  - Rejected the always-on sidebar. He measured it at 4 columns, about 1.5% of width; what bothered him is that it's fixed to the left edge.
  - Other objections: v0.x with one maintainer, and pre-1.0 protocol bumps that stop old clients attaching. The AGPL objection is stale; his README notes herdr is now Apache 2.0.
  - Reconsider if a 4–6-agent fleet makes the panel pay for itself.
  - Built `murmur` for agent state across machines, which herdr's single-target `--remote` didn't cover at 0.8.2.
- **[obra/dotfiles](https://github.com/obra/dotfiles/tree/df3be5633e1528b731efd1face8c1677a2850801)** (117★, tmux + zellij). Review runs as a daemon: [roborev](https://github.com/kenn-io/roborev) reviews every commit with agent panels. Skills fetch the findings as JSON, fix them, and close each with a recorded comment. Also: a [`coderabbit-extract`](https://github.com/obra/dotfiles/blob/df3be5633e1528b731efd1face8c1677a2850801/bin/coderabbit-extract) that turns bot review threads into agent context, and `/par` for adversarial self-review.
- **[pabloimrik17/dotfiles](https://github.com/pabloimrik17/dotfiles/tree/763509170817a2d4efafe1c1f7bed09a6cf7728d)** (9★). gh-dash `z`/`Z` open tuicr inline or in a tmux popup. lazygit `V` runs `tuicr -w`. A [tuicr config](https://github.com/pabloimrik17/dotfiles/blob/763509170817a2d4efafe1c1f7bed09a6cf7728d/dot_config/tuicr/config.toml) whose comment types and export intro tell agents how to treat each type. A house rule: never shadow a built-in key.

### zellij

Thin. No dotfiles found that put a review tool beside an agent in zellij; the zellij agent work lives in WASM plugins rather than in people's configs.

- **[roeeyn/dotfiles](https://github.com/roeeyn/dotfiles/tree/4c730a23a37220f3bdff02f5eb0c5800fbc20170)**. A review task in a daily note opens a named zellij tab running Claude with a review prompt ([review.lua](https://github.com/roeeyn/dotfiles/blob/4c730a23a37220f3bdff02f5eb0c5800fbc20170/dot/.config/bujo-nvim/lua/bujo/review.lua)). The script only ever creates tabs, because most `zellij action` verbs act on the focused tab, not a named one. Uses the zj-radar status rail.
- **[rollecode/dotfiles](https://github.com/rollecode/dotfiles/tree/ba5f22e04e48758a26878a85d919104158a48aca)**. Locked-by-default with a tmux-style prefix. Claude hooks drive zellij-attention tab badges through a 10-line `zellij pipe` shim. A destructive-command guard hook.
- **[Yazelix Nova](https://github.com/Yazelix/nova/tree/fc23b86f57bdf7b4596700015214f299e0ddc4cd)** (formerly yazelix, ~1.1k★). A Nix-built zellij distribution that forks zellij. Its [agent-status comparison](https://github.com/Yazelix/nova/blob/fc23b86f57bdf7b4596700015214f299e0ddc4cd/docs/agent-status-references.md) is the best survey of herdr against the zellij agent plugins.
- **zellij limits people documented:**
  - Pane titles don't reliably reach plugins.
  - Plugin host calls block the server thread; polling 30 agent panes produced tens of thousands of timeouts.
  - `zellij pipe` blocks until every plugin instance consumes the message.
  - Claude Code Agent Teams needs a fake `tmux` shim on zellij.
  - `Ctrl g` collides with Claude and opencode.

## Leaving herdr: the evidence

| Repo | Commit | Stated reason |
|---|---|---|
| ljj727/dotfiles | [`445dde04`](https://github.com/ljj727/dotfiles/commit/445dde04ba350deb20be7973c7a302fef97e92a5) | Tried herdr 0.8.2, judged Ghostty + tmux better (no specifics) |
| mikedelafuente/dotfiles-linux | `9e422c2b` | Calls herdr "proprietary" (it is Apache 2.0). The herdr launcher needed waits for pane geometry before starting nvim; the tmux version is a quarter of the size |
| asarchami/dotfiles | [`5e776db1`](https://github.com/asarchami/dotfiles/commit/5e776db1467d6ff41b8ccab171f63e683d0d4586) | "herdr didn't work out in practice" |
| polo871209/dotfiles | [`cc00e2c1`](https://github.com/polo871209/dotfiles/commit/cc00e2c109c7779dbe8d354a7965f7097470a861) | Moved agent subprocess panes back to tmux |
| lohanidamodar/gitpod-dotfiles | [`f11e5240`](https://github.com/lohanidamodar/gitpod-dotfiles/commit/f11e5240074206e959a9d12a642add47c32438f7) | Kept tmux as default, herdr opt-in |
| jakeryderv/.dots | `ba7f7d91` | Stopped nesting herdr in tmux: runs them side by side to keep mouse, scrollback, and prefix intact |

All of these are from herdr 0.8.x, July–September 2026. herdr has had several releases since (you're on 0.9.4).

## Gaps

- No dotfiles found with a terminal Jira client (jira-cli, jiratui) wired into a multiplexer, or using lnav, posting/atac, lazysql/harlequin, overseer.nvim, act, or the AWS TUIs. Recommendations for those rest on the tools' own docs.
- No nvim review plugin (octo, codecompanion, avante, sidekick) found sending review comments into an agent pane; only feature requests.
- No dotfiles found that migrated from zellij to herdr with a commit-level reason (one blog, tesar.tech, lists where zellij still wins: persistent floating panes, keyboard tab moving, rerun prompts on restore).
- Code search was unavailable to the researchers, so setups configured without README or topic mentions are missing. Stars are a poor signal here: the richest agent-integrated setups found have under 10 stars.
