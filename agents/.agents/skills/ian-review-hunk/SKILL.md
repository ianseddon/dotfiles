---
name: ian-review-hunk
description: Draft GitHub PR reviews in Ian's voice and let him curate them in a live Hunk session before posting. Use when Ian asks to review PRs "in hunk", to run ian reviews he can curate, or to post curated hunk reviews.
---

# Ian review, curated in Hunk

Subagents draft reviews with the `ian-reviewer` skill. Ian curates each draft in a Hunk tab. The agent posts the result to GitHub only when Ian says to.

Read `ian-reviewer` (voice and review procedure) and `hunk-review` (`hunk skill path`, session commands) before starting.

## The two kinds of notes

Hunk separates notes by source, and this workflow depends on it:

| source | how it gets there | what it holds here | Ian can |
|---|---|---|---|
| `ai` | `--agent-context` sidecar at launch | context: dropped and folded candidates with their reasons | read only (not reply targets) |
| `agent` | `hunk session comment apply` | drafts meant for posting | `R` reply, `D` delete (reply-free) |
| `user` | Ian presses `c` | his own comments | `E` edit, `D` delete |

Agent notes aren't editable in the TUI (`editable: false`), so Ian changes a draft by replying to it.

## Conventions Ian uses

- **reply starting with `=`**: post the rest of the reply verbatim instead of the draft
- **any other reply**: an instruction for the draft ("shorter", "drop the second sentence"). "nice", "keep", "lgtm" and similar mean keep it as is
- **his own note starting with `=`**: post the rest verbatim at that line
- **his own note without `=`**: draft a comment in Ian's voice from it, at that line. A note on a dropped context line usually means "promote this"
- **deleted draft**: don't post it
- the latest reply on a draft wins

## Storage

Keep everything under `~/.cache/ian-reviews/<owner>-<repo>-<n>/`. Never use `/tmp`; other agents clear it.

- `draft.json`: the subagent's draft (below)
- `context.json`: the Hunk sidecar

## 1. Draft

One subagent per PR, following `ian-reviewer`'s procedure: read the whole diff, collect candidates, pick the through line, up to five comments. Draft only, no GitHub writes. It writes `draft.json`:

```json
{
  "repo": "owner/repo",
  "number": 123,
  "head": "<sha>",
  "event": "approve | comment | request_changes",
  "through_line": "one sentence",
  "comments": [{ "path": "src/a.ts", "line": 42, "body": "..." }],
  "context": [{ "kind": "dropped | folded", "path": "src/b.ts", "line": 10, "body": "dropped: ... (reason)" }],
  "notes": ["stacked on #467", "conflicts with main"]
}
```

- every `line` is on the RIGHT side and inside a hunk of `git diff $(git merge-base origin/<base> <head>) <head>`. GitHub rejects inline comments on unchanged lines, so move a comment to the nearest changed line rather than drop it
- `context.line` is `null` when the candidate has no changed line to sit on
- bodies are plain text: no markdown quote markers, no em dashes

## 2. Open the Hunk tab

Build `context.json` from `draft.json`:

```json
{
  "version": 1,
  "summary": "<through line>",
  "files": [
    { "path": "src/b.ts", "annotations": [{ "newRange": [10, 10], "summary": "dropped: ...", "author": "ian-reviewer · dropped" }] }
  ]
}
```

Only anchored context goes in `files`. The top-level `summary` doesn't show on Hunk's first screen, so anything that matters goes in chat too.

Open a tab Ian can see in his herdr workspace (`herdr` skill), then start Hunk in its pane:

```bash
pane=$(herdr tab create --workspace "$HERDR_WORKSPACE_ID" --label "ian review #<n>" --no-focus | jq -r .result.root_pane.pane_id)
herdr pane run "$pane" 'GH_TOKEN="$(gh auth token)" hunk gh pr <n> --repo <owner/repo> -- --agent-context ~/.cache/ian-reviews/<dir>/context.json'
```

`GH_TOKEN` is required for private repos. Find the session with `hunk session list --json`: it's the one whose `review.url` ends in `/pull/<n>`. Match on that, not `--repo`, since several tabs can share a repo.

## 3. Push the drafts

```bash
hunk session comment apply <session-id> --stdin --focus --json
```

with `{"comments":[{"filePath": ..., "newLine": ..., "summary": <body>, "author": "ian-reviewer · draft"}]}`. Only the comments go in Hunk. The review body stays out of the diff: it connects the comments, so it's written after curation.

Then tell Ian in chat, per PR: the through line, the proposed event, unanchored context and `notes`, and a one-line key reminder (`R` reply, `=` for verbatim, `D` drop, `c` add).

## 4. Collect

When Ian says he's done (or says "post"), read everything:

```bash
hunk session comment list <session-id> --type all --json
```

Build the final comment set with the conventions above:

- agent draft, no replies: keep
- agent draft, latest reply `=...`: use the reply text
- agent draft, latest reply is an instruction: rewrite in Ian's voice, or keep for "nice"/"keep"
- user root note: `=...` verbatim, otherwise draft from it
- missing agent drafts were deleted: skip them

For every rewrite or drafted note, add the new text back into Hunk as an agent reply on that thread (`comment add <sid> --reply-to <noteId> --summary <text> --author "ian-reviewer · rewrite"`), so Ian sees exactly what will post. A later `=` or instruction reply from Ian supersedes it.

Then write the review body per `ian-reviewer`'s rules, from the comments that survived: one sentence naming what connects them, or the minimal approve line if none survived. Put the body and event in chat.

## 5. Post when Ian says

Only on Ian's explicit go-ahead. No preview step beyond what's already in Hunk and chat.

1. re-check the head: `gh pr view <n> --json headRefOid`. If it moved, say so and re-anchor before posting
2. re-check every line is inside a diff hunk at the head
3. `POST repos/<owner>/<repo>/pulls/<n>/reviews` with `commit_id`, `event`, `body`, and `comments: [{path, line, side: "RIGHT", body}]`
4. confirm the review's comment count matches (`GET .../reviews/<id>/comments`)

Report the review URL. Leave the tab open; Ian closes it. Closing a tab ends the session and its notes, so collect before anything closes.

## Pitfalls

- hunk TUIs belong to Ian: never run `hunk diff`/`hunk gh` in your own shell for him to see; open a herdr tab
- don't post the drafts' sidecar context; it's context
- a draft parser must strip markdown (`> ` quote markers) before notes go into Hunk
- with several PRs, run the drafting subagents in parallel and open each tab as soon as its draft is ready
