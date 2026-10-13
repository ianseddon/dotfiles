# Agent personas in OMP

Evidence review of the custom task-agent ("persona") configuration, and what to add, change, or delete. Harness version at time of writing: `omp 18.2.4`; measurements taken 2026-09-17 over all sessions from 2026-08-07 through 2026-09-17.

For the general question - when to use a persona at all versus a skill, rule, hook, permission, or code-orchestrated fan-out, and which setups are common in practice - see [Choosing agent configuration mechanisms](./agent-configuration-approaches.md).

## Recommendation

Keep the persona layer small and mechanical. It buys tool scoping, model routing, turnaround shape, and a stable name to dispatch; it does not buy expertise, and the harness's own direction is to put expertise in skills. Concretely:

1. **Change** `review-router`: its `delegations.agent` enum and its delegation prose name four agents that no longer resolve (`designer`, `performance-optimizer`, `ai-architect`, `deployment-expert`). Replace with `reviewer`, `security-reviewer`, `ian-reviewer`, `task`.
2. **Add** `ian-reviewer` as a persona: 24 spawns already invoke the Ian lens, but 23 of them do it by hand-writing "read `skill://ian-reviewer`, then review..." into a generic `task` spawn; only 1 used an agent of that name. The persona makes it one dispatch (`autoloadSkills: [ian-reviewer]`), read-only tools, `@slow`.
3. **Add** `researcher` as a persona: the bundled `librarian` that carried this job was removed upstream (18.1.9) after 15 spawns, research-shaped dispatches continue (12 recorded `scout` spawns), and the local `research` skill still instructs the caller to delegate without being able to define the delegate. Persona = read-only web tools + `autoloadSkills: [research]` + a sources schema.
4. **Change** the `pr-review-swarm` skill's model-routing and delegation lists (lines ~47 and ~190-195) to the same roster, and drop the `designer` row.
5. **Delete** `modelRoles.designer` from `~/.omp/agent/config.yml`: the `designer` subagent and role were removed in 18.1.5, so nothing consumes it.
6. **Decide** on `task.enableLsp`: `review-router` and the bundled `reviewer`/`security-reviewer` all declare `lsp` and the global gate is off, so that capability is inert (0 of 513 subagent transcripts ever ran an `lsp` call; verified to appear once the setting is on). Either enable it for review personas or stop declaring `lsp`.
7. **Track** `agents/.omp/agent/agents/` in git, or stop deploying the persona through a symlink into an untracked directory - skills are tracked, this is not, so a fresh checkout loses the only persona.

Do not rebuild the removed bundled specialists as a roster of domain personas. See "Rejected alternatives".

## What exists today

Roster as reported by the harness (`omp agents unpack`, plus `~/.omp/agent/agents/`):

| Agent | Source | Tools | Model | Notes |
| --- | --- | --- | --- | --- |
| `task` | bundled | all | `@task` (unset -> `default`) | general purpose, `spawns: "*"` |
| `scout` | bundled | read, grep, glob, web_search | `@smol` | read-only recon, verbatim reads |
| `reviewer` | bundled | read, grep, glob, bash, lsp, web_search, ast_grep | `@slow` | `spawns: [scout]` |
| `security-reviewer` | bundled | read, grep, glob, lsp, ast_grep | inherited | read-only |
| `sonic` | bundled | (default) | `@smol` | mechanical updates only |
| `review-router` | user (this repo) | read, grep, glob, bash, lsp, ast_grep | `@flash` -> `@mid` -> `@smol` -> `@task` | cheap-first PR router, structured output |

Deployment: `~/.omp/agent/agents/review-router.md` is a symlink to `agents/.omp/agent/agents/review-router.md`. Project-scope personas would live in `<repo>/.omp/agents/*.md`; none exist in any repo on this machine.

Settings that shape personas (`~/.omp/agent/config.yml`, everything else at default):

- `modelRoles`: `flash` (glm-5.3-flash:low), `mid` (gpt-5.6-terra:medium), `smol`, `slow`, `plan`, `advisor`, `vision`, `default`, and a dead `designer`.
- `task.disabledAgents: []`, `task.agentModelOverrides: {}`, `task.agentPrewalk: {}`, `task.agentAdvisor: {}`, `task.agentServiceTierOverrides: {}`.
- `task.eager: default`, `task.enableEffort: false`, `task.enableLsp: false`, `task.maxRecursionDepth: 2`, `task.maxConcurrency: 32`.

## Measured usage (376 spawns, 2026-08-07 to 2026-09-17)

Counted from the `task` tool calls in `~/.omp/agent/sessions/**/*.jsonl`:

| Agent | Spawns | Share |
| --- | --- | --- |
| `scout` | 150 | 40% |
| `task` (default) | 111 | 30% |
| `reviewer` | 45 | 12% |
| `review-router` | 30 | 8% |
| `librarian` | 15 | 4% (bundled, now removed) |
| `security-reviewer` | 7 | 2% |
| `task` (explicit) | 6 | |
| `designer` | 4 | (bundled, now removed) |
| `sonic` | 3 | |
| `performance-optimizer` | 3 | (user, deleted) |
| `ian-reviewer` | 1 | |
| `deployment-expert` | 1 | (user, deleted) |

Other measured facts:

- Adoption is rising: 135 spawns in August, 241 in the first 17 days of September.
- `review-router` ran on its intended cheap role in 22 of the 27 spawns whose resolved model was recorded (`flash`), with `smol`/`mid` as fallbacks, i.e. the cheap-first routing works as configured. It requested delegations in only a small fraction of runs (`reviewer` 7, `security-reviewer` 5, none to the removed specialists), so its stale enum has not caused a visible failure yet.
- Spawn prompts are hand-written in the `# Target / # Change / # Acceptance` shape in 349 of 376 spawns (93%), 354 state an output contract, 178 name an evidence requirement, and 46 state a read-only constraint explicitly. Only 45 (12%) pass an `outputSchema`, while 354 state the output contract in prose instead.
- The Ian lens appears in 24 spawns: 14 as `task`, 8 inside `review-router` triage output, 1 as an agent named `ian-reviewer`, 1 as `reviewer`.
- `lsp` was executed 0 times in 513 subagent transcripts (`task.enableLsp` is `false`); `ast_grep` was executed 0 times in either parent or subagent transcripts.
- Persona-directory hygiene: `~/.omp/agent/agents/` holds only the `review-router` symlink; `~/.claude/agents/` (also used by that harness historically) is mid-deletion in this repo's working tree.

## Evidence from vendor documentation

Primary sources only; quotes verified against the fetched pages. The recurring, cross-vendor guidance is what carries weight.

**1. The description is the router.** Anthropic: "Claude uses each subagent's description to decide when to delegate tasks." Gemini CLI: "It decides whether an agent is a relevant expert based on the agent's description." Codex: `description` is "Human-facing guidance for when Codex should use this agent." Copilot: `description` is required. Agentskills.io: phrase it "Use this skill when...", not "This skill does...". Anthropic's own recommendation to encourage delegation is to say so in the description ("use proactively").

**2. One responsibility per persona.** Anthropic: "Design focused subagents: each subagent should excel at one specific task". Codex: "The best custom agents are narrow and opinionated." OpenAI Agents SDK: "Have specialized agents that excel in one task, rather than having a general purpose agent that is expected to be good at anything."

**3. Least-privilege tools.** Anthropic allowlist/denylist with a read-only reviewer as the worked example; Codex `sandbox_mode = "read-only"` for its explorer/reviewer/docs-researcher agents; Gemini CLI `tools:` lists; OpenCode permission maps with read-only built-in `plan`/`explore`/`scout`. Every vendor's review/explore example is read-only.

**4. Model routing per sub-task, calibrated not minimized.** Anthropic documents routing to cheaper models for cost, but its built-in Explore now "inherits the main conversation's model instead of always running on Haiku" (v2.1.198). Codex: start from the strong model; lighter models are for scans and high-volume narrow work. OpenAI: prototype on the most capable model, then downgrade after evals.

**5. Subagents start with clean context, so the brief must be self-contained.** Anthropic: "It doesn't see your conversation history..." and "Each subagent needs an objective, an output format, guidance on the tools and sources to use, and clear task boundaries."

**6. Ask for a distilled return.** Anthropic: subagents return "a condensed, distilled summary of its work (often 1,000-2,000 tokens)"; push large artifacts to the filesystem to avoid the "game of telephone".

**7. Guardrails live outside persona prose.** Anthropic: "A real guardrail needs to be deterministic, and the enforcement methods are hooks and permissions... an instruction like 'never edit .env' is a request, not a guarantee." Gemini CLI implements it as TOML policy scoped by `subagent = "<name>"`.

**8. Restraint on roster size.** Anthropic: define a subagent "when you keep spawning the same kind of worker with the same instructions"; "only increasing complexity when needed". OpenAI: "Our general recommendation is to maximize a single agent's capabilities first."

**9. Budget the descriptions.** Anthropic warns when combined subagent descriptions exceed 15,000 tokens; the skills listing truncates at 1,536 characters. Descriptions are paid for every turn; detail belongs in the body, which loads only on invocation.

Known disagreements, useful as counterweights: Anthropic's multi-agent post says "most coding tasks involve fewer truly parallelizable tasks than research, and LLM agents are not yet great at coordinating and delegating to other agents in real time" (multi-agent coding fits read-heavy breadth, not parallel writes); Claude Code allows nested spawning up to three layers while Gemini CLI forbids subagents spawning subagents entirely; and Anthropic's own docs warn "Running many subagents that each return detailed results can consume significant context."

Sources: [Claude Code subagents](https://code.claude.com/docs/en/sub-agents), [Claude Code skills](https://code.claude.com/docs/en/skills.md), [skills best practices](https://agentskills.io/skill-creation/best-practices), [optimizing descriptions](https://agentskills.io/skill-creation/optimizing-descriptions), [Building effective agents](https://www.anthropic.com/engineering/building-effective-agents), [multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system), [effective context engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents), [OpenCode agents](https://opencode.ai/docs/agents/), [GitHub Copilot custom agents configuration](https://docs.github.com/copilot/reference/custom-agents-configuration).

## Empirical evidence on personas, reviewers, and tool scoping

Peer-reviewed and lab-published results, with the counter-results kept in.

**Persona text does not make a model smarter.** Zheng et al. (Findings of EMNLP 2024) tested 162 roles and 2,410 factual questions across four model families: "adding personas in system prompts does not improve model performance", "none of the personas lead to statistically better model performance", and "certain personas may actually lead to lower performance". The only positive coefficients are tiny: in-domain role alignment ("the effect size of domain alignment is relatively small") and audience framing ("Audience-specific prompts are significantly better than speaker-specific prompts with small effect sizes"). Automatic role selection fails: "the best-performing role per question is often idiosyncratic". Kong et al. (NAACL 2024) do report large gains from a role-play template (AQuA 53.5% -> 63.8%, Last Letter 23.8% -> 84.2%), but attribute the mechanism: "role-play prompting acts as a more effective trigger for the CoT process". Kim et al. (2024) find the sign flips by dataset - "degrading their reasoning abilities in 7 out of 12 datasets in llama3" - and that "LLM-generated personas obtain more stable results than handcrafted personas". For code specifically, Cheng & Mastropaolo (2026): "increasing system-prompt constraint specificity does not monotonically improve correctness". Personas also do not hold: Li et al. (2024) measure "a significant instruction drift within eight rounds of conversations", and a 2026 long-horizon study of 2,008 conversations reports "no evaluated model and configuration reliably preserves either dimensions: trajectory accuracy averages only 44.4%".

Implication: a persona earns its place through what it *mechanically* declares - tool scope, model, output contract, autoloaded skill, isolation - not through character. That is exactly the shape of the roster here: five bundled agents differ by tools and model, not by prose personality.

**Two same-model reviewers do not beat one; forced disagreement does.** The most on-point controlled ablation (Adversarial Review, ICML 2026 DL4C workshop) reports on LiveCodeBench: zero-shot 77%, Self-Refine 77%, single-reviewer 77%, two independent reviewers 75%, forced-disagreement AR 87% - with the stated reason "the critic and the generator are the same model making the same mistakes". The failure mode is named false consensus: "two agents appear to agree, but the agreement may only reflect conversational pressure to converge", and AR's own end-to-end gain over a Claude Code baseline costs "about 4.5x the tokens of Zero-shot". Supporting: model errors are strongly correlated across 350+ models ("models agree 60% of the time when both models err"), and "larger and more accurate models have highly correlated errors", so extra same-model copies are not independent. Multi-agent systems' "performance gains on popular benchmarks are often minimal" with 14 documented failure modes (MAST). Self-correction without external feedback is unreliable: "LLMs struggle to self-correct their responses without external feedback, and at times, their performance even degrades".

Implication: this is the evidence behind the swarm's existing "never delegate merely to obtain a second opinion" and "never pad an empty delegation list" rules, and the reason not to add reviewer personas for panel symmetry. What does pay: a differently-trained critic (CriticGPT: "models catch more bugs than human contractors paid for code review"), external verification (executable tests, verifiers), and lenses that are actually different rather than another sample of the same model - which is the real argument for keeping the Ian lens as a distinct, cheaply dispatchable persona instead of another generic reviewer.

**Tool restriction is the best-evidenced lever, for reliability and for safety.** Tool-selection accuracy degrades as the tool list grows: MetaTool's CSR "decreases as the length of the tool list increases, especially in the range from top 5 to top 10"; a 2025 MCP study reports tool retrieval "more than triples tool selection accuracy (43.13% vs 13.62% baseline)" while cutting prompt tokens by over half; a DATE 2025 agent study attributes failures to "the large number of available options confusing the LLM" and reports large success-rate gains after cutting to "fewer, more relevant tools". The counter-result matters: the optimum is query-dependent, not "fewer is always better" (a fixed 5-tool shortlist beat an adaptive policy on ToolBench aggregate coverage, 64.7% vs 61.9%, while finding nothing on hard queries). On the safety side, tool allowlisting cut prompt-injection attack success to 7.5% in AgentDojo; argument-level least privilege cut it from 39.9% to 1.0% while "maintaining the agent's utility"; capability/data-flow restriction solved 77% of AgentDojo tasks with provable security versus 84% undefended (a ~7-point utility cost); component isolation protects "without any loss of functionality" at under 30% overhead for three-quarters of queries. No study was found showing least privilege improves *coding* task success - the reliability results are about tool selection, not sandboxed agents.

Implication: read-only, narrowly-scoped personas are the well-supported default (this is also what every vendor's own review/explore agent does), and the researcher persona's deliberate omission of `bash` is the concrete form of it: web content plus a shell is the injection surface these defenses target. The counter-result is why the personas here keep narrow, *relevant* tool sets rather than the absolute minimum, and why the router still gets `bash` for `git diff`.

Sources: [Zheng et al., EMNLP 2024 Findings](https://aclanthology.org/2024.findings-emnlp.888/) ([HTML](https://arxiv.org/html/2311.10054v3)), [Kong et al., NAACL 2024](https://aclanthology.org/2024.naacl-long.228/), [Kim et al. 2024](https://arxiv.org/abs/2408.08631), [Cheng & Mastropaolo 2026](https://arxiv.org/abs/2602.15228), [Li et al., instruction instability](https://arxiv.org/abs/2402.10962), [long-horizon persona collapse](https://arxiv.org/abs/2607.28818), [persona vectors](https://arxiv.org/abs/2507.21509), [Adversarial Review](https://arxiv.org/abs/2608.18167), [correlated model errors](https://arxiv.org/abs/2506.07962), [MAST](https://arxiv.org/abs/2503.13657), [self-correction limits](https://arxiv.org/abs/2310.01798), [CriticGPT](https://arxiv.org/abs/2407.00215), [MetaTool](https://arxiv.org/abs/2310.03128), [RAG-MCP tool retrieval](https://arxiv.org/abs/2505.03275), [Less-is-More](https://arxiv.org/abs/2411.15399), [tool shortlist depth](https://arxiv.org/abs/2605.24660), [AgentDojo](https://arxiv.org/abs/2406.13352), [Progent](https://arxiv.org/abs/2504.11703), [CaMeL](https://arxiv.org/abs/2503.18813), [IsolateGPT](https://arxiv.org/abs/2403.04960), [Toolshed](https://arxiv.org/abs/2410.14594).

Absent evidence, recorded so it is not filled in later by assumption: no controlled one-vs-two-reviewer study on human-validated real-world defects with precision/recall reported; no study of expert-vs-generic reviewer *persona* effects on bug-finding; no published Berkeley BFCL tool-count ablation; no multi-lab replication of the persona-effect literature.

## Findings

**F1 - Dead delegation targets in a live router.** `review-router` may request `designer`, `performance-optimizer`, `ai-architect`, or `deployment-expert`; none resolve. `designer` was bundled until 18.1.5 ("Removed the bundled `designer` subagent and `designer` model role"), `librarian` until 18.1.9 ("Removed the librarian agent"), and `performance-optimizer`/`deployment-expert` were user personas that no longer exist (their recorded spawns carried `agentSource: user`). A request for one fails preflight, and the swarm skill only says a missing specialist "falls back to `reviewer` with the same narrow lens" - the round trip is wasted and the intended lens is lost. Cost is currently low (the router has requested only `reviewer` and `security-reviewer`) but the failure mode is invisible: the router is being told these are options.

**F2 - The Ian lens is invoked by hand 23 times out of 24.** The lens is described in `pr-review-swarm` as "a read-only `task` after loading `skill://ian-reviewer`", which makes a persona-level property depend on the caller composing the right prompt. Spawn names in the transcripts (`IanLens`, `IanRoundThree`, `IanLens401`, `InitialIanLens`) show the instruction being retyped. This is exactly Anthropic's "same kind of worker with the same instructions" trigger for a definition, and `autoloadSkills` is the mechanism that removes the dependency (the autoload path is a provenance-only injected message, so it cannot be mistaken for a user invocation).

**F3 - Declared `lsp` is inert for every subagent, but one setting flips it.** The LSP tool is registered "only when both `session.enableLsp !== false` and `lsp.enabled` allow it"; for a spawn, the child value resolves as `(parent.enableLsp ?? true) && settings.get("task.enableLsp")`, which defaults to `false`, and plan mode forces it off. `review-router`, `reviewer`, and `security-reviewer` all list `lsp`, and zero of 513 subagent transcripts executed it. Verified by experiment: with `task.enableLsp: true`, a spawned `reviewer` called `lsp` with `action: status` and got `success: true`; with the default, the tool is not mounted at all. For read-only review personas this is the one global toggle that changes the evidence available to the reviewer rather than its taste.

**F4 - Two dead references to the removed `designer` role.** `modelRoles.designer: anthropic/claude-opus-5` has no consumer after 18.1.5, and `pr-review-swarm` line ~47 still reads "`designer` uses `@designer`". Dead config that looks live is worse than absent config: it suggests a persona exists that does not.

**F5 - The persona is deployed by symlink from an untracked directory.** `~/.omp/agent/agents/review-router.md` -> `agents/.omp/agent/agents/review-router.md`, and `agents/.omp/` is untracked (`?? agents/.omp/`) even though `agents/.agents/skills/` is tracked. A fresh checkout therefore reproduces the skills but silently loses the persona, and the symlink makes the loss invisible in `~/.omp`. (The repo's `docs/` notes are untracked too, so there is precedent for local-only files - the difference is that nothing else in `~/.omp` depends on them.)

**F6 - The remaining persona knobs are unused, and the two that matter most are cheap.** Nothing sets `spawns`, `blocking`, `prewalk`, `advisor`, `read-summarize`, or `agentModelOverrides`. `prewalk`/`advisor` exist per agent (`task.agentPrewalk`, `task.agentAdvisor`) and the user already runs the global advisor (`advisor.enabled: true`), but no persona opts in. This is a place to leave alone until a persona demonstrably needs it - the vendor evidence gives no basis for arming them speculatively.

**F7 - The harness's direction is personas for mechanics, skills for knowledge.** Two personas were removed upstream in three weeks while ~40 skills (AWS, webapp-testing, archify, diagnosing-bugs, tdd, ...) were added. Restating that knowledge in a persona body would duplicate the skill and pay its tokens on every dispatch. The evidence supports at most the two additions below, both of which are dispatch-shape definitions rather than knowledge.

## Recommended changes

### 1. Add `ian-reviewer` (persona) - highest evidence

Verified to parse and appear in discovery as a project-scope agent; content is in the appendix. Rationale: F2, plus GitHub/Anthropic "limit tool access" and "the reviewer is read-only" pattern. It is read-only by construction (no `edit`/`write`/`task` in `tools`), routes to `@slow`, and preloads the skill.

Where: `agents/.omp/agent/agents/ian-reviewer.md` (symlinked like `review-router`), or `<repo>/.omp/agents/` if it should be repo-scoped.

Then update `pr-review-swarm` step 4 to dispatch `agent: "ian-reviewer"` and delete the "after loading `skill://ian-reviewer`" instruction.

### 2. Add `researcher` (persona) - removes a hand-rolled pattern

15 `librarian` spawns (all on the cheap role) plus 12 research-shaped `scout` spawns show the job is routine; the job has no owner since 18.1.9, and the local `research` skill explicitly delegates to a background agent without being able to define one. The persona is read-only web tools (no `bash`, deliberately: external content plus shell is the injection surface the least-privilege literature targets), `autoloadSkills: [research]`, `@mid` with `@smol` fallback, and a `sources` schema that forces per-claim URLs.

### 3. Change `review-router` to the live roster

- `delegations.elements.properties.agent.enum`: `[reviewer, security-reviewer, ian-reviewer, task]`.
- Delegation prose: keep `reviewer`, `security-reviewer`, `task` ("another domain specialist after it loads the matching installed skill"), add `ian-reviewer`; delete the four dead bullets.
- Leave model ordering, `thinking-level: low`, and the output schema alone: the output schema is what makes the router's cheap path cheap, and its routing has been observed working.

### 4. Change `pr-review-swarm` routing text

- Drop "`designer` uses `@designer`".
- Replace the specialist list in step 4 with `reviewer`, `security-reviewer`, `ian-reviewer`, `task` and state that absent specialists fall back to `reviewer` with the same lens (already the graceful-degradation rule).

### 5. Delete `modelRoles.designer`

One line in `~/.omp/agent/config.yml`; `omp config reset`/hand-edit both work. Nothing consumes `@designer`.

### 6. Decide `task.enableLsp`

Verified behavior: with the default `false`, no subagent can have the tool (`enableLsp` for a child resolves as `(parent.enableLsp ?? true) && settings.get("task.enableLsp")`, and `LspTool.createIf` returns null when false), and 0 of 513 subagent transcripts executed an `lsp` call. With `task.enableLsp: true`, a bundled `reviewer` spawned in a scratch session declared `lsp` and successfully ran `action: status`. So the choice is live, not theoretical.

Recommend `true` while review personas declare `lsp`: the bundled `reviewer` declares it, and `references`/`definition`/`diagnostics` are evidence a grep cannot reproduce, which is the whole point of a review persona. The cost is tokens and possible server startup latency in subagents, which is what the setting's description names. If it stays `false`, remove `lsp` from the persona tool lists instead, so the declaration stops claiming a capability that is gated off.

### 7. Track the persona directory (repo convention is inconsistent here)

Today `agents/.agents/skills/` is tracked, while `agents/.omp/` (the only persona) and the whole `docs/` directory are untracked working-tree files. The persona is live only because `~/.omp/agent/agents/review-router.md` symlinks into the untracked path, so a fresh checkout of this repo reproduces the skills but not the persona. Either commit `agents/.omp/agent/agents/` (matching how skills are handled, in its own atomic commit so the in-flight skill churn stays out) or accept it as local-only and stop relying on the symlink. This note lives beside the existing untracked notes in `docs/`, so it inherits that choice until `docs/` is committed.

## Rejected alternatives

- **Rebuilding the removed domain specialists (`designer`, `performance-optimizer`, `ai-architect`, `deployment-expert`) as user personas.** Upstream deleted `designer` in 18.1.5, and the other three were user personas whose files no longer exist; together they accounted for 8 spawns in six weeks (designer 4, performance-optimizer 3, deployment-expert 1). Their jobs are now covered by skills the main agent can load (`aws-*`, `webapp-testing`, `archify`, `frontend-design`), and every persona description is context paid on every session turn (Anthropic's 15,000-token description warning; the 1,536-character skills-listing cap). `librarian` is deliberately excluded from this argument: 15 spawns for one recurring job is exactly the threshold that justifies a definition, which is why it becomes `researcher` instead.
- **A persona per SDK ecosystem (Payload, Nitro, Cloudflare, DuckDB).** Knowledge, not dispatch shape: it belongs in the skills that already exist, and a persona cannot express it any better than the skill text while adding a roster entry to route.
- **Setting `task.eager: preferred`/`always` to force more delegation.** Adoption is not stalled (135 -> 241 spawns month over month) and Anthropic's own numbers put multi-agent runs at 4x chat tokens and 15x for research-shaped swarms. `always` additionally injects a delegation prelude into eligible first turns, which is a behavioral change to every session. Revisit only if the goal is explicitly "delegate more", and prefer `preferred`.
- **Arming `prewalk`/`advisor` on personas.** `prewalk` exists to hand implementation to a cheap model after planning, which none of these read-only personas do; the global advisor is already on. No evidence for arming them here.
- **Making the personas repo-scoped instead of user-scoped.** The Ian lens and the research job both appear across Nexus, dotfiles, and bridge repos; scoping them to one repository would defeat F2.

## Appendix: proposed persona files

Both validated against the running harness: placed under `<project>/.omp/agents/` and read from a fresh headless session, the discovered roster came back as `ian-reviewer, researcher, review-router, scout, reviewer, security-reviewer, task` - the two new personas parse, carry their frontmatter, and are offered to the dispatcher alongside the bundled set.

### `ian-reviewer.md`

```markdown
---
name: ian-reviewer
description: Read-only reviewer that applies the Ian review lens - design, abstraction, simplicity, organization, naming, coupling, and evidence-backed behavior - to a change. Use for diff, PR, or pre-merge review when taste and concrete behavioral cost matter more than checklist coverage.
tools:
  - read
  - grep
  - glob
  - bash
  - ast_grep
  - yield
model:
  - "@slow"
autoloadSkills:
  - ian-reviewer
output:
  properties:
    verdict:
      metadata:
        description: "Plain-text summary, 1-3 sentences, lowercase"
      type: string
    coverage:
      metadata:
        description: What was reviewed and what was not
      type: string
  optionalProperties:
    findings:
      metadata:
        description: "Populate via incremental yield sections under type: [\"findings\"]; do not repeat in a final payload."
      elements:
        properties:
          title:
            metadata:
              description: "Imperative, lowercase, <=80 chars"
            type: string
          body:
            metadata:
              description: "One paragraph: the concern, the concrete near-term cost it creates, and the smaller design that avoids it"
            type: string
          severity:
            metadata:
              description: "blocking (concrete near-term cost), question (needs author context), note (preference)"
            enum:
              - blocking
              - question
              - note
          file_path:
            metadata:
              description: Path to the affected file
            type: string
          line_start:
            metadata:
              description: First line (1-indexed)
            type: number
          line_end:
            metadata:
              description: Last line (1-indexed, <=10 lines)
            type: number
---

Apply the Ian review lens to the assigned change. The lens is preloaded as an autoloaded skill; follow its voice and its priority order (principled pragmatism, The Right Abstraction, simplicity, organization and coupling, naming, behavioral evidence).

Operate read-only. Bash is limited to `git diff`, `git log`, `git show`, `git status`, `jj diff --git`, and `gh pr diff`. Never edit, write, format, build, test, commit, or push.

<procedure>
1. Establish the scope from the task: a diff range, a PR, or an explicit file set. Read the patch first (`git diff`, `jj diff --git`, `gh pr diff <n>`).
2. Read the changed code in full context, plus the callers and consumers of anything whose contract changed.
3. Judge in this order: is the behavior correct; is the abstraction the right one; is the organization and naming honest; is the coupling warranted; is the change supported by evidence.
4. For each concern, name the concrete cost: a migration, an unavoidable next step, a correctness or compat risk, or a maintainability tax that lands soon. Rank the concern by that cost, not by taste.
5. Ask a focused question instead of asserting when author context or a tradeoff could change the answer.
</procedure>

<criteria>
A finding earns a place only when it is anchored to a changed line and one of:
- a concrete near-term correctness, safety, migration, compatibility, or operational cost
- an organization, naming, or coupling problem with a smaller design named in the same comment
- a claim stated as evidence that the change does not actually hold

Drop style nits a formatter would catch, pre-existing defects, speculative concerns, and anything that needs assumptions about author intent.
</criteria>

<output>
Findings: incremental `yield` with `type: ["findings"]`.
Verdict fields: incremental `yield` with `type: ["verdict"]` and `type: ["coverage"]`.
Affirmations are rare and appear only in the verdict, never as a standalone finding. After all sections, stop; idle finalization assembles the result.
</output>
```

### `researcher.md`

```markdown
---
name: researcher
description: Read-only librarian for facts outside this repository - current official documentation, API contracts, version behavior, standards, vendor limits, and pricing. MUST be used when an answer depends on how a third-party system behaves today rather than how this codebase is written.
tools:
  - read
  - grep
  - glob
  - web_search
  - yield
model:
  - "@mid"
  - "@smol"
thinkingLevel: medium
autoloadSkills:
  - research
output:
  properties:
    summary:
      metadata:
        description: Brief summary of the verified findings and what remains uncertain
      type: string
  optionalProperties:
    report:
      metadata:
        description: "The complete deliverable when the task asks for a report or comparison - full markdown at the depth requested. Never a summary of it."
      type: string
    sources:
      metadata:
        description: Every source relied on, with the exact claim it settles
      elements:
        properties:
          url:
            metadata:
              description: URL of the primary source
            type: string
          claim:
            metadata:
              description: The claim this source settles, stated in one sentence
            type: string
          kind:
            metadata:
              description: Source class
            enum:
              - official-docs
              - source-code
              - spec
              - first-party-api
              - secondary
    conflicts:
      metadata:
        description: Places where sources disagree or where no primary source exists
      elements:
        properties:
          question:
            metadata:
              description: The unresolved question
            type: string
          note:
            metadata:
              description: What each source says and why it stays unresolved
            type: string
---

Answer the assigned question from primary sources, then hand back the minimum another agent needs to act without re-reading anything.

<directives>
- Prefer, in order: official documentation, the vendor's own source or changelog, the specification, a first-party API response. A blog post or forum answer is a lead to a primary source, never the source.
- Verify each claim on the page that owns it; record the URL next to the claim it settles.
- State the version or date the source was read when behavior is version-dependent.
- When sources conflict or no primary source exists, say so under `conflicts` instead of choosing silently.
- Read-only: never write, edit, or execute state-changing commands. Report what you found, not what you would do.
</directives>

<procedure>
1. Restate the question as the specific facts that decide it.
2. Search for the owning source of each fact; open it and read the relevant section rather than trusting the search result summary.
3. Cross-check any load-bearing claim against a second primary source when one exists.
4. Flag facts that are inferred rather than quoted.
</procedure>

<output>
`summary` and `sources` are the baseline. A task that asks for a report, comparison, or enumeration gets the full body under `report`, not a pointer to it. Use incremental `yield` while working so partial findings survive.
</output>
```

## How the measurements were taken

```bash
# roster and frontmatter of every bundled agent
omp agents unpack --dir /tmp/omp-bundled --json

# spawn census by agent type (session transcripts)
python3 - <<'PY'
import json
from pathlib import Path
from collections import Counter
root = Path.home()/".omp/agent/sessions"
counts = Counter()
for f in root.glob("*/*.jsonl"):
    for line in open(f, errors="ignore"):
        if '"toolCall"' not in line:
            continue
        try: event = json.loads(line)
        except Exception: continue
        for c in (event.get("message", {}).get("content") or []):
            if isinstance(c, dict) and c.get("type") == "toolCall" and c.get("name") == "task":
                args = c.get("arguments")
                args = json.loads(args) if isinstance(args, str) else (args or {})
                for t in (args.get("tasks") or []):
                    counts[(t.get("agent") or "task(default)")] += 1
print(counts.most_common())
PY

# settings that shape personas
omp config list --json | jq 'to_entries | map(select(.key|test("^task\\.")))'

# subagent tool usage, for the lsp/ast_grep claims
# (scan "toolName" occurrences inside ~/.omp/agent/sessions/*/*/*.jsonl)

# persona-file validation: drop candidate files in a scratch project and read the roster
cd /tmp/persona-verify   # contains .omp/agents/{ian-reviewer,researcher}.md
omp -p --model @smol --no-title "List every subagent name available to you in the task tool description, comma-separated, nothing else."

# lsp gate: the same spawn with task.enableLsp on the command-line overlay
omp -p --config lsp-probe.yml --no-title "Spawn exactly one subagent: agent 'reviewer', task: 'Call the lsp tool once with action status...'"
```

Upstream changes cited above come from the installed changelog: `~/.bun/install/global/node_modules/@oh-my-pi/pi-coding-agent/dist/CHANGELOG-*.md` (18.1.5 removed the bundled `designer` subagent and role; 18.1.9 removed `librarian`).
