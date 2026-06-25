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

### .codex/agents/ files

Create `.codex/agents/` if it does not exist.

Copy the 5 pre-built agent files from `~/.codex/skills/loop-engineer-codex/agents/` into `.codex/agents/`:
- `tool-scout.toml`
- `developer.toml`
- `qa-tester.toml`
- `auditor.toml`
- `memory-keeper.toml`

Then write **only** `verifier.toml` — substituting the actual STOP_CONDITION (never write the literal placeholder):

    name = "verifier"
    description = "Runs the stop condition. Marks tasks done or failed. Never writes application code."
    model = "gpt-5.5"
    model_reasoning_effort = "high"
    developer_instructions = """
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
    Call report_agent_job_result when done.
    """

Confirm to user:
> "loop-stack/ created: PLAN.md · STATUS.md · MEMORY.md · TOOLS.md
> .codex/agents/ ready: tool-scout · developer · qa-tester · verifier · auditor · memory-keeper"

---

## Phase 5 — Start the Loop

Tell the user:

> **Start Codex in your project directory, then paste this `/goal` prompt:**

Print with real values substituted — never print literal placeholders:

```
/goal {GOAL}

State files: loop-stack/. Agent definitions: .codex/agents/.
Budget: {BUDGET_STRING}

Step 1 — Before the first iteration, use spawn_agent to run the tool-scout agent.
Wait for it to finish and write loop-stack/TOOLS.md.

Step 2 — Loop until all tasks in loop-stack/PLAN.md are checked or budget is reached.
Print progress each iteration: [Task X/N | Turn Y]

Each iteration:
a. Read loop-stack/PLAN.md and STATUS.md — pick the next unchecked task.
b. spawn_agent: developer — implement the task.
c. spawn_agent: qa-tester — run tests.
d. spawn_agent: verifier — check stop condition: {STOP_CONDITION}
   - VERIFIED_PASS → go to (e)
   - FAILED, attempts < 3 → retry developer with error context from STATUS.md
   - FAILED, attempts >= 3 → stop, report blocker to user
e. spawn_agent: auditor — review completed work.
   - CLEAN or WARN → go to (f)
   - BLOCK → stop, report critical issue to user
f. spawn_agent: memory-keeper — distill learnings into loop-stack/MEMORY.md.
g. Advance to next task.

Step 3 — When all tasks verified: write loop-stack/REPORT.md and stop.
```

> **Requirements:**
> - Codex CLI v0.128.0+ with `features.multi_agent = true` (on by default)
> - `/goal` is a TUI slash command — run `codex` first, then paste the prompt above
> - Models: `gpt-5.5` for main agents, `gpt-5.4-mini` for tool-scout and memory-keeper — edit `.toml` files to change

---

## Rules

- Phase 0 always first — check for resume.
- Never write literal `{STOP_CONDITION}` into generated files.
- Agent files go in `.codex/agents/`. State files go in `loop-stack/`.
- All agents must read MEMORY.md and TOOLS.md before acting.
