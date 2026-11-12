---
name: ian-hunk-self-review
description: Present agent-generated code (spec, plan and implementation gates, and the agent's own PRs) to Ian for review in a live Hunk session beside the worker, with the authoring agent annotating the key areas as Hunk agent notes, then collect his notes and act on them. Use whenever an agent's own work is ready for Ian's review. Not for other people's PRs, which Ian reviews in tuicr (`tuicr` skill, `review-worktree`).
---

# Ian's review of agent-generated code, in Hunk

Hunk is the review surface for code an agent wrote for Ian. tuicr is only for reviewing other people's code.

Read `hunk-review` (session commands) and `herdr` (panes) first. Hunk TUIs belong to Ian: never run `hunk diff` or `hunk gh` in your own shell; start them in a pane he can see.

## 1. Open Hunk beside the worker

Split a pane to the right of the worker that wrote the code, in that worker's worktree:

```bash
pane=$(herdr pane split --pane <worker pane> --direction right --cwd <worktree> --no-focus | jq -r .result.pane.pane_id)
```

Then load what is under review:

| Under review | Command in the pane |
|---|---|
| A gate on the task branch (spec, plan, a step), no PR yet | `hunk diff $(git merge-base origin/<base> HEAD) HEAD` |
| The agent's own pushed PR | `GH_TOKEN="$(gh auth token)" hunk gh pr <n> --repo <owner/repo>` |

```bash
herdr pane run "$pane" '<command>'
```

For a live PR, always review the PR itself (`hunk gh pr`), not a local range. If GitHub has not caught up with a push yet, say so and wait.

Find the session with `hunk session list --json`: for a PR, the one whose `review.url` ends in `/pull/<n>`; for a gate, the one whose repo is the worktree. Record the session id and pane id with the task so later turns can reach them.

## 2. Annotate the key areas

The agent that made the change (the worker, not a supervisor relaying for it) annotates the key areas with Hunk agent notes before Ian starts, because it knows why each part is the way it is. A supervisor that opened the pane hands the worker the session id and asks it to annotate.

Send all notes as one batch, with `--focus` so agent notes are visible and his view lands on the first one:

```bash
printf '%s\n' '{"comments":[
  {"filePath":"src/access/roles.ts","newLine":12,"summary":"Single source of truth for role checks; every collection gate below calls these.","author":"<worker>"},
  {"filePath":"SPEC.md","newLine":99,"summary":"Decision needed: should analysts keep user export?","rationale":"Analysts handle import/export today.","author":"<worker>"}
]}' | hunk session comment apply <sid> --stdin --focus --json
```

What to annotate:

- where to start reading, and the order that tells the story
- the decisions and trade-offs, with the alternative that was rejected
- risky or subtle code: security and access checks, migrations, concurrency, anything that is easy to get wrong
- each open question or decision Ian must make, anchored where it applies (for a spec, at the relevant section)
- deliberate omissions or out-of-scope items he might otherwise flag

Keep notes few and specific: intent, risk, or a question, not a restatement of the diff. Anchor each on a changed line (`newLine`) or a hunk; for a PR, every anchor must be inside the PR's diff. Never pre-answer his review or mark anything approved. Re-annotate only what changed after a reload, replying to the earlier note rather than duplicating it.

Then tell Ian in chat what is up for review, where the pane is, and what decision you need, with the PR's full URL when there is one.

## 3. Collect Ian's notes

Ian leaves notes with `c` and replies to agent notes with `R`. When he says he is done (in chat, or in the worker's pane), read them:

```bash
hunk session comment list <sid> --type user --json
hunk session comment list <sid> --type all --json   # when replies to agent notes matter
```

His notes are direct instructions for the work under review. Hand them to the worker that owns it, with file and line, exactly as he wrote them. A supervisor relays them through its normal steering channel, not by typing into the worker's pane. A note that asks a question gets an answer, not a code change.

## 4. Close the loop in Hunk

After the worker addresses the notes:

1. Reply to each of Ian's notes with what changed or the answer: `hunk session comment add <sid> --reply-to <noteId> --summary "<what changed>" --author "<worker>"`.
2. Reload so Ian sees the new code: `hunk session reload <sid> -- diff $(git merge-base origin/<base> HEAD) HEAD`. For a PR, reload once GitHub shows the new head.
3. Tell Ian it is ready for another pass, or that the gate is approved and work continues.

Reloading drops highlights on files that changed, and closing the pane ends the session and its notes. Collect before anything closes.

## 5. Clean up

Close the pane when the task is cleaned up, or when Ian says he is finished with it. Never close it while his notes are uncollected.

## What stays the same

- No reviewer is requested or assigned on the PR until Ian has signed off on its diff in Hunk.
- Comments posted to GitHub follow `ian-reviewer`'s voice and are shown to Ian for approval before posting. Hunk notes are not posted to GitHub unless he asks.
