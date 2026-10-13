# Choosing agent configuration mechanisms

How to decide between an agent persona and the other levers a coding harness offers (skills, rules, hooks, permissions, tools, code-orchestrated fan-out), and which setups are common in practice. Vendor guidance and empirical results are cited; the harness-specific mapping uses OMP because that is what runs here, but the decision rules are harness-agnostic.

## The one-line rule

**A persona is a runtime contract, not a knowledge store.** Reach for one when the work needs a different *operating envelope* - a different tool surface, a different model, an isolated context window, its own output schema, its own permission level, its own parallelism. If what you actually want to change is *what the agent knows* or *what it must not do*, a persona is the wrong lever and a skill, rule, tool, hook, or permission is the right one.

The evidence for that split is blunt. Persona text in a system prompt does not improve accuracy on factual questions ("none of the personas lead to statistically better model performance", 162 roles x 2,410 questions), and the positive results that do exist are reasoning-scaffold effects explicitly attributed to chain-of-thought triggering, not to the identity. Meanwhile the mechanistic levers are measurable: tool scoping changes tool-selection accuracy and prompt-injection resistance; model routing changes cost; context isolation changes how much the main thread has to remember.

## The decision ladder

Walk it in order; stop at the first rung that fits.

| # | Rung | Loaded when | Cost | Reach for it when | Evidence |
| --- | --- | --- | --- | --- | --- |
| 0 | **Main thread** | always | your own context | the task is iterative, shares context with the work already done, or is a quick targeted change | Claude Code: "Use the main conversation when... the task needs frequent back-and-forth... multiple phases share significant context" |
| 1 | **Rule / context file** (`AGENTS.md`, `RULES.md`, `.omp/rules/*.mdc`) | context file: session opening; `RULES.md`: every request | tokens every session (small if short) | a durable convention, command, or expectation that must apply to *every* task. Keep it small; `RULES.md` only for the handful of hard requirements that must survive a long transcript | Codex: "Keep it small... a feedback loop" (repeated mistakes, recurring PR feedback); Anthropic: rules are "a request, not a guarantee" |
| 2 | **Skill** | description in prompt; body only when read/invoked | description every turn, body once | repeatable procedure or domain knowledge (an API's conventions, a review rubric, a release checklist) | Anthropic skill-vs-subagent table: skill = "reusable instructions, knowledge, or workflows", subagent = "isolated worker with its own context"; agentskills.io: scope to "a coherent unit of work", cut anything the agent would get right anyway |
| 3 | **Hook / permission** | on the event | ~zero context | something that must *never* happen, or must be mechanically rewritten: block a command, redact output, rewrite tool args, gate a path | Anthropic: "A real guardrail needs to be deterministic, and the enforcement methods are hooks and permissions"; in OMP, a throwing `tool_call` hook fails closed |
| 4 | **Tool** (built-in, custom, MCP, eval `@tool`) | schema in prompt | schema every turn | the capability has to be *executable and validated*, not described: a deploy, an API call, a parser, a query. Tool quality pays more than persona prose | Anthropic: "we actually spent more time optimizing our tools than the overall prompt"; OpenAI: rate each tool's risk (read-only vs write, reversibility) |
| 5 | **Persona / subagent** | name + description + tool list always; body only when spawned | description every turn; the child's own context | the work needs a different tool surface, model, permission level, context window, or return shape - or runs in parallel | Claude Code's subagent triggers: "verbose output you don't need in your main context"; "you want to enforce specific tool restrictions or permissions"; "the work is self-contained and can return a summary" |
| 6 | **Code-orchestrated fan-out** (loop, `workpool`, script) | n/a | n/a | the same instruction applies to N items and the set is known up front | OpenAI: "orchestrating via code makes tasks more deterministic and predictable, in terms of speed, cost and performance"; OMP's `workpool` queues items onto keep-alive subagents instead of spawning one process per item |
| 7 | **Long-lived observer** (advisor-style) | per turn | one extra model call per turn | you want a second set of eyes on the *main* agent's work continuously rather than a reviewer dispatched per change | vendor pattern: supervisor/reviewer roles; OMP ships this as the advisor runtime rather than as a persona |

Ordering matters. A persona is the most expensive rung that is not parallelism: it costs a description on every turn, a fresh context window on every spawn (agents start blank - "It doesn't see your conversation history"), and 4x-15x the tokens of an inline chat for the work itself. Everything below it on the ladder is cheaper and more deterministic for the same goal.

## Setups that are common in practice

### A. Zero custom personas (bundled set only)

Use the harness's own agents plus good rules/skills. Vendor guidance actively recommends this starting point: OpenAI - "our general recommendation is to maximize a single agent's capabilities first"; Codex sequences capabilities as rules -> plugins -> MCP -> subagents, subagents *last*; Anthropic - "only increasing complexity when needed" and "define a custom subagent when you keep spawning the same kind of worker with the same instructions".

Right when: your work is mostly iterative editing with one model. Failure mode: context pollution and cost - long exploration displacing the requirements you are tracking, which is what subagents are for.

### B. Minimal role trio: explore / implement / verify

The shape every vendor's own built-ins converge on. Claude Code ships an Explore agent (read-only) plus a general-purpose agent; OpenCode ships `plan` (permissions set to `ask` for edits and bash), `explore` ("fast, read-only agent for exploring codebases. Cannot modify files"), `scout` ("read-only agent for external docs and dependency research"), and `general`; Codex documents `pr_explorer` (read-only, "Stay in exploration mode"), `reviewer` (read-only, effort high, "Lead with concrete findings... avoid style-only comments unless they hide a real bug"), and `docs_researcher` ("Do not make code changes"); Gemini CLI documents a `security-auditor` with `tools: [read_file, grep_search]` and "Do not fix it yourself; just report it".

Three personas, differentiated by tools and model tier, not by personality prose: a cheap read-only explorer, a strong writer, a strong read-only verifier. Read-heavy parallel work is the well-supported case; write-heavy parallel work is where the guidance turns cautious ("Be more careful with parallel write-heavy workflows, because agents editing code at once can create conflicts").

### C. Verifier-centric: one writer, one *deliberately adversarial* verifier

The evidence says the second reviewer only pays when it is not a clone of the first. A controlled reviewer-count ablation on LiveCodeBench put zero-shot, self-refine, one reviewer, and two independent reviewers in a statistical tie (77/77/77/75%) - "the critic and the generator are the same model making the same mistakes" - while a critic forced to disagree reached 87%. Model errors are strongly correlated across 350+ models ("models agree 60% of the time when both models err"), and "larger and more accurate models have highly correlated errors". What does pay: a purpose-trained critic (CriticGPT: "models catch more bugs than human contractors paid for code review"), an external oracle (tests, types, a runnable repro), or a lens that is structurally different (design taste, threat model, perf).

Practical form: one strong implementer; verification via executable evidence first; a single reviewer persona with a *specific* lens and a narrow scope; disagreement engineered by giving the verifier only the artifact and the criteria ("a reviewer running in a fresh subagent context sees only the diff and the criteria you give it, not the reasoning that produced the change"), not the author's rationale.

### D. Skills-first, personas only for isolation

Put the knowledge in skills; keep personas to the ones that need a different envelope. This is where Anthropic's own product guidance points skills-vs-subagents, and it matches the direction of the harnesses: OMP removed two bundled specialist personas (librarian, designer) in three weeks while its skill set grew to dozens. If a "specialist" persona's only content is expertise, it is a skill that costs a roster entry and a description on every turn.

### E. Policy-first: permissions and hooks carry the rules

Give the persona no normative rules at all; enforce with permission maps and event hooks. OpenCode exposes `permission` keys (`ask`/`allow`/`deny` per tool, plus `permission.task` globs that remove a subagent from the task tool description entirely); Gemini CLI scopes policy rules per subagent name in `policy.toml`; Anthropic's answer to "never do X" is hooks and permissions, not prose. The measured payoff: tool allowlisting dropped prompt-injection success to 7.5% in AgentDojo, argument-level least privilege dropped it from 39.9% to 1.0% "while maintaining the agent's utility", and capability/data-flow restriction solved 77% of tasks with provable security versus 84% undefended.

Caveat: the same literature shows the optimum is query-dependent, not "fewer tools is always better" (a fixed 5-tool shortlist beat an adaptive policy on ToolBench aggregate coverage, 64.7% vs 61.9%, while finding nothing on hard queries), and no study shows least privilege improving *coding* task success - the reliability results are about tool selection.

### F. Tier routing as the organizing axis

Instead of organizing personas by role, organize them by cost tier and let the model choice be the distinguishing feature: cheap-first for scans and triage, strong for judgment, with escalation when confidence is low. Vendor support: Anthropic's routing pattern ("routing easy/common questions to smaller, cost-efficient models... hard/unusual questions to more capable models"); Codex's model ladder (terra "for agents that favor speed and efficiency over depth, such as exploration, read-heavy scans", luna "for fast, narrowly scoped agents handling clear, repeatable, or high-volume work", effort `high` for reviewers); OpenAI's method - "build your agent prototype with the most capable model for every task to establish a performance baseline. From there, try swapping in smaller models".

Counter-evidence, from the same vendors: Anthropic's built-in Explore now *inherits* the main model rather than always running Haiku, and Codex says "start with gpt-5.6" for most tasks. Calibrate with a baseline instead of minimizing on principle.

### G. Framework topologies: manager, handoffs, debate, supervisor

The elaborate end: a coordinator agent with specialist workers, peer handoffs with full-context transfer, or debate rounds. Evidence for default use is weak: debate "does not reliably outperform other proposed prompting strategies, such as self-consistency and ensembling", MAS "performance gains on popular benchmarks are often minimal" with 14 documented failure modes, and orchestration quality is hyperparameter-sensitive. Handoffs also deliberately drop the isolation benefit - the Agents SDK transfers the conversation: "it's as though the new agent takes over the conversation, and gets to see the entire previous conversation history" (filterable with `input_filter`).

Use when the work is genuinely parallel and read-heavy, the subtasks are independent, and the value justifies the token multiplier. Not as a default shape, and not to get a "second opinion".

### H. Code-orchestrated fan-out instead of LLM orchestration

For a known set of items, a loop beats a coordinator agent: deterministic, resumable, and it does not pay a model to decide what to do next. OMP's `workpool` (queue items onto the least-loaded keep-alive subagent) and eval-defined tools (`@tool`) are the in-harness forms; a plain script with a CLI is the general form. Pair it with one persona for the per-item envelope (read-only, cheap, schema) rather than one persona per item.

### I. Always-on observers instead of per-change reviewers

Two different products: a reviewer persona dispatched per change (catches defects in an artifact) versus an observer that watches the main agent continuously (catches drift, forgotten constraints, bad assumptions while they are cheap to fix). Vendors ship the second as supervisor/QA-checker roles; OMP ships it as the advisor runtime with its own model role. They are not substitutes: the observer sees the process, the reviewer sees the result.

## Anti-patterns, with the evidence

- **Persona as knowledge base.** Duplicates the skill, costs a description every turn, and the persona's body cannot be updated by the skill's own references. Anthropic caps the combined description budget at 15,000 tokens precisely because this grows without bound.
- **Persona as guardrail.** Prose is a request. Deterministic enforcement lives in permissions and hooks.
- **Roster proliferation.** Every added persona is one more routing decision for the dispatcher and one more ambiguous option at dispatch time; provider docs warn about tool/description overlap in the same terms ("The issue isn't solely the number of tools, but their similarity or overlap").
- **Panel symmetry.** Reviewers added "for coverage" are the exact configuration measured as no better than a single pass.
- **Unbounded reviewer.** "A reviewer prompted to find gaps will usually report some, even when the work is sound... Chasing every finding leads to over-engineering." Constrain the mandate (correctness and stated requirements) and let the rest be optional.
- **Unscoped delegation.** "The infinite exploration... You ask Claude to 'investigate' something without scoping it. Claude reads hundreds of files, filling the context."
- **Parallel writers without isolation.** Coordination overhead and conflicts; if the work must be parallel and writes, isolate the working copies (worktrees/sandboxes) and integrate deliberately.
- **Mega-description.** Detail belongs in the body, which loads on invocation. A description is a routing tag written for the dispatcher, in imperative "use this when..." phrasing.
- **Role membership by vibe.** The one reproducible persona effect is domain alignment, and it is small; the one reliable benefit of a persona is mechanical.

## Worked drills

| Situation | Rung | Why |
| --- | --- | --- |
| "Never touch `.env` / never force-push" | Hook / permission | must be deterministic; prose is not enforcement |
| "This repo uses Bun, tests are `bun test`, no em dashes" | Rule / context file | applies to every task, small, durable |
| "How do we do X in this framework / how do we release" | Skill | knowledge plus procedure, loaded on demand |
| "Where does auth live in this codebase" | Persona (read-only, cheap) | verbose exploration that would pollute the main context |
| "Review this diff for design taste" | Persona (read-only, strong model, own schema) + skill for the lens | different model, different tools, different return shape than the writer |
| "Verify this fix actually works" | Tool/execution first (tests, repro, real surface), persona only for interpretation | self-critique without external feedback "at times degrades" performance |
| "Research current vendor docs and cite sources" | Persona (read-only web tools, sources schema) + skill for the method | fresh context, citation contract, external content kept away from write tools |
| "Apply the same migration to 40 files" | Code-orchestrated fan-out + one persona envelope | known item set; a coordinator agent adds cost and nondeterminism |
| "Keep an eye on my session" | Long-lived observer (advisor) | watches the process, not an artifact |
| "Add a persona for Payload/Nitro/DuckDB" | None - skill | it is knowledge; the persona would only restate it |

## What the evidence does not support

- No study measures persona effects inside an agentic loop (tool use, multi-turn); the persona literature is single-shot generation and QA.
- No evidence that least-privilege restriction improves *task success* on coding work; the reliability results concern tool selection.
- No controlled one-vs-two-reviewer study on human-validated real-world defects with precision/recall; the closest are benchmark pass rates and one industrial case report.
- No measurement that persona descriptions change token cost or outcome; the strongest numbers available are token multipliers (agents ~4x chat, multi-agent ~15x) and one tool-description rewrite credited with a 40% task-completion-time reduction.
- Persona identity can be a *safety* liability: role-play framing is a documented jailbreak vector ("success rates of... 70.8% on GPT-4o, and 68.2% on Claude-3.7") and stronger persona adherence is reported to increase vulnerability - one more reason to keep personas mechanical and narrow.

## Sources

Vendor: [Claude Code subagents](https://code.claude.com/docs/en/sub-agents) · [Claude Code skills](https://code.claude.com/docs/en/skills.md) · [steering Claude Code: skills, hooks, rules, subagents](https://claude.com/blog/steering-claude-code-skills-hooks-rules-subagents-and-more) · [Building effective agents](https://www.anthropic.com/engineering/building-effective-agents) · [effective context engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) · [multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system) · [Agent Skills best practices](https://agentskills.io/skill-creation/best-practices) · [OpenAI practical guide to building agents](https://cdn.openai.com/business-guides-and-resources/a-practical-guide-to-building-agents.pdf) · [Codex subagents](https://learn.chatgpt.com/docs/agent-configuration/subagents.md) · [Codex AGENTS.md](https://learn.chatgpt.com/docs/agent-configuration/agents-md.md) · [OpenAI Agents SDK multi-agent](https://openai.github.io/openai-agents-python/multi_agent/) · [Gemini CLI subagents](https://raw.githubusercontent.com/google-gemini/gemini-cli/main/docs/core/subagents.md) · [Google ADK workflows](https://google.github.io/adk-docs/workflows/) · [GitHub Copilot custom agents](https://docs.github.com/copilot/reference/custom-agents-configuration) · [OpenCode agents](https://opencode.ai/docs/agents/).

Empirics: [Zheng et al., EMNLP 2024 Findings](https://aclanthology.org/2024.findings-emnlp.888/) · [Kong et al., NAACL 2024](https://aclanthology.org/2024.naacl-long.228/) · [Kim et al. 2024](https://arxiv.org/abs/2408.08631) · [Adversarial Review](https://arxiv.org/abs/2608.18167) · [correlated model errors](https://arxiv.org/abs/2506.07962) · [MAST: why multi-agent systems fail](https://arxiv.org/abs/2503.13657) · [Should we be going MAD?](https://arxiv.org/abs/2311.17371) · [self-correction limits](https://arxiv.org/abs/2310.01798) · [CriticGPT](https://arxiv.org/abs/2407.00215) · [self-consistency](https://arxiv.org/abs/2203.11171) · [non-monotonic vote scaling](https://arxiv.org/abs/2403.02419) · [MetaTool](https://arxiv.org/abs/2310.03128) · [Less is More tool reduction](https://arxiv.org/abs/2411.15399) · [tool shortlist depth](https://arxiv.org/abs/2605.24660) · [AgentDojo](https://arxiv.org/abs/2406.13352) · [Progent least privilege](https://arxiv.org/abs/2504.11703) · [CaMeL](https://arxiv.org/abs/2503.18813) · [role-play jailbreaks](https://arxiv.org/html/2508.20325).

OMP mechanics used above: `omp://task-agent-discovery.md`, `omp://skills.md`, `omp://context-files.md`, `omp://hooks.md`, `omp://settings.md`, `omp://agent-hub.md`.
