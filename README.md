<div align="center">
  <img src="assets/loop.png" alt="loop-engineer logo" width="140" />

  <h1>loop-engineer</h1>

  <p>Answer 4 questions. A 6-agent team iterates until your goal is verified — across Claude Code and Codex CLI.</p>

  ![Version](https://img.shields.io/badge/version-1.0.0-0d9488?style=flat-square)
  ![Claude Code](https://img.shields.io/badge/Claude_Code-supported-1a1a2e?style=flat-square&logo=anthropic&logoColor=white)
  ![Codex](https://img.shields.io/badge/OpenAI_Codex-supported-412991?style=flat-square&logo=openai&logoColor=white)
  ![License](https://img.shields.io/badge/license-MIT-22c55e?style=flat-square)
  ![Loop Engineering](https://img.shields.io/badge/Loop_Engineering-June_2026-0ea5e9?style=flat-square)

</div>

---

## What it does

You describe a goal and a stop condition. The skill breaks it into tasks, discovers your available tools and MCPs, then orchestrates a team of 6 agents — developer, QA tester, verifier, auditor, memory-keeper, and tool-scout — iterating until every task passes verification or the budget runs out. You step in only when something is stuck.

Works on **Claude Code** (autonomous loop via Agent tool) and **OpenAI Codex CLI** (outputs a `codex /goal` command). Same wizard, same `loop-stack/` files, same 6 agents — different runtime.

All state lives in `loop-stack/` so the loop survives context resets and can be resumed. A `MEMORY.md` file accumulates project learnings across iterations, making each run smarter than the last.

---

## Supported agents

| Skill | Agent | How the loop runs |
|---|---|---|
| `/loop-engineer` | **Claude Code** | Claude orchestrates agents autonomously via Agent tool |
| `/loop-engineer-codex` | **OpenAI Codex CLI** | Outputs `codex /goal` command — Codex runs the loop natively |

---

## Quick install

**Claude Code (macOS / Linux):**
```bash
curl -s https://raw.githubusercontent.com/vibhasdutta/loop-engineer/main/install.sh | bash
```

**Codex CLI (macOS / Linux):**
```bash
curl -s https://raw.githubusercontent.com/vibhasdutta/loop-engineer/main/install.sh | bash -s -- --codex
```

**Both at once:**
```bash
git clone https://github.com/vibhasdutta/loop-engineer.git && bash loop-engineer/install.sh --both
```

→ [Full installation guide](docs/installation.md) — plugin system, Windows, manual copy, verify steps

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

Both run the same wizard — 4 questions:

```
Q1. What do you want the loop to accomplish?
Q2. How do we verify success? (exact command — e.g. npm test exits 0)
Q3. What's the budget? (e.g. 10 turns · $5 · 15 turns or $3)
Q4. Auto-commit after each verified task? (yes / no)
```

Then 2 smart follow-up questions are suggested based on your goal (answer or skip). After that — no further input needed.

---

## How the loop works

Each task goes through a fixed pipeline:

```
tool-scout (once) → discovers your MCPs, plugins, project tools → TOOLS.md

Per task:
Developer → QA Tester → Verifier → Auditor → Memory Keeper → next task
```

- **Verifier** runs the exact stop condition you gave — tasks only advance on a real pass
- **Auditor** flags security issues, tech debt, pattern violations (pauses on critical)
- **Memory Keeper** distills learnings into `loop-stack/MEMORY.md` after each task
- **Failures** retry up to 3 times, then pause and ask you what to do

A completion report is written to `loop-stack/REPORT.md` when done.

→ [Full flow diagram and agent details](docs/how-it-works.md)

---

## Docs

| | |
|---|---|
| [Installation](docs/installation.md) | All install methods — Claude Code, Codex CLI, plugin system, Windows |
| [How It Works](docs/how-it-works.md) | Full flow, 6 agents, generated files, failure handling |
| [Loop Engineering](docs/loop-engineering.md) | What loop engineering is, Ralph technique, maker/checker split, references |

---

## License

MIT
