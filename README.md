<div align="center">
  <img src="assets/loop.png" alt="loop-engineer logo" width="140" />

  <h1>loop-engineer</h1>

  <p>Answer 2 questions. A 7-agent team runs fully autonomously until your goal is done.</p>

  ![Version](https://img.shields.io/badge/version-1.1.1-0d9488?style=flat-square)
  ![Claude Code](https://img.shields.io/badge/Claude_Code-supported-1a1a2e?style=flat-square&logo=anthropic&logoColor=white)
  ![Cursor](https://img.shields.io/badge/Cursor-supported-000000?style=flat-square)
  ![Gemini CLI](https://img.shields.io/badge/Gemini_CLI-supported-4285F4?style=flat-square&logo=google&logoColor=white)
  ![Antigravity](https://img.shields.io/badge/Antigravity-supported-7c3aed?style=flat-square)
  ![OpenCode](https://img.shields.io/badge/OpenCode-supported-f97316?style=flat-square)
  ![Hermes](https://img.shields.io/badge/Hermes_Agent-supported-e11d48?style=flat-square)
  ![Codex](https://img.shields.io/badge/OpenAI_Codex-supported-412991?style=flat-square&logo=openai&logoColor=white)
  ![agentskills.io](https://img.shields.io/badge/agentskills.io-compatible-22c55e?style=flat-square)
  ![License](https://img.shields.io/badge/license-MIT-6b7280?style=flat-square)

</div>

---

## What it does

You describe a goal in one or two sentences. The skill breaks it into 3–7 atomic tasks, auto-discovers every MCP server, skill, plugin, and project tool available to your agent, then orchestrates a team of 7 specialists — running fully autonomously until every task passes verification or the budget runs out. No further user input needed after the two setup questions.

**What makes it different from a single-agent prompt:**

- **Researcher runs before every developer pass** — the developer never writes code blind. It gets codebase analysis, API findings, identified gotchas, and a suggested approach before touching a file.
- **Tool scout builds a Usage Guide** — not just a list of what tools exist, but exact callable names and invocation syntax so developers use MCP tools, skills, and project commands correctly without guessing.
- **Dynamic researcher count** — simple goals get 2 researchers, multi-system goals get 4, each assigned a focused domain (architecture, APIs, data, deployment).
- **Memory accumulates across tasks and loops** — each completed task distills learnings into `MEMORY.md`. The `.global/MEMORY.md` persists across all loops in the project so the agent gets smarter over time.
- **Verifier is goal-specific** — written fresh for each loop with the actual stop condition, not a generic "did it work" check.
- **Fully autonomous failure handling** — 3 verifier failures → auto-skip; auditor BLOCK → auto-fix once then skip. Never pauses for user input.

---

## Supported platforms

| Platform | Skill | Agent dispatch | Parallelism |
|---|---|---|---|
| **Claude Code** | `/loop-engineer` | `Agent` tool | ✅ true parallel |
| **Cursor** | `/loop-engineer` | `Agent` tool | ✅ true parallel |
| **Antigravity CLI** (`agy`) | `/loop-engineer` | prose dispatch | ✅ true parallel |
| **Antigravity 2.0** (desktop) | `/loop-engineer` | prose dispatch | ✅ true parallel |
| **Hermes Agent** | `/loop-engineer` | `delegate_task` | ✅ true parallel |
| **Gemini CLI** | `/loop-engineer` | named agent tools | ⚡ sequential |
| **OpenCode** | `/loop-engineer` | `task` tool | ⚡ sequential |
| **OpenAI Codex CLI** | `/loop-engineer` | `spawn_agent` | ✅ true parallel |

---

## Install

### Plugin system — Claude Code (recommended, auto-updates)

```bash
claude plugin add https://github.com/vibhasdutta/loop-engineer
```

### One-liner — macOS / Linux (Claude Code)

```bash
curl -s https://raw.githubusercontent.com/vibhasdutta/loop-engineer/main/install.sh | bash
```

### Manual — macOS / Linux

```bash
git clone https://github.com/vibhasdutta/loop-engineer.git
cd loop-engineer
bash install.sh              # Claude Code (default)
bash install.sh --cursor     # Cursor
bash install.sh --gemini     # Gemini CLI
bash install.sh --antigravity # Antigravity (CLI + 2.0 desktop)
bash install.sh --opencode   # OpenCode
bash install.sh --hermes     # Hermes Agent
bash install.sh --codex      # OpenAI Codex CLI
bash install.sh --all        # all platforms
```

### Manual — Windows (PowerShell)

```powershell
git clone https://github.com/vibhasdutta/loop-engineer.git
cd loop-engineer
.\install.ps1              # Claude Code (default)
.\install.ps1 -Cursor      # Cursor
.\install.ps1 -Gemini      # Gemini CLI
.\install.ps1 -Antigravity # Antigravity (CLI + 2.0 desktop)
.\install.ps1 -OpenCode    # OpenCode
.\install.ps1 -Hermes      # Hermes Agent
.\install.ps1 -Codex       # OpenAI Codex CLI
.\install.ps1 -All         # all platforms
```

→ [Full installation guide with per-platform verify steps](docs/installation.md)

---

## Quick start

**Claude Code / Cursor** — open any project and type:
```
/loop-engineer
```

**Gemini CLI** — describe a multi-step goal (auto-activates) or use the shortcut:
```
/loop-engineer
```

**Antigravity** — in `agy` TUI or Antigravity 2.0, describe a goal or use:
```
/goal  I want to add authentication to my API
```

**OpenCode** — open any project and type:
```
/loop-engineer
```

**Hermes Agent** — type the slash command or describe a multi-step goal:
```
/loop-engineer
```

**Codex CLI** — open Codex and type:
```
/loop-engineer
```
This scaffolds the state files and prints a `/goal` command to paste for the actual loop run.

The wizard asks **2 questions only:**

```
Q1. What do you want the loop to accomplish? (1–2 sentences)
Q2. Auto-commit after each verified task? (yes / no)
```

Everything else is automatic — LOOP_ID, stop condition, budget, context gathering, task decomposition, tool discovery, and the full agent loop.

---

## How it works

```
Phase 0  Resume check
         Scans loop-stack/*/STATUS.md — skips *_DONE dirs.
         Found: offer resume or fresh start.

Phase 1  Wizard
         2 questions. Generates LOOP_ID (4 meaningful words, max 24 chars).

Phase 2  State files
         Creates loop-stack/<LOOP_ID>/ with PLAN.md, STATUS.md, MEMORY.md,
         TOOLS.md, RESEARCH.md. Creates loop-stack/.global/ if missing.

Phase 3  Agent setup
         Copies 6 static agent files from the skill's agents/ directory.
         Writes verifier.md fresh with the actual stop condition substituted in.

Phase 4  Startup sequence (parallel on supporting platforms)
         ├── Researchers  (2–4, assigned domains, run in parallel)
         ├── Tool Scout   (discovers MCPs, skills, project tools + writes Usage Guide)
         └── Planner      (reads all research + tools, creates 3–7 tasks with [G1]/[G2] group tags)

Phase 5  Outer loop — per parallel group until all tasks done or budget hit:
         ├── Researchers  (one per task, parallel)
         ├── Developers   (one per task, parallel)
         ├── Memory-keeper checkpoint (local only)
         ├── QA Testers   (one per task, parallel)
         ├── Verifiers    (one per task, parallel)
         │    PASS ──────────────────────────────────→ Auditor
         │    FAIL < 3 ──────────────────────────────→ retry from Researchers
         │    FAIL ≥ 3 ──────────────────────────────→ auto-skip
         ├── Auditors     (passing tasks only, parallel)
         │    CLEAN/WARN ─────────────────────────────→ advance
         │    BLOCK ──────────────────────────────────→ auto-fix once → retry → auto-skip
         └── Memory-keeper final (local + global write)
         → mark [x], git commit if enabled, find next group

Phase 6  Report
         Renames loop-stack/<LOOP_ID>/ → loop-stack/<LOOP_ID>_DONE/
         Writes REPORT.md, prints summary.
```

---

## The 7 agents

| Agent | What it does |
|---|---|
| **tool-scout** | Reads MCP configs, skill directories, and project files. Writes `TOOLS.md` with what's available — including a **Tool Usage Guide** of exact callable names and invocation syntax so developers can use each tool without guessing. Cached globally for 7 days. |
| **researcher** | Reads global memory and tools, analyzes the codebase, identifies APIs and gotchas, and writes `RESEARCH.md` before every developer pass. Dynamic count (2–4) based on goal complexity, each assigned a focused domain. |
| **planner** | Reads all researcher output and tool discoveries. Creates 3–7 atomic tasks tagged with parallel group markers: same `[GN]` = run in parallel, different `[GN]` = sequential dependency. Runs once at startup. |
| **developer** | Reads `RESEARCH.md`, then checks `TOOLS.md ## Tool Usage Guide` for exact invocation syntax before writing code. Implements one task. Appends discoveries to `MEMORY.md` inline. Never marks tasks complete. |
| **qa-tester** | Tests using the project's real tooling (from `TOOLS.md`). Checks at least one edge case flagged in `RESEARCH.md`. Reports pass/fail counts. Never writes application code. |
| **verifier** | Dynamically written per loop with the actual stop condition. Runs it, marks `[x]` in `PLAN.md` on pass, writes error on fail. Hard rule: never marks done unless verification actually passed. |
| **auditor** | Reviews the diff for security issues, tech debt, pattern violations, and missing boundary checks. Three outcomes: CLEAN (proceed), WARN (non-blocking), BLOCK (triggers one auto-fix attempt). |
| **memory-keeper** | Distills new learnings into loop `MEMORY.md` and the shared `loop-stack/.global/MEMORY.md`. Runs twice per task batch: checkpoint after developers, full consolidation after auditors. |

---

## State files

```
loop-stack/
  <loop-id>/              ← one dir per loop, namespaced, no collisions
    PLAN.md               ← goal, [G1]/[G2] task checklist, stop condition, budget
    STATUS.md             ← current state, attempt count, last result per agent
    MEMORY.md             ← learnings accumulated this loop
    TOOLS.md              ← MCP servers, skills, project tools, Tool Usage Guide
    RESEARCH.md           ← researcher findings per task
    REPORT.md             ← written on completion
  <loop-id>_DONE/         ← renamed when complete; skipped by resume check
  .global/
    MEMORY.md             ← cross-loop project learnings (shared, persistent)
    TOOLS.md              ← cached tool discovery (7-day TTL)
```

---

## Platform details

| Platform | Context file | Agent files | Skills path | MCP config |
|---|---|---|---|---|
| Claude Code | `CLAUDE.md` | `.claude/agents/` | `~/.claude/skills/` | `~/.claude/settings.json` |
| Cursor | `.cursorrules` / `CLAUDE.md` | `.cursor/agents/` | `~/.cursor/skills/` | `~/.cursor/mcp.json` |
| Gemini CLI | `GEMINI.md` | `.gemini/agents/` | `~/.gemini/skills/` | `~/.gemini/settings.json` |
| Antigravity CLI | `AGENTS.md` | `.agents/` | `~/.gemini/antigravity-cli/skills/` | `~/.gemini/antigravity-cli/mcp_config.json` |
| Antigravity 2.0 | `AGENTS.md` | `.agents/` | `~/.agents/skills/` | `~/.agents/mcp_config.json` |
| OpenCode | `AGENTS.md` | `.opencode/agents/` | `~/.config/opencode/skills/` | `opencode.json` → `mcp` key |
| Hermes Agent | `HERMES.md` / `.hermes.md` | `.hermes/agents/` | `~/.hermes/skills/` | `~/.hermes/config.yaml` → `mcp_servers` |

Copy the platform's context file to your project root after installing — it tells the agent where the skill lives, how subagents work, and what slash commands are available.

---

## Docs

| | |
|---|---|
| [Installation](docs/installation.md) | Per-platform install steps, post-install setup, verify commands |
| [How It Works](docs/how-it-works.md) | Full phase walkthrough, agent roles, state file schema, failure handling |
| [Loop Engineering](docs/loop-engineering.md) | What loop engineering is, maker/checker split, references |

---

## License

MIT
