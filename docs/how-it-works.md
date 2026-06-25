# How It Works

## Flow

```
/loop-engineer
        │
        ▼
┌─────────────────────────────────────┐
│  Phase 0: Resume check              │
│  Existing loop-stack/? Resume/fresh │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  Wizard: 4 questions + 2 smart Q's  │
│  goal · verify · budget · git · ctx │
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
│  loop-stack/ PLAN · STATUS          │
│              MEMORY · TOOLS         │
│  .claude/agents/ × 6               │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  Tool Scout (runs once)             │
│  Reads ~/.claude/settings.json      │
│  Reads skills/, plugins, pkg files  │
│  Writes loop-stack/TOOLS.md         │
└──────────────┬──────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────┐
│  Outer loop  [Task X/N — Y% | Turn Z]                │
│                                                      │
│   Developer  → reads MEMORY + TOOLS, implements      │
│       ↓                                              │
│   QA Tester  → runs project test suite               │
│       ↓                                              │
│   Verifier   → checks stop condition                 │
│       ↓              ↓                               │
│    PASS             FAIL                             │
│       ↓         attempts < 3 → retry developer       │
│   Auditor    → attempts ≥ 3 → pause, ask user        │
│       ↓                                              │
│   CLEAN/WARN → Memory Keeper → distill learnings     │
│   BLOCK      → pause, ask user                       │
│       ↓                                              │
│   Next task or ALL DONE                              │
│                                                      │
│  Exits: ALL DONE · budget hit · user stops           │
└──────────────────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  loop-stack/REPORT.md               │
│  outcome · tasks · learnings · tools│
└─────────────────────────────────────┘
```

---

## The 6 Agents

| Agent | Role | Writes code? |
|---|---|---|
| `tool-scout` | Discovers MCPs, skills, plugins, project tooling → `TOOLS.md` | No |
| `developer` | Implements the current task using tools from `TOOLS.md` | Yes |
| `qa-tester` | Runs the project's test suite and checks edge cases | No |
| `verifier` | Runs the stop condition — marks tasks done or failed | No |
| `auditor` | Reviews for security issues, tech debt, pattern violations | No |
| `memory-keeper` | Distills learnings into `MEMORY.md` after each task | No |

Only the developer writes application code. All other agents are explicitly forbidden from doing so.

On **Claude Code**, the outer loop runs autonomously — Claude spawns each agent via the Agent tool. On **Codex CLI**, the skill outputs a `codex /goal "..."` command and Codex runs the loop natively. Same agents, same files, different runtime.

---

## Generated Files

| Path | Purpose |
|---|---|
| `loop-stack/PLAN.md` | Goal, stop condition, budget, task list |
| `loop-stack/STATUS.md` | Live state — current task, attempts, last results. Survives context resets. |
| `loop-stack/MEMORY.md` | Accumulated learnings — grows smarter each iteration and across runs |
| `loop-stack/TOOLS.md` | Discovered MCPs, skills, plugins, project tooling |
| `loop-stack/REPORT.md` | Generated on completion — outcome, tasks, learnings, tools used |
| `.claude/agents/tool-scout.md` | Agent definition for tool discovery |
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
| Task fails 1–2 times | Retries automatically — developer sees error context from STATUS.md |
| Task fails 3 times | Loop pauses — Claude reports what failed, asks: retry / skip / stop |
| Auditor flags BLOCK | Loop pauses — Claude reports critical issue, asks how to proceed |
| Budget exhausted | Loop stops — reports completed and remaining tasks |
| All tasks verified | State → ALL DONE — REPORT.md generated |

---

## Memory

`loop-stack/MEMORY.md` accumulates learnings across every task iteration. It persists between context resets and even across separate loop runs in the same project. By the time the loop is on task 5, it already knows things like "uses yarn not npm" or "jest needs --clearCache after config changes" — learned from tasks 1–4.

---

## When to Use It

**Good fit:**
- Bug fixes across multiple files
- Test suite repair
- Dependency upgrades
- Refactoring with a passing test suite as the stop condition
- Any multi-step task with a verifiable finish line

**Not a good fit:**
- Single-turn tasks (just prompt directly)
- Tasks where verification requires human judgment
- Goals too vague to define a stop condition
