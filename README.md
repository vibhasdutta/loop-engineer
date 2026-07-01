<div align="center">
  <img src="assets/loop.png" alt="loop-engineer logo" width="140" />

  <h1>loop-engineer</h1>

  <p>Answer 2 questions. A self-assembling 9-agent team runs fully autonomously until your goal is done.</p>

  ![Version](https://img.shields.io/badge/version-1.2.0-0d9488?style=flat-square)
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

You describe a goal in one or two sentences — any goal. The skill researches the problem space, discovers every available resource (MCPs, skills, APIs, datasets, local tools), plans atomic tasks, assembles a team of specialists tailored to the domain, then executes fully autonomously until every task passes verification or the budget runs out. No further user input needed after the two setup questions.

Works for any objective: software development, research papers, data analysis, content creation, automation pipelines, system configuration, or anything else.

**What makes it different from a single-agent prompt:**

- **Domain-agnostic by design** — no hardcoded task types or procedures. Agents derive their behavior from the goal. The same framework that builds a web service can write a research report or configure a data pipeline.
- **Self-assembling agent team** — after planning, an `agent-factory` creates 1–3 specialized agents tuned to the specific goal domain and writes an `AGENTS.md` manifest. Executors check this and use specialists when available. If generic agents are sufficient, factory creates nothing.
- **Resource scout runs before everything** — discovers MCPs, skills, local tools, APIs, and datasets relevant to the goal. Writes a usage guide with exact callable names and invocation syntax so executors never have to guess.
- **Researcher runs before every executor pass** — the executor never acts blind. The researcher consults a 33-category knowledge-sources directory to find the right research channels for the goal domain, then prioritizes finding existing tools, MCPs, libraries, and APIs before planning how to build. Writes structured findings for three audiences: executor (how to do it), evaluator (verification criteria), and auditor (quality standards).
- **Memory accumulates across tasks and loops** — each completed task distills learnings into `MEMORY.md`. The `.global/MEMORY.md` persists across all loops in the project so the agent gets smarter over time.
- **Fully autonomous failure handling** — 3 verifier failures → auto-skip; auditor BLOCK → auto-fix once then skip. Never pauses for user input.

---

## Supported platforms

| Platform | Skill | Agent dispatch | Parallelism |
|---|---|---|---|
| **Claude Code** | `/loop-engineer` | `Agent` tool | ✅ true parallel |
| **Cursor** | `/loop-engineer` | `Agent` tool | ✅ true parallel |
| **Antigravity CLI** (`agy`) | `/loop-engineer` | `invoke_subagent` | ✅ true parallel |
| **Antigravity IDE** (VS Code / JetBrains) | `/loop-engineer` | `invoke_subagent` | ✅ true parallel |
| **Antigravity 2.0** (desktop) | `/loop-engineer` | `invoke_subagent` | ✅ true parallel |
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
bash install.sh --antigravity # Antigravity (CLI + IDE + 2.0)
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
.\install.ps1 -Antigravity # Antigravity (CLI + IDE + 2.0)
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

**Antigravity** — in `agy`, IDE, or 2.0, describe a goal or type:
```
/loop-engineer
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

Everything else is automatic — LOOP_ID, stop condition, budget, context gathering, task decomposition, resource discovery, agent assembly, and the full execution loop.

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
         TOOLS.md, RESEARCH.md, AGENTS.md. Creates loop-stack/.global/ if missing.

Phase 3  Agent setup
         Copies static agent files from the skill's agents/ directory.
         Writes verifier.md fresh with the actual stop condition substituted in.

Phase 4  Startup sequence (parallel on supporting platforms)
         ├── Researchers    (2–4, universal domains, run in parallel)
         ├── Resource Scout (discovers MCPs, skills, tools, APIs, datasets)
         ├── Planner        (reads all research + resources, creates tasks with [G1]/[G2] tags)
         └── Agent Factory  (reads PLAN.md, creates 1–3 domain-specialized agents → AGENTS.md)

Phase 5  Outer loop — per parallel group until all tasks done or budget hit:
         ├── Researchers    (one per task, parallel)
         ├── Executors      (one per task, parallel — check AGENTS.md for specialists first)
         ├── Memory-keeper checkpoint (local only)
         ├── Evaluators     (one per task, parallel)
         ├── Verifiers      (one per task, parallel)
         │    PASS ──────────────────────────────────→ Auditor
         │    FAIL < 3 ──────────────────────────────→ retry from Researchers
         │    FAIL ≥ 3 ──────────────────────────────→ auto-skip
         ├── Auditors       (passing tasks only, parallel)
         │    CLEAN/WARN ─────────────────────────────→ advance
         │    BLOCK ──────────────────────────────────→ auto-fix once → retry → auto-skip
         └── Memory-keeper final (local + global write)
         → mark [x], git commit if enabled, find next group

Phase 6  Report
         Renames loop-stack/<LOOP_ID>/ → loop-stack/<LOOP_ID>_DONE/
         Writes REPORT.md, prints summary.
```

---

## The agent team

| Agent | What it does |
|---|---|
| **resource-scout** | Discovers everything available for the goal — MCP servers, skills, local tools, APIs, datasets, external resources. Writes `TOOLS.md` with a usage guide of exact callable names and invocation syntax. Propagates newly discovered resources live during execution. Cached globally for 7 days. |
| **researcher** | Maps what's known, what's needed, and what could go wrong before the executor acts. Consults `knowledge-sources.md` to identify the right research channels for the goal domain (33 categories: search engines, package registries, GitHub, APIs, security databases, finance, medical, etc.), then searches across those sources — prioritizing existing MCPs, skills, libraries, and APIs before building from scratch. Writes `RESEARCH.md` for three audiences: the executor (how to do it), the evaluator (what to verify), and the auditor (what right looks like). Dynamic count (2–4) based on goal complexity. Runs before every executor pass. |
| **planner** | Reads all researcher output and resource discoveries. Creates atomic tasks tagged with parallel group markers: same `[GN]` = run in parallel, different `[GN]` = sequential dependency. Runs once at startup. |
| **agent-factory** | Runs after planning. Reads `PLAN.md` and `TOOLS.md`, determines whether the goal needs domain specialists, and creates 1–3 purpose-built agents when beneficial. Writes specialists to `loop-stack/<LOOP_ID>/agents/` (loop-specific, not platform-global). Writes `AGENTS.md` manifest so executors know which specialists exist and when to use them. Creates nothing if generic agents are sufficient. |
| **executor** | Reads `RESEARCH.md`, checks `AGENTS.md` for loop-specific specialists (from `loop-stack/<LOOP_ID>/agents/`), then derives execution method from the goal — writes code, produces documents, processes data, runs pipelines, or whatever the task requires. Implements one task. Appends discoveries to `MEMORY.md` inline. Goal output always goes to the project directory, never inside `loop-stack/`. Never marks tasks complete. |
| **evaluator** | Reads `RESEARCH.md § Verification Criteria` first — the researcher already defined what passing looks like for this specific task. Then confirms output exists in the right place (project directory, not `loop-stack/`), satisfies those criteria, and is complete with no placeholders. Reports pass/fail with specifics. Never executes the goal itself. |
| **verifier** | Dynamically written per loop with the actual stop condition. Runs it, marks `[x]` in `PLAN.md` on pass, writes error on fail. Hard rule: never marks done unless verification actually passed. |
| **auditor** | Reads `RESEARCH.md § Quality Standards` first — the researcher already documented what good output looks like vs. what to avoid for this task. Catches problems the evaluator wouldn't: things that technically work but aren't done the right way. Three outcomes: CLEAN (proceed), WARN (non-blocking), BLOCK (triggers one auto-fix attempt). |
| **memory-keeper** | Distills new learnings into loop `MEMORY.md` and the shared `loop-stack/.global/MEMORY.md`. Runs twice per task batch: checkpoint after executors, full consolidation after auditors. |

---

## State files

```
loop-stack/
  <loop-id>/              ← one dir per loop, namespaced, no collisions
    PLAN.md               ← goal, [G1]/[G2] task checklist, stop condition, budget
    STATUS.md             ← current state, attempt count, last result per agent
    MEMORY.md             ← learnings accumulated this loop
    TOOLS.md              ← resources, tools, APIs, usage guide
    RESEARCH.md           ← 7 sections: context, tools, requirements, approach,
                             verification criteria, quality standards, prior attempts
    AGENTS.md             ← specialized agents manifest created by agent-factory
    REPORT.md             ← written on completion
    agents/               ← loop-specific domain specialists (written by agent-factory)
  <loop-id>_DONE/         ← renamed when complete; skipped by resume check
  .global/
    MEMORY.md             ← cross-loop project learnings (shared, persistent)
    TOOLS.md              ← cached resource discovery (7-day TTL)
```

---

## Platform details

| Platform | Context file | Agent files | Skills path | MCP config |
|---|---|---|---|---|
| Claude Code | `CLAUDE.md` | `.claude/agents/` | `~/.claude/skills/` | `~/.claude/settings.json` |
| Cursor | `.cursorrules` / `CLAUDE.md` | `.cursor/agents/` | `~/.cursor/skills/` | `~/.cursor/mcp.json` |
| Gemini CLI | `GEMINI.md` | `.gemini/agents/` | `~/.gemini/skills/` | `~/.gemini/settings.json` |
| Antigravity CLI | `AGENTS.md` | `.agents/` | `~/.gemini/antigravity-cli/skills/` | `~/.gemini/config/mcp_config.json` |
| Antigravity IDE | `AGENTS.md` | `.agents/` | `~/.gemini/antigravity/skills/` | `~/.gemini/config/mcp_config.json` |
| Antigravity 2.0 | `AGENTS.md` | `.agents/` | `~/.gemini/config/skills/` | `~/.gemini/config/mcp_config.json` |
| OpenCode | `AGENTS.md` | `.opencode/agents/` | `~/.config/opencode/skills/` | `opencode.json` → `mcp` key |
| Hermes Agent | `HERMES.md` / `.hermes.md` | `.hermes/agents/` | `~/.hermes/skills/` | `~/.hermes/config.yaml` → `mcp_servers` |
| OpenAI Codex CLI | — | `.codex/agents/` (TOML) | `~/.codex/skills/` | `~/.codex/config.yaml` |

> **Codex note:** knowledge-sources live at `.codex/knowledge-sources/` (sibling of agents/, not inside it) — Codex's agents/ directory holds only TOML agent definitions.

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
