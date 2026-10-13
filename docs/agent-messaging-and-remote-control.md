# Agent messaging, notifications, and remote control

Research snapshot: 2026-09-09. Goal: keep Zellij/tmux for terminal multiplexing while retaining agent attention monitoring, phone notifications, and remote input/approvals. Investigation used official specifications, project documentation, release-tagged source where noted, GitHub release metadata, and read-only local CLI checks. No software was installed or upgraded; no service, configuration, agent session, or phone subscription was changed. Product interoperability was not smoke-tested.

## Conclusion

**There is an existing protocol worth adopting: Agent Client Protocol (ACP). There is not a demonstrated universal add-on that makes arbitrary already-running coding-agent terminals expose reliable typed status, questions, and approvals.** The distinction is a standard interface implemented by participating harnesses versus a sidecar controlling terminal bytes.

**Updated after the Agent Manager/Paseo follow-up:** local workspace DX and phone control need not share a product, and tmux is acceptable. **Paseo supports importing externally created conversations, including OMP, in released v0.7.2.** It cannot adopt the existing TUI process, but a deliberate stop-and-resume handoff is available. Given the user's interest in Paseo, evaluate that handoff first; compare **Agent Manager** as the desktop workspace independently. For simultaneous access to the unchanged native process, **Agent Manager + Collie** has a real shared-tmux transport seam, but not shared status/metadata. Details and release-source citations appear below.

Recommendation is conditional on which part of the current experience must remain unchanged:

- **Keep native TUIs locally, hand off occasionally:** use plain tmux/Zellij or Agent Manager at the PC; stop the original agent at a safe boundary and import its saved conversation into Paseo. This is continuation in a new process, not live takeover. Before import, notifications still need the local manager or native harness producer.
- **Keep the same live process accessible from both surfaces:** evaluate Agent Manager + Collie's tmux backend, or Collie with plain tmux/Zellij. Resolve socket access and per-harness status gaps; sharing terminal bytes does not share attention semantics.
- **Use one session owner with two clients:** evaluate Paseo for structured desktop/mobile interaction, or Agent of Empires for its tmux-oriented local/web experience. Enable OMP and select its approval policy deliberately in Paseo.
- **Build or contribute a reusable semantic boundary:** use ACP where implemented. Do not assume ACP also supplies background-session ownership, network authentication, phone push, or transparent attachment to a normal TUI.

These recommendations are judgments based on the evidence below, not claims of tested compatibility with the installed harnesses.

## The layers that are easy to conflate

| Layer | Responsibility | Examples |
| --- | --- | --- |
| Agent semantics | Messages, tool lifecycle, explicit input requests, correlated decisions | ACP, AG-UI; harness SDK/RPC or hooks |
| Delivery | Moving events/messages, authentication, disconnect behavior | stdio, HTTP/SSE/WebSocket, SSH |
| Terminal access | Discovering panes, reading rendered output, injecting input | Zellij/tmux CLI, Collie adapters, AgentAPI PTY |
| Human-facing product | Dashboard, phone UI, push, pending-request state, local/remote coordination | Collie, Paseo, AoE, HAPI, Happy |

A common consumer interface still needs producers. HTTP, WebSocket, MQTT, or a notification service do not themselves define what an agent means by “blocked.” A protocol notification is also not necessarily a phone push notification.

## Protocol comparison

| Protocol | Useful capabilities | Important limit | Fit for this goal |
| --- | --- | --- | --- |
| **Agent Client Protocol v1** | Structured messages and tool updates; prompt/cancel; correlated permission options; negotiated structured elicitation | Stable transport is stdio subprocess; no automatic attachment to an existing agent TUI or phone push service | Strongest existing coding-harness interface |
| **ACP v2 draft** | Explicit foreground `running`, `idle`, `requires_action` states | Draft, not a production interoperability baseline | Closely matches the desired monitoring vocabulary; watch rather than assume |
| **AG-UI** | Agent/frontend event stream, state, tools, human-interrupt/resume model | Requires backend integration; adoption centers on agent frameworks; 1.0 behavioral spec remains draft | Genuine alternative for building a web/mobile agent frontend |
| **A2A 1.0** | Remote tasks, input-required/auth-required states, messages, streaming, webhook push | Server-owned tasks, not terminal sessions; core does not define operation-specific tool authorization semantics | Useful orchestration layer, less direct for coding-agent supervision |
| **MCP + Tasks extension** | Tool-operation elicitation and durable task/input handling | Exposes MCP server operations, not the host agent's entire conversation, status, or native approvals | Useful internally, not a universal monitor/controller boundary |

Sources: [ACP tools/permissions](https://agentclientprotocol.com/protocol/v1/tool-calls), [elicitation](https://agentclientprotocol.com/protocol/v1/elicitation), [transports](https://agentclientprotocol.com/protocol/v1/transports), [v2 draft announcement](https://agentclientprotocol.com/announcements/acp-v2-draft), [AG-UI introduction](https://docs.ag-ui.com/introduction), [interrupts](https://docs.ag-ui.com/concepts/interrupts), [draft status](https://docs.ag-ui.com/spec/draft/index), [A2A specification](https://a2a-protocol.org/v1.0.0/specification), [MCP current changes](https://modelcontextprotocol.io/specification/2026-07-28/changelog), [Tasks extension](https://modelcontextprotocol.io/extensions/tasks/overview).

### Why ACP is the closest match

ACP v1 already separates ordinary text (`session/prompt`) from an approval (`session/request_permission`). An approval request identifies the session/tool and offers option IDs such as allow-once or reject-once. The client answers that particular request with a selected option or cancellation. This is fundamentally stronger than typing `y` into whatever happens to be in a terminal pane. Tool execution is reported through `session/update`; structured user input has a separate, capability-negotiated elicitation mechanism. [Tool/permission spec](https://agentclientprotocol.com/protocol/v1/tool-calls), [elicitation spec](https://agentclientprotocol.com/protocol/v1/elicitation).

There are actual coding-harness implementations, not just a schema:

- Claude: [Claude Agent SDK → ACP adapter](https://github.com/zed-industries/claude-agent-acp).
- Codex: [ACP adapter that launches Codex App Server](https://github.com/agentclientprotocol/codex-acp).
- Gemini: native [`gemini --acp`](https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/acp-mode.md).
- OpenCode: native [`opencode acp`](https://opencode.ai/docs/acp/).
- pi: community [`pi-acp`](https://github.com/svkozak/pi-acp), which spawns `pi --mode rpc`.
- OMP: upstream native [`omp acp`](https://github.com/can1357/oh-my-pi/blob/main/packages/coding-agent/src/modes/acp/acp-mode.ts), with [documented client-routed approvals](https://github.com/can1357/oh-my-pi/blob/main/docs/approval-mode.md#acp-sessions). This is not inferred from pi ancestry and does not establish the user's installed-version support.

**The tradeoff:** the ACP client generally launches the agent's programmatic mode and owns the conversation UI. `session/load`/`resume` concerns conversation state, not hot-attaching a second controller to the normal interactive process. ACP v1's terminal methods ask the client to create/manage commands; they are not a generic PTY attachment API. Standard HTTP/WS transport remains a [proposal](https://agentclientprotocol.com/rfds/streamable-http-websocket-transport). A gateway can supply remote connectivity, but gateways are not automatically interoperable. [Session setup](https://agentclientprotocol.com/protocol/v1/session-setup), [terminals](https://agentclientprotocol.com/protocol/v1/terminals), [transports](https://agentclientprotocol.com/protocol/v1/transports).

### “Blocked” must be explicit

- A quiet terminal could be thinking, rate-limited, disconnected, finished, or asking a question.
- ACP v1 tool status `pending` means arguments are still streaming **or** approval is awaited. Alerting on every pending tool is incorrect.
- ACP `end_turn` means the response ended; it does not distinguish a completed answer from a clarification question expressed only in prose.
- A pending permission/elicitation request is actionable evidence, with a correlation ID. Its resolution is different from a new chat message.
- ACP v2 adds `requires_action`, but its own announcement says draft and recommends feature-flagging rather than shipping by default.

Sources: [tool status](https://agentclientprotocol.com/protocol/v1/tool-calls#status), [turn lifecycle](https://agentclientprotocol.com/protocol/v1/prompt-turn), [v2 lifecycle](https://agentclientprotocol.com/protocol/v2/prompt-lifecycle), [draft announcement](https://agentclientprotocol.com/announcements/acp-v2-draft).

### Why not just A2A or MCP?

A2A genuinely has input-required states and HTTP webhook push; a client can act on behalf of a human. But its abstraction is an opaque remote task. `AUTH_REQUIRED` is not an interchangeable tool-approval dialog, and the core explicitly leaves authorization scope/representation/validity to implementations. Its webhook is not APNs/FCM/Web Push delivery. It still needs a coding-harness adapter and human-facing gateway. [A2A specification](https://a2a-protocol.org/v1.0.0/specification).

MCP elicitation answers questions needed by an MCP server operation. Current 2026-07-28 core uses multi-round-trip input-required responses; durable Tasks moved into an optional official extension. Neither requires the host agent to publish every native approval, message, or state transition. Adding an MCP notification server therefore does not make arbitrary agents observable and remotely controllable. [MCP changes](https://modelcontextprotocol.io/specification/2026-07-28/changelog), [elicitation](https://modelcontextprotocol.io/specification/2026-07-28/client/elicitation), [Tasks](https://modelcontextprotocol.io/extensions/tasks/overview).

Naming trap: **Agent Client Protocol** is not the IBM/BeeAI-associated **Agent Communication Protocol**, whose site now says it is part of A2A. [Communication Protocol site](https://agentcommunicationprotocol.dev/introduction/welcome).

## Collie: the immediate finding

### Existing installation versus current release

The local systemd unit points to a Herdr-managed checkout whose `package.json` reports **0.34.0**. The latest release lookup returned **v1.8.0**, published 2026-09-09. Inspected `main` was one packaging-only commit beyond that release, with no differences in the cited integration code/docs. Local `zellij --version` reports **0.44.3**; read-only help checks confirm pane-targeted text input and JSON pane listing. This is not a live Collie/Zellij compatibility test. [Release](https://github.com/AltanS/collie/releases/tag/v1.8.0).

Current Collie supports `COLLIE_MUX=herdr|tmux|zellij`; Herdr need not be installed or running with either other backend. Zellij/tmux remain explicitly **experimental**, tested upstream on Zellij 0.44.2 and tmux 3.6b with a single operator/host. [Multiplexer guide](https://github.com/AltanS/collie/blob/v1.8.0/docs/multiplexers.md).

For Zellij, one bridge targets **one existing named session**. It lists panes/tabs, reads rendered screen output, and sends text/keys through the CLI. It does not create/restart/resurrect sessions. “Show in terminal” is disabled; topology discovery has an upstream-declared 12-second ceiling, which should not be misquoted as every notification taking 12 seconds. tmux maps all sessions of one server to Collie spaces. [Mux contract](https://github.com/AltanS/collie/blob/v1.8.0/MUX_CONTRACT.md).

### The important harness gap

The shipped beacon emitter explicitly hardcodes `BEACON_HARNESS = "claude"`; the documented installer is `collie hooks install claude`. Its map is:

| Claude hook | Beacon state |
| --- | --- |
| `SessionStart` | idle |
| `UserPromptSubmit` | working |
| `Stop` / `SessionEnd` | idle |
| `Notification`, matcher `idle_prompt` | waiting |

Collie maps `waiting` to `blocked`. But Claude defines `idle_prompt` as approximately **60 seconds after finishing a response without further typing**. The shipped emitter does not register `PermissionRequest` or the distinct `permission_prompt` notification. Thus the documented beacon path is not complete immediate blocked-on-approval detection. A phone UI parsing a visible permission panel is not evidence that the background status/push path receives that event. [Emitter](https://github.com/AltanS/collie/blob/v1.8.0/cli/beacon.ts), [decorator](https://github.com/AltanS/collie/blob/v1.8.0/bridge/beacon/decorate.ts), [state transitions](https://github.com/AltanS/collie/blob/v1.8.0/bridge/state-engine.ts), [Claude notification semantics](https://code.claude.com/docs/en/hooks#notification).

**This is potentially a missing alert, not just a delayed alert.** [INFERENCE from the event map] After `UserPromptSubmit` sets `working`, an unresolved permission prompt does not finish the turn and therefore does not produce the post-response `idle_prompt` signal. With no permission hook updating the beacon, the pane can remain `working` throughout the wait. Reliable permission alerts through this beacon path need an additional integration; waiting 60 seconds is not a workaround. This inference was not exercised against a live Claude session.

Collie does already understand **OMP history**: the journal registry aliases `omp` to `pi` and recognizes OMP session storage. That does **not** supply an OMP beacon emitter or establish OMP detection/attention notifications in Zellij. The record's generic `harness` field is an extensibility point, not a shipped producer for every harness. [Journal registry](https://github.com/AltanS/collie/blob/v1.8.0/bridge/journal/registry.ts), [beacon contract](https://github.com/AltanS/collie/blob/v1.8.0/bridge/beacon/types.ts).

Per-harness coverage in the examined release, specifically for the **standalone Zellij/tmux beacon path**, not Herdr's own detection:

| Harness | Conversation-history reader | Shipped beacon status producer | Consequence |
| --- | --- | --- | --- |
| Claude Code | Yes | Yes, the five events above | Working/idle and delayed post-response waiting; permission waits are not covered by those registrations |
| OpenCode | Yes | None established by the shipped beacon setup | History support does not provide pane identity or attention alerts |
| Codex | Yes | None established by the shipped beacon setup | Same gap; native Codex APIs elsewhere do not automatically integrate with Collie |
| OMP / pi | Yes; OMP aliases to pi | None established by the shipped beacon setup | Normal OMP/pi TUIs are not demonstrated as agent-aware Zellij panes |
| Grok / Hermes | Yes | None established by the shipped beacon setup | Reader support is not status-hook support |

The existing dotfiles include an OpenCode configuration, so OpenCode coverage is relevant too; that does not establish which harnesses are currently in use. Sources are the release's [journal registry](https://github.com/AltanS/collie/blob/v1.8.0/bridge/journal/registry.ts), [Claude-fixed emitter](https://github.com/AltanS/collie/blob/v1.8.0/cli/beacon.ts), and [documented hook setup](https://github.com/AltanS/collie/blob/v1.8.0/docs/multiplexers.md#collie-writes-hooks-into-claudes-own-settings). Generic terminal text/key control is separate from this agent-status coverage.

**Practical implication:** this is a promising way to remove Herdr while retaining the phone UI, not a proven zero-work replacement for all Herdr monitoring. An eventual migration is a major-version upgrade plus deployment/config migration, not merely setting `COLLIE_MUX` in the old install. Standalone config defaults differ; Zellij needs `XDG_RUNTIME_DIR` in the service; 1.x introduces device pairing. Preserve the existing VAPID keys/subscriptions and trusted-user/hostname restrictions. [Upgrade guide](https://github.com/AltanS/collie/blob/v1.8.0/docs/upgrading.md), [security](https://github.com/AltanS/collie/blob/v1.8.0/docs/security.md).

## Existing product shortlist

| Tool | What it supplies | Session/multiplexer tradeoff | OMP/pi reality |
| --- | --- | --- | --- |
| **Collie** | Existing-pane dashboard, phone PWA, push, terminal input | Keeps Zellij/tmux; experimental backends | OMP history understood; shipped beacon producer Claude-only |
| **Paseo** | Mobile/web/desktop clients, push, conversation and supported approvals | Daemon owns launches; mux-independent but not existing-TUI attachment | Released OMP RPC/rpc-ui implementation; opt-in, default unattended |
| **Agent of Empires** | Agent TUI, phone web dashboard, push, terminal and structured chat | Requires tmux and its session workflow; not a Zellij backend | Released `omp acp` and `pi-acp` registrations; terminal detection separately heuristic |
| **HAPI** | Multi-harness web/PWA messaging, push, approvals where supported | Wrapper/hub owns session; handoff differs by harness | Pi is remote-only RPC and always auto-approve; no verified OMP integration |
| **Happy** | Native phone/web client, push, supported permissions | Wrapper-managed local/remote continuation | Main documented coverage Claude/Codex, not a demonstrated OMP/pi solution |
| **ntfy + native hooks** | Phone alerts, links, optional HTTP action buttons | Leaves existing agent/TUI/mux intact | Needs an actual harness event producer; not a built-in OMP controller |

### Paseo: first full-mobile OMP candidate

[Paseo](https://github.com/getpaseo/paseo) advertises mobile/web/desktop clients, voice, daemon-managed agents and optional encrypted relay/direct Tailscale access. Its stable **v0.7.2** source contains an OMP provider, RPC/rpc-ui launch code, and an approval response mapper. This is stronger evidence than a generic claim of supporting pi. However the provider is **disabled by default**, its default mode is **full/unattended**, and its public provider list lags the implementation. Treat this as an opt-in integration to exercise, not guaranteed drop-in compatibility.

`paseo attach` attaches to a Paseo-managed agent, not an arbitrary existing OMP TUI. You can keep Zellij for shells, but agent launch/interaction moves under Paseo. Native push uses Expo; relay E2EE should not be generalized into a claim that notification payloads are invisible to the push service. [Released manifest](https://github.com/getpaseo/paseo/blob/v0.7.2/packages/protocol/src/provider-manifest.ts), [runtime](https://github.com/getpaseo/paseo/blob/v0.7.2/packages/server/src/server/agent/providers/omp/runtime.ts), [permission mapper](https://github.com/getpaseo/paseo/blob/v0.7.2/packages/server/src/server/agent/providers/omp/rpc-ui-permission-mapper.ts), [connectivity](https://github.com/getpaseo/paseo/blob/main/public-docs/connectivity.md), [push implementation](https://github.com/getpaseo/paseo/blob/main/packages/server/src/server/push/push-service.ts).

**External sessions are not excluded.** Released `paseo import` imports a provider session; the OMP provider resumes from a native `.jsonl` file and streams its saved history into Paseo. The app also includes a workspace import sheet. This makes the earlier “Paseo must own launch” description incomplete: it owns the resumed process, but the original conversation may have begun outside Paseo. See the handoff section below. [CLI import](https://github.com/getpaseo/paseo/blob/v0.7.2/packages/cli/src/commands/agent/import.ts), [OMP import/resume](https://github.com/getpaseo/paseo/blob/v0.7.2/packages/server/src/server/agent/providers/omp/agent.ts).

### Agent of Empires: strongest tmux-specific alternative

[AoE](https://github.com/agent-of-empires/agent-of-empires) provides terminal sessions plus structured ACP workers, a phone dashboard, and Web Push. Stable **v1.15.3** explicitly registers `omp acp` and `pi-acp`. Its OMP terminal detector uses screen patterns; structured ACP approvals are a separate, stronger channel. It is worth considering if moving to tmux and accepting a session manager are acceptable. Running it inside Zellij does not remove its tmux dependency. Given the reason for leaving Herdr, this workflow cost matters. [Released structured view](https://github.com/agent-of-empires/agent-of-empires/blob/v1.15.3/docs/structured-view.md), [OMP terminal rules](https://github.com/agent-of-empires/agent-of-empires/blob/main/src/tmux/detect/manifests/omp.toml), [push guide](https://www.agent-of-empires.com/docs/push-notifications/).

### HAPI and Happy: useful, but inspect each harness row

[HAPI v0.29.1](https://github.com/tiann/hapi/blob/v0.29.1/docs/guide/agents.md) is broad, but its Pi support is `pi --mode rpc`, **no local input path**, and **always auto-approve**. Its general seamless-terminal-handoff claim does not apply to Pi; no verified OMP support was found. It has a local hub/SQLite, web UI and push integrations. [Architecture](https://github.com/tiann/hapi/blob/main/docs/guide/how-it-works.md), [PWA](https://github.com/tiann/hapi/blob/main/docs/guide/pwa.md).

[Happy](https://github.com/slopus/happy) is primarily a Claude/Codex native-phone product. Its wrapper-managed switch to remote mode restarts the session in that mode, not arbitrary process attachment. Current self-hosting docs describe a single container with embedded PGlite/local storage; older comparisons claiming mandatory external Postgres/Redis are stale. No demonstrated OMP/pi support was found. [Server docs](https://github.com/slopus/happy/blob/main/packages/happy-server/README.md).

### ntfy: transport, not agent control

[ntfy](https://docs.ntfy.sh/publish/) provides straightforward HTTP publishing, phone notifications, click URLs and action buttons. Native harness events can publish a small machine/session label plus an attention reason, leaving the normal TUI untouched. This is a small integration, not a ready-made harness-independent monitor. Separate turn-finished alerts from actual permission/question events.

A notification button that calls HTTP still needs an authenticated endpoint, request correlation, and a harness response path. ntfy alone supplies none of those agent semantics. [claude-push](https://github.com/coa00/claude-push) demonstrates an existing Claude-only permission-hook/ntfy response bridge; it was README-reviewed, not security-audited, and warns that knowledge of its topic enables approval responses. It is evidence that such a bridge exists, not a recommended universal solution.

Use authenticated, access-controlled topics and minimal metadata rather than source/tool payloads. Self-hosted instant iOS notifications still depend on an APNs-connected upstream; self-hosting is not the same as eliminating push-provider infrastructure. [Access control](https://docs.ntfy.sh/config/#access-control), [iOS delivery](https://docs.ntfy.sh/config/#ios-instant-notifications).

### AgentAPI: existing generic HTTP adapter, not a phone product

[Coder AgentAPI](https://github.com/coder/agentapi) exposes `/message`, `/messages`, `/status` and SSE `/events` over a managed terminal emulator. It launches the agent with `agentapi server -- <agent>`; `agentapi attach` connects to that managed terminal, not arbitrary existing Zellij panes. It uses harness-specific TUI cleanup, and status is `stable`/`running`, not typed permission/input-required. No OMP integration was established. Useful if building a thin client around terminal agents, but weaker semantics than ACP and no complete phone-push layer.

## Agent Manager: a local workspace, not a phone product

Follow-up snapshot: **v0.36.0**, released 2026-09-06. Current main was 11 commits ahead, including unreleased Codex status and Pi/Grok focus fixes; the interface/lifecycle findings here use the release. [Release](https://github.com/YoanWai/agent-manager/releases/tag/v0.36.0), [release-to-main comparison](https://github.com/YoanWai/agent-manager/compare/71a0c6a1f45b25d01e3e6a2355da85f7760489fa...dfd43a897c419eece921fa538f84d430e643f10f).

Agent Manager is an agent-centric **desktop workflow layer over tmux**, not a new multiplexer backend. Its distinctive features are a foldable project/session tree, prompts sent without attaching, shell tabs, optional worktrees, exact-conversation revival/forking for supported harnesses, and full-file diff review whose line comments are sent back as a review prompt. It offers embedded focus and a real full-screen tmux attach. Sessions survive the manager quitting. [README](https://github.com/YoanWai/agent-manager/blob/v0.36.0/README.md), [workflow guide](https://github.com/YoanWai/agent-manager/blob/v0.36.0/docs/usage.md).

That makes it more relevant to the **at-PC DX** question than Collie, which is primarily the remote surface. Against AoE, both own agent sessions/worktrees, but AoE additionally supplies its own phone UI/push and structured ACP workers. Against Paseo, Agent Manager prioritizes interacting with native terminal CLIs, while Paseo's managed protocol sessions support its structured clients. These are suitability judgments, not a comparative usability test.

### Harness and status coverage

| Harness | Agent Manager v0.36.0 status integration | Limitation |
| --- | --- | --- |
| Claude Code | Native hooks, refined/fallback screen analysis | `waiting` combines permission/input dialogs and prose questions; not a typed approval API |
| Codex / OpenCode | Built-in screen rules and conversation capture | Output/version-sensitive classification, not native lifecycle subscription |
| pi | Built-in screen rules and pi-specific session/resume/fork commands | Does not establish OMP compatibility |
| OMP | Custom tool configuration can launch it | No shipped OMP rules, native session integration, or OMP MCP registration style established |

Other built-ins include Grok, Gemini, Command Code and Hermes. Custom `[tools.<name>]` blocks can supply commands/status rules, but “can launch a CLI” is not “has complete integration.” Unlike Collie's beacon emitter, Agent Manager's Claude hook map includes `Notification` matching `permission_prompt|elicitation_dialog` → waiting, and `Stop` → finished. Its broader cross-harness classifications are still partly heuristic. [Configuration](https://github.com/YoanWai/agent-manager/blob/v0.36.0/docs/configuration.md), [built-ins](https://github.com/YoanWai/agent-manager/blob/v0.36.0/internal/config/config.go), [Claude hooks](https://github.com/YoanWai/agent-manager/blob/v0.36.0/internal/hooks/hooks.go).

**The manager must remain running for its classifier and notifications.** Quitting preserves tmux agents, not fresh monitoring. CLI/MCP does not start a replacement poller. `sessions --json` reads stored statuses and fresh tmux liveness; it requires a legitimate `AGENT_MANAGER_SESSION_ID` caller and omits native conversation IDs, socket/pane IDs and status freshness. `wait` observes stored classifications and reports `manager_awake`; it is not an event subscription. `send_session` queues agent-to-agent text and deliberately holds it at permission dialogs, so its MCP interface is not a remote user-approval protocol. SQLite has richer fields, but consuming them is an internal-schema dependency. [CLI/session implementation](https://github.com/YoanWai/agent-manager/blob/v0.36.0/internal/sessioncmd/session.go), [caller validation](https://github.com/YoanWai/agent-manager/blob/v0.36.0/internal/sessioncmd/terminal.go), [wait](https://github.com/YoanWai/agent-manager/blob/v0.36.0/internal/sessioncmd/wait.go), [poller](https://github.com/YoanWai/agent-manager/blob/v0.36.0/internal/ui/poller.go).

Its “as-is CLI” promise also has qualifications: it adds launch notes/MCP coordination instructions, generated Claude settings, Codex config overrides, and an OpenCode `OPENCODE_CONFIG` file. Some other harnesses receive persistent user-scope MCP registration. Installed credentials/features are reused, but launch behavior/configuration is not entirely untouched. [Launch](https://github.com/YoanWai/agent-manager/blob/v0.36.0/internal/launch/launch.go), [MCP registration](https://github.com/YoanWai/agent-manager/blob/v0.36.0/internal/mcpreg/mcpreg.go).

## Combinations: share a transport or hand off ownership

| Arrangement | What is shared | What is not automatic | Assessment |
| --- | --- | --- | --- |
| **Native CLI / Agent Manager → Paseo import** | Saved provider conversation and working tree, sequentially | Same live process, pending tool/approval, or desktop-manager metadata | Best first handoff experiment given interest in Paseo |
| **Agent Manager + Collie** | Exact tmux panes/live agent processes | Agent identity/status, project tree, worktree/lifecycle metadata | Strong simultaneous-control candidate; not zero-integration monitoring |
| **Agent Manager + KDE Connect**, optionally Collie for control | Existing desktop notifications forwarded to Android | Structured input, durable internet push, mobile approval responses | Existing low-code alert candidate; verify desktop/phone delivery |
| **Agent Manager + ntfy + Collie/SSH** | A custom exporter forwards attention; remote tool accesses the same pane | No shipped Agent Manager ntfy/webhook sink | Narrow glue, not a new protocol; keep manager alive or use native hooks |
| **AoE alone, or Paseo alone** | One owner's sessions across its clients | Arbitrary Agent Manager live-process adoption | Coherent integrated alternative, not a second manager grafted onto the first |

### Agent Manager + Collie: real transport seam, separate status

Agent Manager uses a private tmux server named `agentmgr` and sessions named `am_<id>`. Collie supports:

```dotenv
COLLIE_MUX=tmux
COLLIE_MUX_ENDPOINT_TMUX=agentmgr
```

That slashless endpoint means `tmux -L agentmgr`. It can address the same underlying panes, rather than launching a duplicate agent. **Configuration-supported candidate, not an exercised combination.** Agent Manager groups do not become Collie groups; Collie sees one space per tmux session and uses its own status beacons. [Agent Manager tmux](https://github.com/YoanWai/agent-manager/blob/v0.36.0/internal/tmux/tmux.go), [Collie endpoint](https://github.com/AltanS/collie/blob/v1.8.0/bridge/mux/tmux/exec.ts).

Deployment matters: Collie's service has `PrivateTmp=yes`, which can hide the default `/tmp/tmux-<uid>/agentmgr` socket. An absolute path still under `/tmp` does not fix the namespace. One candidate retaining isolation is to start the manager with a consistent `TMUX_TMPDIR` under the user's runtime directory, then point Collie at the resulting absolute socket. Set this before creating the server; changing the environment does not move an existing server. The current host's package database offers tmux 3.7_c, but tmux was not installed as a package during this research. [Collie unit](https://github.com/AltanS/collie/blob/v1.8.0/systemd/collie.service), [systemd isolation](https://www.freedesktop.org/software/systemd/man/latest/systemd.exec.html#PrivateTmp=), [Agent Manager socket resolution](https://github.com/YoanWai/agent-manager/blob/v0.36.0/internal/tmux/tmux.go).

Keep **Agent Manager as the sole lifecycle/group/worktree owner**. Collie's raw create/close/rename operations bypass its database; no fine-grained policy enforcing “input allowed, lifecycle forbidden” was established. Collie's watchers use `ignore-size,read-only`, favorable for sharing, but desktop resizing and external attach still need testing. Browsing Collie does not steal focus; its explicit Show in terminal action can switch every other non-control tmux client. Avoid treating that as a synchronized Agent Manager selection. [Collie adapter](https://github.com/AltanS/collie/blob/v1.8.0/bridge/mux/tmux/adapter.ts), [watcher flags](https://github.com/AltanS/collie/blob/v1.8.0/bridge/mux/tmux/protocol.ts).

### Notifications can be a third component

Agent Manager has desktop notifications, not built-in phone push. **KDE Connect Send Notifications** is an existing desktop-to-phone bridge and supports non-Plasma Linux with caveats. On this Ghostty setup, Agent Manager first emits OSC 777 and returns before `notify-send`; the forwarded notification may belong to Ghostty rather than agent-manager. KDE Connect watches desktop D-Bus notifications, so actual delivery, app filters, VPN connectivity and Android background behavior require verification. A successful escape write is not proof of phone receipt. [KDE feature](https://userbase.kde.org/KDEConnect#Send_Notifications), [manager routing](https://github.com/YoanWai/agent-manager/blob/v0.36.0/internal/notify/notify.go), [Ghostty notifications](https://ghostty.org/docs/config/reference#desktop-notifications).

ntfy provides a cleaner explicit network sink, but Agent Manager has no inspected configurable webhook/command callback. A small notification sink or read-only exporter would be new integration work. Neither forwarding route supplies correlated permission responses; link to the chosen control surface rather than invent allow/deny semantics from `waiting`.

## Paseo handoff over the tailnet: implemented, not live takeover

**SSH can provide the escape hatch the user proposed.** Paseo v0.7.2 exposes `paseo import --provider <provider> [--cwd <path>] <handle>` as a top-level CLI command. It imports an existing provider conversation, including one not started by Paseo. For **OMP the handle is the native `.jsonl` file path**, not Agent Manager's ID and not merely OMP's UUID. The provider reads model/thinking settings, starts a new runtime with that session file, and imports history. [CLI command](https://github.com/getpaseo/paseo/blob/v0.7.2/packages/cli/src/commands/agent/import.ts), [registration](https://github.com/getpaseo/paseo/blob/v0.7.2/packages/cli/src/cli.ts), [OMP import/resume](https://github.com/getpaseo/paseo/blob/v0.7.2/packages/server/src/server/agent/providers/omp/agent.ts), [session discovery](https://github.com/getpaseo/paseo/blob/v0.7.2/packages/server/src/server/agent/providers/omp/session-descriptor.ts), [history import](https://github.com/getpaseo/paseo/blob/v0.7.2/packages/server/src/server/agent/provider-session-import.ts).

Example syntax, **not executed**:

```bash
# On the agent's host, after gracefully stopping the original session:
paseo import --provider omp --cwd /absolute/project-or-worktree \
  /absolute/path/to/conversation.jsonl
```

The released app also has an **Import Session sheet wired into the workspace screen**, fetching recent importable conversations from enabled/available providers and calling the same import endpoint. Thus SSH need not be how the import itself is performed; it can be used just to reach and safely stop the original TUI, then the app can select the saved conversation. This UI path was source-inspected, not phone-tested. [Import sheet](https://github.com/getpaseo/paseo/blob/v0.7.2/packages/app/src/components/import-session-sheet.tsx), [workspace integration](https://github.com/getpaseo/paseo/blob/v0.7.2/packages/app/src/screens/workspace/workspace-screen.tsx), [server discovery/import](https://github.com/getpaseo/paseo/blob/v0.7.2/packages/server/src/server/agent/import-sessions.ts).

Safe handoff model:

1. Work normally at the PC in a native agent TUI, optionally managed by Agent Manager.
2. Reach the existing pane over tailnet SSH. Let the turn finish or interrupt deliberately, then exit the original agent so it is no longer writing the conversation. Prefer a clean turn boundary.
3. Import through Paseo's app or CLI on the host with the same user/session files and exact project/worktree directory.
4. Continue from Paseo; its messaging/approvals/notifications apply to the managed continuation.

**Do not equate saved history with live execution state.** This does not transfer an in-flight command, pending permission dialog, process-local extension state, shell environment, or Agent Manager groups/review metadata. Do not let the old process or Agent Manager's revive action run a second writer against the same conversation. The inspected import path checks for duplicate Paseo imports, not ownership of an independently running external process. For OMP, enable the opt-in provider and choose approval mode deliberately before continuing; its default is full/unattended.

**Before handoff, Paseo is not the notifier for that external session.** If the phone must alert when a locally launched agent blocks, keep the manager/native notification producer plus a forwarding route. Sessions expected to need unattended mobile interaction can start in Paseo; import can remain the exception for ad hoc native sessions.

This changes the recommendation from “Paseo only if everything starts under its daemon” to **“Paseo for mobile, with an explicit transcript handoff from the preferred desktop workflow.”** The remaining question is whether that handoff preserves the needed context and feels sufficiently cheap in practice, not whether an import command exists.

## How to choose without rebuilding everything

The decisive choice is now **simultaneous access to one live process versus an explicit saved-conversation handoff**, not tmux versus Zellij:

1. First pilot a disposable OMP native session → graceful exit → Paseo import, with OMP enabled and a deliberate approval mode. Check saved context, the actual worktree, model/thinking settings, one question/approval and phone delivery. No production-session experiment was performed here.
2. Evaluate Agent Manager's local tree/prompt/diff-review workflow separately. Its OMP custom-tool work is independent of Paseo's existing OMP import support. Plain tmux remains a valid local starting point.
3. If interruptions/restarts are unacceptable, pilot Agent Manager + Collie against the exact shared socket, with Agent Manager alone managing lifecycle. Verify pane identity, resizing, input/focus, and actual per-harness attention coverage.
4. Evaluate an existing notification forwarder before writing a custom bridge. Agent Manager must stay running for its own classifications; native harness producers can be independent.
5. Prefer AoE as one integrated owner if its local and mobile surfaces both fit. Use ACP for new semantic integrations, not as a promise of live-process adoption.

Remote terminal input grants shell-level control, including after the agent exits. Keep remote access private and authenticated; distinguish private Tailscale Serve from public Funnel. Permission notifications must not silently change approval policy.

**Research boundary:** source and specification findings are verified as described; migration, notification reliability, simultaneous local/remote behavior, and compatibility with the user's installed agent versions remain untested. No operational changes were made.
