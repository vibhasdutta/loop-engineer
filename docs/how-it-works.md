# How It Works

## Flow

```
/loop-engineer
        │
        ▼
┌─────────────────────────────────────────────────────┐
│  Phase 1: Wizard — 3 questions                       │
│  mode (build/research/patch/audit, skipped if passed │
│  as an argument) · goal · git integration            │
│  Auto: LOOP_ID · stop · budget                       │
│  No resume support — every run starts a fresh loop.  │
└──────────────┬────────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────┐
│  Phase 2+3: Initialize loop (one script call)        │
│  scripts/init-loop.sh|.ps1 creates:                  │
│  loop-stack/<id>/ PLAN.md · STATUS.md                │
│                   MEMORY.md · TOOLS.md               │
│                   RESEARCH.md · AGENTS.md             │
│                   agents/ (for specialists)          │
│                   + .global/                          │
│  <platform>/agents/ × 8 + knowledge-sources/         │
│  verifier.md/.toml written fresh with the real        │
│  stop condition substituted in                        │
└──────────────┬──────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────┐
│  Phase 4: Startup sequence (runs once)               │
│                                                      │
│  Step 1 — Parallel Researchers (2–4)                 │
│    Each assigned a universal domain:                 │
│    · Context & Prior Work                            │
│    · External Knowledge & Resources                  │
│    · Requirements & Constraints                      │
│    · Environment & Integration                       │
│       ↓                                              │
│  Step 2 — Resource Scout                             │
│    Discovers MCPs, skills, tools, APIs, datasets     │
│    Checks .global/TOOLS.md (7-day cache first)       │
│    Writes loop-stack/<id>/TOOLS.md                   │
│       ↓                                              │
│  Step 3 — Planner                                    │
│    Reads research + TOOLS.md                         │
│    Creates atomic tasks tagged [G1]/[G2] (parallel   │
│    group markers) — writes PLAN.md                   │
│                                                      │
│  Agent Factory does NOT run here — it's on-demand,   │
│  invoked later per-task in Phase 5, not a fixed step │
└──────────────┬───────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────┐
│  Phase 5: Outer loop  [Task X/N — Y% | Turn Z]       │
│  Runs per parallel group — FULLY AUTONOMOUS          │
│  Mode gating: research/audit skip the build step;    │
│  audit's Auditor pass IS the task; patch tells        │
│  researchers/executors the existing code is ground   │
│  truth (fix/extend, don't rewrite)                    │
│                                                      │
│   Researchers (parallel)                             │
│     Reads global MEMORY + TOOLS, writes RESEARCH.md  │
│     (research mode: writes the task's final output)  │
│       ↓                                              │
│   Agent Factory (on-demand, parallel across tasks    │
│     that need it) — only for tasks with no specialist│
│     that clearly need one; most tasks skip this      │
│       ↓                                              │
│   Executors — SKIPPED in research/audit mode          │
│     Reads RESEARCH.md, checks AGENTS.md for          │
│     specialists, derives execution method from goal  │
│     Appends learnings to MEMORY.md inline            │
│       ↓                                              │
│   Auditors (parallel) — audit mode: this IS the task │
│     Reviews build for security/tech-debt/patterns     │
│   CLEAN/WARN → Verifier                              │
│   BLOCK      → auto-fix once → re-audit → auto-skip  │
│       ↓                                              │
│   Verifiers (parallel) — the final gate               │
│     Checks RESEARCH.md criteria (right place,        │
│     satisfies criteria, no placeholders) THEN         │
│     runs the stop condition — one call, both jobs    │
│       ↓              ↓                               │
│    PASS             FAIL                             │
│       ↓         attempts < 3 → retry from Researchers│
│   Memory-Keeper  attempts ≥ 3 → AUTO-SKIP             │
│   (single, learnings/context only — never executes   │
│    the goal)                                          │
│     Consolidates → loop MEMORY.md + .global/MEMORY   │
│       ↓                                              │
│   Next group or ALL DONE                             │
│                                                      │
│  Stuck-agent detection is inline — the orchestrator  │
│  checks stale heartbeats in STATUS.md itself; there  │
│  is no dedicated watcher agent.                      │
│  Exits: ALL DONE · budget hit                        │
└──────────────┬───────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────┐
│  Phase 6: Completion                        │
│  <id>/ → <id>_DONE/ (bookkeeping only)      │
│  REPORT.md — outcome · tasks · learnings    │
└─────────────────────────────────────────────┘
```

---

## Modes

Set once in Phase 1 (or passed as an argument, e.g. `/loop-engineer patch`), gates Phase 5 for the whole loop:

| Mode | What it does |
|---|---|
| `build` (default) | New work from scratch — full pipeline, unchanged. |
| `patch` | Fixes or extends the existing codebase — same pipeline, but every researcher/executor spawn adds: the existing code is ground truth, read it first, then fix or extend it, don't rewrite from scratch. |
| `research` | Investigate and report only, no code changes. Skips the executor and auditor steps entirely; the researcher writes each task's final deliverable directly, and the verifier checks that against the stop condition. |
| `audit` | Review only, no code changes. Skips the executor step; the auditor's review of existing code/output IS the task, with findings written to RESEARCH.md instead of triggering an auto-fix. |

---

## The Agent Team

| Agent | Role | Writes goal output? |
|---|---|---|
| `resource-scout` | Discovers all available resources — MCP servers, skills, local tools, APIs, datasets. Writes TOOLS.md with a usage guide of exact callable names and invocation syntax. Checks 7-day global cache first. | No |
| `researcher` | Consults `knowledge-sources.md` to find the right research channels for the goal domain (33 categories covering search engines, code repos, package registries, APIs, security, finance, medical, etc.), then researches across those channels — prioritizing existing MCPs, skills, libraries, and APIs before building from scratch. Writes `RESEARCH.md` with 7 sections: Context & Prior Work, Existing Tools & Resources, Requirements & Constraints, Suggested Approach, Verification Criteria, Quality Standards, Prior Attempt Analysis. Two audiences: executor (how) and verifier/auditor (verify, quality). Dynamic count (2–4). Runs before every executor pass. | No |
| `planner` | Creates atomic tasks tagged with [G1]/[G2] parallel group markers. Same group = parallel, different group = sequential dependency. Runs once at startup. | No |
| `agent-factory` | On-demand tool, not a fixed phase step. Invoked only right before executing a specific task that clearly needs domain expertise a generic executor lacks — checked per task in Phase 5, before spawning executors. Writes one purpose-built agent to `loop-stack/<LOOP_ID>/agents/` (loop-specific, not platform-global) and updates the AGENTS.md manifest. Most loops never call it. | No |
| `executor` | Reads RESEARCH.md, checks AGENTS.md for loop-specific specialists (from `loop-stack/<LOOP_ID>/agents/`), then derives execution method from the goal — writes code, produces documents, processes data, or whatever the task requires. Goal output always goes to the project directory, never inside loop-stack/. Appends discoveries to MEMORY.md inline. | Yes |
| `auditor` | Runs right after the build. Reads RESEARCH.md `## Quality Standards` first — the researcher documented what good output looks like vs. what to avoid for this task. Catches problems a functional check wouldn't: things that technically work but aren't done the right way. Three outcomes: CLEAN (proceed to verifier), WARN (non-blocking, proceed), BLOCK (auto-fix once, then proceeds either way). In audit mode, this review IS the task. | No |
| `verifier` | The final quality gate before a task is marked done — merges what used to be two passes. Reads RESEARCH.md `## Verification Criteria` first — the researcher already defined what passing looks like for this task — confirms output is in the right place, satisfies those criteria, and is complete, then runs the actual stop condition (dynamically written per loop with the real condition substituted in). Marks [x] in PLAN.md on pass; a FAIL triggers a retry from the researcher. Hard rule: never marks done unless verification actually passed. | No |
| `memory-keeper` | Distills learnings into loop MEMORY.md and global .global/MEMORY.md — nothing else. Runs once per batch, after verification — a single final consolidation. Executors already append learnings to MEMORY.md inline as they work. Never executes the goal or writes goal output. | No |

Only the executor produces goal output. All other agents are explicitly forbidden from doing so.

The framework is **domain-agnostic** — it works for any goal: coding, research, content production, data analysis, automation, or any other objective. The executor derives its execution method from the goal; so does the verifier when checking results.

Every platform below was verified directly against its own current documentation (not secondhand summaries) before writing this.

On **Claude Code**, agents run in true parallel via the `Agent` tool — call it N times in one response. **Cursor** runs true parallel via the `Task` tool (cursor.com/docs/subagents): "Agent sends multiple Task tool calls in a single message, so subagents run simultaneously." **Antigravity**'s `invoke_subagent` (antigravity.google/docs/subagents) has no "Subagents array" parameter — each call returns immediately since subagents "run asynchronously in the background," so calling it multiple times back-to-back dispatches them concurrently; nesting is capped at 10 levels. **Hermes Agent**'s `delegate_task(tasks=[...])` takes one array of task definitions per call, runs them concurrently on a thread pool with a **default cap of 3** (raise via `delegation.max_concurrent_children`), and is synchronous — the call blocks until every task in the array returns. **Codex CLI**'s `spawn_agent` is enabled by default on current releases (no feature flag needed) with a **default cap of 6 concurrent** (`agents.max_threads`) and nesting capped at depth 1. **Gemini CLI v0.36+** runs subagents in true parallel (developers.googleblog.com, added April 2026) — its own docs note a caveat worth repeating here: avoid parallel subagents for tasks requiring heavy concurrent code edits, since multiple agents editing the same files can conflict. **VS Code Copilot** also supports true parallel dispatch via the `agent`/`runSubagent` tool (code.visualstudio.com/docs/agents/subagents) — phrasing a batch as "Run these N subagents in parallel" triggers concurrent execution; nesting is disabled by default (`chat.subagents.allowInvocationsFromSubagents`, max depth 5 when enabled). **OpenCode** is the one platform still sequential — not by design, but because its `task` tool dispatch has an ongoing upstream bug. The original report ([#14195](https://github.com/anomalyco/opencode/issues/14195)) was closed, but sequential dispatch was reported again in a newer issue ([#29638](https://github.com/anomalyco/opencode/issues/29638)) with fix PRs open as of late May 2026 — check that issue for current status before assuming it's fixed.

---

## Generated Files

| Path | Purpose |
|---|---|
| `loop-stack/<id>/PLAN.md` | Goal, stop condition, budget, task list with [G1]/[G2] group tags |
| `loop-stack/<id>/STATUS.md` | Live state — current task, attempts, last results. Survives context resets. |
| `loop-stack/<id>/MEMORY.md` | Accumulated learnings — grows smarter each iteration |
| `loop-stack/<id>/TOOLS.md` | Discovered MCPs, skills, tools, APIs, datasets |
| `loop-stack/<id>/RESEARCH.md` | 7-section researcher output: Context & Prior Work, Existing Tools & Resources, Requirements & Constraints, Suggested Approach, Verification Criteria (for verifier), Quality Standards (for auditor), Prior Attempt Analysis |
| `loop-stack/<id>/AGENTS.md` | Specialized agents manifest, updated on-demand by agent-factory (starts as "NONE CREATED YET") |
| `loop-stack/<id>/agents/` | Loop-specific domain specialists written by agent-factory |
| `loop-stack/<id>/REPORT.md` | Generated on completion — outcome, tasks, learnings, tools used |
| `loop-stack/<id>_DONE/` | Loop directory renamed on completion — bookkeeping only, nothing reads it back; every `/loop-engineer` run starts a fresh loop |
| `loop-stack/.global/MEMORY.md` | Cross-loop learnings (shared across all loops) |
| `loop-stack/.global/TOOLS.md` | Cached tool discovery (7-day TTL, shared across all loops) |
| `<platform-agents>/` | Agent definitions copied from the skill on setup (e.g. `.claude/agents/` for Claude Code, `.codex/agents/` for Codex, `.opencode/agents/` for OpenCode) |
| `<platform-agents>/knowledge-sources.md` | Index mapping goal type → which category files to read |
| `<platform-agents>/knowledge-sources/` | 33 category reference files (search engines, GitHub, package managers, APIs, security, finance, medical, etc.) — researcher reads these to find the right sources for the goal domain |

All state lives in `loop-stack/`. You can inspect any file at any time to see progress.

---

## Failure Handling

| Situation | What happens |
|---|---|
| Auditor flags BLOCK | **Auto-fix once** — executor retried with BLOCK context, re-audited |
| Auto-fix still blocks | **Auto-skip** — added to skipped_tasks, loop continues (audit mode: BLOCK is just recorded as a finding, always proceeds to verifier) |
| Verifier fails 1–2 times | Retries automatically — researcher re-runs with error context, then executor/auditor repeat |
| Verifier fails 3 times | **Auto-skip** — added to skipped_tasks, loop continues fully autonomous |
| Budget exhausted | Loop stops — reports completed and skipped tasks |
| All tasks verified | State → ALL DONE — directory renamed `<id>_DONE/`, REPORT.md generated |
| Agent takes much longer than its peers | Orchestrator checks its heartbeat in STATUS.md itself, proceeds without it if stale — no dedicated watcher agent involved |

The loop is **fully autonomous** — it never pauses for user input after the initial 3-question setup, and never resumes a previous run — every invocation starts fresh.

---

## Global Memory and Tool Cache

Every agent reads `loop-stack/.global/MEMORY.md` and `loop-stack/.global/TOOLS.md` before any local loop files. This means:

- **Tool discovery**: resource-scout checks if `.global/TOOLS.md` is < 7 days old before re-scanning. Saves time on every new loop.
- **Memory**: learnings from previous loops (e.g., "this project uses yarn not npm", "API requires auth token in header") are available to every new loop automatically.
- **Research**: researcher checks global memory for prior solutions before doing fresh analysis.

The memory-keeper writes to both the loop's `MEMORY.md` and `.global/MEMORY.md` — once per task batch, after auditors. Executors already append their own learnings to `MEMORY.md` inline as they work, so no separate checkpoint pass is needed.

---

## When to Use It

**Good fit:**
- Any multi-step goal with a verifiable finish line
- Research tasks that span multiple sources and need synthesis
- Content production with a quality bar (outline → draft → review → final)
- Data processing pipelines with validation requirements
- Software development: bug fixes, feature implementation, refactoring
- Automation scripts with acceptance criteria
- System configuration with a verifiable end state

**Not a good fit:**
- Single-turn tasks (just prompt directly)
- Tasks where verification requires human judgment
- Goals too vague to define a stop condition
