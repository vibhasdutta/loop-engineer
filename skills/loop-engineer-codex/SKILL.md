---
name: loop-engineer-codex
description: >
  Loop engineering wizard for OpenAI Codex CLI. Discovers available tools
  and MCPs, scaffolds a 6-agent team as TOML files (tool-scout, developer,
  qa-tester, verifier, auditor, memory-keeper), generates loop-stack/<LOOP_ID>/
  state files with persistent memory, and outputs the exact `codex /goal` command.
---

# Loop Engineer (Codex)

You are running a loop engineering wizard for OpenAI Codex. Follow these phases in order.

---

## Phase 0 — Resume Check

Before anything else, scan for any `loop-stack/*/STATUS.md` files (subdirectory pattern) in the current directory.

**If none found:** continue to Phase 1.

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
- lowercase, replace non-alphanumeric runs with hyphens, strip leading/trailing hyphens, max 40 chars
- Example: "Add auth flow to API" → "add-auth-flow-to-api"
- If the resulting LOOP_ID is empty (e.g., goal was all punctuation or non-ASCII), use a timestamp fallback: `loop-` + current date-time as `YYYYMMDD-HHMMSS`.
- After truncating to 40 chars, strip any trailing hyphen.

Store as LOOP_ID.

**Q2 — Stop condition:**
> "How do we verify success? Exact command or condition.
> Examples: `npm test exits 0` · `python -m pytest exits 0` · `all tasks in loop-stack/<LOOP_ID>/PLAN.md checked`"

**Q3 — Budget:**
> "Maximum budget? Examples: `10 turns` · `$5` · `15 turns or $3, whichever first`"

**Q4 — Git integration:**
> "Auto-commit after each verified task? (yes / no)"

Store: `GOAL`, `LOOP_ID`, `STOP_CONDITION`, `BUDGET_STRING`, `USE_GIT`.

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

    ## Extra Context
    {EXTRA_CONTEXT_1 or "(none)"}
    {EXTRA_CONTEXT_2 or "(none)"}

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

Initialize global memory if needed:
- If `loop-stack/.global/MEMORY.md` does not exist, create it:

      # Global Loop Memory
      Cross-loop project learnings. Written by memory-keeper after each task.
      ## Learnings
      (none yet)

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
    Note: LOOP_DIR is provided in your spawning prompt.
    1. Read [LOOP_DIR]/MEMORY.md — check for verification gotchas.
    2. Read [LOOP_DIR]/STATUS.md and [LOOP_DIR]/PLAN.md.
    3. Run: {STOP_CONDITION}
    4. If PASSES:
       - Set [LOOP_DIR]/STATUS.md State to VERIFIED_PASS
       - Mark task done in [LOOP_DIR]/PLAN.md (- [ ] to - [x])
       - Update Task Progress
       - If no unchecked tasks remain: set State to ALL DONE
    5. If FAILS:
       - Set State to FAILED
       - Write exact error to Last Developer Result
    HARD RULE: Never write or edit application code.
    HARD RULE: Never mark done unless verification actually passed.
    Call report_agent_job_result when done.
    """

After copying/writing all files, confirm to user:
> "loop-stack/<LOOP_ID>/ created: PLAN.md · STATUS.md · MEMORY.md · TOOLS.md
> loop-stack/.global/ initialized: MEMORY.md
> .codex/agents/ ready: tool-scout · developer · qa-tester · verifier · auditor · memory-keeper"

---

## Phase 5 — Start the Loop

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
Check loop-stack/.global/TOOLS.md:
- If it exists and was modified less than 7 days ago: copy its content to loop-stack/<LOOP_ID>/TOOLS.md and skip discovery (write Status: REUSED FROM GLOBAL).
- Otherwise: discover all available tools, MCPs, plugins. Write results to BOTH loop-stack/<LOOP_ID>/TOOLS.md AND loop-stack/.global/TOOLS.md (overwrite global).
Wait for tool-scout to finish before proceeding.

Step 2 — Loop until all tasks in loop-stack/<LOOP_ID>/PLAN.md are checked or budget is reached.
Print progress each iteration: [Task X/N | Turn Y]

Each iteration:
a. Read loop-stack/<LOOP_ID>/PLAN.md and loop-stack/<LOOP_ID>/STATUS.md — pick the next unchecked task.
b. spawn_agent: developer — pass "Loop directory: loop-stack/<LOOP_ID>/" — implement the task.
c. spawn_agent: qa-tester — pass "Loop directory: loop-stack/<LOOP_ID>/" — run tests.
d. spawn_agent: verifier — pass "Loop directory: loop-stack/<LOOP_ID>/" — check stop condition: {STOP_CONDITION}
   - VERIFIED_PASS → go to (e)
   - FAILED, attempts < 3 → retry developer with error context from loop-stack/<LOOP_ID>/STATUS.md
   - FAILED, attempts >= 3 → stop, report blocker to user
e. spawn_agent: auditor — pass "Loop directory: loop-stack/<LOOP_ID>/" — review completed work.
   - CLEAN or WARN → go to (f)
   - BLOCK → stop, report critical issue to user
f. spawn_agent: memory-keeper — pass "Loop directory: loop-stack/<LOOP_ID>/" — distill learnings into loop-stack/<LOOP_ID>/MEMORY.md and loop-stack/.global/MEMORY.md.
g. Advance to next task.

Step 3 — When all tasks verified: write loop-stack/<LOOP_ID>/REPORT.md and stop.
```

> **Requirements:**
> - Codex CLI v0.128.0+ with `features.multi_agent = true` (on by default)
> - `/goal` is a TUI slash command — run `codex` first, then paste the prompt above
> - Models: `gpt-5.5` for main agents, `gpt-5.4-mini` for tool-scout and memory-keeper — edit `.toml` files to change

---

## Rules

- Phase 0 always first — check for resume before asking anything.
- Never write literal `{STOP_CONDITION}` into generated files.
- Agent files go in `.codex/agents/`. State files go in `loop-stack/<LOOP_ID>/`.
- All agents must read MEMORY.md and TOOLS.md before acting.
- Each loop runs in its own `loop-stack/<LOOP_ID>/` directory — never read/write another loop's files.
- Global files (`loop-stack/.global/`) are shared across all loops — always check them before running tool discovery or starting fresh.
