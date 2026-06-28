---
name: loop-engineer-codex
description: >
  Loop engineering wizard for OpenAI Codex CLI. Discovers available tools
  and MCPs, scaffolds a 7-agent team as TOML files (tool-scout, researcher,
  developer, qa-tester, verifier, auditor, memory-keeper), generates
  loop-stack/<LOOP_ID>/ state files with persistent memory, and outputs the
  exact `codex /goal` command to run the fully autonomous loop.
---

# Loop Engineer (Codex)

You are running a loop engineering wizard for OpenAI Codex. Follow these phases in order.

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

- **Resume** → skip to Phase 5, output the `/goal` command using existing files in `loop-stack/{loop-id}/`.
- **Fresh** → delete only `loop-stack/<loop-id>/` directory (do NOT delete `.codex/agents/` — those are shared across loops), continue to Phase 1.

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

One at a time. Wait for full answer.

**Q1 — Goal:**
> "What do you want the loop to accomplish? (1-2 sentences)"

After storing GOAL, generate LOOP_ID by slugifying GOAL:
- lowercase, replace non-alphanumeric runs with hyphens, strip leading/trailing hyphens
- Take only the first 4 meaningful words (skip stop words: a, an, the, to, for, of, in, on, with, and, or)
- Truncate to **24 chars max**, strip any trailing hyphen
- Example: "Add authentication flow to the REST API" → "add-auth-flow-api"
- If the resulting LOOP_ID is empty, use timestamp fallback: `loop-` + `YYYYMMDD-HHMMSS`.

Store as LOOP_ID.

**Q2 — Git integration:**
> "Auto-commit after each verified task? (yes / no)"

Store: `GOAL`, `LOOP_ID`, `USE_GIT`.
Auto-set: `STOP_CONDITION` = "all tasks in loop-stack/<LOOP_ID>/PLAN.md checked", `BUDGET_STRING` = "20 turns".

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
    All agents read this before acting. Updated by memory-keeper after each verified task.
    ## Learnings
    (none yet)

**loop-stack/<LOOP_ID>/TOOLS.md:**

    # Discovered Tools
    Written by tool-scout at loop start. All agents check this for available tooling.
    ## Status
    PENDING

**loop-stack/<LOOP_ID>/RESEARCH.md:**

    # Research Log
    Written by the researcher agent before each task. Developer reads this before coding.
    ## Current Task Research
    (none yet)

Initialize global memory if needed:
- If `loop-stack/.global/MEMORY.md` does not exist, create it:

      # Global Loop Memory
      Cross-loop project learnings. Written by memory-keeper after each task.
      ## Learnings
      (none yet)

### .codex/agents/ files

Create `.codex/agents/` if it does not exist.

Copy the 6 pre-built agent files from `~/.codex/skills/loop-engineer-codex/agents/` into `.codex/agents/`:
- `tool-scout.toml`
- `researcher.toml`
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
    Note: LOOP_DIR is provided in your spawning prompt.
    1. Read loop-stack/.global/MEMORY.md — check for cross-loop verification gotchas.
    2. Read [LOOP_DIR]/MEMORY.md — check for verification gotchas for this loop.
    3. Read [LOOP_DIR]/STATUS.md and [LOOP_DIR]/PLAN.md.
    4. Run: {STOP_CONDITION}
    5. If PASSES:
       - Set [LOOP_DIR]/STATUS.md State to VERIFIED_PASS
       - Mark task done in [LOOP_DIR]/PLAN.md (- [ ] to - [x])
       - Update Task Progress
       - If no unchecked tasks remain: set State to ALL DONE
    6. If FAILS:
       - Set State to FAILED
       - Write exact error to Last Developer Result
    HARD RULE: Never write or edit application code.
    HARD RULE: Never mark done unless verification actually passed.
    Call report_agent_job_result when done.
    """

After copying/writing all files, confirm to user:
> "loop-stack/<LOOP_ID>/ created: PLAN.md · STATUS.md · MEMORY.md · TOOLS.md · RESEARCH.md
> loop-stack/.global/ initialized: MEMORY.md
> .codex/agents/ ready: tool-scout · researcher · developer · qa-tester · verifier · auditor · memory-keeper"

---

## Phase 4 — Start the Loop

Tell the user:

> **Start Codex in your project directory, then paste this `/goal` prompt:**

Print with real values substituted — never print literal placeholders:

```
/goal {GOAL}

Loop directory: loop-stack/<LOOP_ID>/
Agent definitions: .codex/agents/.
Budget: {BUDGET_STRING}

Step 1 — Before the first iteration, use spawn_agent to run the tool-scout agent.
Pass it: "Loop directory: loop-stack/<LOOP_ID>/"
GLOBAL DATA FIRST: Check loop-stack/.global/TOOLS.md before any discovery:
- If it exists and was modified less than 7 days ago: copy its content to loop-stack/<LOOP_ID>/TOOLS.md and skip discovery (write Status: REUSED FROM GLOBAL).
- Otherwise: discover all available tools, MCPs, plugins. Write results to BOTH loop-stack/<LOOP_ID>/TOOLS.md AND loop-stack/.global/TOOLS.md (overwrite global).
Wait for tool-scout to finish before proceeding.

Step 2 — Loop until all tasks in loop-stack/<LOOP_ID>/PLAN.md are checked or budget is reached.
FULLY AUTONOMOUS — never pause for user input. Handle all failures automatically.
Print progress each iteration: [Task X/N | Turn Y]
Track skipped_tasks = []

Each iteration:
a. Read loop-stack/<LOOP_ID>/PLAN.md and loop-stack/<LOOP_ID>/STATUS.md — pick the next unchecked task.

b. spawn_agent: researcher — pass "Loop directory: loop-stack/<LOOP_ID>/"
   Instructions: "GLOBAL DATA FIRST — read loop-stack/.global/MEMORY.md AND loop-stack/.global/TOOLS.md before anything else. Then read [LOOP_DIR]/MEMORY.md, TOOLS.md, PLAN.md, STATUS.md. Research the current task. Write findings to loop-stack/<LOOP_ID>/RESEARCH.md. Update STATUS.md 'Last Researcher Result' with one-line summary."
   Wait for researcher to finish.

c. spawn_agent: developer — pass "Loop directory: loop-stack/<LOOP_ID>/"
   Instructions: "GLOBAL DATA FIRST — read loop-stack/.global/MEMORY.md AND loop-stack/.global/TOOLS.md. Then read [LOOP_DIR]/MEMORY.md, TOOLS.md, PLAN.md, STATUS.md. READ BEFORE CODING: loop-stack/<LOOP_ID>/RESEARCH.md. Implement the current task. Previous attempt: {Last Developer Result}."
   Wait for developer to finish.

d. spawn_agent: qa-tester — pass "Loop directory: loop-stack/<LOOP_ID>/"
   Instructions: "GLOBAL DATA FIRST — read loop-stack/.global/MEMORY.md AND loop-stack/.global/TOOLS.md. Read [LOOP_DIR]/RESEARCH.md for edge cases."
   Wait for qa-tester to finish.

e. spawn_agent: verifier — pass "Loop directory: loop-stack/<LOOP_ID>/"
   Instructions: "GLOBAL DATA FIRST — read loop-stack/.global/MEMORY.md. Check stop condition: {STOP_CONDITION}"
   - VERIFIED_PASS → go to (f)
   - FAILED, attempts < 3 → increment attempts in STATUS.md, retry from (b) with error context
   - FAILED, attempts >= 3 → AUTO-SKIP (do NOT ask user): append task to skipped_tasks, update STATUS.md Skipped Tasks, advance to next task

f. spawn_agent: auditor — pass "Loop directory: loop-stack/<LOOP_ID>/"
   Instructions: "GLOBAL DATA FIRST — read loop-stack/.global/MEMORY.md AND loop-stack/.global/TOOLS.md. Read [LOOP_DIR]/RESEARCH.md for constraints."
   - CLEAN or WARN → go to (g)
   - BLOCK → AUTO-FIX (do NOT ask user): retry developer once with BLOCK issue as context, re-run verifier.
     If still BLOCK → append task to skipped_tasks, advance to next task.

g. spawn_agent: memory-keeper — pass "Loop directory: loop-stack/<LOOP_ID>/"
   Wait for memory-keeper to finish before advancing.

h. Advance to next task. If USE_GIT=yes: commit loop-stack/<LOOP_ID>/PLAN.md + STATUS.md.

Step 3 — When all tasks verified or budget reached:
- Update STATUS.md State to ALL DONE (or BUDGET_REACHED)
- Rename loop directory: mv loop-stack/<LOOP_ID>/ loop-stack/<LOOP_ID>_DONE/
- Write loop-stack/<LOOP_ID>_DONE/REPORT.md with goal, outcome, completed tasks, skipped tasks, key learnings from MEMORY.md
- Stop.
```

> **Requirements:**
> - Codex CLI v0.128.0+ with `features.multi_agent = true` (on by default)
> - `/goal` is a TUI slash command — run `codex` first, then paste the prompt above
> - Models: `gpt-5.5` for main agents, `gpt-5.4-mini` for tool-scout and memory-keeper — edit `.toml` files to change

---

## Rules

- Phase 0 always first — check for resume before asking anything. Skip `_DONE` folders.
- Never write literal `{STOP_CONDITION}` into generated files.
- Agent files go in `.codex/agents/`. State files go in `loop-stack/<LOOP_ID>/`.
- **Global data first**: Every spawn instruction must tell agents to read `loop-stack/.global/MEMORY.md` AND `loop-stack/.global/TOOLS.md` before acting.
- Researcher runs before developer every task — provides grounded context, reduces hallucination.
- On loop completion: rename `loop-stack/<LOOP_ID>/` → `loop-stack/<LOOP_ID>_DONE/`.
- Each loop runs in its own `loop-stack/<LOOP_ID>/` directory — never read/write another loop's files.
- Global files (`loop-stack/.global/`) are shared across all loops — always check them first.
- **Fully autonomous**: Never pause for user. On 3 failures: auto-skip. On audit BLOCK: auto-fix once then skip.
