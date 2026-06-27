<div align="center">
  <img src="assets/loop.png" alt="loop-engineer logo" width="140" />

  <h1>loop-engineer</h1>

  <p>Answer 2 questions. A 6-agent team runs autonomously until your goal is done — no further input needed.</p>

  ![Version](https://img.shields.io/badge/version-1.0.0-0d9488?style=flat-square)
  ![Claude Code](https://img.shields.io/badge/Claude_Code-supported-1a1a2e?style=flat-square&logo=anthropic&logoColor=white)
  ![Codex](https://img.shields.io/badge/OpenAI_Codex-supported-412991?style=flat-square&logo=openai&logoColor=white)
  ![License](https://img.shields.io/badge/license-MIT-22c55e?style=flat-square)
  ![Loop Engineering](https://img.shields.io/badge/Loop_Engineering-June_2026-0ea5e9?style=flat-square)

</div>

---

## What it does

You describe a goal. The skill breaks it into tasks, auto-discovers your available tools and MCPs, then orchestrates a team of 6 agents — tool-scout, developer, QA tester, verifier, auditor, and memory-keeper — iterating until every task passes verification or the 20-turn budget runs out. You only step in if something is critically blocked.

Works on **Claude Code** (autonomous loop via Agent tool) and **OpenAI Codex CLI** (outputs a `codex /goal` command). Same wizard, same `loop-stack/` files, same 6 agents — different runtime.

All state lives in `loop-stack/<loop-id>/` — each loop gets its own namespaced directory so multiple loops can run in the same project without collision. A `MEMORY.md` accumulates learnings per loop, and a shared `loop-stack/.global/MEMORY.md` carries knowledge across all loops in the project.

---

## Supported runtimes

| Skill | Runtime | How the loop runs |
|---|---|---|
| `/loop-engineer` | **Claude Code** | Claude orchestrates 6 agents autonomously via Agent tool |
| `/loop-engineer-codex` | **OpenAI Codex CLI** | Outputs `codex /goal` command — Codex runs the loop natively |

---

## Quick install

**Plugin system (recommended — auto-updates):**
```bash
claude plugin add https://github.com/vibhasdutta/loop-engineer
```

**macOS / Linux — Claude Code:**
```bash
curl -s https://raw.githubusercontent.com/vibhasdutta/loop-engineer/main/install.sh | bash
```

**macOS / Linux — Codex CLI:**
```bash
curl -s https://raw.githubusercontent.com/vibhasdutta/loop-engineer/main/install.sh | bash -s -- --codex
```

**macOS / Linux — both:**
```bash
git clone https://github.com/vibhasdutta/loop-engineer.git
cd loop-engineer && bash install.sh --both
```

**Windows (PowerShell):**
```powershell
git clone https://github.com/vibhasdutta/loop-engineer.git
cd loop-engineer
.\install.ps1          # Claude Code only
.\install.ps1 -Codex   # Codex CLI only
.\install.ps1 -Both    # both
```

→ [Full installation guide](docs/installation.md) — plugin system, manual copy, verify steps

---

## Quick start

**Claude Code** — open any project and type:
```
/loop-engineer
```

**Codex CLI** — open any project and type:
```
/loop-engineer-codex
```

The wizard asks **2 questions only**:

```
Q1. What do you want the loop to accomplish?
Q2. Auto-commit after each verified task? (yes / no)
```

Everything else is automatic — stop condition, budget, context gathering, task decomposition, tool discovery. The loop runs to completion with no further input.

---

## How the loop works

```
Phase 0  Resume check — finds existing loop-stack/<loop-id>/ dirs, offers resume or fresh start

Phase 1  Wizard — 2 questions, auto-generates LOOP_ID from goal slug

Phase 2  Task decomposition — 3–7 atomic tasks derived from your goal

Phase 3  File generation — creates loop-stack/<loop-id>/ with PLAN, STATUS, MEMORY, TOOLS

Phase 4  Tool discovery — tool-scout reads your MCPs, plugins, project tools (7-day global cache)

Phase 5  Outer loop — per task:
         Developer → QA Tester → Verifier → Auditor → Memory Keeper → next task

Phase 6  Report — loop-stack/<loop-id>/REPORT.md written, summary printed
```

### The 6 agents

| Agent | Role |
|---|---|
| **tool-scout** | Discovers MCPs, skills, plugins, project tools. Runs once. Results cached globally for 7 days. |
| **developer** | Implements the current task. Reads MEMORY for context. Never marks tasks complete. |
| **qa-tester** | Tests the implementation using real project tooling. Never writes application code. |
| **verifier** | Runs the stop condition. Marks task done or failed in PLAN.md. Default stance: reject until proven. |
| **auditor** | Reviews for security issues, tech debt, pattern violations. Pauses loop only on critical findings. |
| **memory-keeper** | Distills learnings into loop MEMORY.md and the shared .global/MEMORY.md after each task. |

### State files

```
loop-stack/
  <loop-id>/          ← one dir per loop, no collisions
    PLAN.md           ← goal + task checklist
    STATUS.md         ← current state, attempts, last results
    MEMORY.md         ← learnings accumulated this loop
    TOOLS.md          ← discovered tools for this loop
    REPORT.md         ← written on completion
  .global/
    MEMORY.md         ← cross-loop project learnings (shared)
    TOOLS.md          ← cached tool discovery (7-day TTL)
```

### Failure handling

- Verifier FAIL → retry up to 3 times → pause and ask user
- Auditor BLOCK → pause loop, show issue, ask: fix / skip / stop
- Budget reached (20 turns default) → stop and write partial report

---

## Docs

| | |
|---|---|
| [Installation](docs/installation.md) | All install methods — Claude Code, Codex CLI, plugin system, Windows |
| [How It Works](docs/how-it-works.md) | Full flow, 6 agents, generated files, failure handling |
| [Loop Engineering](docs/loop-engineering.md) | What loop engineering is, maker/checker split, references |

---

## License

MIT
