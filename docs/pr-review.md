# PR and agent-authored review

Current simplified trial: stock herdr-pickr for PR/MR links and
jhochenbaum/herdr-hunk-diff for agent-authored changes. The former custom
worktree-layout and PR-agent workflow was removed and remains available in
Git history.

## GitHub and GitLab links

Ctrl+click a PR or MR link in Herdr, then choose:

- `t`: full review in tuicr, including submission to the forge.
- `h`: quick read-only diff in Hunk.
- `d`: plain diff in bat.
- `o`: browser.

In gh-dash, `t` opens the selected PR in tuicr. The old custom `T` and `S`
agent actions are archived and no longer bound.

## Agent-authored changes

Focus the agent or worktree pane, then use:

- `prefix+shift+h`: review changes in Hunk.
- `prefix+shift+a`: review staged changes.
- `prefix+shift+s`: send unsent inline comments to the associated agent.

Hunk follows tracked file edits, shows agent notes immediately, and keeps sent
comments visible for inline replies. Untracked files are excluded. Open these
reviews on demand; there is no automatic worktree layout or review-on-idle hook.
