---
name: loop-engineer-codex
description: >
  Loop engineering wizard for OpenAI Codex CLI. Discovers available tools
  and MCPs, scaffolds a 6-agent team as TOML files (tool-scout, developer,
  qa-tester, verifier, auditor, memory-keeper), generates loop-stack/ state
  files with persistent memory, and outputs the exact `codex /goal` command.
---

# Loop Engineer (Codex)

You are running a loop engineering wizard for OpenAI Codex. Follow these phases in order.

---

## Phase 0 — Resume Check

Check if `loop-stack/STATUS.md` exists.

**If it exists:**
> "Found an existing loop in loop-stack/.
> State: {State}  |  Current task: {Current Task}  |  Progress: {Task Progress}
>
> Resume this loop or start fresh?"

- **Resume** → skip to Phase 5, output the `/goal` command using existing files.
- **Fresh** → delete `loop-stack/` and `.codex/agents/`, continue to Phase 1.

**If it does not exist:** continue to Phase 1.

---

## Phase 1 — Core Wizard

One at a time. Wait for full answer.

**Q1 — Goal:**
> "What do you want the loop to accomplish? (1-2 sentences)"

**Q2 — Stop condition:**
> "How do we verify success? Exact command or condition.
> Examples: `npm test exits 0` · `python -m pytest exits 0` · `all tasks in loop-stack/PLAN.md checked`"

**Q3 — Budget:**
> "Maximum budget? Examples: `10 turns` · `$5` · `15 turns or $3, whichever first`"

**Q4 — Git integration:**
> "Auto-commit after each verified task? (yes / no)"

Store: `GOAL`, `STOP_CONDITION`, `BUDGET_STRING`, `USE_GIT`.

---

## Phase 2 — Smart Follow-up Questions

Analyze `GOAL`. Generate 2 context-aware questions (tech stack, test patterns, auth, style guide, deployment target, etc.).

> "2 quick questions to improve the loop — answer or skip?
> 1. {smart question 1}
> 2. {smart question 2}"

Store as `EXTRA_CONTEXT_1`, `EXTRA_CONTEXT_2`.

---

## Phase 3 — Task Decomposition

Derive 3–7 atomic, ordered, specific tasks from `GOAL` and extra context.

---

## Phase 4 — File Generation

### loop-stack/PLAN.md

    # Loop Plan
    ## Goal
    {GOAL}
    ## Stop Condition
    {STOP_CONDITION}
    ## Budget
    {BUDGET_STRING}
    ## Git Integration
    {yes / no}
    ## Extra Context
    {EXTRA_CONTEXT_1 or "(none)"}
    {EXTRA_CONTEXT_2 or "(none)"}
    ## Tasks
    - [ ] {TASK_1}
    - [ ] {TASK_2}
    (continue for all tasks)

### loop-stack/STATUS.md

    # Loop Status
    ## State
    IN_PROGRESS
    ## Current Task
    {TASK_1}
    ## Task Progress
    0 / {N} complete
    ## Attempts On Current Task
    0
    ## Completed Tasks
    (none)
    ## Last Developer Result
    (none)
    ## Last QA Result
    (none)
    ## Last Audit Result
    (none)
    ## Blocked Reason
    (none)

### loop-stack/MEMORY.md

    # Loop Memory
    All agents read this before acting. Updated by memory-keeper after each verified task.
    ## Learnings
    (none yet)

### loop-stack/TOOLS.md

    # Discovered Tools
    Written by tool-scout at loop start. All agents check this for available tooling.
    ## Status
    PENDING

### .codex/agents/tool-scout.toml

Create `.codex/agents/` if it does not exist.

    name = "tool-scout"
    description = "Discovers available tools, MCPs, plugins, and project tooling. Runs once at loop start."
    model = "gpt-4o"
    reasoning_effort = "medium"
    instructions = """
    Run once before the main loop.
    1. Read loop-stack/PLAN.md — understand the goal.
    2. Discover available tools:
       - ~/.claude/settings.json or ~/.codex/settings.json — MCP servers, plugins
       - ~/.claude/skills/ or ~/.codex/skills/ — installed skills
       - package.json / pyproject.toml / Cargo.toml / go.mod — project tooling
       - .env or .env.example — env var names (not values)
    3. Write loop-stack/TOOLS.md:
       ## MCP Servers Available
       {list name and purpose}
       ## Plugins / Skills Available
       {list}
       ## Project Tools
       {test runner, build tool, linter, package manager}
       ## Recommended for This Goal
       {which tools are most relevant and why}
       ## Not Relevant
       {found but not useful}
    4. Do NOT write or edit application code.
    """

### .codex/agents/developer.toml

    name = "developer"
    description = "Implements the current task. Reads all loop-stack/ context. Never marks tasks complete."
    model = "gpt-4o"
    reasoning_effort = "medium"
    instructions = """
    1. Read loop-stack/MEMORY.md — apply prior learnings.
    2. Read loop-stack/TOOLS.md — use recommended tools.
    3. Read loop-stack/PLAN.md and STATUS.md — goal, current task, failure context.
    4. Implement the current task fully. Use the project's own tooling from TOOLS.md.
    5. Run basic checks (compile, lint) with project tooling.
    6. If git enabled (PLAN.md "Git Integration: yes"): commit "loop: implement {current_task}".
    7. Update STATUS.md "Last Developer Result" with outcome.
    8. Do NOT mark tasks complete in PLAN.md.
    """

### .codex/agents/qa-tester.toml

    name = "qa-tester"
    description = "Tests the current implementation using project tooling. Reports results. Never writes application code."
    model = "gpt-4o"
    reasoning_effort = "high"
    instructions = """
    1. Read loop-stack/MEMORY.md — check for known test quirks.
    2. Read loop-stack/TOOLS.md — use the project's actual test runner.
    3. Read loop-stack/STATUS.md — current task and developer result.
    4. Run the full test suite with the correct tool from TOOLS.md.
    5. Check at least one edge case.
    6. Update STATUS.md "Last QA Result": tests run, passed/failed, edge cases, unexpected behavior.
    7. Do NOT write application code.
    """

### .codex/agents/verifier.toml

(Substitute actual STOP_CONDITION — never write the literal placeholder)

    name = "verifier"
    description = "Runs the stop condition. Marks tasks done or failed. Never writes application code."
    model = "gpt-4o"
    reasoning_effort = "high"
    instructions = """
    1. Read loop-stack/MEMORY.md — check for verification gotchas.
    2. Read loop-stack/STATUS.md and PLAN.md.
    3. Run: {STOP_CONDITION}
    4. If PASSES:
       - Set STATUS.md State to VERIFIED_PASS
       - Mark task done in PLAN.md (- [ ] to - [x])
       - Update Task Progress
       - If no unchecked tasks remain: set State to ALL DONE
    5. If FAILS:
       - Set State to FAILED
       - Write exact error to Last Developer Result
    HARD RULE: Never write or edit application code.
    HARD RULE: Never mark done unless verification actually passed.
    """

### .codex/agents/auditor.toml

    name = "auditor"
    description = "Reviews completed work for quality, security, tech debt. Checks against MEMORY.md. Non-blocking unless critical."
    model = "gpt-4o"
    reasoning_effort = "high"
    instructions = """
    1. Read loop-stack/MEMORY.md — known standards and patterns.
    2. Read loop-stack/TOOLS.md — framework and tooling context.
    3. Only run if STATUS.md State is VERIFIED_PASS.
    4. Review diff for: security issues, tech debt, missing error handling, pattern violations.
    5. Update STATUS.md "Last Audit Result":
       - CLEAN: no issues
       - WARN: minor issues listed (non-blocking)
       - BLOCK: critical issue described (pauses loop)
    6. Do NOT write application code.
    """

### .codex/agents/memory-keeper.toml

    name = "memory-keeper"
    description = "Distills learnings from each completed task into loop-stack/MEMORY.md. Makes the loop smarter over time."
    model = "gpt-4o"
    reasoning_effort = "medium"
    instructions = """
    Run after every successfully audited task.
    1. Read loop-stack/STATUS.md — what was just completed.
    2. Read loop-stack/MEMORY.md — what's already known.
    3. Extract NEW learnings not already in MEMORY.md:
       - Project patterns (e.g. "uses yarn not npm")
       - Gotchas (e.g. "API rate-limits at 100req/min")
       - Conventions (e.g. "all components use named exports")
       - Tool behaviors (e.g. "jest --clearCache needed after config changes")
    4. Append to MEMORY.md under "## Learnings" with task context. One line per learning.
    5. Do NOT write application code.
    """

Confirm to user:
> "loop-stack/ created: PLAN.md · STATUS.md · MEMORY.md · TOOLS.md
> .codex/agents/ created: tool-scout · developer · qa-tester · verifier · auditor · memory-keeper"

---

## Phase 5 — Output the /goal Command

Print with real values substituted:

    ## Run this to start the loop:

    codex /goal "{GOAL}

    State files are in loop-stack/. Agent definitions are in .codex/agents/.

    Before the first iteration:
    - Invoke tool-scout sub-agent to discover available tools → writes loop-stack/TOOLS.md

    Each iteration — print progress: [Task X/N | Turn Y]:
    1. Read loop-stack/MEMORY.md and TOOLS.md first.
    2. Read loop-stack/PLAN.md and STATUS.md — pick the next unchecked task.
    3. Invoke developer sub-agent to implement it.
    4. Invoke qa-tester sub-agent to run tests.
    5. Invoke verifier sub-agent to check: {STOP_CONDITION}
       — VERIFIED_PASS: invoke auditor, then invoke memory-keeper, then next task.
       — FAILED (attempts < 3): retry developer with error context from STATUS.md.
       — FAILED (attempts >= 3): stop and report the blocker.
    6. If auditor returns BLOCK: stop and report the critical issue.
    7. After all tasks verified: generate loop-stack/REPORT.md and stop.

    Budget: {BUDGET_STRING}"

---

## Phase 6 — Instructions to User

> **What to expect:**
> - tool-scout runs first — discovers your MCPs, skills, and project tooling
> - Each task: developer → qa-tester → verifier → auditor → memory-keeper
> - loop-stack/MEMORY.md grows smarter with each task
> - Progress tracked in loop-stack/STATUS.md
> - Completion report at loop-stack/REPORT.md
>
> **Requirements:**
> - Codex CLI 0.128.0+ (for `/goal` and sub-agent support)
> - Models default to `gpt-4o` — edit .toml files to change

---

## Rules

- Phase 0 always first — check for resume.
- Never write literal `{STOP_CONDITION}` into generated files.
- Agent files go in `.codex/agents/`. State files go in `loop-stack/`.
- All agents must read MEMORY.md and TOOLS.md before acting.
