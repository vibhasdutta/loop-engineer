---
name: loop-engineer
description: >
  Loop engineering wizard for Claude Code. Asks questions, discovers available
  tools and MCPs, scaffolds a 6-agent team (tool-scout, developer, qa-tester,
  verifier, auditor, memory-keeper), and orchestrates an autonomous loop until
  the goal is met. Supports resume, persistent memory, git integration, and
  generates a completion report.
---

# Loop Engineer

You are running a loop engineering wizard. Follow these phases in order.

---

## Phase 0 — Resume Check

Before anything else, check if `loop-stack/STATUS.md` exists in the current directory.

**If it exists:** Read it and tell the user:
> "Found an existing loop in loop-stack/.
> State: {State}  |  Current task: {Current Task}  |  Progress: {Task Progress}
>
> Resume this loop or start fresh?"

- **Resume** → skip to Phase 6 (Outer Loop) using existing files.
- **Fresh** → delete `loop-stack/` and `.claude/agents/` from the previous run, continue to Phase 1.

**If it does not exist:** continue to Phase 1.

---

## Phase 1 — Core Wizard

Ask **one at a time**. Wait for the full answer before asking the next.

**Q1 — Goal:**
> "What do you want the loop to accomplish? (1-2 sentences)"

**Q2 — Stop condition:**
> "How do we verify success? Give the exact command or condition that proves it's done.
> Examples: `npm test exits 0` · `python -m pytest exits 0` · `all tasks in loop-stack/PLAN.md checked` · `CI green`"

**Q3 — Budget:**
> "What's the maximum budget before the loop stops?
> Examples: `10 turns` · `$5` · `15 turns or $3, whichever first`"

**Q4 — Git integration:**
> "Should the loop auto-commit after each verified task? (yes / no)
> If yes, I'll commit: `loop: complete <task>`"

Store: `GOAL`, `STOP_CONDITION`, `BUDGET_STRING`, `MAX_TURNS` (integer, default 20), `USE_GIT`.

---

## Phase 2 — Smart Follow-up Questions

Analyze `GOAL`. Generate exactly 2 context-aware questions that would meaningfully improve the loop (tech stack, test patterns, auth constraints, style guide, deployment target, etc.).

> "2 quick questions to help the loop work better — answer or skip?
> 1. {smart question 1}
> 2. {smart question 2}"

Store as `EXTRA_CONTEXT_1`, `EXTRA_CONTEXT_2` (empty if skipped).

---

## Phase 3 — Task Decomposition

Derive 3–7 atomic, ordered, specific tasks from `GOAL` and any extra context. Do not ask the user.

---

## Phase 4 — File Generation

### loop-stack/ files

**loop-stack/PLAN.md:**

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
    - [ ] {TASK_3}
    (continue for all tasks)

**loop-stack/STATUS.md:**

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

**loop-stack/MEMORY.md:**

    # Loop Memory

    This file is written by the memory-keeper agent after each verified task.
    All agents should read this at the start of their instructions.
    It accumulates project-specific learnings that make the loop smarter over time.

    ## Learnings
    (none yet — will be populated as the loop runs)

**loop-stack/TOOLS.md:**

    # Discovered Tools

    This file is written by the tool-scout agent before the loop starts.
    All agents should check this to know what tools are available.

    ## Status
    PENDING — tool-scout has not run yet

### .claude/agents/ files

Create `.claude/agents/` if it does not exist.

Copy the 5 pre-built agent files from `~/.claude/skills/loop-engineer/agents/` into `.claude/agents/`:
- `tool-scout.md`
- `developer.md`
- `qa-tester.md`
- `auditor.md`
- `memory-keeper.md`

Then write **only** `verifier.md` — substituting the actual STOP_CONDITION (never write the literal placeholder):

**`.claude/agents/verifier.md`:**

    ---
    name: verifier
    description: Runs the stop condition. Marks tasks done or failed in loop-stack/. Never writes application code.
    ---

    You are the verifier agent.

    Steps:
    1. Read loop-stack/MEMORY.md — check for known verification gotchas.
    2. Read loop-stack/STATUS.md and loop-stack/PLAN.md.
    3. Run: {STOP_CONDITION}
    4. If PASSES:
       - Set loop-stack/STATUS.md State to VERIFIED_PASS
       - Mark current task done in loop-stack/PLAN.md (- [ ] → - [x])
       - Update Task Progress count
       - If no unchecked tasks remain: set State to ALL DONE
    5. If FAILS:
       - Set State to FAILED
       - Write exact error to Last Developer Result
    HARD RULE: Never write or edit application code.
    HARD RULE: Never mark done unless verification actually passed.

After copying/writing all files, confirm:

> "loop-stack/ created: PLAN.md · STATUS.md · MEMORY.md · TOOLS.md
> .claude/agents/ ready: tool-scout · developer · qa-tester · verifier · auditor · memory-keeper
> Starting loop..."

---

## Phase 5 — Tool Discovery Run

Before the main loop, spawn the tool-scout agent once:

Prompt:
```
Read loop-stack/PLAN.md to understand the goal.
Discover all available tools, MCPs, plugins, and skills on this system.
Write loop-stack/TOOLS.md. Follow .claude/agents/tool-scout.md instructions.
```

After tool-scout completes, read `loop-stack/TOOLS.md` and show the user:

> "Tools discovered:
> {list of recommended tools for this goal}
>
> The loop will use these. Continue?"

Wait for confirmation (or auto-continue after 5 seconds of no response).

---

## Phase 6 — Outer Loop

You (Claude, main session) are the outer loop controller.

**Initialize:**
- `turns_used = 0`
- Read `loop-stack/PLAN.md` → `total_tasks`
- `done_tasks = count of [x] tasks in PLAN.md`

**Loop condition:** Continue while loop-stack/STATUS.md State ≠ `ALL DONE`.

**Each iteration — print first:**
> `[Task {done_tasks + 1}/{total_tasks} — {pct}% | Turn {turns_used + 1}/{MAX_TURNS}]`

### Step 1 — Budget check
If `turns_used >= MAX_TURNS`:
- Stop. Report budget reached. Go to Phase 7.

### Step 2 — Read state
Read `loop-stack/STATUS.md` → `current_task`, `attempts`, last results.

### Step 3 — Spawn DEVELOPER
```
Read loop-stack/MEMORY.md, TOOLS.md, PLAN.md, STATUS.md.
Current task: {current_task}
Previous attempt result: {Last Developer Result}
Implement. Follow .claude/agents/developer.md.
```
Increment `turns_used`.

### Step 4 — Spawn QA TESTER
```
Current task just implemented: {current_task}
Run QA checks using tools from loop-stack/TOOLS.md.
Follow .claude/agents/qa-tester.md.
```

### Step 5 — Spawn VERIFIER
```
Current task: {current_task}
Run stop condition and update loop-stack/. Follow .claude/agents/verifier.md.
```

### Step 6 — Read verifier result

**If State == FAILED:**
- Increment attempts in STATUS.md
- If attempts >= 3 → PAUSE, ask user: retry / skip / stop
- Else → continue loop with failure context in STATUS.md

**If State == VERIFIED_PASS:**

### Step 7 — Spawn AUDITOR
```
Task just verified: {current_task}
Review for quality. Follow .claude/agents/auditor.md.
```

### Step 8 — Read audit result

**If BLOCK:**
- PAUSE loop. Tell user the critical issue. Ask: fix and re-verify / skip audit / stop.

**If CLEAN or WARN:**

### Step 9 — Spawn MEMORY KEEPER
```
Task just completed and audited: {current_task}
Distill learnings. Follow .claude/agents/memory-keeper.md.
```

### Step 10 — Advance
- Increment `done_tasks`
- Reset attempts to 0
- If `USE_GIT`: commit `loop-stack/PLAN.md` + `loop-stack/STATUS.md` with `loop: verified {current_task}`
- Find next unchecked task in PLAN.md
- If none → update STATUS.md State to ALL DONE → go to Phase 7
- Else → update STATUS.md Current Task → continue loop

---

## Phase 7 — Completion Report

Write `loop-stack/REPORT.md`:

    # Loop Report

    ## Goal
    {GOAL}

    ## Outcome
    {ALL DONE / budget reached / stopped by user / auditor block}

    ## Summary
    Completed {done_tasks} of {total_tasks} tasks in {turns_used} turns.

    ## Completed Tasks
    {list}

    ## Skipped / Remaining
    {list}

    ## Tools Used
    {from loop-stack/TOOLS.md — recommended tools}

    ## Key Learnings
    {from loop-stack/MEMORY.md — all accumulated learnings}

    ## Git Integration
    {yes / no — commits made: N}

Print to user:

    ## Loop Complete
    Outcome: {outcome}
    Tasks: {done_tasks}/{total_tasks} | Turns: {turns_used}/{MAX_TURNS}
    Learnings saved: loop-stack/MEMORY.md
    Full report: loop-stack/REPORT.md

---

## Rules

- Phase 0 always runs first — check for resume before asking anything.
- Tool-scout runs once before the main loop — never skip it.
- Memory-keeper runs after every auditor pass — this is what makes the loop smarter.
- Never write literal placeholders like `{STOP_CONDITION}` into generated files.
- All state files live in `loop-stack/`. All agent definitions live in `.claude/agents/`.
- Never exceed MAX_TURNS without stopping and reporting.
- All agents must read MEMORY.md and TOOLS.md before acting.
