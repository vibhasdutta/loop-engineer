---
name: loop-engineer
description: >
  Loop engineering wizard for OpenCode. Asks 2 questions, then orchestrates
  a fully autonomous agent team (tool-scout, researcher, planner, developer,
  qa-tester, verifier, auditor, memory-keeper) until the goal is met.
  Agents run sequentially via the task tool. Dynamic researcher count.
  Persistent memory, git integration, resume support.
---

# Loop Engineer (OpenCode)

You are running a loop engineering wizard. Follow these phases in order.

---

## Phase 0 — Resume Check

Scan for `loop-stack/*/STATUS.md`. **Skip any directory ending with `_DONE`.**

**None found:** continue to Phase 1.
**One found:** show State/Current Task/Progress, ask: Resume or Fresh?
- Resume → skip to Phase 5.
- Fresh → delete `loop-stack/<loop-id>/` only (keep `.opencode/agents/`), continue to Phase 1.
**Multiple found:** list all, ask which to resume or type 'fresh'.

---

## Phase 1 — Core Wizard

**Q1:** "What do you want the loop to accomplish? (1-2 sentences)"

Generate LOOP_ID: lowercase slug, first 4 meaningful words, max 24 chars.
Auto-set: `STOP_CONDITION` = "all tasks in loop-stack/<LOOP_ID>/PLAN.md checked", `MAX_TURNS` = 20.

**Q2:** "Should the loop auto-commit after each verified task? (yes / no)"

---

## Phase 2 — State File Creation

Create `loop-stack/<LOOP_ID>/` with PLAN.md (task stub), STATUS.md, MEMORY.md, TOOLS.md, RESEARCH.md.
Create `loop-stack/.global/MEMORY.md` if missing.

**PLAN.md:**

    # Loop Plan
    ## Goal
    {GOAL}
    ## Stop Condition
    {STOP_CONDITION}
    ## Budget
    20 turns
    ## Git Integration
    {yes / no}
    ## Tasks
    (will be created by the planner agent)

**STATUS.md:**

    # Loop Status
    ## State
    IN_PROGRESS
    ## Current Task
    (planning in progress)
    ## Task Progress
    0 / ? complete
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

---

## Phase 3 — Agent File Setup

**CRITICAL: Use shell commands — do NOT write agent files manually.**

```bash
mkdir -p .opencode/agents
cp ~/.config/opencode/skills/loop-engineer/agents/*.md .opencode/agents/
```

If skill is installed via Claude-compatible path:
```bash
cp ~/.claude/skills/loop-engineer/agents/*.md .opencode/agents/
```

Then write only `verifier.md` with actual STOP_CONDITION substituted (never write the literal placeholder):

    ---
    name: verifier
    description: Runs the stop condition. Marks tasks done or failed. Never writes application code.
    mode: subagent
    steps: 15
    temperature: 0.1
    permission:
      edit: allow
      write: allow
      bash: allow
    ---
    1. Read loop-stack/.global/MEMORY.md FIRST.
    2. Read [LOOP_DIR]/MEMORY.md, STATUS.md, PLAN.md.
    3. Run: {STOP_CONDITION}
    4. PASSES → set State VERIFIED_PASS, mark [x] in PLAN.md, update Task Progress. If all done: ALL DONE.
    5. FAILS → set State FAILED, write exact error to Last Developer Result.
    HARD RULE: Never write application code. Never mark done unless verification actually passed.

Confirm to user:
> "loop-stack/<LOOP_ID>/ created: PLAN.md · STATUS.md · MEMORY.md · TOOLS.md · RESEARCH.md
> .opencode/agents/ ready: tool-scout · researcher · planner · developer · qa-tester · verifier · auditor · memory-keeper
> Starting startup sequence..."

---

## Phase 4 — Startup Sequence

Use the `task` tool to invoke each agent. Agents run sequentially — invoke each, wait for completion, then invoke the next.

### Step 1 — RESEARCHERS (dynamic count, sequential)

Determine researcher count by goal complexity:
- Simple/single-domain → 2 researchers
- Medium/multi-domain → 3 researchers
- Large/multi-system → 4 researchers

Domains to distribute across researchers:
- **Architecture & Code**: source structure, patterns, package files, existing tests
- **Domain & APIs**: README, docs/, external APIs, .env.example, configs
- **Data & State**: DB schema, data models, state management (for 3+ researchers)
- **Deployment & Config**: CI/CD, infrastructure, build, Docker (for 4 researchers)

Invoke each researcher sequentially using the `task` tool:
```
agent: researcher
prompt: |
  Loop directory: loop-stack/<LOOP_ID>/
  Focus: {ASSIGNED_DOMAIN} — {specific files and concerns}
  GLOBAL DATA FIRST: read loop-stack/.global/MEMORY.md and loop-stack/.global/TOOLS.md.
  Write findings to loop-stack/<LOOP_ID>/RESEARCH.md under "## {Domain Name}".
  Update STATUS.md "Last Researcher Result".
```

### Step 2 — TOOL SCOUT

Invoke using the `task` tool:
```
agent: tool-scout
prompt: |
  Loop directory: loop-stack/<LOOP_ID>/
  Check loop-stack/.global/TOOLS.md — if < 7 days old, reuse. Otherwise discover all tools.
  Write to loop-stack/<LOOP_ID>/TOOLS.md AND loop-stack/.global/TOOLS.md.
```

### Step 3 — PLANNER

Invoke using the `task` tool:
```
agent: planner
prompt: |
  Loop directory: loop-stack/<LOOP_ID>/
  Read RESEARCH.md (all sections) and TOOLS.md.
  Create 3–7 tasks with parallel group tags [G1], [G2], etc.
  Same group = independent tasks (can conceptually run in parallel).
  Different group = sequential dependency.
  Replace "## Tasks" in PLAN.md. Update STATUS.md.
```

Auto-continue into outer loop immediately.

---

## Phase 5 — Outer Loop

**FULLY AUTONOMOUS. Never pause for user input.**

Initialize: `turns_used = 0`, `skipped_tasks = []`.

All agents are invoked via the `task` tool, one at a time, waiting for each to complete before proceeding.

### Iteration steps:

1. **Budget check** — over MAX_TURNS → Phase 6.

2. **Read state** — identify current parallel group (all unchecked [GN] tasks).

3. **RESEARCHERS** — invoke one per task in batch sequentially (2 if batch=1):
   ```
   agent: researcher
   prompt: |
     Loop directory: loop-stack/<LOOP_ID>/
     GLOBAL DATA FIRST — read loop-stack/.global/MEMORY.md AND loop-stack/.global/TOOLS.md.
     Then read loop-stack/<LOOP_ID>/MEMORY.md, TOOLS.md, PLAN.md, STATUS.md.
     Current task: {this_task}
     Research what the developer needs for THIS SPECIFIC TASK.
     Append findings to loop-stack/<LOOP_ID>/RESEARCH.md under "## Task-Specific Research — {this_task}".
   ```
   Increment turns_used.

4. **DEVELOPERS** — invoke one per task sequentially:
   ```
   agent: developer
   prompt: |
     Loop directory: loop-stack/<LOOP_ID>/
     GLOBAL DATA FIRST — read loop-stack/.global/MEMORY.md AND loop-stack/.global/TOOLS.md.
     Read MEMORY.md, TOOLS.md, PLAN.md, STATUS.md.
     READ: RESEARCH.md "## Task-Specific Research — {this_task}".
     Current task: {this_task}. Scope: only files for this task.
     Implement. Append discoveries to MEMORY.md. Update STATUS.md.
   ```
   Increment turns_used.

5. **MEMORY-KEEPER checkpoints** — invoke one per task sequentially. Local only.

6. **QA TESTERS** — invoke one per task sequentially.

7. **VERIFIERS** — invoke one per task sequentially.

8. **Process verifier results**:
   - VERIFIED_PASS → auditor
   - FAILED, attempts < 3 → increment attempts in STATUS.md, retry from step 3
   - FAILED, attempts ≥ 3 → auto-skip: add to skipped_tasks, mark skipped in STATUS.md

9. **AUDITORS** — invoke one per passing task sequentially.

10. **Process audit results**:
    - CLEAN/WARN → proceed
    - BLOCK → auto-fix: invoke developer once more with BLOCK context + re-verify. Still BLOCK → auto-skip.

11. **MEMORY-KEEPER final** — single invoke, local + global write.

12. **Advance** — mark [x] in PLAN.md, increment done_tasks, reset attempts.
    - If `USE_GIT`: commit PLAN.md + STATUS.md.
    - Find next unchecked group.
    - None → ALL DONE → rename `loop-stack/<LOOP_ID>/` → `loop-stack/<LOOP_ID>_DONE/` → Phase 6.
    - Else → update STATUS.md → continue loop.

---

## Phase 6 — Completion Report

Write `loop-stack/<LOOP_ID>_DONE/REPORT.md` and print summary to user.

---

## Rules

- Phase 0 first. Skip `_DONE` folders.
- **File copy**: `cp ~/.config/opencode/skills/loop-engineer/agents/*.md .opencode/agents/` — never manual.
- **Global data first**: every agent reads `.global/MEMORY.md` + `.global/TOOLS.md` before acting.
- **Sequential execution**: OpenCode's `task` tool runs one agent at a time — invoke each, wait, then proceed.
- **Researcher before developer**: always. Dynamic count based on goal complexity.
- **Memory-keeper twice per batch**: checkpoint (local) after devs, consolidation (local+global) after audit.
- **Developers append to MEMORY.md directly** during work.
- **Planner**: once at startup after researchers + tool-scout. Tasks MUST use [G1]/[G2] group tags.
- **Fully autonomous**: no pauses. 3 fails → auto-skip. BLOCK → auto-fix once → skip.
- **doom_loop**: if OpenCode triggers doom_loop detection (3 identical tool calls), the developer agent has `doom_loop: allow` — the loop continues.
- On completion: rename to `<LOOP_ID>_DONE/`.
- **AGENTS.md**: copy `platforms/opencode/AGENTS.md` to the project root if not present — it gives OpenCode context about the loop.
