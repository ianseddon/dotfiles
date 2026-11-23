// Work Board: stable 5-column SDLC pipeline for your own Jira tickets,
// GitHub PRs, and live Herdr agent sessions, paired with a zoom-in stack
// so the board stays out of sight while you focus on a single task.
//
// Roles (via props().role):
//   "bar"       Always-visible 28px bottom pulse bar. Owns the background
//               poller and handles key commands ("work-board.toggle", "work-board.refresh").
//   "board"     Full-window 5-column board inside view-stack.
//   "card-menu" Pointer popup for per-card actions.

import { View, div, svg, image } from "gpui-kit";
import { h_flex, v_flex } from "gpui-base";
import {
  agents,
  appHome,
  checking,
  closeOverlay,
  exec,
  home,
  keys,
  layout,
  nextCommand,
  openOverlay,
  panes,
  props,
  readTextFile,
  run,
  setAgentOrder,
  setShared,
  shared,
  spaces,
  theme,
  window,
  writeTextFile,
} from "herdr";

const STACK_ID = "view-stack";
const POLL_MS = 90_000;
const CLOCK_MS = 30_000;
const STALE_WARN_DAYS = 1;
const STALE_HOT_DAYS = 3;
const JIRA_KEY_RE = /\b([A-Z][A-Z0-9]{1,9}-\d+)\b/i;
const DEFAULT_BRANCHES = new Set(["main", "master", "develop", "HEAD"]);
const AGENT_RANK = { blocked: 4, done: 3, working: 2, idle: 1 };

const COLUMNS = [
  {
    key: "spec_build",
    label: "Spec & Build",
    subtitle: "Local worktrees & agents",
    ball: "me",
    accentKey: "working",
  },
  {
    key: "self_review",
    label: "Self-Review",
    subtitle: "Drafts & no reviewers",
    ball: "me",
    accentKey: "blocked",
  },
  {
    key: "needs_action",
    label: "Needs Action",
    subtitle: "Unresolved · CI · conflicts",
    ball: "me",
    accentKey: "ansi1",
  },
  {
    key: "in_review",
    label: "In Review",
    subtitle: "Waiting on reviewers",
    ball: "others",
    accentKey: "muted",
  },
  {
    key: "ready_to_merge",
    label: "Ready to Merge",
    subtitle: "Approved & green CI",
    ball: "me",
    accentKey: "done",
  },
];

function findNode(node, id) {
  if (!node) return null;
  if (node.id === id) return node;
  for (const child of node.children ?? []) {
    const found = findNode(child, id);
    if (found) return found;
  }
  return null;
}

function activeView() {
  return findNode(layout(), STACK_ID)?.active ?? "workspace";
}

function setView(child) {
  run("layout.select", { stack: STACK_ID, child });
}

function toggleView() {
  setView(activeView() === "board" ? "workspace" : "board");
}

function cachePath() {
  return `${appHome()}/work-board-cache.json`;
}

function dataBinPath() {
  return `${appHome()}/mods/work-board/bin/work-board-data`;
}

function openExternal(url) {
  if (!url) return;
  const opener = window()?.platform === "macos" ? "open" : "xdg-open";
  exec(opener, [url]).catch(() => {});
}

function ageMs(iso) {
  if (!iso) return 0;
  const t = Date.parse(iso);
  return Number.isFinite(t) ? Math.max(0, Date.now() - t) : 0;
}

function ageDays(iso) {
  return ageMs(iso) / 86_400_000;
}

function formatAge(iso) {
  if (!iso) return "";
  const mins = Math.floor(ageMs(iso) / 60_000);
  if (mins < 1) return "<1m";
  if (mins < 60) return `${mins}m`;
  const hours = Math.floor(mins / 60);
  if (hours < 48) return `${hours}h`;
  return `${Math.floor(hours / 24)}d`;
}

function cleanPrTitle(title, jiraKey) {
  if (!title) return "";
  if (!jiraKey) return title;
  const escaped = jiraKey.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  return title
    .replace(new RegExp(`\\s*\\(${escaped}\\)\\s*$`, "i"), "")
    .replace(new RegExp(`^${escaped}[:\\s-]+`, "i"), "")
    .trim();
}

function extractJiraKey(text) {
  const m = text?.match(JIRA_KEY_RE);
  return m ? m[1].toUpperCase() : null;
}

function sanitizeBranchSlug(branch) {
  return (branch ?? "").replace(/\//g, "-").toLowerCase();
}

function programIcon(program, size, color) {
  if (!program?.icon) return null;
  return program.tint
    ? svg(program.icon).size(size).flex_none().text_color(color)
    : image(program.icon).w(size).h(size).flex_none();
}

function statusDot(t, status, size = 7) {
  const color = t[status] ?? t.dim;
  if (status === "working") {
    return svg("mods/workspace-chrome/spinner.svg").size(size + 3).flex_none().text_color(t.working).spin(900);
  }
  if (status === "idle") {
    return div().size(size).flex_none().rounded(size).border(1.5).border_color(t.idle ?? t.dim);
  }
  return div().size(size).flex_none().rounded(size).bg(color);
}

// Joins live Herdr spaces/panes/agents onto PR items, and produces Spec & Build
// cards for active local spaces that do not yet have an open PR.
function buildBoardModel(snapshot) {
  const allSpaces = spaces();
  const allPanes = panes();
  const allAgents = agents();

  const agentsBySpace = new Map();
  for (const a of allAgents) {
    const list = agentsBySpace.get(a.space) ?? [];
    list.push(a);
    agentsBySpace.set(a.space, list);
  }

  // Collect all branches seen per space (from space.branch + panes in its tabs).
  const branchesBySpace = new Map();
  const spaceByTab = new Map();
  for (const s of allSpaces) {
    const set = new Set();
    if (s.branch) set.add(s.branch);
    branchesBySpace.set(s.id, set);
    for (const tab of s.tabs ?? []) spaceByTab.set(tab.id, s.id);
  }
  for (const p of allPanes) {
    const sid = spaceByTab.get(p.tab);
    if (sid && p.branch) branchesBySpace.get(sid)?.add(p.branch);
  }

  const matchedSpaces = new Set();
  const prs = snapshot?.prs ?? [];
  const jiraMap = snapshot?.jira ?? {};

  const prCards = prs.map((pr) => {
    const slug = sanitizeBranchSlug(pr.branch);
    const matches = allSpaces.filter((s) => {
      const branches = branchesBySpace.get(s.id);
      if (branches?.has(pr.branch)) return true;
      if (slug && s.folder?.toLowerCase().endsWith(`/${slug}`)) return true;
      return false;
    });

    for (const s of matches) matchedSpaces.add(s.id);

    const linkedAgents = matches
      .flatMap((s) => agentsBySpace.get(s.id) ?? [])
      .sort((a, b) => (AGENT_RANK[b.status] ?? 0) - (AGENT_RANK[a.status] ?? 0));

    const topAgent = linkedAgents[0] ?? null;
    const primarySpace = matches[0] ?? null;

    return {
      kind: "pr",
      id: pr.id,
      column: pr.column,
      ball: pr.ball,
      parked: pr.parked,
      repo: pr.repo,
      repoShort: pr.repoShort,
      number: pr.number,
      url: pr.url,
      branch: pr.branch,
      isStacked: pr.isStacked,
      title: cleanPrTitle(pr.title, pr.jiraKey),
      rawTitle: pr.title,
      reason: pr.reason,
      waitingSince: pr.waitingSince,
      ciState: pr.ciState,
      mergeable: pr.mergeable,
      additions: pr.additions,
      deletions: pr.deletions,
      unresolvedNeedsMe: pr.unresolvedNeedsMe,
      unresolvedTotal: pr.unresolvedTotal,
      siblingPrCount: pr.siblingPrCount,
      jiraKey: pr.jiraKey,
      jira: pr.jira ?? (pr.jiraKey ? jiraMap[pr.jiraKey] ?? null : null),
      space: primarySpace,
      agents: linkedAgents,
      topAgent,
    };
  });

  // Unmatched live spaces with either an agent or a feature branch go into Spec & Build.
  const localCards = [];
  for (const s of allSpaces) {
    if (matchedSpaces.has(s.id)) continue;
    const spaceAgents = (agentsBySpace.get(s.id) ?? []).sort(
      (a, b) => (AGENT_RANK[b.status] ?? 0) - (AGENT_RANK[a.status] ?? 0)
    );
    const hasFeatureBranch = Boolean(s.branch && !DEFAULT_BRANCHES.has(s.branch));
    if (spaceAgents.length === 0 && !hasFeatureBranch) continue;

    const jiraKey = extractJiraKey(s.branch) ?? extractJiraKey(s.name);
    const jira = jiraKey ? jiraMap[jiraKey] ?? null : null;
    const topAgent = spaceAgents[0] ?? null;
    const repoGuess = inferRepoFromFolder(s.folder);
    const changedMs = Math.max(0, ...(s.tabs ?? []).map((tb) => tb.changed_at ?? 0));

    localCards.push({
      kind: "local",
      id: `space:${s.id}`,
      column: "spec_build",
      ball: topAgent?.status === "working" ? "others" : "me",
      parked: false,
      repo: repoGuess.full,
      repoShort: repoGuess.short,
      number: null,
      url: null,
      branch: s.branch ?? "",
      isStacked: false,
      title: jira?.summary || s.name || s.branch || "Workspace",
      rawTitle: s.name,
      reason: topAgent
        ? `${topAgent.program?.name ?? "Agent"} · ${topAgent.status}`
        : s.branch || "Local branch",
      waitingSince: changedMs ? new Date(changedMs).toISOString() : null,
      ciState: null,
      mergeable: null,
      additions: null,
      deletions: null,
      unresolvedNeedsMe: 0,
      unresolvedTotal: 0,
      siblingPrCount: 0,
      jiraKey,
      jira,
      space: s,
      agents: spaceAgents,
      topAgent,
    });
  }

  return [...localCards, ...prCards];
}

function inferRepoFromFolder(folder) {
  if (!folder) return { full: "local", short: "local" };
  // Matches ~/dev/wt/<owner>/<repo>/<branch> or ~/dev/github.com/<owner>/<repo>
  const wtMatch = folder.match(/\/wt\/([^/]+\/[^/]+)/);
  if (wtMatch) return { full: wtMatch[1], short: wtMatch[1].split("/")[1] };
  const ghMatch = folder.match(/\/github\.com\/([^/]+\/[^/]+)/);
  if (ghMatch) return { full: ghMatch[1], short: ghMatch[1].split("/")[1] };
  const parts = folder.replace(/\/+$/, "").split("/").filter(Boolean);
  const last = parts[parts.length - 1] ?? "local";
  return { full: last, short: last };
}

function sortColumnCards(cards) {
  return [...cards].sort((a, b) => {
    // 1. Blocked agents always float to the very top.
    const aBlocked = a.topAgent?.status === "blocked" ? 1 : 0;
    const bBlocked = b.topAgent?.status === "blocked" ? 1 : 0;
    if (aBlocked !== bBlocked) return bBlocked - aBlocked;

    // 2. Non-parked above parked.
    if (Boolean(a.parked) !== Boolean(b.parked)) return a.parked ? 1 : -1;

    // 3. Oldest waiting time (stalest) first.
    const aTime = a.waitingSince ? Date.parse(a.waitingSince) : Infinity;
    const bTime = b.waitingSince ? Date.parse(b.waitingSince) : Infinity;
    if (aTime !== bTime) return aTime - bTime;

    return (a.id ?? "").localeCompare(b.id ?? "");
  });
}

function focusItem(item) {
  if (item.topAgent) {
    run("agent.focus", { terminal: item.topAgent.address });
    setView("workspace");
    return true;
  }
  if (item.space) {
    run("space.select", { id: item.space.id });
    setView("workspace");
    return true;
  }
  return false;
}

export default class WorkBoard extends View {
  init(_props, cx) {
    const role = props()?.role ?? "board";
    this.role = role;
    this.loading = false;
    this.lastCacheRaw = null;

    if (checking()) return;

    // Periodic UI tick to keep relative age labels fresh.
    cx.timer.every(CLOCK_MS, (cx) => cx.notify());

    if (role === "bar") {
      // Load persisted cache immediately so the UI never waits on the network.
      cx.spawn(async (cx) => {
        try {
          const raw = await readTextFile(cachePath());
          if (raw) {
            this.lastCacheRaw = raw;
            const parsed = JSON.parse(raw);
            if (!shared("work-board.snapshot")) {
              setShared("work-board.snapshot", parsed);
            }
          }
        } catch {
          // Ignore malformed or absent cache.
        }
        cx.notify();
        this.refresh(cx);
      });

      cx.timer.every(POLL_MS, (cx) => this.refresh(cx));

      // Handle global key commands ("work-board.toggle", "work-board.refresh").
      cx.spawn(async (cx) => {
        for (;;) {
          const cmd = await nextCommand();
          if (cmd === "toggle") toggleView();
          else if (cmd === "refresh") this.refresh(cx);
          cx.notify();
        }
      });
    }
  }

  refresh(cx) {
    if (this.loading) return;
    this.loading = true;
    setShared("work-board.loading", true);
    cx.notify();

    cx.spawn(async (cx) => {
      try {
        const res = await exec(dataBinPath(), ["--json"], { timeout: 45_000 });
        if (res.code === 0 && res.stdout) {
          const parsed = JSON.parse(res.stdout);
          setShared("work-board.snapshot", parsed);
          setShared("work-board.error", null);
          const nextRaw = JSON.stringify(parsed);
          try {
            await writeTextFile(cachePath(), nextRaw, this.lastCacheRaw);
            this.lastCacheRaw = nextRaw;
          } catch {
            // Stale expected snapshot; re-read on next write.
            this.lastCacheRaw = await readTextFile(cachePath()).catch(() => null);
          }
        } else {
          setShared("work-board.error", (res.stderr || `exit ${res.code}`).trim().slice(0, 160));
        }
      } catch (err) {
        setShared("work-board.error", String(err?.message ?? err).slice(0, 160));
      } finally {
        this.loading = false;
        setShared("work-board.loading", false);
        cx.notify();
      }
    });
  }

  paletteHint() {
    const mac = window()?.platform === "macos";
    const mod = {
      cmd: mac ? "⌘" : "Ctrl+",
      ctrl: mac ? "⌃" : "Ctrl+",
      shift: mac ? "⇧" : "Shift+",
      alt: mac ? "⌥" : "Alt+",
      option: mac ? "⌥" : "Alt+",
    };
    const b = keys().find((k) => k.section === "global" && k.action === "app.palette");
    if (!b) return "commands";
    const parts = b.keys.endsWith("--") ? [...b.keys.slice(0, -2).split("-"), "-"] : b.keys.split("-");
    const key = parts.map((p) => mod[p.toLowerCase()] ?? p.toUpperCase()).join("");
    return `${key}  commands`;
  }

  // ---- Role: "bar" (always-shown 28px pulse strip) ----
  renderBar(t) {
    const snap = shared("work-board.snapshot");
    const isLoading = Boolean(shared("work-board.loading"));
    const inBoard = activeView() === "board";
    const allAgents = agents();
    const blockedCount = allAgents.filter((a) => a.status === "blocked").length;
    const space = spaces().find((s) => s.active);

    const counts = snap?.counts ?? null;
    const activePr = space?.branch ? snap?.prs?.find((p) => p.branch === space.branch) : null;

    const pill = (id, label, count, color, filterPreset) =>
      h_flex()
        .id(id)
        .h(20)
        .px(7)
        .gap(5)
        .rounded(5)
        .items_center()
        .cursor_pointer()
        .hover((s) => s.bg(t.hover))
        .on_click(() => {
          if (filterPreset) setShared("work-board.filter", filterPreset);
          setView("board");
        })
        .child(div().size(6).rounded(3).bg(color).flex_none())
        .child(div().text_size(11.5).text_color(t.foreground).font_semibold().child(String(count)))
        .child(div().text_size(11).text_color(t.muted).child(label));

    return h_flex()
      .size_full()
      .px(10)
      .gap(10)
      .items_center()
      .bg(t.chrome)
      .border_t(1)
      .border_color(t.border)
      .text_size(11.5)
      .text_color(t.muted)
      // Board / Workspace toggle button
      .child(
        h_flex()
          .id("wb-toggle")
          .h(20)
          .px(8)
          .gap(6)
          .rounded(5)
          .items_center()
          .cursor_pointer()
          .bg(inBoard ? t.accent : t.raised)
          .text_color(inBoard ? t.accent_foreground : t.foreground)
          .hover((s) => s.bg(inBoard ? t.accent : t.hover))
          .tooltip("Toggle Work Board (bind work-board.toggle in keys.json)")
          .on_click(() => toggleView())
          .when(blockedCount > 0 && !inBoard, (el) =>
            el.child(div().size(6).rounded(3).bg(t.blocked).flex_none())
          )
          .child(div().font_semibold().text_size(11).child(inBoard ? "← Workspace" : "Board"))
      )
      // Live pipeline summary pills
      .when(Boolean(counts), (el) =>
        el
          .child(pill("bar-self", "self-review", counts.self_review, t.blocked, "mine"))
          .child(pill("bar-act", "action", counts.needs_action, t.ansi1 ?? t.blocked, "mine"))
          .child(pill("bar-merge", "merge", counts.ready_to_merge, t.done, "mine"))
          .child(pill("bar-rev", "review", counts.in_review, t.dim, "all"))
      )
      .when(!counts, (el) =>
        el.child(div().text_color(t.dim).child(isLoading ? "Loading GitHub & Jira..." : "No snapshot yet"))
      )
      // Divider + active space context when zoomed into workspace
      .when(!inBoard && Boolean(space), (el) =>
        el
          .child(div().w(1).h(12).bg(t.border))
          .child(
            div()
              .max_w(220)
              .truncate()
              .text_color(t.muted)
              .child(space.branch ? `${space.name} · ${space.branch}` : space.name)
          )
          .when(Boolean(activePr), (e2) =>
            e2.child(
              h_flex()
                .id("bar-active-pr")
                .h(19)
                .px(6)
                .gap(5)
                .rounded(4)
                .bg(t.raised)
                .items_center()
                .cursor_pointer()
                .hover((s) => s.bg(t.hover))
                .on_click(() => openExternal(activePr.url))
                .when(Boolean(activePr.jiraKey), (e3) =>
                  e3.child(div().text_size(10.5).font_semibold().text_color(t.accent).child(activePr.jiraKey))
                )
                .child(div().text_size(10.5).text_color(t.foreground).child(`#${activePr.number}`))
            )
          )
      )
      .child(div().flex_1())
      // Right side: agent count + refresh status + command palette
      .child(
        h_flex()
          .gap(6)
          .items_center()
          .child(div().size(6).rounded(3).bg(blockedCount > 0 ? t.blocked : t.dim))
          .child(`${allAgents.length} ${allAgents.length === 1 ? "agent" : "agents"}`)
          .when(blockedCount > 0, (el) =>
            el.child(div().text_color(t.blocked).font_semibold().child(`· ${blockedCount} blocked`))
          )
      )
      .when(isLoading, (el) =>
        el.child(svg("mods/workspace-chrome/spinner.svg").size(11).text_color(t.muted).spin(900))
      )
      .child(
        div()
          .id("bar-palette")
          .text_color(t.dim)
          .cursor_pointer()
          .hover((s) => s.text_color(t.foreground))
          .on_click(() => run("app.palette"))
          .child(this.paletteHint())
      );
  }

  // ---- Role: "card-menu" (pointer popup) ----
  renderCardMenu(t) {
    const { item, overlay } = props();
    if (!item) return div();

    const menuItem = (id, label, sub, action, accent = false) =>
      h_flex()
        .id(id)
        .h(30)
        .px(10)
        .gap(8)
        .rounded(6)
        .items_center()
        .cursor_pointer()
        .text_color(accent ? t.accent : t.foreground)
        .hover((s) => s.bg(t.hover))
        .on_click(() => {
          closeOverlay(overlay);
          action();
        })
        .child(div().flex_1().truncate().text_size(12).child(label))
        .when(Boolean(sub), (el) => el.child(div().text_size(10.5).text_color(t.dim).child(sub)));

    const activeSpace = spaces().find((s) => s.active);
    const targetMachine = activeSpace?.machine ?? null;
    const wtPath =
      item.repo && item.branch && item.repo.includes("/")
        ? `${targetMachine ? "~" : home()}/dev/wt/${item.repo}/${sanitizeBranchSlug(item.branch)}`
        : null;

    return v_flex()
      .w_full()
      .p(6)
      .gap(2)
      .bg(t.popover)
      .child(
        div()
          .px(10)
          .pt(4)
          .pb(6)
          .text_size(11)
          .text_color(t.muted)
          .truncate()
          .child(
            [item.jiraKey, item.number ? `#${item.number}` : null, item.repoShort]
              .filter(Boolean)
              .join(" · ")
          )
      )
      .when(Boolean(item.space || item.topAgent), (el) =>
        el.child(menuItem("cm-focus", "Zoom into workspace", item.space?.name ?? "", () => focusItem(item), true))
      )
      .when(Boolean(item.url), (el) =>
        el.child(menuItem("cm-pr", "Open PR in browser", `#${item.number}`, () => openExternal(item.url)))
      )
      .when(Boolean(item.jira?.url), (el) =>
        el.child(menuItem("cm-jira", "Open Jira ticket", item.jiraKey, () => openExternal(item.jira.url)))
      )
      .when(!item.space && Boolean(wtPath), (el) =>
        el.child(
          menuItem("cm-wt", "Open worktree space", targetMachine ?? "local", () => {
            const args = {
              name: item.jiraKey ? `${item.jiraKey} ${item.branch}` : item.branch,
              folder: wtPath,
            };
            if (targetMachine) args.machine = targetMachine;
            run("space.new", args);
            setView("workspace");
          })
        )
      )
      .child(div().h(1).my(3).bg(t.border))
      .child(menuItem("cm-close", "Dismiss", "Esc", () => {}));
  }

  // ---- Role: "board" (full-window 5-column pipeline) ----
  renderChip(t, id, label, active, onClick) {
    return h_flex()
      .id(id)
      .h(24)
      .px(9)
      .gap(5)
      .rounded(6)
      .items_center()
      .cursor_pointer()
      .border(1)
      .border_color(active ? t.accent : t.border)
      .bg(active ? t.accent + "22" : t.surface)
      .text_size(11.5)
      .text_color(active ? t.accent : t.muted)
      .hover((s) => s.bg(active ? t.accent + "30" : t.hover).text_color(t.foreground))
      .on_click(onClick)
      .child(label);
  }

  renderCard(t, item, col, showRepoTag) {
    const days = ageDays(item.waitingSince);
    const staleHot = col.ball === "me" && days >= STALE_HOT_DAYS;
    const staleWarn = col.ball === "me" && days >= STALE_WARN_DAYS && !staleHot;

    const stripeColor =
      item.topAgent?.status === "blocked"
        ? t.blocked
        : item.column === "needs_action"
        ? t.ansi1 ?? t.blocked
        : item.column === "ready_to_merge"
        ? t.done
        : item.column === "self_review"
        ? t.blocked
        : item.topAgent?.status === "working"
        ? t.working
        : t.border;

    const ageColor = staleHot
      ? t.ansi1 ?? t.blocked
      : staleWarn
      ? t.blocked
      : t.dim;

    const ciGlyph =
      item.ciState === "SUCCESS"
        ? { text: "✓", color: t.done }
        : item.ciState === "FAILURE" || item.ciState === "ERROR"
        ? { text: "✗", color: t.ansi1 ?? t.blocked }
        : item.ciState === "PENDING" || item.ciState === "EXPECTED"
        ? { text: "⋯", color: t.blocked }
        : null;

    const openMenu = () =>
      openOverlay({
        mod: "work-board",
        props: { role: "card-menu", item },
        kind: "popup",
        at: "pointer",
        width: 260,
      });

    return v_flex()
      .id(`card-${item.id}`)
      .w_full()
      .flex_none()
      .rounded(7)
      .overflow_hidden()
      .bg(item.parked ? t.chrome : t.surface)
      .border(1)
      .border_color(item.topAgent?.status === "blocked" ? t.blocked : t.border)
      .cursor_pointer()
      .hover((s) => s.border_color(stripeColor).bg(t.raised))
      .on_click(() => {
        if (!focusItem(item)) openMenu();
      })
      .child(
        v_flex()
          .w_full()
          .min_w(0)
          .px(9)
          .py(7)
          .gap(4)
          .border_l(3)
          .border_color(stripeColor)
          // Row 1: Jira key · PR # · Repo · Multi-PR/Stack · Age · Menu button
          .child(
            h_flex()
              .gap(5)
              .items_center()
              .text_size(10.5)
              .when(Boolean(item.jiraKey), (el) =>
                el.child(
                  div()
                    .id(`jira-${item.id}`)
                    .px(5)
                    .py(1)
                    .rounded(4)
                    .bg(t.accent + "20")
                    .text_color(t.accent)
                    .font_semibold()
                    .cursor_pointer()
                    .hover((s) => s.bg(t.accent + "38"))
                    .tooltip(item.jira?.summary || item.jiraKey)
                    .on_click((_e, cx) => {
                      cx.stop_propagation();
                      if (item.jira?.url) openExternal(item.jira.url);
                    })
                    .child(item.jiraKey)
                )
              )
              .when(Boolean(item.number), (el) =>
                el.child(
                  div()
                    .id(`pr-${item.id}`)
                    .text_color(t.muted)
                    .font_semibold()
                    .cursor_pointer()
                    .hover((s) => s.text_color(t.foreground))
                    .tooltip("Open PR in browser")
                    .on_click((_e, cx) => {
                      cx.stop_propagation();
                      openExternal(item.url);
                    })
                    .child(`#${item.number}`)
                )
              )
              .when(showRepoTag && Boolean(item.repoShort), (el) =>
                el.child(div().text_color(t.dim).truncate().child(item.repoShort))
              )
              .when(item.siblingPrCount > 1, (el) =>
                el.child(
                  div()
                    .px(4)
                    .rounded(3)
                    .bg(t.raised)
                    .text_color(t.muted)
                    .text_size(9.5)
                    .child(`${item.siblingPrCount} PRs`)
                )
              )
              .when(item.isStacked, (el) =>
                el.child(
                  div()
                    .px(4)
                    .rounded(3)
                    .bg(t.raised)
                    .text_color(t.dim)
                    .text_size(9.5)
                    .child("stack")
                )
              )
              .child(div().flex_1())
              .when(Boolean(item.waitingSince), (el) =>
                el.child(
                  div()
                    .flex_none()
                    .px(4)
                    .rounded(3)
                    .bg(staleHot ? (t.ansi1 ?? t.blocked) + "22" : staleWarn ? t.blocked + "1e" : t.chrome + "00")
                    .text_color(ageColor)
                    .font_semibold()
                    .child(formatAge(item.waitingSince))
                )
              )
              .child(
                div()
                  .id(`more-${item.id}`)
                  .px(3)
                  .rounded(3)
                  .text_color(t.dim)
                  .cursor_pointer()
                  .hover((s) => s.bg(t.hover).text_color(t.foreground))
                  .on_click((_e, cx) => {
                    cx.stop_propagation();
                    openMenu();
                  })
                  .child("⋯")
              )
          )
          // Row 2: Title
          .child(
            div()
              .text_size(12.2)
              .font_semibold()
              .text_color(item.parked ? t.muted : t.foreground)
              .truncate()
              .child(item.title || item.branch)
          )
          // Row 3: Reason · CI · Jira status · Live agents
          .child(
            h_flex()
              .gap(6)
              .items_center()
              .text_size(10.5)
              .when(Boolean(ciGlyph), (el) =>
                el.child(div().flex_none().font_bold().text_color(ciGlyph.color).child(ciGlyph.text))
              )
              .child(div().truncate().text_color(t.muted).child(item.reason))
              .when(Boolean(item.jira?.status), (el) =>
                el.child(
                  div()
                    .flex_none()
                    .px(4)
                    .rounded(3)
                    .bg(t.chrome)
                    .text_color(t.dim)
                    .text_size(9.5)
                    .child(item.jira.status)
                )
              )
              .child(div().flex_1())
              // Live agent pills when an agent is attached to this branch/space
              .when(item.agents.length > 0, (el) =>
                el.child(
                  h_flex()
                    .gap(4)
                    .items_center()
                    .flex_none()
                    .children(
                      item.agents.slice(0, 2).map((a) =>
                        h_flex()
                          .px(5)
                          .py(1)
                          .gap(4)
                          .rounded(4)
                          .bg(t.raised)
                          .items_center()
                          .child(statusDot(t, a.status, 6))
                          .when(Boolean(programIcon(a.program, 11, t.foreground)), (e2) =>
                            e2.child(programIcon(a.program, 11, t.foreground))
                          )
                          .child(div().text_size(10).text_color(t.foreground).child(a.program?.key ?? "agent"))
                      )
                    )
                    .when(item.agents.length > 2, (e2) =>
                      e2.child(div().text_size(9.5).text_color(t.dim).child(`+${item.agents.length - 2}`))
                    )
                )
              )
              .when(item.agents.length === 0 && Boolean(item.space), (el) =>
                el.child(
                  div()
                    .flex_none()
                    .px(4)
                    .rounded(3)
                    .bg(t.raised)
                    .text_size(9.5)
                    .text_color(t.dim)
                    .child("open")
                )
              )
          )
      );
  }

  renderColumnBody(t, col, items, groupByRepo, showRepoTag) {
    if (items.length === 0) {
      return div()
        .w_full()
        .py(18)
        .px(10)
        .rounded(7)
        .border(1)
        .border_color(t.border)
        .text_size(11)
        .text_color(t.dim)
        .child("Nothing here");
    }

    if (!groupByRepo) {
      return v_flex()
        .flex_1()
        .min_h(0)
        .overflow_y_scrollbar()
        .gap(7)
        .children(items.map((item) => this.renderCard(t, item, col, showRepoTag)));
    }

    // Repo swimlanes inside each column (for comparing chip filtering vs grouping).
    const byRepo = new Map();
    for (const item of items) {
      const key = item.repoShort || "local";
      const list = byRepo.get(key) ?? [];
      list.push(item);
      byRepo.set(key, list);
    }

    return v_flex()
      .flex_1()
      .min_h(0)
      .overflow_y_scrollbar()
      .gap(10)
      .children(
        [...byRepo.entries()].map(([repoName, group]) =>
          v_flex()
            .w_full()
            .gap(6)
            .child(
              h_flex()
                .px(3)
                .gap(6)
                .items_center()
                .child(div().text_size(10.5).font_semibold().text_color(t.muted).child(repoName))
                .child(div().text_size(10).text_color(t.dim).child(String(group.length)))
                .child(div().flex_1().h(1).bg(t.border))
            )
            .children(group.map((item) => this.renderCard(t, item, col, false)))
        )
      );
  }

  renderBoard(t, cx) {
    const snap = shared("work-board.snapshot");
    const isLoading = Boolean(shared("work-board.loading"));
    const error = shared("work-board.error");

    const filter = shared("work-board.filter") ?? "all";
    const repoFilter = shared("work-board.repo") ?? "all";
    const showParked = Boolean(shared("work-board.showParked"));
    const groupByRepo = Boolean(shared("work-board.groupByRepo"));

    const allItems = buildBoardModel(snap);

    // Keep agent.next / agent.prev aligned with pipeline urgency order.
    const orderedAgentAddrs = COLUMNS.flatMap((col) =>
      sortColumnCards(allItems.filter((i) => i.column === col.key)).flatMap((i) =>
        i.agents.map((a) => a.address)
      )
    );
    if (orderedAgentAddrs.length > 0) setAgentOrder(orderedAgentAddrs);

    // Compute available repos from items.
    const repoCounts = new Map();
    for (const item of allItems) {
      if (!showParked && item.parked) continue;
      const key = item.repoShort || "local";
      repoCounts.set(key, (repoCounts.get(key) ?? 0) + 1);
    }
    const repoList = [...repoCounts.entries()].sort((a, b) => b[1] - a[1]);

    const visibleItems = allItems.filter((item) => {
      if (!showParked && item.parked) return false;
      if (repoFilter !== "all" && (item.repoShort || "local") !== repoFilter) return false;
      if (filter === "mine" && item.ball !== "me") return false;
      if (filter === "agents" && item.agents.length === 0) return false;
      if (filter === "stale" && ageDays(item.waitingSince) < STALE_HOT_DAYS) return false;
      return true;
    });

    const parkedCount = allItems.filter((i) => i.parked).length;
    const mineCount = allItems.filter((i) => !i.parked && i.ball === "me").length;
    const withAgentCount = allItems.filter((i) => !i.parked && i.agents.length > 0).length;
    const staleCount = allItems.filter((i) => !i.parked && ageDays(i.waitingSince) >= STALE_HOT_DAYS).length;

    const showRepoTag = repoFilter === "all" && !groupByRepo;

    return v_flex()
      .size_full()
      .bg(t.canvas)
      // Header + filter strip
      .child(
        v_flex()
          .w_full()
          .flex_none()
          .px(18)
          .py(12)
          .gap(8)
          .bg(t.chrome)
          .border_b(1)
          .border_color(t.border)
          // Row 1: Title, counts, refresh, back to workspace
          .child(
            h_flex()
              .items_center()
              .gap(10)
              .child(div().text_size(17).font_semibold().text_color(t.foreground).child("Work Board"))
              .child(
                div()
                  .text_size(11.5)
                  .text_color(t.muted)
                  .child(
                    snap?.fetchedAt
                      ? `${visibleItems.length} shown · synced ${formatAge(snap.fetchedAt)} ago`
                      : "Syncing..."
                  )
              )
              .when(Boolean(error), (el) =>
                el.child(div().text_size(11).text_color(t.ansi1 ?? t.blocked).truncate().child(`· ${error}`))
              )
              .child(div().flex_1())
              .child(
                this.renderChip(t, "wb-group-repo", groupByRepo ? "Swimlanes: Repo" : "Group by repo", groupByRepo, () => {
                  setShared("work-board.groupByRepo", !groupByRepo);
                  cx.notify();
                })
              )
              .child(
                this.renderChip(t, "wb-refresh", isLoading ? "Refreshing..." : "↻ Refresh", false, () => {
                  run("work-board.refresh");
                })
              )
              .child(
                h_flex()
                  .id("wb-back")
                  .h(24)
                  .px(10)
                  .rounded(6)
                  .items_center()
                  .cursor_pointer()
                  .bg(t.solid)
                  .text_size(11.5)
                  .font_semibold()
                  .text_color(t.solid_foreground)
                  .on_click(() => setView("workspace"))
                  .child("← Workspace")
              )
          )
          // Row 2: State filter chips + Repo filter chips
          .child(
            h_flex()
              .gap(6)
              .items_center()
              .child(
                this.renderChip(t, "flt-all", `All (${allItems.length - (showParked ? 0 : parkedCount)})`, filter === "all", () => {
                  setShared("work-board.filter", "all");
                })
              )
              .child(
                this.renderChip(t, "flt-mine", `Waiting on me (${mineCount})`, filter === "mine", () => {
                  setShared("work-board.filter", "mine");
                })
              )
              .child(
                this.renderChip(t, "flt-agents", `Has agent (${withAgentCount})`, filter === "agents", () => {
                  setShared("work-board.filter", "agents");
                })
              )
              .child(
                this.renderChip(t, "flt-stale", `Stale >3d (${staleCount})`, filter === "stale", () => {
                  setShared("work-board.filter", "stale");
                })
              )
              .when(parkedCount > 0, (el) =>
                el.child(
                  this.renderChip(
                    t,
                    "flt-parked",
                    showParked ? `Showing parked (${parkedCount})` : `Parked (${parkedCount})`,
                    showParked,
                    () => setShared("work-board.showParked", !showParked)
                  )
                )
              )
              .child(div().w(1).h(14).mx(4).bg(t.border))
              .child(
                this.renderChip(t, "repo-all", "All repos", repoFilter === "all", () => {
                  setShared("work-board.repo", "all");
                })
              )
              .children(
                repoList.map(([name, count]) =>
                  this.renderChip(t, `repo-${name}`, `${name} (${count})`, repoFilter === name, () => {
                    setShared("work-board.repo", repoFilter === name ? "all" : name);
                  })
                )
              )
          )
      )
      // 5 Pipeline Columns
      .child(
        h_flex()
          .flex_1()
          .min_h(0)
          .w_full()
          .px(14)
          .py(12)
          .gap(10)
          .children(
            COLUMNS.map((col) => {
              const colItems = sortColumnCards(visibleItems.filter((i) => i.column === col.key));
              const accent = t[col.accentKey] ?? t.muted;
              const isMutedCol = col.ball === "others";

              return v_flex()
                .flex_1()
                .min_w(0)
                .h_full()
                .gap(8)
                // Column header
                .child(
                  v_flex()
                    .flex_none()
                    .px(8)
                    .py(6)
                    .gap(2)
                    .rounded(7)
                    .bg(isMutedCol ? t.chrome : t.surface)
                    .border(1)
                    .border_color(isMutedCol ? t.border : accent + "55")
                    .child(
                      h_flex()
                        .items_center()
                        .gap(7)
                        .child(div().size(7).rounded(4).bg(accent).flex_none())
                        .child(
                          div()
                            .text_size(12.5)
                            .font_semibold()
                            .text_color(isMutedCol ? t.muted : t.foreground)
                            .truncate()
                            .child(col.label)
                        )
                        .child(div().flex_1())
                        .child(
                          div()
                            .px(6)
                            .py(1)
                            .rounded(4)
                            .bg(accent + "22")
                            .text_size(10.5)
                            .font_semibold()
                            .text_color(accent)
                            .child(String(colItems.length))
                        )
                    )
                    .child(div().text_size(10).text_color(t.dim).truncate().child(col.subtitle))
                )
                // Scrollable column cards (flat or grouped by repo)
                .child(this.renderColumnBody(t, col, colItems, groupByRepo, showRepoTag));
            })
          )
      );
  }

  render(cx) {
    const t = theme();
    if (this.role === "bar") return this.renderBar(t);
    if (this.role === "card-menu") return this.renderCardMenu(t);
    return this.renderBoard(t, cx);
  }
}
