# How It Works

## Flow

```
/loop-engineer
        │
        ▼
┌─────────────────────────────────────────────────────┐
│  Phase 0: Resume check                              │
│  Runs scripts/check-resume.sh|.ps1 — deterministic,  │
│  never inferred by the model from scanning files.    │
│  ACTIVE + continuation intent → auto-resume, no ask  │
│  ACTIVE, no continuation      → ask Resume or Fresh  │
│  DONE/EXTENDED_DONE + continuation → EXTEND SEQUENCE:│
│    reopen <id>_DONE → <id>_EXTENDED in place, reuse  │
│    all research/memory/tools, ask 1 follow-up        │
│    question, re-plan new tasks, jump to Phase 5      │
│  Nothing relevant found → Phase 1                    │
└──────────────┬────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  Phase 1: Wizard — 2 questions      │
│  goal · git integration             │
│  Auto: LOOP_ID · stop · budget      │
└──────────────┬──────────────────────┘
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
│  <platform>/agents/ × 9 + knowledge-sources/         │
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
│                                                      │
│   Researchers (parallel)                             │
│     Reads global MEMORY + TOOLS, writes RESEARCH.md  │
│       ↓                                              │
│   Agent Factory (on-demand, parallel across tasks    │
│     that need it) — only for tasks with no specialist│
│     that clearly need one; most tasks skip this      │
│       ↓                                              │
│   Executors                                          │
│     Reads RESEARCH.md, checks AGENTS.md for          │
│     specialists, derives execution method from goal  │
│       ↓                                              │
│   Memory-Keeper checkpoint                           │
│     Distills executor learnings → MEMORY.md          │
│       ↓                                              │
│   Evaluators (parallel)                              │
│     Verifies output quality using goal-appropriate   │
│     methods — reports pass/fail with detail          │
│       ↓                                              │
│   Verifiers (parallel)                               │
│     Checks stop condition                            │
│       ↓              ↓                               │
│    PASS             FAIL                             │
│       ↓         attempts < 3 → retry                 │
│   Auditors   →  attempts ≥ 3 → AUTO-SKIP             │
│   (passing tasks only)                               │
│   CLEAN/WARN → proceed                               │
│   BLOCK      → auto-fix once → retry → auto-skip     │
│       ↓                                              │
│   Memory-Keeper final                                │
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
│  Fresh loop:    <id>/ → <id>_DONE/          │
│  Extended loop: <id>_EXTENDED/ → <id>_EXTENDED_DONE/ │
│  REPORT.md — outcome · tasks · learnings    │
└─────────────────────────────────────────────┘
```

---

## The Agent Team

| Agent | Role | Writes goal output? |
|---|---|---|
| `resource-scout` | Discovers all available resources — MCP servers, skills, local tools, APIs, datasets. Writes TOOLS.md with a usage guide of exact callable names and invocation syntax. Checks 7-day global cache first. | No |
| `researcher` | Consults `knowledge-sources.md` to find the right research channels for the goal domain (33 categories covering search engines, code repos, package registries, APIs, security, finance, medical, etc.), then researches across those channels — prioritizing existing MCPs, skills, libraries, and APIs before building from scratch. Writes `RESEARCH.md` with 7 sections: Context & Prior Work, Existing Tools & Resources, Requirements & Constraints, Suggested Approach, Verification Criteria, Quality Standards, Prior Attempt Analysis. Three audiences: executor (how), evaluator (verify), auditor (quality). Dynamic count (2–4). Runs before every executor pass. | No |
| `planner` | Creates atomic tasks tagged with [G1]/[G2] parallel group markers. Same group = parallel, different group = sequential dependency. Runs once at startup. | No |
| `agent-factory` | On-demand tool, not a fixed phase step. Invoked only right before executing a specific task that clearly needs domain expertise a generic executor lacks — checked per task in Phase 5, before spawning executors. Writes one purpose-built agent to `loop-stack/<LOOP_ID>/agents/` (loop-specific, not platform-global) and updates the AGENTS.md manifest. Most loops never call it. | No |
| `executor` | Reads RESEARCH.md, checks AGENTS.md for loop-specific specialists (from `loop-stack/<LOOP_ID>/agents/`), then derives execution method from the goal — writes code, produces documents, processes data, or whatever the task requires. Goal output always goes to the project directory, never inside loop-stack/. Appends discoveries to MEMORY.md inline. | Yes |
| `evaluator` | Reads RESEARCH.md `## Verification Criteria` first — the researcher already defined what passing looks like for this task. Then confirms output is in the right place (project directory, not loop-stack/), satisfies those criteria, and is complete. Reports pass/fail with specifics. | No |
| `verifier` | Dynamically written per loop with the actual stop condition. Marks [x] in PLAN.md on pass. Hard rule: never marks done unless verification passed. | No |
| `auditor` | Reads RESEARCH.md `## Quality Standards` first — the researcher documented what good output looks like vs. what to avoid for this task. Catches problems the evaluator wouldn't: things that technically work but aren't done the right way. Three outcomes: CLEAN (proceed), WARN (non-blocking), BLOCK (auto-fix once). | No |
| `memory-keeper` | Distills learnings into loop MEMORY.md and global .global/MEMORY.md. Runs twice per batch: checkpoint after executors, consolidation after auditors. | No |

Only the executor produces goal output. All other agents are explicitly forbidden from doing so.

The framework is **domain-agnostic** — it works for any goal: coding, research, content production, data analysis, automation, or any other objective. The executor derives its execution method from the goal; so does the evaluator when verifying results.

On **Claude Code**, **Cursor**, **Antigravity**, **Hermes Agent**, and **Codex CLI**, agents run in true parallel — Antigravity uses `invoke_subagent`, Hermes uses `delegate_task`, Codex uses `spawn_agent`. On **Gemini CLI** and **OpenCode**, each agent is a named tool invoked sequentially — one at a time, no concurrent dispatch.

---

## Generated Files

| Path | Purpose |
|---|---|
| `loop-stack/<id>/PLAN.md` | Goal, stop condition, budget, task list with [G1]/[G2] group tags |
| `loop-stack/<id>/STATUS.md` | Live state — current task, attempts, last results. Survives context resets. |
| `loop-stack/<id>/MEMORY.md` | Accumulated learnings — grows smarter each iteration |
| `loop-stack/<id>/TOOLS.md` | Discovered MCPs, skills, tools, APIs, datasets |
| `loop-stack/<id>/RESEARCH.md` | 7-section researcher output: Context & Prior Work, Existing Tools & Resources, Requirements & Constraints, Suggested Approach, Verification Criteria (for evaluator), Quality Standards (for auditor), Prior Attempt Analysis |
| `loop-stack/<id>/AGENTS.md` | Specialized agents manifest, updated on-demand by agent-factory (starts as "NONE CREATED YET") |
| `loop-stack/<id>/agents/` | Loop-specific domain specialists written by agent-factory |
| `loop-stack/<id>/REPORT.md` | Generated on completion — outcome, tasks, learnings, tools used |
| `loop-stack/<id>_DONE/` | Fresh loop directory renamed on completion — check-resume script skips these unless continuation intent is detected |
| `loop-stack/<id>_EXTENDED/` | A `_DONE` loop reopened in place to continue with new tasks — same directory, same research/memory/tools, not a new loop-id |
| `loop-stack/<id>_EXTENDED_DONE/` | Renamed when an extended loop completes |
| `loop-stack/.global/MEMORY.md` | Cross-loop learnings (shared across all loops) |
| `loop-stack/.global/TOOLS.md` | Cached tool discovery (7-day TTL, shared across all loops) |
| `<platform-agents>/` | Agent definitions copied from the skill on setup (e.g. `.claude/agents/` for Claude Code, `.codex/agents/` for Codex, `.opencode/agents/` for OpenCode) |
| `<platform-agents>/knowledge-sources.md` | Index mapping goal type → which category files to read |
| `<platform-agents>/knowledge-sources/` | 33 category reference files (search engines, GitHub, package managers, APIs, security, finance, medical, etc.) — researcher reads these to find the right sources for the goal domain |
| `<skill-dir>/scripts/check-resume.sh` / `.ps1` | Deterministic scan of `loop-stack/` for ACTIVE / DONE / EXTENDED_DONE loops — Phase 0 always runs this instead of inferring state from a file listing |

All state lives in `loop-stack/`. You can inspect any file at any time to see progress.

---

## Failure Handling

| Situation | What happens |
|---|---|
| Task fails 1–2 times | Retries automatically — executor sees error context + researcher re-runs |
| Task fails 3 times | **Auto-skip** — added to skipped_tasks, loop continues fully autonomous |
| Auditor flags BLOCK | **Auto-fix once** — executor retried with BLOCK context, re-verified |
| Auto-fix still blocks | **Auto-skip** — added to skipped_tasks, loop continues |
| Budget exhausted | Loop stops — reports completed and skipped tasks |
| All tasks verified | State → ALL DONE — directory renamed `<id>_DONE/` (or `<id>_EXTENDED_DONE/` if it was an extended loop), REPORT.md generated |
| Agent takes much longer than its peers | Orchestrator checks its heartbeat in STATUS.md itself, proceeds without it if stale — no dedicated watcher agent involved |

The loop is **fully autonomous** — it never pauses for user input after the initial 2-question setup.

---

## Global Memory and Tool Cache

Every agent reads `loop-stack/.global/MEMORY.md` and `loop-stack/.global/TOOLS.md` before any local loop files. This means:

- **Tool discovery**: resource-scout checks if `.global/TOOLS.md` is < 7 days old before re-scanning. Saves time on every new loop.
- **Memory**: learnings from previous loops (e.g., "this project uses yarn not npm", "API requires auth token in header") are available to every new loop automatically.
- **Research**: researcher checks global memory for prior solutions before doing fresh analysis.

The memory-keeper writes to both the loop's `MEMORY.md` and `.global/MEMORY.md` — twice per task batch: once after executors (checkpoint), once after auditors (consolidation).

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
