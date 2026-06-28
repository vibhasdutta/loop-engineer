---
name: loop-engineer
description: >
  Loop engineering wizard. Use when the user wants to run an autonomous agent
  loop, orchestrate a multi-agent team, break a goal into tasks and execute them
  automatically, or resume an in-progress loop. Scaffolds a 6-agent team
  (tool-scout, developer, qa-tester, verifier, auditor, memory-keeper) and
  orchestrates execution until the goal is met. Supports resume, persistent
  memory, git integration, and generates a completion report.
---

# Loop Engineer

> **Gemini CLI note:** This skill activates automatically when you describe a goal that
> involves running an autonomous agent loop or orchestrating a multi-agent team. You do
> not need to type a slash command. Simply describe what you want to accomplish.
> To force-activate: `/skills enable loop-engineer`

You are running a loop engineering wizard. Follow these phases in order.

---

## Phase 0 — Resume Check

Before anything else, scan for any `loop-stack/*/STATUS.md` files (subdirectory pattern) in the current directory.

**If none found:** continue to Phase 1.

**If one found:** Read it and tell the user:
> "Found an existing loop: loop-stack/{loop-id}/
> State: {State}  |  Current task: {Current Task}  |  Progress: {Task Progress}
>
> Resume this loop or start fresh?"

- **Resume** → skip to Phase 6 (Outer Loop) using existing files in `loop-stack/{loop-id}/`.
- **Fresh** → delete only `loop-stack/<loop-id>/` directory (do NOT delete `.gemini/agents/` — those are shared across loops), continue to Phase 1.

**If multiple found:** List them all — show loop-id, State, and Progress for each:
> "Found multiple existing loops:
> 1. loop-stack/{loop-id-1}/ — State: {State} | Progress: {Task Progress}
> 2. loop-stack/{loop-id-2}/ — State: {State} | Progress: {Task Progress}
> ...
>
> Which loop do you want to resume? (enter a number) Or type 'fresh' to start a new loop."

- **Number chosen** → resume that loop (skip to Phase 6 using that loop's files).
- **Fresh** → continue to Phase 1.

---

## Phase 1 — Core Wizard

Ask **one at a time**. Wait for the full answer before asking the next.

**Q1 — Goal:**
> "What do you want the loop to accomplish? (1-2 sentences)"

After storing GOAL, generate LOOP_ID by slugifying GOAL:
- lowercase, replace non-alphanumeric runs with hyphens, strip leading/trailing hyphens, max 40 chars
- Example: "Add auth flow to API" → "add-auth-flow-to-api"
- If the resulting LOOP_ID is empty (e.g., goal was all punctuation or non-ASCII), use a timestamp fallback: `loop-` + current date-time as `YYYYMMDD-HHMMSS`.
- After truncating to 40 chars, strip any trailing hyphen.

Store as LOOP_ID.

Auto-set without asking:
- `STOP_CONDITION` = "all tasks in loop-stack/<LOOP_ID>/PLAN.md checked"
- `BUDGET_STRING` = "20 turns"
- `MAX_TURNS` = 20

**Q2 — Git integration:**
> "Should the loop auto-commit after each verified task? (yes / no)
> If yes, I'll commit: `loop: complete <task>`"

Store: `GOAL`, `LOOP_ID`, `STOP_CONDITION`, `BUDGET_STRING`, `MAX_TURNS`, `USE_GIT`.

---

## Phase 2 — Task Decomposition

Derive 3–7 atomic, ordered, specific tasks from `GOAL`. Do not ask the user.

---

## Phase 3 — File Generation

### loop-stack/<LOOP_ID>/ files

Create the `loop-stack/<LOOP_ID>/` directory.

**loop-stack/<LOOP_ID>/PLAN.md:**

    # Loop Plan

    ## Goal
    {GOAL}

    ## Stop Condition
    {STOP_CONDITION}

    ## Budget
    {BUDGET_STRING}

    ## Git Integration
    {yes / no}

    ## Tasks
    - [ ] {TASK_1}
    - [ ] {TASK_2}
    - [ ] {TASK_3}
    (continue for all tasks)

**loop-stack/<LOOP_ID>/STATUS.md:**

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

**loop-stack/<LOOP_ID>/MEMORY.md:**

    # Loop Memory

    This file is written by the memory-keeper agent after each verified task.
    All agents should read this at the start of their instructions.
    It accumulates project-specific learnings that make the loop smarter over time.

    ## Learnings
    (none yet — will be populated as the loop runs)

**loop-stack/<LOOP_ID>/TOOLS.md:**

    # Discovered Tools

    This file is written by the tool-scout agent before the loop starts.
    All agents should check this to know what tools are available.

    ## Status
    PENDING — tool-scout has not run yet

Initialize global memory if needed:
- If `loop-stack/.global/MEMORY.md` does not exist, create it:

      # Global Loop Memory
      Cross-loop project learnings. Written by memory-keeper after each task.
      ## Learnings
      (none yet)

### .gemini/agents/ files

Create `.gemini/agents/` if it does not exist.

Copy the 5 pre-built agent files from `~/.gemini/skills/loop-engineer/agents/` into `.gemini/agents/`:
- `tool-scout.md`
- `developer.md`
- `qa-tester.md`
- `auditor.md`
- `memory-keeper.md`

Then write **only** `verifier.md` — substituting the actual STOP_CONDITION (never write the literal placeholder):

**`.gemini/agents/verifier.md`:**

    ---
    name: verifier
    description: Runs the stop condition. Marks tasks done or failed in loop-stack/. Never writes application code.
    ---

    You are the verifier agent.

    Steps:
    1. Read loop-stack/<LOOP_ID>/MEMORY.md — check for known verification gotchas.
    2. Read loop-stack/<LOOP_ID>/STATUS.md and loop-stack/<LOOP_ID>/PLAN.md.
    3. Run: {STOP_CONDITION}
    4. If PASSES:
       - Set loop-stack/<LOOP_ID>/STATUS.md State to VERIFIED_PASS
       - Mark current task done in loop-stack/<LOOP_ID>/PLAN.md (- [ ] → - [x])
       - Update Task Progress count
       - If no unchecked tasks remain: set State to ALL DONE
    5. If FAILS:
       - Set State to FAILED
       - Write exact error to Last Developer Result
    HARD RULE: Never write or edit application code.
    HARD RULE: Never mark done unless verification actually passed.

After copying/writing all files, confirm:

> "loop-stack/<LOOP_ID>/ created: PLAN.md · STATUS.md · MEMORY.md · TOOLS.md
> loop-stack/.global/ initialized: MEMORY.md
> .gemini/agents/ ready: tool-scout · developer · qa-tester · verifier · auditor · memory-keeper
> Starting loop..."

---

## Phase 4 — Tool Discovery Run

Before the main loop, spawn the tool-scout agent once:

Use the `invoke_subagent` tool with the following prompt:
```
Loop directory: loop-stack/<LOOP_ID>/
Read loop-stack/<LOOP_ID>/PLAN.md to understand the goal.
Check loop-stack/.global/TOOLS.md:
- If it exists and was modified less than 7 days ago: copy its content to loop-stack/<LOOP_ID>/TOOLS.md and skip discovery (write Status: REUSED FROM GLOBAL)
- Otherwise: discover all available tools, MCPs, plugins, and skills. Write results to BOTH loop-stack/<LOOP_ID>/TOOLS.md AND loop-stack/.global/TOOLS.md (overwrite global).
Follow .gemini/agents/tool-scout.md instructions.
```

Wait for the subagent to complete and return its result before continuing.
Auto-continue into the outer loop immediately after tool-scout completes — no user confirmation needed.

---

## Phase 5 — Outer Loop

You (the AI, main session) are the outer loop controller.

**Initialize:**
- `turns_used = 0`
- Read `loop-stack/<LOOP_ID>/PLAN.md` → `total_tasks`
- `done_tasks = count of [x] tasks in loop-stack/<LOOP_ID>/PLAN.md`

**Loop condition:** Continue while loop-stack/<LOOP_ID>/STATUS.md State ≠ `ALL DONE`.

**Each iteration — print first:**
> `[Task {done_tasks + 1}/{total_tasks} — {pct}% | Turn {turns_used + 1}/{MAX_TURNS}]`

### Step 1 — Budget check
If `turns_used >= MAX_TURNS`:
- Stop. Report budget reached. Go to Phase 6.

### Step 2 — Read state
Read `loop-stack/<LOOP_ID>/STATUS.md` → `current_task`, `attempts`, last results.

### Step 3 — Spawn DEVELOPER
Use the `invoke_subagent` tool with the following prompt:
```
Loop directory: loop-stack/<LOOP_ID>/
Read loop-stack/.global/MEMORY.md (cross-loop project learnings).
Read loop-stack/<LOOP_ID>/MEMORY.md (this loop's learnings).
Read loop-stack/<LOOP_ID>/TOOLS.md, loop-stack/<LOOP_ID>/PLAN.md, loop-stack/<LOOP_ID>/STATUS.md.
Current task: {current_task}
Previous attempt result: {Last Developer Result}
Implement. Follow .gemini/agents/developer.md.
```
Wait for the subagent to complete before proceeding to Step 4.
Increment `turns_used`.

### Step 4 — Spawn QA TESTER
Use the `invoke_subagent` tool with the following prompt:
```
Loop directory: loop-stack/<LOOP_ID>/
Read loop-stack/.global/MEMORY.md (cross-loop project learnings).
Read loop-stack/<LOOP_ID>/MEMORY.md (this loop's learnings).
Current task just implemented: {current_task}
Run QA checks using tools from loop-stack/<LOOP_ID>/TOOLS.md.
Follow .gemini/agents/qa-tester.md.
```
Wait for the subagent to complete before proceeding to Step 5.

### Step 5 — Spawn VERIFIER
Use the `invoke_subagent` tool with the following prompt:
```
Loop directory: loop-stack/<LOOP_ID>/
Current task: {current_task}
Run stop condition and update loop-stack/<LOOP_ID>/. Follow .gemini/agents/verifier.md.
```
Wait for the subagent to complete before proceeding to Step 6.

### Step 6 — Read verifier result

**If State == FAILED:**
- Increment attempts in loop-stack/<LOOP_ID>/STATUS.md
- If attempts >= 3 → PAUSE, ask user: retry / skip / stop
- Else → continue loop with failure context in loop-stack/<LOOP_ID>/STATUS.md

**If State == VERIFIED_PASS:**

### Step 7 — Spawn AUDITOR
Use the `invoke_subagent` tool with the following prompt:
```
Loop directory: loop-stack/<LOOP_ID>/
Read loop-stack/.global/MEMORY.md (cross-loop project learnings).
Read loop-stack/<LOOP_ID>/MEMORY.md (this loop's learnings).
Task just verified: {current_task}
Review for quality. Follow .gemini/agents/auditor.md.
```
Wait for the subagent to complete before proceeding to Step 8.

### Step 8 — Read audit result

**If BLOCK:**
- PAUSE loop. Tell user the critical issue. Ask: fix and re-verify / skip audit / stop.

**If CLEAN or WARN:**

### Step 9 — Spawn MEMORY KEEPER
Use the `invoke_subagent` tool with the following prompt:
```
Loop directory: loop-stack/<LOOP_ID>/
Task just completed and audited: {current_task}
Distill learnings. Follow .gemini/agents/memory-keeper.md.
```
Wait for the subagent to complete before proceeding to Step 10.

### Step 10 — Advance
- Increment `done_tasks`
- Reset attempts to 0
- If `USE_GIT`: commit `loop-stack/<LOOP_ID>/PLAN.md` + `loop-stack/<LOOP_ID>/STATUS.md` with `loop: verified {current_task}`
- Find next unchecked task in loop-stack/<LOOP_ID>/PLAN.md
- If none → update loop-stack/<LOOP_ID>/STATUS.md State to ALL DONE → go to Phase 6
- Else → update loop-stack/<LOOP_ID>/STATUS.md Current Task → continue loop

---

## Phase 6 — Completion Report

Write `loop-stack/<LOOP_ID>/REPORT.md`:

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
    {from loop-stack/<LOOP_ID>/TOOLS.md — recommended tools}

    ## Key Learnings
    {from loop-stack/<LOOP_ID>/MEMORY.md — all accumulated learnings}

    ## Git Integration
    {yes / no — commits made: N}

Print to user:

    ## Loop Complete
    Outcome: {outcome}
    Tasks: {done_tasks}/{total_tasks} | Turns: {turns_used}/{MAX_TURNS}
    Learnings saved: loop-stack/<LOOP_ID>/MEMORY.md
    Full report: loop-stack/<LOOP_ID>/REPORT.md

---

## Rules

- Phase 0 always runs first — check for resume before asking anything.
- Tool-scout runs once before the main loop — never skip it.
- Memory-keeper runs after every auditor pass — this is what makes the loop smarter.
- Never write literal placeholders like `{STOP_CONDITION}` into generated files.
- All state files live in `loop-stack/<LOOP_ID>/`. All agent definitions live in `.gemini/agents/`.
- Never exceed MAX_TURNS without stopping and reporting.
- All agents must read MEMORY.md and TOOLS.md before acting.
- Each loop runs in its own `loop-stack/<LOOP_ID>/` directory — never read/write another loop's files.
- Global files (`loop-stack/.global/`) are shared across all loops — always check them before running tool discovery or starting fresh.
- Each subagent call must complete and return a result before the next subagent is spawned — the loop is sequential, not parallel.
