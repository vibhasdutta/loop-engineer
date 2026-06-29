# How It Works

## Flow

```
/loop-engineer
        │
        ▼
┌─────────────────────────────────────┐
│  Phase 1: Resume check              │
│  Finds loop-stack/*/STATUS.md       │
│  Skips *_DONE dirs, offers resume   │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  Phase 2: Wizard — 2 questions      │
│  goal · git integration             │
│  Auto: LOOP_ID · stop · budget      │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────┐
│  Phase 3: File generation                       │
│  loop-stack/<id>/ PLAN.md · STATUS.md           │
│                   MEMORY.md · TOOLS.md          │
│                   RESEARCH.md · AGENTS.md       │
│                   + .global/                    │
│  .claude/agents/ × 9                            │
└──────────────┬──────────────────────────────────┘
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
│       ↓                                              │
│  Step 4 — Agent Factory                              │
│    Reads PLAN.md + TOOLS.md                          │
│    Creates 1–3 specialized agent files if needed     │
│    Writes AGENTS.md manifest                         │
│    Creates nothing if generic agents are sufficient  │
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
│  Exits: ALL DONE · budget hit                        │
└──────────────┬───────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  Phase 6: Completion                │
│  Rename: <id>/ → <id>_DONE/         │
│  loop-stack/<id>_DONE/REPORT.md     │
│  outcome · tasks · learnings        │
└─────────────────────────────────────┘
```

---

## The Agent Team

| Agent | Role | Writes goal output? |
|---|---|---|
| `resource-scout` | Discovers all available resources — MCP servers, skills, local tools, APIs, datasets. Writes TOOLS.md with a usage guide. Checks 7-day global cache first. | No |
| `researcher` | Maps what's known, what's needed, and what could go wrong before the executor acts. Writes RESEARCH.md before every executor pass. Dynamic count (2–4). | No |
| `planner` | Creates atomic tasks tagged with [G1]/[G2] parallel group markers. Runs once at startup. | No |
| `agent-factory` | Reads PLAN.md and TOOLS.md after planning. Creates 1–3 specialized agent files when the goal benefits from domain expertise. Writes AGENTS.md manifest. Creates nothing if generic agents are sufficient. | No |
| `executor` | Reads RESEARCH.md and checks AGENTS.md for specialists before acting. Derives execution method from the goal — writes code, produces documents, processes data, or whatever the task requires. Appends discoveries to MEMORY.md inline. | Yes |
| `evaluator` | Verifies output quality using methods appropriate to the goal type. Derives verification approach from the goal and task — not a preset checklist. Reports pass/fail with detail. | No |
| `verifier` | Dynamically written per loop with the actual stop condition. Marks [x] in PLAN.md on pass. Hard rule: never marks done unless verification passed. | No |
| `auditor` | Reviews for goal alignment, quality, accuracy, and constraint violations. Three outcomes: CLEAN (proceed), WARN (non-blocking), BLOCK (auto-fix once). | No |
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
| `loop-stack/<id>/RESEARCH.md` | Researcher findings for current task — read by executor, evaluator, auditor |
| `loop-stack/<id>/AGENTS.md` | Specialized agents manifest created by agent-factory |
| `loop-stack/<id>/REPORT.md` | Generated on completion — outcome, tasks, learnings, tools used |
| `loop-stack/<id>_DONE/` | Loop directory renamed on completion — Phase 1 skips these |
| `loop-stack/.global/MEMORY.md` | Cross-loop learnings (shared across all loops) |
| `loop-stack/.global/TOOLS.md` | Cached tool discovery (7-day TTL, shared across all loops) |
| `.claude/agents/resource-scout.md` | Agent definition for resource discovery |
| `.claude/agents/researcher.md` | Agent definition for pre-task research |
| `.claude/agents/planner.md` | Agent definition for task planning |
| `.claude/agents/agent-factory.md` | Agent definition for specialist creation |
| `.claude/agents/executor.md` | Agent definition for goal execution |
| `.claude/agents/evaluator.md` | Agent definition for output quality verification |
| `.claude/agents/verifier.md` | Agent definition for stop condition checking |
| `.claude/agents/auditor.md` | Agent definition for quality review |
| `.claude/agents/memory-keeper.md` | Agent definition for learning distillation |

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
| All tasks verified | State → ALL DONE — directory renamed `<id>_DONE/`, REPORT.md generated |

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
