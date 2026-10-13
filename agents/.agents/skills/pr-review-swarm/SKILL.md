---
name: pr-review-swarm
description: Review and converge one GitHub pull request with a cheap-first OMP router, narrowly delegated specialist review, exhaustive thread triage, verified autonomous fixes, and a final queue containing only human decisions. Use when asked to swarm-review a PR, address all PR feedback, triage review threads, shepherd a PR through review, or keep fixing a PR until autonomous review work is exhausted. Accepts one PR number or URL.
---

# PR Review Swarm

Converge one GitHub pull request. Use a cheap router for every review pass, delegate only dangerous or uncertain scopes, account for every finding and review thread, fix clear actionable feedback, settle bot nits, and repeat on the delta until the autonomous queue is empty.

Genuine design choices remain open and are consolidated for the user. Human-participated threads may remain open solely for the PR author to reply or resolve; addressed human threads are not autonomous work.

## Interface

Input is exactly one open GitHub PR, as a number or URL. If no argument is supplied, resolve the PR for the current branch. Never fall back to reviewing an unassociated branch diff. If zero or multiple PRs match, ask for one exact PR.

Operate in the dedicated worktree returned by the GitHub `pr_checkout` operation. If that cannot fetch the PR head, fetch `pull/<number>/head` and create a detached worktree elsewhere. Never switch, stash, reset, or edit the user's live working tree.

Record PR URL, owner/repo, base branch and SHA, head branch and SHA, worktree path, state, draft status, and changed files. Use `pr://` reads for metadata and diffs, the GitHub device for checkout, push, and Actions watching, and `gh api graphql` only for review-thread operations the GitHub device does not expose.

GitHub is the source of truth. Each round begins from a fresh remote HEAD and thread snapshot.

## Autonomy and GitHub boundary

- Reviewer and router agents are read-only. The orchestrator alone edits, verifies, commits, pushes, comments, and resolves threads.
- Apply clear, localized actionable fixes from swarm, bot, or human sources.
- Batch all fixes for one round into one verified atomic commit. Follow repository commit rules; absent a rule, use `fix: address review findings`.
- Push normally through `pr_push`. Never force-push.
- Resolve addressed all-bot threads and all-bot nits silently after the relevant verification or push.
- A thread with any human participation stays open. Never reply to it or resolve it. A clear actionable human finding may still be fixed and pushed; list its commit SHA for the user to cite in their own reply.
- Post validated, non-nit swarm findings as bot-labeled inline comments, upsert one bot-labeled summary, and never submit `APPROVE` or `REQUEST_CHANGES` as the user's review decision.
- Never post secrets, credentials, private operational data, or absolute production metrics from a public repository.

Every GitHub body this skill creates starts with:

```markdown
> [!NOTE]
> Automated by **PR Review Swarm**. This is not a human-authored review.
```

## Model routing

Use OMP roles rather than concrete model IDs in the skill:

- `review-router` starts with `@flash`, then falls back to `@mid`, then `@smol`, then `@task`.
- `reviewer` uses `@slow` for delegated subtle correctness and architecture.
- `security-reviewer` uses its discovered routing.
- `designer` uses `@designer`.
- conditional `task` and installed specialists use their discovered routing, normally `@task`.
- the Ian lens uses a read-only `task` after loading `skill://ian-reviewer`.

The `@flash` role is mapped to GLM 5.3 Flash via OpenRouter and is the cheap-first router default. The general `@mid` role is mapped to GPT-5.6 Terra and remains the router's first fallback. The `@smol` role remains GPT-5.6 Luna for scouts and lightweight tasks. Model configuration remains centralized in `~/.omp/agent/config.yml`. At runtime record the actual model used for every agent. Never rewrite model configuration during a PR run.

If `review-router` is unavailable, run one `reviewer` against the exact initial or delta scope. Do not fall back to the old fixed full panel. Missing specialists fall back to `reviewer` with the same narrow lens. If `ian-reviewer` is unavailable, record the coverage gap instead of inventing Ian's persona.

## Persistent run state

Maintain across rounds:

- `base_sha`
- `current_head_sha`
- `last_reviewed_sha`
- `last_strong_review_sha`
- `router_rounds`
- `strong_rounds`
- `initial_ian_review_complete`
- candidate ledger and root-cause fingerprints
- deferred ambiguous thread IDs
- latest external-review activity timestamp

Round budgets:

- maximum five cheap router and triage rounds
- maximum three strong-review rounds
- the initial routed delegation batch counts as one strong round when any strong agent runs
- a router-only round does not consume the strong budget

## Candidate ledger

Normalize every router finding, delegated finding, CI failure, and review thread into a candidate with:

- stable source ID
- source type and author
- source thread ID, when present
- all thread participants
- path and diff line, or `general`
- title, evidence, impact, confidence, and proposed outcome
- root-cause cluster ID and stable fingerprint
- classification: `actionable`, `nit`, or `ambiguous`
- ownership: `all-bot`, `human-participated`, or `swarm`
- status: `pending`, `fixed`, `resolved`, `human-follow-up`, or `deferred`
- verification command or observed scenario
- commit SHA, when fixed
- disposition reason

Deduplication merges root causes, not source records. Preserve every source ID so counts reconcile.

The fingerprint is derived from repository identity, normalized path, nearest stable symbol or module, and normalized root cause. Exclude HEAD SHA, line numbers, severity, reviewer names, and wording so it survives pushes and line drift.

## Classification

Classify every candidate before mutating code or GitHub.

### Actionable

All must hold:

- evidence-backed and introduced or exposed by the PR
- one materially correct expected outcome
- concrete fix localized to one file or a small, tightly related set
- no new product, architecture, schema, migration, dependency, compatibility, or scope decision
- relevant verification can prove the result

Severity does not override ambiguity.

### Nit

Behavior is correct and merge-safe. Includes preference, low-value cleanup, speculative concern, duplicate, already-fixed, not-introduced, and disproved feedback. Record a precise reason code.

### Ambiguous

Use when reasonable outcomes compete, evidence is insufficient, scope is broad, a durable contract may change, verification cannot establish safety, reviewers disagree, permissions block delivery, or a fix fails to converge. State the decision, evidence, recommendation, and alternatives.

Ambiguous candidates never stop or restart the loop by themselves. Leave their threads unresolved, mark them deferred once, and continue exhausting autonomous work.

## Workflow

### 1. Refresh and inventory

Read repository instructions, manifests, CI configuration, changed-file ownership, and relevant domain docs. Fetch every review-thread page, but initially keep only:

- thread ID and resolved/outdated state
- path and line
- all participant identities and automation markers
- first 1500 characters of each comment
- comment creation and update times

Fetch a full comment body only immediately before fixing it or when ambiguity depends on omitted text.

Account for resolved and outdated threads as terminal records. Active work is every unresolved, non-outdated thread. Unknown participants are human.

A comment is automated when its GitHub author type is `Bot`, its login ends in `[bot]` or matches a known review bot, or its body carries an explicit automated-comment marker. Any real human participant makes the entire thread human-participated.

### 2. Choose initial or delta mode

On the first round:

- mode is `initial`
- scope is `base_sha..current_head_sha`
- router receives the full changed-file list and diff

After a reviewed HEAD changes:

- mode is `delta`
- scope is `last_reviewed_sha..current_head_sha`
- router receives only the delta, affected interface consumers, compact prior cluster summaries, and new thread heads

Classify the delta before routing:

- docs, generated files, comments, or whitespace only: skip code review; triage threads only
- test only: router examines whether assertions can falsely pass; delegate only if uncertain
- localized implementation: router plus exact affected consumers
- public contract, durable data, migration, auth, identity, concurrency, or cross-module change: router may request strong specialists
- thread-only activity: triage it; never launch a full panel solely because a bot commented

Never reread the cumulative PR in an intermediate round unless the router identifies an unscopable cross-cutting contract.

### 3. Run the cheap router

Dispatch one `review-router` agent with mode, exact scope, repository path, repository rules, changed files, SHAs, prior fingerprints, and compact active-thread summaries.

The router:

- performs its own first-pass review
- returns findings, danger, confidence, and coverage
- requests at most four narrowly scoped delegations
- sets whether the Ian lens is relevant to this delta
- sets whether final strong confirmation will be needed

Low danger plus high confidence with no delegations is the intended cheap path. Do not add reviewers for panel symmetry.

Increment `router_rounds`. Once review and triage for the current HEAD are complete, set `last_reviewed_sha = current_head_sha`.

### 4. Delegate only requested scopes

Run independent delegations in one `task` batch. Each receives only its requested files, functions, or hunks plus enough surrounding interface context. Reviewers never see each other's outputs.

Possible targets:

- `reviewer`: subtle correctness, architecture, test validity, or cross-module contracts
- `security-reviewer`: auth, tenant, secret, attacker-controlled flow, or dangerous sink
- `designer`: changed interaction or accessibility behavior
- `performance-optimizer`: demonstrated hot path, rendering, cache, query, bundle, or high-volume loop
- `ai-architect`: model, prompt, tool, agent, streaming, structured-output, or MCP behavior
- `deployment-expert`: Vercel deployment, runtime, routing, environment, domain, or CI behavior
- `task`: another domain specialist after loading its matching installed skill

Run Ian reviewer once on the initial substantive PR diff. On later deltas, run it only when the router sets `needs_ian_review` because abstraction, organization, naming, coupling, or expressive types materially changed. Mechanical fixes do not rerun Ian reviewer.

Strong agents report evidence, trigger, impact, confidence, path, and a changed line. Increment `strong_rounds` once per round containing any strong delegation and update `last_strong_review_sha`.

### 5. Synthesize and post new findings

Normalize router and delegated outputs into the ledger. Validate each candidate against current code and repository conventions. Cluster duplicates while preserving provenance. For disagreement, run the smallest decisive read-only experiment; unresolved disagreement is ambiguous, not a vote.

Post only validated non-nit findings:

- batch diff-anchored findings into one `COMMENT` review
- put general findings in the sticky summary
- include `<!-- pr-review-swarm-finding:<fingerprint> -->` in every inline body
- search every existing inline comment for that fingerprint before posting
- if it exists, attach current evidence to the existing ledger cluster and sticky summary without creating another thread
- include converging reviewer names

An exceptional Ian affirmation may appear only in the reviewer or sticky summary and never creates an inline thread. Omit the section entirely when there is none.

### 6. Triage threads cheaply

Apply deterministic rules before model reasoning:

- resolved or outdated: terminal
- known fingerprint: attach to existing cluster
- stale comment tied to an older SHA: mark stale unless current code still proves it
- human participation: human-follow-up or ambiguous; never auto-resolve
- bot duplicate, already-fixed, disproved, or preference: nit
- concrete localized bot finding with one safe fix: actionable

Batch all remaining uncertain all-bot threads into one router call with their body heads and affected hunks. Do not create one model call per thread. The router returns a classification and reason for each source ID.

Escalate a thread to a strong reviewer only when it is high impact and still ambiguous after the batched router pass. Strong review is never needed merely to resolve a nit.

For all-bot threads:

- actionable: fix, verify, push, then resolve silently
- nit: resolve silently and record reason
- ambiguous: leave unresolved and defer

For human-participated threads:

- actionable: fix, verify, and push, but leave open without reply
- nit: leave open as human follow-up
- ambiguous: leave open and defer

### 7. Fix and verify one batch

The orchestrator applies every clear fix for the round. Before changing an exported symbol, use LSP references and migrate every affected caller. Fix the source, reuse existing patterns, and exclude unrelated worktree changes.

Verify each fix through the narrowest observable route that proves it: reproduced behavior, existing changed-contract test, real UI, API, CLI, TUI, or migration surface. Run targeted formatter, typecheck, lint, and tests for affected scope when those checks exist. Add a test only for an uncovered changed contract or reproduced regression.

If a fix reveals a decision or cannot be proved safe, reclassify it as ambiguous. Never leave a pending actionable candidate.

### 8. Commit, push, and overlap settling work

After the batch passes targeted verification:

1. confirm remote HEAD still equals the round input SHA
2. review the intended commit file set
3. create one atomic commit
4. push without force
5. record the new remote SHA on fixed entries

Immediately after push, run these concurrently:

- required GitHub Actions watch for the pushed HEAD
- detectable review-bot checks
- inventory and cheap router review of `last_reviewed_sha..new_head_sha`

Do not wait for CI before starting delta inventory. When required checks and detectable bots settle, refetch threads once and triage newly arrived feedback.

Use the repository's documented timeout for detectable bot checks; otherwise use 15 minutes. Do not wait for an invisible bot with no check or activity signal. After checks become terminal, use a two-minute review-activity quiescence window, then proceed.

A failed required check becomes a candidate. Fix a clear PR-caused failure; defer infrastructure or ownership uncertainty as ambiguous.

If push permission is unavailable, preserve the verified local commit, flag the exact failure as ambiguous, and continue read-only work.

### 9. Final strong confirmation

Do not run a fixed final panel.

Run one final scoped `reviewer` only when the router set `needs_final_strong_review`, initial danger was high or critical, a P0/P1 finding was fixed, a durable/public contract changed, or router confidence is low. Scope it to dangerous deltas and affected interfaces. Review the full cumulative PR only when the concern genuinely cannot be scoped.

Run Ian reviewer at final confirmation only if design-relevant changes occurred after its last pass.

If the final reviewer finds a new actionable issue, it enters the normal delta loop. If the strong-round budget is exhausted, defer remaining concerns as ambiguous with reason `strong-round-backstop`.

### 10. Continue or finish

Start another cheap round when:

- a new actionable candidate exists
- an all-bot nit remains unresolved
- a required check has a clear PR-caused failure
- remote HEAD changed with a substantive delta
- new review feedback arrived

Do not restart code review for docs-only, formatting-only, or thread-only activity.

At five cheap rounds, never start a sixth. Convert work requiring another fix cycle to ambiguous with reason `iteration-backstop`.

A repeated identical HEAD, source set, and disposition snapshot is an earlier no-progress backstop. Convert the blocked concern to ambiguous with reason `no-progress` and finish remaining autonomous work.

## Sticky summary

Maintain exactly one top-level comment containing `<!-- pr-review-swarm-summary -->`. Update it in place after each round. Include:

- current HEAD, router round, and strong round counts
- router danger, confidence, coverage, and actual model
- delegated agents, actual models, scopes, and reasons
- required-check and detectable-bot state
- candidate totals reconciled by classification and status
- fixes and verification with commit SHAs
- bot nits resolved with reasons
- convergent findings
- an Ian reviewer affirmation only when non-empty
- ambiguous decisions
- human follow-ups
- compact prior-round history

Do not create per-round summary comments.

## Completion gate

Finish only when all hold for current remote HEAD:

- cheap router or explicit mechanical-delta skip completed
- every active thread and fresh finding is in the ledger
- every actionable candidate is fixed and verified or reclassified ambiguous
- every all-bot nit and verified all-bot actionable thread is resolved
- required checks are green or a non-actionable failure is ambiguous
- detectable review bots settled and their latest feedback was triaged
- any required final strong confirmation completed
- no validated finding remains unposted
- counts reconcile with no pending status

End with a concise local report. Put ambiguous decisions first with recommendation and alternatives, then human follow-ups. State final HEAD, checks, commits, resolved bot threads, router rounds, strong rounds, actual models, and verification evidence.

Do not ask about ambiguous items until the autonomous queue is empty.

## Graceful degradation

- `@flash` unavailable or exhausted: router agent falls back to `@mid`, then `@smol`, then `@task`.
- Router agent unavailable: one scoped `reviewer` covers the initial or delta input.
- Specialist unavailable: one scoped `reviewer` uses that lens.
- GitHub comment permission unavailable: continue review, fixes, and local reporting; flag the write failure ambiguous.
- Actions unavailable: run repository checks locally and flag the missing remote signal.
- PR closed or merged: stop without mutation and report state.
- User interruption: stop at the next safe boundary, preserve ledger state, and report remaining statuses.