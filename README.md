<div align="center">
  <img src="assets/loop.png" alt="loop-engineer logo" width="140" />

  <h1>loop-engineer</h1>

  <p>Answer 2 questions. A self-assembling 9-agent team runs fully autonomously until your goal is done.</p>

  ![Version](https://img.shields.io/badge/version-1.6.0-0d9488?style=flat-square)
  ![Claude Code](https://img.shields.io/badge/Claude_Code-supported-1a1a2e?style=flat-square&logo=anthropic&logoColor=white)
  ![Cursor](https://img.shields.io/badge/Cursor-supported-000000?style=flat-square)
  ![Gemini CLI](https://img.shields.io/badge/Gemini_CLI-supported-4285F4?style=flat-square&logo=google&logoColor=white)
  ![Antigravity](https://img.shields.io/badge/Antigravity-supported-7c3aed?style=flat-square)
  ![OpenCode](https://img.shields.io/badge/OpenCode-supported-f97316?style=flat-square)
  ![Hermes](https://img.shields.io/badge/Hermes_Agent-supported-e11d48?style=flat-square)
  ![Codex](https://img.shields.io/badge/OpenAI_Codex-supported-412991?style=flat-square&logo=openai&logoColor=white)
  ![VS Code Copilot](https://img.shields.io/badge/VS_Code_Copilot-supported-0078D4?style=flat-square&logo=visualstudiocode&logoColor=white)
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

All entries below confirmed against each vendor's own current documentation (fetched directly, not secondhand).

| Platform | Skill | Agent dispatch | Parallelism |
|---|---|---|---|
| **Claude Code** | `/loop-engineer` | `Agent` tool | ✅ true parallel — call it N times in one response |
| **Cursor** | `/loop-engineer` | `Task` tool | ✅ true parallel — confirmed via cursor.com/docs/subagents: multiple `Task` calls in one message run simultaneously |
| **Antigravity CLI** (`agy`) | `/loop-engineer` | `invoke_subagent` | ✅ true parallel — confirmed via antigravity.google/docs/subagents: each call returns immediately (async background execution), so calling it N times back-to-back dispatches N concurrent subagents. No "Subagents array" parameter exists. Nesting capped at 10 levels. |
| **Antigravity IDE** (VS Code / JetBrains) | `/loop-engineer` | `invoke_subagent` | ✅ true parallel (see above) |
| **Antigravity 2.0** (desktop) | `/loop-engineer` | `invoke_subagent` | ✅ true parallel (see above) |
| **Hermes Agent** | `/loop-engineer` | `delegate_task(tasks=[...])` | ✅ true parallel — one call, array of task definitions, synchronous (blocks until all return). **Default cap of 3 concurrent** (`delegation.max_concurrent_children`, floor 1, no ceiling) |
| **Gemini CLI** | `/loop-engineer` | named agent tools (`@agent-name`) | ✅ true parallel (v0.36+, confirmed via developers.googleblog.com) — official caveat: avoid parallel subagents for heavy concurrent code edits (file conflict risk) |
| **OpenCode** | `/loop-engineer` | `task` tool | ⚡ sequential — still unresolved as of writing. Original bug ([#14195](https://github.com/anomalyco/opencode/issues/14195)) was closed, but sequential dispatch was reported again in a newer issue ([#29638](https://github.com/anomalyco/opencode/issues/29638)) with fix PRs open as of late May 2026; check that issue for current status |
| **OpenAI Codex CLI** | `/loop-engineer` | `spawn_agent` | ✅ true parallel — enabled by default on current releases (no feature flag needed; older versions may need `features.multi_agent = true`). **Default cap of 6 concurrent** (`agents.max_threads`), nesting capped at depth 1 (`agents.max_depth`) |
| **VS Code GitHub Copilot** | attach `loop-engineer.prompt.md` | `agent`/`runSubagent` tool | ✅ true parallel — confirmed via code.visualstudio.com/docs/agents/subagents: phrase a batch as "Run these N subagents in parallel" and they run concurrently. Nesting disabled by default (enable via `chat.subagents.allowInvocationsFromSubagents`, max depth 5) |

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
bash install.sh --copilot    # VS Code GitHub Copilot
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
.\install.ps1 -Copilot     # VS Code GitHub Copilot
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

**VS Code GitHub Copilot** — after installing:
1. From your project root, run the init command printed by install (or run `init-loop.sh --platform copilot` directly).
2. Open Copilot Chat, switch to **Agent mode**.
3. Attach `.github/prompts/loop-engineer.prompt.md` via `#loop-engineer.prompt` and describe your goal.

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
         Runs scripts/check-resume.sh|.ps1 — deterministic scan, not model judgment.
         ACTIVE loop + continuation intent  → auto-resume straight to Phase 5.
         ACTIVE loop, no continuation intent → ask Resume or Fresh.
         DONE/EXTENDED_DONE + continuation intent → EXTEND: reopen the same
           directory in place (<id>_DONE → <id>_EXTENDED), reuse all existing
           research/memory/tools, ask one follow-up question, re-plan, jump to Phase 5.
         Nothing relevant found → Phase 1.

Phase 1  Wizard
         2 questions. Generates LOOP_ID (4 meaningful words, max 24 chars).

Phase 2+3  Initialize loop (one script call)
         scripts/init-loop.sh|.ps1 creates loop-stack/<LOOP_ID>/ (PLAN.md,
         STATUS.md, MEMORY.md, TOOLS.md, RESEARCH.md, AGENTS.md), copies agent
         files, and writes verifier.md/.toml with the actual stop condition
         substituted in. Creates loop-stack/.global/ if missing.

Phase 4  Startup sequence (parallel on supporting platforms)
         ├── Researchers    (2–4, universal domains, run in parallel)
         └── Resource Scout (discovers MCPs, skills, tools, APIs, datasets)
         Planner runs once, reading all research + resources, creating tasks
         with [G1]/[G2] tags. Agent-factory does NOT run here — it's on-demand
         (see below), not a fixed startup step.

Phase 5  Outer loop — per parallel group until all tasks done or budget hit:
         ├── Researchers    (one per task, parallel)
         ├── Agent Factory  (on-demand: only for tasks that clearly need a
         │                   specialist and have none yet — most tasks skip this)
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
         Stuck-agent detection is inline — the orchestrator itself checks stale
         heartbeats in STATUS.md; there is no dedicated watcher agent.

Phase 6  Report
         Fresh loop:    loop-stack/<LOOP_ID>/ → loop-stack/<LOOP_ID>_DONE/
         Extended loop: loop-stack/<LOOP_ID>_EXTENDED/ → loop-stack/<LOOP_ID>_EXTENDED_DONE/
         Writes REPORT.md, prints summary.
```

---

## The agent team

| Agent | What it does |
|---|---|
| **resource-scout** | Discovers everything available for the goal — MCP servers, skills, local tools, APIs, datasets, external resources. Writes `TOOLS.md` with a usage guide of exact callable names and invocation syntax. Propagates newly discovered resources live during execution. Cached globally for 7 days. |
| **researcher** | Maps what's known, what's needed, and what could go wrong before the executor acts. Consults `knowledge-sources.md` to identify the right research channels for the goal domain (33 categories: search engines, package registries, GitHub, APIs, security databases, finance, medical, etc.), then searches across those sources — prioritizing existing MCPs, skills, libraries, and APIs before building from scratch. Writes `RESEARCH.md` for three audiences: the executor (how to do it), the evaluator (what to verify), and the auditor (what right looks like). Dynamic count (2–4) based on goal complexity. Runs before every executor pass. |
| **planner** | Reads all researcher output and resource discoveries. Creates atomic tasks tagged with parallel group markers: same `[GN]` = run in parallel, different `[GN]` = sequential dependency. Runs once at startup. |
| **agent-factory** | On-demand tool, not a fixed phase — invoked only right before executing a specific task that clearly needs domain expertise a generic executor lacks, and only for that task. Reads `PLAN.md`, `RESEARCH.md`, and `TOOLS.md`, then writes one purpose-built agent to `loop-stack/<LOOP_ID>/agents/` (loop-specific, not platform-global) and updates the `AGENTS.md` manifest. Most loops never call it. |
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
    AGENTS.md             ← specialized agents manifest, updated on-demand by agent-factory
    REPORT.md             ← written on completion
    agents/               ← loop-specific domain specialists (written by agent-factory)
  <loop-id>_DONE/         ← renamed when a fresh loop completes
  <loop-id>_EXTENDED/     ← a _DONE loop reopened in place to continue with new tasks,
                             reusing all its research/memory/tools — not a new loop-id
  <loop-id>_EXTENDED_DONE/← renamed when an extended loop completes
  .global/
    MEMORY.md             ← cross-loop project learnings (shared, persistent)
    TOOLS.md              ← cached resource discovery (7-day TTL)
```

`scripts/check-resume.sh`/`.ps1` is the source of truth for what's active, done, or extended-done — Phase 0 always runs it rather than scanning `loop-stack/` by inference.

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
| VS Code Copilot | `.github/copilot-instructions.md` | `.github/loop-engineer/agents/` | `~/.config/loop-engineer/copilot/` | `.vscode/mcp.json` |

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
