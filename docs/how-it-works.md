# How It Works

## Flow

```
/loop-engineer
        │
        ▼
┌─────────────────────────────────────┐
│  Phase 0: Resume check              │
│  Finds loop-stack/*/STATUS.md       │
│  Skips *_DONE dirs, offers resume   │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  Wizard: 2 questions                │
│  goal · git integration             │
│  Auto: LOOP_ID · stop · budget      │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  Task decomposition                 │
│  3–7 atomic ordered tasks           │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  File generation                    │
│  loop-stack/<id>/ PLAN · STATUS     │
│                   MEMORY · TOOLS    │
│                   RESEARCH          │
│  .claude/agents/ × 7               │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  Tool Scout (runs once)             │
│  Checks .global/TOOLS.md first      │
│  (7-day cache — skips re-discovery) │
│  Writes loop-stack/<id>/TOOLS.md    │
└──────────────┬──────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────┐
│  Outer loop  [Task X/N — Y% | Turn Z]  FULLY AUTO   │
│                                                      │
│   Researcher → reads global MEMORY + TOOLS           │
│               researches codebase, writes RESEARCH   │
│       ↓                                              │
│   Developer  → reads RESEARCH + MEMORY + TOOLS       │
│               implements task                        │
│       ↓                                              │
│   QA Tester  → runs project test suite               │
│               uses researcher-flagged edge cases     │
│       ↓                                              │
│   Verifier   → checks stop condition                 │
│       ↓              ↓                               │
│    PASS             FAIL                             │
│       ↓         attempts < 3 → retry                 │
│   Auditor    → attempts ≥ 3 → AUTO-SKIP              │
│       ↓                                              │
│   CLEAN/WARN → Memory Keeper → distill learnings     │
│   BLOCK      → auto-fix once → retry → auto-skip     │
│       ↓                                              │
│   Next task or ALL DONE                              │
│                                                      │
│  Exits: ALL DONE · budget hit                        │
└──────────────────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  Rename: <id>/ → <id>_DONE/         │
│  loop-stack/<id>_DONE/REPORT.md     │
│  outcome · tasks · learnings        │
└─────────────────────────────────────┘
```

---

## The 7 Agents

| Agent | Role | Writes code? |
|---|---|---|
| `tool-scout` | Discovers MCPs, skills, plugins, project tooling → `TOOLS.md`. Checks global cache first. | No |
| `researcher` | Reads global MEMORY + TOOLS, researches codebase, writes `RESEARCH.md` for the developer | No |
| `developer` | Reads `RESEARCH.md` and implements the task using tools from `TOOLS.md` | Yes |
| `qa-tester` | Runs the project's test suite and checks researcher-flagged edge cases | No |
| `verifier` | Runs the stop condition — marks tasks done or failed | No |
| `auditor` | Reviews for security issues, tech debt, pattern violations | No |
| `memory-keeper` | Distills learnings into `MEMORY.md` + global `.global/MEMORY.md` after each task | No |

Only the developer writes application code. All other agents are explicitly forbidden from doing so.

The researcher runs before the developer every task — it reads the codebase, identifies patterns, notes gotchas, and writes a structured `RESEARCH.md`. The developer then reads this before coding, reducing hallucination and failed attempts.

On **Claude Code** and **Cursor**, the outer loop runs autonomously — Claude/Cursor spawns each agent via the Agent tool. On **Gemini CLI**, it uses `invoke_subagent` with sequential completion constraints. On **Codex CLI**, the skill outputs a `codex /goal "..."` command and Codex runs the loop natively.

---

## Generated Files

| Path | Purpose |
|---|---|
| `loop-stack/<id>/PLAN.md` | Goal, stop condition, budget, task list |
| `loop-stack/<id>/STATUS.md` | Live state — current task, attempts, last results. Survives context resets. |
| `loop-stack/<id>/MEMORY.md` | Accumulated learnings — grows smarter each iteration |
| `loop-stack/<id>/TOOLS.md` | Discovered MCPs, skills, plugins, project tooling |
| `loop-stack/<id>/RESEARCH.md` | Researcher findings for current task — read by developer, QA, auditor |
| `loop-stack/<id>/REPORT.md` | Generated on completion — outcome, tasks, learnings, tools used |
| `loop-stack/<id>_DONE/` | Loop directory renamed on completion — Phase 0 skips these |
| `loop-stack/.global/MEMORY.md` | Cross-loop project learnings (shared across all loops) |
| `loop-stack/.global/TOOLS.md` | Cached tool discovery (7-day TTL, shared across all loops) |
| `.claude/agents/tool-scout.md` | Agent definition for tool discovery |
| `.claude/agents/researcher.md` | Agent definition for pre-task research |
| `.claude/agents/developer.md` | Agent definition for implementation |
| `.claude/agents/qa-tester.md` | Agent definition for testing |
| `.claude/agents/verifier.md` | Agent definition for stop condition checking |
| `.claude/agents/auditor.md` | Agent definition for quality review |
| `.claude/agents/memory-keeper.md` | Agent definition for learning distillation |

All state lives in `loop-stack/`. You can inspect any file at any time to see progress.

---

## Failure Handling

| Situation | What happens |
|---|---|
| Task fails 1–2 times | Retries automatically — developer sees error context + researcher re-runs |
| Task fails 3 times | **Auto-skip** — added to skipped_tasks, loop continues fully autonomous |
| Auditor flags BLOCK | **Auto-fix once** — developer retried with BLOCK context, re-verified |
| Auto-fix still blocks | **Auto-skip** — added to skipped_tasks, loop continues |
| Budget exhausted | Loop stops — reports completed and skipped tasks |
| All tasks verified | State → ALL DONE — directory renamed `<id>_DONE/`, REPORT.md generated |

The loop is **fully autonomous** — it never pauses for user input after the initial 2-question setup.

---

## Global Memory and Tool Cache

Every agent reads `loop-stack/.global/MEMORY.md` and `loop-stack/.global/TOOLS.md` before any local loop files. This means:

- **Tool discovery**: tool-scout checks if `.global/TOOLS.md` is < 7 days old before re-scanning. Saves time on every new loop.
- **Memory**: learnings from previous loops (e.g., "this project uses yarn not npm", "tests need DB running") are available to every new loop automatically.
- **Research**: researcher checks global memory for prior solutions before doing fresh codebase analysis.

The memory-keeper writes to both the loop's `MEMORY.md` and `.global/MEMORY.md` after every task.

---

## When to Use It

**Good fit:**
- Bug fixes across multiple files
- Test suite repair
- Dependency upgrades
- Refactoring with a passing test suite as the stop condition
- Feature implementation with a clear acceptance criterion
- Any multi-step task with a verifiable finish line

**Not a good fit:**
- Single-turn tasks (just prompt directly)
- Tasks where verification requires human judgment
- Goals too vague to define a stop condition
