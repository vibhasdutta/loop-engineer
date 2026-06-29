---
name: loop-engineer
description: >
  Loop engineering wizard for Hermes Agent. Asks 2 questions, then orchestrates
  a fully autonomous parallel agent team (resource-scout, researcher, planner,
  agent-factory, executor, evaluator, verifier, auditor, memory-keeper) for any goal.
  Uses delegate_task for true parallel subagent dispatch. Persistent memory,
  git integration, resume support. Activate with /loop-engineer.
compatibility: Requires git and a terminal backend (local, docker, ssh, modal, or daytona)
metadata:
  author: vibhasdutta
  version: "1.0"
  hermes:
    tags: [orchestration, multi-agent, loop-engineering, autonomous, coding]
    category: development
    requires_toolsets: [terminal]
---

# Loop Engineer (Hermes Agent)

You are running a loop engineering wizard. Follow these phases in order.

---

## Phase 0 — Resume Check

Scan for `loop-stack/*/STATUS.md`. **Skip any directory ending with `_DONE`.**

**None found:** continue to Phase 1.
**One found:** show State/Current Task/Progress, ask: Resume or Fresh?
- Resume → skip to Phase 5.
- Fresh → delete `loop-stack/<loop-id>/` only (keep `.hermes/agents/`), continue to Phase 1.
**Multiple found:** list all, ask which to resume or type 'fresh'.

---

## Phase 1 — Core Wizard

**Q1:** "What do you want the loop to accomplish? (1-2 sentences)"

Generate LOOP_ID: lowercase slug, first 4 meaningful words, max 24 chars.
Auto-set: `STOP_CONDITION` = "all tasks in loop-stack/<LOOP_ID>/PLAN.md checked", `MAX_TURNS` = 20.

**Q2:** "Should the loop auto-commit after each verified task? (yes / no)"

---

## Phase 2 — State File Creation

Create `loop-stack/<LOOP_ID>/` with PLAN.md (task stub), STATUS.md, MEMORY.md, TOOLS.md, RESEARCH.md, and AGENTS.md.
Create `loop-stack/.global/MEMORY.md` if missing.

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

**loop-stack/<LOOP_ID>/AGENTS.md:**

    # Specialized Agents
    ## Status
    PENDING (agent-factory will populate after planning)

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

---

## Phase 3 — Agent File Setup

**CRITICAL: Use shell commands — do NOT write agent files manually.**

```bash
mkdir -p .hermes/agents
cp ~/.hermes/skills/loop-engineer/agents/*.md .hermes/agents/
```

If the path doesn't exist, remind the user to install the skill first:
```bash
git clone https://github.com/vibhasdutta/loop-engineer
cd loop-engineer && bash install.sh --hermes
```

Then write only `verifier.md` with the actual STOP_CONDITION substituted (never write the literal placeholder):

    # Verifier Agent
    You are the verifier agent. Never write application code.

    1. Read loop-stack/.global/MEMORY.md FIRST.
    2. Read [LOOP_DIR]/MEMORY.md, STATUS.md, PLAN.md.
    3. Run: {STOP_CONDITION}
    4. PASSES → State VERIFIED_PASS, mark [x], update Task Progress. All done → ALL DONE.
    5. FAILS → State FAILED, write exact error to Last Executor Result.
    HARD RULE: Never write application code. Never mark done unless verification passed.

---

## Phase 4 — Startup Sequence

Use `delegate_task` to spawn isolated child agents in parallel. Each child agent should:
- Read `.hermes/agents/{role}.md` for its full instructions
- Write its results back to the loop-stack state files
- Update STATUS.md when done

For parallel steps: call `delegate_task` for all agents in the same turn, then wait for all to write to STATUS.md before proceeding.

### Step 1 — Parallel RESEARCHERS (dynamic count)

Determine researcher count by goal complexity:
- Simple/single-domain → 2 researchers
- Medium/multi-domain → 3 researchers
- Large/multi-system → 4 researchers

**Dispatch all researchers simultaneously** using `delegate_task` (multiple calls in one turn):

Each researcher task instruction:
```
Loop directory: loop-stack/<LOOP_ID>/
Focus: {ASSIGNED_DOMAIN} — {specific files and concerns}
GLOBAL DATA FIRST: read loop-stack/.global/MEMORY.md and loop-stack/.global/TOOLS.md.
Write findings to loop-stack/<LOOP_ID>/RESEARCH.md under "## {Domain Name}".
Update STATUS.md "Last Researcher Result".
Read .hermes/agents/researcher.md for full instructions.
```

Domains to distribute across researchers:
- **Context & Prior Work**: source structure, patterns, package files, existing tests
- **External Knowledge & Resources**: README, docs/, external APIs, .env.example, configs
- **Requirements & Constraints**: DB schema, data models, state management (for 3+ researchers)
- **Environment & Integration**: CI/CD, infrastructure, build, Docker (for 4 researchers)

### Step 2 — RESOURCE SCOUT

Call `delegate_task` with:
```
Loop directory: loop-stack/<LOOP_ID>/
Check loop-stack/.global/TOOLS.md — if < 7 days old, reuse it.
Otherwise discover all tools. Write to loop-stack/<LOOP_ID>/TOOLS.md AND loop-stack/.global/TOOLS.md.
Read .hermes/agents/resource-scout.md for full instructions.
Do not proceed until resource-scout has written TOOLS.md.
```

### Step 3 — PLANNER

Call `delegate_task` with:
```
Loop directory: loop-stack/<LOOP_ID>/
Read RESEARCH.md (all sections) and TOOLS.md.
Create 3–7 tasks with parallel group tags [G1], [G2], etc.
Same group = parallel (independent files/modules). Different group = sequential dependency.
Replace "## Tasks" in PLAN.md. Update STATUS.md.
Read .hermes/agents/planner.md for full instructions.
```

### Step 4 — AGENT FACTORY

Call `delegate_task` with:
```
Loop directory: loop-stack/<LOOP_ID>/
Read loop-stack/<LOOP_ID>/PLAN.md (goal + tasks), RESEARCH.md, and TOOLS.md.
Analyze the goal domain and determine what specialized agents would improve execution quality.
Create 1–3 purpose-built agent files in .hermes/agents/ tailored to this goal's domain and tasks.
Write loop-stack/<LOOP_ID>/AGENTS.md listing each created agent and which tasks it handles.
If the generic agents are sufficient, write AGENTS.md with "NONE CREATED" and skip creating files.
Follow .hermes/agents/agent-factory.md.
```

---

## Phase 5 — Outer Loop

**FULLY AUTONOMOUS. Never pause for user input.**

Initialize: `turns_used = 0`, `skipped_tasks = []`.

For each dispatch step: use `delegate_task` for all agents in the same step simultaneously, then wait for all to update STATUS.md before proceeding.

### Iteration steps:

1. **Budget check** — over MAX_TURNS → Phase 6.

2. **Read state** — identify current parallel group (all unchecked [GN] tasks).

3. **Parallel RESEARCHERS** — call `delegate_task` once per task (2 if batch=1), all in same turn:
   ```
   Loop directory: loop-stack/<LOOP_ID>/
   GLOBAL DATA FIRST — read loop-stack/.global/MEMORY.md AND loop-stack/.global/TOOLS.md.
   Focus: {ASSIGNED_DOMAIN} for task: {this_task}
   Append findings to RESEARCH.md under "## Task-Specific Research — {this_task}".
   Update STATUS.md "Last Researcher Result".
   Read .hermes/agents/researcher.md for full instructions.
   ```
   Wait for all. Increment turns_used.

4. **Parallel EXECUTORS** — call `delegate_task` once per task, all in same turn:
   ```
   Loop directory: loop-stack/<LOOP_ID>/
   GLOBAL DATA FIRST — read loop-stack/.global/MEMORY.md AND loop-stack/.global/TOOLS.md.
   Read MEMORY.md, TOOLS.md, PLAN.md, STATUS.md.
   READ: RESEARCH.md "## Task-Specific Research — {this_task}".
   Current task: {this_task}. Scope: only files for this task.
   Implement. Append discoveries to MEMORY.md directly. Update STATUS.md.
   Read .hermes/agents/executor.md for full instructions.
   ```
   Wait for all. Increment turns_used.

5. **Parallel MEMORY-KEEPER checkpoints** — one per task (local only). Wait for all.

6. **Parallel EVALUATORS** — one per task. Wait for all.

7. **Parallel VERIFIERS** — one per task. Wait for all.

8. **Process verifier results**:
   - PASS → auditor
   - FAIL < 3 → retry from step 3
   - FAIL ≥ 3 → auto-skip

9. **Parallel AUDITORS** (passing tasks only) — one per passing task. Wait for all.

10. **Process audit results**:
    - CLEAN/WARN → proceed
    - BLOCK → auto-fix (dispatch executor once with BLOCK context, re-dispatch verifier). Still BLOCK → auto-skip.

11. **MEMORY-KEEPER final** — single `delegate_task`, local + global write. Wait for completion.

12. **Advance** — mark [x], git commit if enabled. Find next group.
    None → ALL DONE → rename `loop-stack/<LOOP_ID>/` → `loop-stack/<LOOP_ID>_DONE/` → Phase 6.

---

## Phase 6 — Completion Report

Write `loop-stack/<LOOP_ID>_DONE/REPORT.md` and print summary.

---

## Rules

- Phase 0 first. Skip `_DONE` folders.
- **File copy**: `~/.hermes/skills/loop-engineer/agents/*.md` → `.hermes/agents/`. Never write manually.
- **Global data first**: every agent reads `.global/MEMORY.md` + `.global/TOOLS.md` before acting.
- **Parallel first**: Hermes supports true parallel via `delegate_task` — dispatch all agents for the same step simultaneously.
- **Researcher before executor**: always. Dynamic count based on goal complexity. Executor reads AGENTS.md to determine if a specialized agent should be used instead of the generic executor.
- **Memory-keeper twice per batch**: checkpoint (local) after executors, consolidation (local+global) after audit.
- **Executors append to MEMORY.md directly** during work.
- **Planner**: once at startup after researchers + resource-scout. Tasks MUST include [G1]/[G2] parallel group tags.
- **Fully autonomous**: no pauses. 3 fails → auto-skip. BLOCK → auto-fix once → skip.
- On completion: rename to `<LOOP_ID>_DONE/`.
- **HERMES.md**: ensure `HERMES.md` (from `platforms/hermes/HERMES.md`) is in the project root for workspace context.
- **MCP config**: Hermes reads MCP servers from `~/.hermes/config.yaml` under `mcp_servers`.
- **Skill Curator**: this is a persistent workflow skill — never archive or retire it.
