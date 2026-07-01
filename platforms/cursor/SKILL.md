---
name: loop-engineer
description: >
  Loop engineering wizard for Cursor. Asks 2 questions, then orchestrates
  a fully autonomous parallel agent team (resource-scout, researcher, planner,
  agent-factory, executor, evaluator, verifier, auditor, memory-keeper) for any goal.
  Multiple agents run in parallel — dynamic researcher count, multiple executors
  on independent parts simultaneously. Persistent memory, git integration, resume support.
---

# Loop Engineer (Cursor)

You are running a loop engineering wizard. Follow these phases in order.

---

## Phase 0 — Resume Check

Scan for `loop-stack/*/STATUS.md`. **Skip any directory ending with `_DONE`.**

**None found:** continue to Phase 1.
**One found:** show State/Current Task/Progress, ask: Resume or Fresh?
- Resume → skip to Phase 5 using existing files.
- Fresh → delete `loop-stack/<loop-id>/` only (keep `.cursor/agents/`), continue to Phase 1.
**Multiple found:** list all, ask which to resume or type 'fresh'.

---

## Phase 1 — Core Wizard

**Q1:** "What do you want the loop to accomplish? (1-2 sentences)"

Generate LOOP_ID: lowercase slug, first 4 meaningful words, max 24 chars.
Auto-set: `STOP_CONDITION` = "all tasks in loop-stack/<LOOP_ID>/PLAN.md checked", `MAX_TURNS` = 20.

**Q2:** "Should the loop auto-commit after each verified task? (yes / no)"

---

## Phase 2 — State File Creation

Create `loop-stack/<LOOP_ID>/` with:

**PLAN.md** (task stub — planner fills in Phase 4):

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
    ## Last Executor Result
    (none)
    ## Last Evaluator Result
    (none)
    ## Last Audit Result
    (none)
    ## Blocked Reason
    (none)

**MEMORY.md:** `# Loop Memory\nUpdated continuously by all agents.\n## Learnings\n(none yet)`
**TOOLS.md:** `# Discovered Tools\n## Status\nPENDING`
**RESEARCH.md:** `# Research Log\n## Context & Prior Work\n(pending)\n## External Knowledge & Resources\n(pending)\n## Task-Specific Research\n(pending)`

**loop-stack/<LOOP_ID>/AGENTS.md:**

    # Specialized Agents
    ## Status
    PENDING (agent-factory will populate after planning)

Create `loop-stack/<LOOP_ID>/agents/` directory (agent-factory will write specialist agents here).

Create `loop-stack/.global/MEMORY.md` if missing.

---

## Phase 3 — Agent File Setup

**CRITICAL: Use shell commands — do NOT write agent files manually.**

**Bash (macOS/Linux):**
```bash
mkdir -p .cursor/agents
mkdir -p .cursor/agents/knowledge-sources
cp ~/.cursor/skills/loop-engineer/agents/resource-scout.md .cursor/agents/
cp ~/.cursor/skills/loop-engineer/agents/researcher.md .cursor/agents/
cp ~/.cursor/skills/loop-engineer/agents/planner.md .cursor/agents/
cp ~/.cursor/skills/loop-engineer/agents/agent-factory.md .cursor/agents/
cp ~/.cursor/skills/loop-engineer/agents/executor.md .cursor/agents/
cp ~/.cursor/skills/loop-engineer/agents/evaluator.md .cursor/agents/
cp ~/.cursor/skills/loop-engineer/agents/auditor.md .cursor/agents/
cp ~/.cursor/skills/loop-engineer/agents/memory-keeper.md .cursor/agents/
cp ~/.cursor/skills/loop-engineer/agents/knowledge-sources/*.md .cursor/agents/knowledge-sources/
```

**PowerShell (Windows):**
```powershell
New-Item -ItemType Directory -Force .cursor\agents | Out-Null
New-Item -ItemType Directory -Force ".cursor\agents\knowledge-sources" | Out-Null
Copy-Item "$env:USERPROFILE\.cursor\skills\loop-engineer\agents\*.md" ".cursor\agents\"
Copy-Item "$env:USERPROFILE\.cursor\skills\loop-engineer\agents\knowledge-sources\*.md" ".cursor\agents\knowledge-sources\"
```

Then write only `verifier.md` with actual STOP_CONDITION substituted:

    ---
    name: verifier
    description: Runs the stop condition. Marks tasks done or failed. Never writes application code.
    ---
    1. Read loop-stack/.global/MEMORY.md FIRST.
    2. Read [LOOP_DIR]/MEMORY.md, STATUS.md, PLAN.md.
    3. Run: {STOP_CONDITION}
    4. PASSES → State VERIFIED_PASS, mark [x], update Task Progress. All done → ALL DONE.
    5. FAILS → State FAILED, write exact error to Last Executor Result.
    HARD RULE: Never write application code. Never mark done unless verification passed.

Confirm: > ".cursor/agents/ ready · loop-stack/<LOOP_ID>/ created (PLAN.md, STATUS.md, MEMORY.md, TOOLS.md, RESEARCH.md, AGENTS.md) · agent-factory queued · Starting startup sequence..."

---

## Phase 4 — Startup Sequence

### Step 1 — Parallel RESEARCHERS (dynamic count)

Determine researcher count by goal complexity:
- Simple/single-domain → 2
- Medium/multi-domain → 3
- Large/multi-system → 4

**Spawn all simultaneously** (call Agent tool N times in one response).

Divide domains across researchers:
- **Context & Prior Work**: source structure, patterns, package.json/pyproject.toml/go.mod, tests
- **External Knowledge & Resources**: README, docs/, external APIs, .env.example, configs, integrations
- **Requirements & Constraints**: DB schema, data models, state management (for 3+ researchers)
- **Environment & Integration**: CI/CD, infrastructure, build, Docker (for 4 researchers)

Each researcher prompt:
```
Loop directory: loop-stack/<LOOP_ID>/
Focus: {ASSIGNED_DOMAIN} — {specific files and concerns}
GLOBAL DATA FIRST: read loop-stack/.global/MEMORY.md and loop-stack/.global/TOOLS.md.
Write findings to loop-stack/<LOOP_ID>/RESEARCH.md under "## {Domain Name}".
Update STATUS.md "Last Researcher Result".
Follow .cursor/agents/researcher.md.
```

Wait for ALL to complete.

### Step 2 — RESOURCE SCOUT

```
Loop directory: loop-stack/<LOOP_ID>/
Check loop-stack/.global/TOOLS.md — if < 7 days old, reuse. Otherwise discover all tools.
Write to loop-stack/<LOOP_ID>/TOOLS.md AND loop-stack/.global/TOOLS.md.
Follow .cursor/agents/resource-scout.md.
```

### Step 3 — PLANNER

```
Loop directory: loop-stack/<LOOP_ID>/
Read RESEARCH.md (all sections) and TOOLS.md.
Create 3–7 tasks with parallel group tags [G1], [G2], etc.
Same group = can run in parallel (independent files/modules).
Different group = sequential dependency.
Example:
  - [ ] [G1] Set up project config and database schema
  - [ ] [G2] Implement API authentication endpoints
  - [ ] [G2] Implement user profile frontend component
  - [ ] [G3] Integration tests
Replace "## Tasks" in PLAN.md. Update STATUS.md.
Follow .cursor/agents/planner.md.
```

### Step 4 — AGENT FACTORY

```
Loop directory: loop-stack/<LOOP_ID>/
Read loop-stack/<LOOP_ID>/PLAN.md (goal + tasks), RESEARCH.md, and TOOLS.md.
Analyze the goal domain and determine what specialized agents would improve execution quality.
Create 1–3 purpose-built agent files in loop-stack/<LOOP_ID>/agents/ tailored to this goal's domain and tasks.
Write loop-stack/<LOOP_ID>/AGENTS.md listing each created agent and which tasks it handles.
If the generic agents are sufficient, write AGENTS.md with "NONE CREATED" and skip creating files.
Follow .cursor/agents/agent-factory.md.
```

Auto-continue into outer loop.

---

## Phase 5 — Outer Loop

**FULLY AUTONOMOUS. Never pause for user input.**

Initialize: `turns_used = 0`, `skipped_tasks = []`, read total_tasks.

Print per iteration: `[Task {done+1}/{total} — {pct}% | Turn {turn}/{MAX_TURNS}]`

### Step 1 — Budget check → over MAX_TURNS → Phase 6.

### Step 2 — Read state. Identify current parallel group (all unchecked [GN] tasks).

### Step 3 — Parallel RESEARCHERS
Spawn one per task in batch (2 if batch=1, more if task is complex). Each appends to RESEARCH.md. Wait for all. Increment turns_used.

### Step 4 — Parallel EXECUTORS
Spawn one per task simultaneously:
```
Loop directory: loop-stack/<LOOP_ID>/
GLOBAL DATA FIRST — read loop-stack/.global/MEMORY.md AND loop-stack/.global/TOOLS.md.
Read MEMORY.md, TOOLS.md, PLAN.md, STATUS.md.
READ: RESEARCH.md section "## Task-Specific Research — {this_task}".
Current task: {this_task}. Scope: only files for this task.
Implement. Append discoveries directly to MEMORY.md. Update STATUS.md.
Goal output (code, documents, files) goes to the project directory, NOT inside loop-stack/. loop-stack/ is state-only.
Follow .cursor/agents/executor.md.
```
Wait for all. Increment turns_used.

### Step 5 — Parallel MEMORY-KEEPER checkpoints
One per task: local MEMORY.md only. Wait for all.

### Step 6 — Parallel EVALUATORS. One per task. Wait for all.

### Step 7 — Parallel VERIFIERS. One per task. Wait for all.

### Step 8 — Process results
- PASS → auditor
- FAIL < 3 attempts → retry from Step 3
- FAIL ≥ 3 → auto-skip

### Step 9 — Parallel AUDITORS (per passing task). Wait for all.

### Step 10 — Process audit results
- CLEAN/WARN → proceed
- BLOCK → auto-fix (one executor retry + re-verify). Still BLOCK → auto-skip.

### Step 11 — MEMORY-KEEPER final consolidation (single)
Distill all completed tasks. Write to MEMORY.md + loop-stack/.global/MEMORY.md.

### Step 12 — Advance
Mark [x]. Git commit if enabled. Find next group. None → ALL DONE →
rename `loop-stack/<LOOP_ID>/` → `loop-stack/<LOOP_ID>_DONE/` → Phase 6.

---

## Phase 6 — Completion Report

Write `loop-stack/<LOOP_ID>_DONE/REPORT.md` and print summary.

---

## Rules

- Phase 0 first. Skip `_DONE` folders.
- **File copy**: shell commands only. Never write agent files manually.
- **Global data first**: every agent reads `.global/MEMORY.md` + `.global/TOOLS.md`.
- **Parallel first**: same group = spawn simultaneously. Different group = sequential.
- **Researcher before executor**: always. Dynamic count.
- **Memory-keeper twice per batch**: checkpoint (local) after executors, consolidation (local+global) after audit.
- **Executors append to MEMORY.md directly** during work.
- **Planner**: once at startup after researchers + resource-scout.
- **Fully autonomous**: no pauses. 3 fails → auto-skip. BLOCK → auto-fix once → skip.
- On completion: rename to `<LOOP_ID>_DONE/`.
