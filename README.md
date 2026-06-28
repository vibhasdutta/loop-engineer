<div align="center">
  <img src="assets/loop.png" alt="loop-engineer logo" width="140" />

  <h1>loop-engineer</h1>

  <p>Answer 2 questions. A 7-agent team runs fully autonomously until your goal is done — no further input needed.</p>

  ![Version](https://img.shields.io/badge/version-1.1.0-0d9488?style=flat-square)
  ![Claude Code](https://img.shields.io/badge/Claude_Code-supported-1a1a2e?style=flat-square&logo=anthropic&logoColor=white)
  ![Cursor](https://img.shields.io/badge/Cursor-supported-000000?style=flat-square)
  ![Gemini CLI](https://img.shields.io/badge/Gemini_CLI-supported-4285F4?style=flat-square&logo=google&logoColor=white)
  ![Codex](https://img.shields.io/badge/OpenAI_Codex-supported-412991?style=flat-square&logo=openai&logoColor=white)
  ![License](https://img.shields.io/badge/license-MIT-22c55e?style=flat-square)
  ![Loop Engineering](https://img.shields.io/badge/Loop_Engineering-June_2026-0ea5e9?style=flat-square)

</div>

---

## What it does

You describe a goal. The skill breaks it into tasks, auto-discovers your available tools and MCPs, then orchestrates a team of 7 agents — tool-scout, researcher, developer, QA tester, verifier, auditor, and memory-keeper — iterating fully autonomously until every task passes verification or the 20-turn budget runs out. No user input required after setup.

All state lives in `loop-stack/<loop-id>/` — each loop gets its own namespaced directory so multiple loops can run in the same project without collision. A `MEMORY.md` accumulates learnings per loop, a `RESEARCH.md` passes context from researcher to developer, and a shared `loop-stack/.global/MEMORY.md` carries knowledge across all loops in the project.

---

## Supported runtimes

| Skill | Runtime | How the loop runs |
|---|---|---|
| `/loop-engineer` | **Claude Code** | Claude orchestrates 7 agents autonomously via Agent tool |
| `/loop-engineer` | **Cursor** | Same skill, `.cursor/agents/` agent path |
| `/loop-engineer` | **Gemini CLI** | Semantic activation, `invoke_subagent` for each agent |
| `/loop-engineer` | **Antigravity** | Natural language activation, prose-based agent dispatch |
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

**macOS / Linux — multiple platforms:**
```bash
git clone https://github.com/vibhasdutta/loop-engineer.git
cd loop-engineer
bash install.sh              # Claude Code only
bash install.sh --cursor     # Cursor
bash install.sh --gemini     # Gemini CLI
bash install.sh --codex      # Codex CLI
bash install.sh --all        # all platforms
```

**Windows (PowerShell):**
```powershell
git clone https://github.com/vibhasdutta/loop-engineer.git
cd loop-engineer
.\install.ps1              # Claude Code (default)
.\install.ps1 -Cursor      # Cursor
.\install.ps1 -Gemini      # Gemini CLI
.\install.ps1 -Codex       # Codex CLI
.\install.ps1 -All         # all platforms
```

→ [Full installation guide](docs/installation.md)

---

## Quick start

**Claude Code / Cursor** — open any project and type:
```
/loop-engineer
```

**Gemini CLI** — describe your goal in natural language, or force-activate:
```
/skills enable loop-engineer
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

Everything else is automatic — LOOP_ID generation, stop condition, budget, context gathering, task decomposition, tool discovery. The loop runs to completion with no further input.

---

## How the loop works

```
Phase 0  Resume check — finds existing loop-stack/<loop-id>/ dirs (skips *_DONE), offers resume or fresh

Phase 1  Wizard — 2 questions, auto-generates LOOP_ID (max 24 chars, 4 meaningful words)

Phase 2  Task decomposition — 3–7 atomic tasks derived from your goal

Phase 3  File generation — creates loop-stack/<loop-id>/ with PLAN, STATUS, MEMORY, TOOLS, RESEARCH

Phase 4  Tool discovery — tool-scout reads your MCPs, plugins, project tools (7-day global cache)

Phase 5  Outer loop — per task:
         Researcher → Developer → QA Tester → Verifier → Auditor → Memory Keeper → next task

Phase 6  Report — loop-stack/<loop-id>_DONE/REPORT.md written, summary printed
```

### The 7 agents

| Agent | Role |
|---|---|
| **tool-scout** | Discovers MCPs, skills, plugins, project tools. Runs once. Results cached globally for 7 days. |
| **researcher** | Reads global memory/tools, researches codebase, writes `RESEARCH.md` before each task. Prevents hallucination. |
| **developer** | Reads `RESEARCH.md` and implements the task. Never marks tasks complete. |
| **qa-tester** | Tests the implementation using real project tooling and researcher-flagged edge cases. |
| **verifier** | Runs the stop condition. Marks task done or failed in PLAN.md. Default stance: reject until proven. |
| **auditor** | Reviews for security issues, tech debt, pattern violations. Auto-fix attempted once on BLOCK. |
| **memory-keeper** | Distills learnings into loop `MEMORY.md` and shared `.global/MEMORY.md` after each task. |

### State files

```
loop-stack/
  <loop-id>/          ← one dir per loop, no collisions
    PLAN.md           ← goal + task checklist
    STATUS.md         ← current state, attempts, last results
    MEMORY.md         ← learnings accumulated this loop
    TOOLS.md          ← discovered tools for this loop
    RESEARCH.md       ← researcher findings for current task
    REPORT.md         ← written on completion
  <loop-id>_DONE/     ← renamed when complete, skipped in Phase 0
  .global/
    MEMORY.md         ← cross-loop project learnings (shared)
    TOOLS.md          ← cached tool discovery (7-day TTL)
```

### Failure handling

- Verifier FAIL → retry up to 3 times → **auto-skip** (fully autonomous, no user pause)
- Auditor BLOCK → **auto-fix once** → retry → auto-skip if still blocked
- Budget reached (20 turns default) → stop and write partial report
- On completion: loop directory renamed `<loop-id>_DONE/`

---

## Docs

| | |
|---|---|
| [Installation](docs/installation.md) | All install methods — Claude Code, Cursor, Gemini CLI, Codex CLI, plugin system, Windows |
| [How It Works](docs/how-it-works.md) | Full flow, 7 agents, generated files, failure handling |
| [Loop Engineering](docs/loop-engineering.md) | What loop engineering is, maker/checker split, references |

---

## License

MIT
