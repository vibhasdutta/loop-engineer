---
name: loop-engineer
description: >
  Loop engineering wizard. Use when the user wants to run an autonomous agent
  loop, orchestrate a multi-agent team, break a goal into tasks and execute them
  automatically, or resume an in-progress loop. Scaffolds a 7-agent team
  (tool-scout, researcher, developer, qa-tester, verifier, auditor, memory-keeper)
  and orchestrates a fully autonomous execution until the goal is met. Supports
  resume, persistent memory, git integration, and generates a completion report.
---

# Loop Engineer

> **Antigravity note:** This skill activates automatically when you describe a goal that
> involves running an autonomous agent loop or orchestrating a multi-agent team.
> You do not need to use a slash command — describe your goal in natural language.
> The manager agent will detect the intent and activate the skill.

You are running a loop engineering wizard. Follow these phases in order.

---

## Phase 0 — Resume Check

Before anything else, scan for any `loop-stack/*/STATUS.md` files in the current directory.
**Skip any directory whose name ends with `_DONE` — those loops are already complete.**

**If none found (excluding `_DONE` folders):** continue to Phase 1.

**If one found:** Read it and tell the user:
> "Found an existing loop: loop-stack/{loop-id}/
> State: {State}  |  Current task: {Current Task}  |  Progress: {Task Progress}
>
> Resume this loop or start fresh?"

- **Resume** → skip to Phase 5 (Outer Loop) using existing files in `loop-stack/{loop-id}/`.
- **Fresh** → delete only `loop-stack/<loop-id>/` directory (do NOT delete `.agents/` — those are shared across loops), continue to Phase 1.

**If multiple found:** List them all — show loop-id, State, and Progress for each:
> "Found multiple existing loops:
> 1. loop-stack/{loop-id-1}/ — State: {State} | Progress: {Task Progress}
> 2. loop-stack/{loop-id-2}/ — State: {State} | Progress: {Task Progress}
> ...
>
> Which loop do you want to resume? (enter a number) Or type 'fresh' to start a new loop."

- **Number chosen** → resume that loop (skip to Phase 5 using that loop's files).
- **Fresh** → continue to Phase 1.

---

## Phase 1 — Core Wizard

Ask **one at a time**. Wait for the full answer before asking the next.

**Q1 — Goal:**
> "What do you want the loop to accomplish? (1-2 sentences)"

After storing GOAL, generate LOOP_ID by slugifying GOAL:
- lowercase, replace non-alphanumeric runs with hyphens, strip leading/trailing hyphens
- Take only the first 4 meaningful words (skip stop words: a, an, the, to, for, of, in, on, with, and, or)
- Truncate to **24 chars max**, strip any trailing hyphen
- Example: "Add authentication flow to the REST API" → "add-auth-flow-api"
- If the resulting LOOP_ID is empty, use timestamp fallback: `loop-` + `YYYYMMDD-HHMMSS`.

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

    ## Skipped Tasks
    (none)

    ## Last Researcher Result
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

**loop-stack/<LOOP_ID>/RESEARCH.md:**

    # Research Log

    Written by the researcher agent before each task.
    Developer reads this before implementing.

    ## Current Task Research
    (none yet)

Initialize global memory if needed:
- If `loop-stack/.global/MEMORY.md` does not exist, create it:

      # Global Loop Memory
      Cross-loop project learnings. Written by memory-keeper after each task.
      ## Learnings
      (none yet)

### .agents/ files

Create `.agents/` if it does not exist.

Copy the 6 pre-built agent files from `~/.gemini/skills/loop-engineer/agents/` into `.agents/`:
- `tool-scout.md`
- `researcher.md`
- `developer.md`
- `qa-tester.md`
- `auditor.md`
- `memory-keeper.md`

Then write **only** `verifier.md` — substituting the actual STOP_CONDITION (never write the literal placeholder):

**`.agents/verifier.md`:**

    ---
    name: verifier
    description: Runs the stop condition. Marks tasks done or failed in loop-stack/. Never writes application code.
    ---

    You are the verifier agent.

    Steps:
    1. Read loop-stack/.global/MEMORY.md (if exists) FIRST — check for cross-loop verification gotchas.
    2. Read [LOOP_DIR]/MEMORY.md — check for known verification gotchas in this loop.
    3. Read [LOOP_DIR]/STATUS.md and [LOOP_DIR]/PLAN.md.
    4. Run: {STOP_CONDITION}
    5. If PASSES:
       - Set [LOOP_DIR]/STATUS.md State to VERIFIED_PASS
       - Mark current task done in [LOOP_DIR]/PLAN.md (- [ ] → - [x])
       - Update Task Progress count
       - If no unchecked tasks remain: set State to ALL DONE
    6. If FAILS:
       - Set State to FAILED
       - Write exact error to Last Developer Result
    HARD RULE: Never write or edit application code.
    HARD RULE: Never mark done unless verification actually passed.

After copying/writing all files, confirm:

> "loop-stack/<LOOP_ID>/ created: PLAN.md · STATUS.md · MEMORY.md · TOOLS.md · RESEARCH.md
> loop-stack/.global/ initialized: MEMORY.md
> .agents/ ready: tool-scout · researcher · developer · qa-tester · verifier · auditor · memory-keeper
> Starting loop..."

---

## Phase 4 — Tool Discovery Run

Before the main loop, dispatch a tool-scout subagent:

Dispatch a subagent with the following goal. The subagent should read `.agents/tool-scout.md` for its role definition.
Do not spawn the next agent until this subagent has written loop-stack/<LOOP_ID>/TOOLS.md.
```
Loop directory: loop-stack/<LOOP_ID>/
IMPORTANT: Read loop-stack/.global/MEMORY.md FIRST — apply any cross-loop project learnings.
Read loop-stack/<LOOP_ID>/PLAN.md to understand the goal.
Check loop-stack/.global/TOOLS.md BEFORE any discovery:
- If it exists and was modified less than 7 days ago: copy its content to loop-stack/<LOOP_ID>/TOOLS.md and skip discovery (write Status: REUSED FROM GLOBAL)
- Otherwise: discover all available tools, MCPs, plugins, and skills. Write results to BOTH loop-stack/<LOOP_ID>/TOOLS.md AND loop-stack/.global/TOOLS.md (overwrite global).
Follow .agents/tool-scout.md instructions.
```

Auto-continue into the outer loop immediately after tool-scout completes — no user confirmation needed.

---

## Phase 5 — Outer Loop

You (the AI, main session) are the outer loop controller.
**FULLY AUTONOMOUS — never pause for user input during the loop. Handle all failures automatically.**

**Initialize:**
- `turns_used = 0`
- `skipped_tasks = []`
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

### Step 2.5 — Spawn RESEARCHER
Dispatch a researcher subagent with the following goal.
The subagent should read `.agents/researcher.md` for its role definition.
Do not spawn the next agent until this subagent has written RESEARCH.md and updated STATUS.md "Last Researcher Result".
```
Loop directory: loop-stack/<LOOP_ID>/
GLOBAL DATA FIRST — read these before anything else:
  - loop-stack/.global/MEMORY.md — cross-loop learnings (check for prior research on similar tasks)
  - loop-stack/.global/TOOLS.md — global tool cache
Then read loop-stack/<LOOP_ID>/MEMORY.md, loop-stack/<LOOP_ID>/TOOLS.md, loop-stack/<LOOP_ID>/PLAN.md.
Current task: {current_task}
Research what the developer needs. Write findings to loop-stack/<LOOP_ID>/RESEARCH.md.
Update STATUS.md "Last Researcher Result" with a one-line summary.
Follow .agents/researcher.md.
```
Increment `turns_used`.

### Step 3 — Spawn DEVELOPER
Dispatch a developer subagent with the following goal.
The subagent should read `.agents/developer.md` for its role definition.
Do not spawn the next agent until this subagent has updated STATUS.md "Last Developer Result".
```
Loop directory: loop-stack/<LOOP_ID>/
GLOBAL DATA FIRST — read these before writing any code:
  - loop-stack/.global/MEMORY.md — cross-loop project learnings (apply patterns found here)
  - loop-stack/.global/TOOLS.md — cross-loop tool cache
Then read loop-stack/<LOOP_ID>/MEMORY.md, loop-stack/<LOOP_ID>/TOOLS.md, loop-stack/<LOOP_ID>/PLAN.md, loop-stack/<LOOP_ID>/STATUS.md.
READ THIS BEFORE CODING: loop-stack/<LOOP_ID>/RESEARCH.md — researcher's findings and suggested approach for this task.
Current task: {current_task}
Last Researcher Result: {Last Researcher Result from STATUS.md}
Previous attempt result: {Last Developer Result from STATUS.md}
Implement. Follow .agents/developer.md.
```
Increment `turns_used`.

### Step 4 — Spawn QA TESTER
Dispatch a QA tester subagent with the following goal.
The subagent should read `.agents/qa-tester.md` for its role definition.
Do not spawn the next agent until this subagent has updated STATUS.md "Last QA Result".
```
Loop directory: loop-stack/<LOOP_ID>/
GLOBAL DATA FIRST — read loop-stack/.global/MEMORY.md for cross-loop test quirks.
Also read loop-stack/.global/TOOLS.md for cross-loop tool context.
Read loop-stack/<LOOP_ID>/MEMORY.md, loop-stack/<LOOP_ID>/TOOLS.md.
Read loop-stack/<LOOP_ID>/RESEARCH.md — check for edge cases the researcher identified.
Read loop-stack/<LOOP_ID>/STATUS.md — developer result: {Last Developer Result from STATUS.md}
Current task just implemented: {current_task}
Run QA checks. Follow .agents/qa-tester.md.
```

### Step 5 — Spawn VERIFIER
Dispatch a verifier subagent with the following goal.
The subagent should read `.agents/verifier.md` for its role definition.
Do not spawn the next agent until this subagent has updated STATUS.md State to VERIFIED_PASS or FAILED.
```
Loop directory: loop-stack/<LOOP_ID>/
GLOBAL DATA FIRST — read loop-stack/.global/MEMORY.md for cross-loop verification gotchas.
Read loop-stack/<LOOP_ID>/MEMORY.md.
Current task: {current_task}
Last QA Result: {Last QA Result from STATUS.md}
Run stop condition and update loop-stack/<LOOP_ID>/. Follow .agents/verifier.md.
```

### Step 6 — Read verifier result

**If State == FAILED:**
- Increment attempts in loop-stack/<LOOP_ID>/STATUS.md
- If attempts >= 3:
  - **Auto-skip — do NOT pause for user.**
  - Add to `skipped_tasks`: `{current_task} (3 attempts failed)`
  - Update loop-stack/<LOOP_ID>/STATUS.md: Skipped Tasks += current_task, Blocked Reason = "3 attempts failed"
  - Advance to next task (go to Step 10 without marking [x])
- Else → continue loop with failure context in loop-stack/<LOOP_ID>/STATUS.md

**If State == VERIFIED_PASS:**

### Step 7 — Spawn AUDITOR
Dispatch an auditor subagent with the following goal.
The subagent should read `.agents/auditor.md` for its role definition.
Do not spawn the next agent until this subagent has updated STATUS.md "Last Audit Result".
```
Loop directory: loop-stack/<LOOP_ID>/
GLOBAL DATA FIRST — read loop-stack/.global/MEMORY.md for cross-loop project standards.
Also read loop-stack/.global/TOOLS.md for cross-loop tool context.
Read loop-stack/<LOOP_ID>/MEMORY.md, loop-stack/<LOOP_ID>/TOOLS.md.
Read loop-stack/<LOOP_ID>/RESEARCH.md — check constraints the researcher identified.
Task just verified: {current_task}
Last Developer Result: {Last Developer Result from STATUS.md}
Last QA Result: {Last QA Result from STATUS.md}
Review for quality. Follow .agents/auditor.md.
```

### Step 8 — Read audit result

**If BLOCK:**
- **Auto-attempt fix — do NOT pause for user.**
  1. Dispatch DEVELOPER again with the BLOCK issue as explicit context (one retry, increment `turns_used`); wait for STATUS.md "Last Developer Result" to update
  2. Dispatch VERIFIER to re-check; wait for STATUS.md State to update
  3. If still BLOCK → add to `skipped_tasks`: `{current_task} (audit block, auto-fix failed)`, advance to next task
  4. If passes → continue to Step 9

**If CLEAN or WARN:**

### Step 9 — Spawn MEMORY KEEPER
Dispatch a memory-keeper subagent with the following goal.
The subagent should read `.agents/memory-keeper.md` for its role definition.
Do not advance to Step 10 until this subagent has updated MEMORY.md.
```
Loop directory: loop-stack/<LOOP_ID>/
Task just completed and audited: {current_task}
Last Audit Result: {Last Audit Result from STATUS.md}
Distill learnings into loop-stack/<LOOP_ID>/MEMORY.md.
Also append the single most important learning to loop-stack/.global/MEMORY.md.
Follow .agents/memory-keeper.md.
```

### Step 10 — Advance
- Increment `done_tasks`
- Reset attempts to 0
- If `USE_GIT`: commit `loop-stack/<LOOP_ID>/PLAN.md` + `loop-stack/<LOOP_ID>/STATUS.md` with `loop: verified {current_task}`
- Find next unchecked task in loop-stack/<LOOP_ID>/PLAN.md
- If none:
  - Update loop-stack/<LOOP_ID>/STATUS.md State to ALL DONE
  - Rename the loop directory to mark it complete:
    - Bash: `mv "loop-stack/<LOOP_ID>" "loop-stack/<LOOP_ID>_DONE"`
  - Go to Phase 6 (use path `loop-stack/<LOOP_ID>_DONE/` from here on)
- Else → update loop-stack/<LOOP_ID>/STATUS.md Current Task → continue loop

---

## Phase 6 — Completion Report

Write `loop-stack/<LOOP_ID>_DONE/REPORT.md`:

    # Loop Report

    ## Goal
    {GOAL}

    ## Outcome
    {ALL DONE / budget reached / stopped by user / auditor block}

    ## Summary
    Completed {done_tasks} of {total_tasks} tasks in {turns_used} turns.
    Skipped: {count} tasks.

    ## Completed Tasks
    {list}

    ## Skipped / Remaining
    {list with skip reasons}

    ## Tools Used
    {from TOOLS.md — recommended tools}

    ## Key Learnings
    {from MEMORY.md — all accumulated learnings}

    ## Git Integration
    {yes / no — commits made: N}

Print to user:

    ## Loop Complete
    Outcome: {outcome}
    Tasks: {done_tasks}/{total_tasks} | Skipped: {len(skipped_tasks)} | Turns: {turns_used}/{MAX_TURNS}
    Loop folder: loop-stack/<LOOP_ID>_DONE/
    Learnings saved: loop-stack/<LOOP_ID>_DONE/MEMORY.md
    Full report: loop-stack/<LOOP_ID>_DONE/REPORT.md

---

## Rules

- Phase 0 always runs first — check for resume before asking anything. Skip `_DONE` folders.
- **Global data first**: Every subagent prompt must instruct agents to read `loop-stack/.global/MEMORY.md` and check `loop-stack/.global/TOOLS.md` BEFORE doing any work. Never re-discover what's already in global.
- Tool-scout runs once before the main loop. It MUST check global TOOLS.md first (skip discovery if <7 days old).
- Researcher runs before developer every task — provides grounded context, reduces hallucination.
- Memory-keeper runs after every auditor pass — writes to both loop and global MEMORY.md.
- Never write literal placeholders like `{STOP_CONDITION}` into generated files.
- All state files live in `loop-stack/<LOOP_ID>/`. All agent definitions live in `.agents/`.
- Never exceed MAX_TURNS without stopping and reporting.
- **Fully autonomous**: Never pause for user input during the loop. On 3 failures: auto-skip. On audit BLOCK: auto-fix once then skip.
- On loop completion: rename `loop-stack/<LOOP_ID>/` → `loop-stack/<LOOP_ID>_DONE/`.
- Each loop runs in its own directory — never read/write another loop's files.
- Global files (`loop-stack/.global/`) are shared across all loops — always check them first.
- Each subagent must complete and update STATUS.md before the next subagent is dispatched — the loop is sequential.
