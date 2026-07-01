---
name: loop-engineer
description: >
  Domain-agnostic autonomous loop for OpenAI Codex CLI. Asks 2 questions, scaffolds
  a parallel agent team as TOML files (resource-scout, researcher, planner, agent-factory,
  executor, evaluator, verifier, auditor, memory-keeper), generates loop-stack/<LOOP_ID>/
  state files, and outputs the exact `codex /goal` command for the fully autonomous loop.
---

# Loop Engineer (Codex)

You are running a loop engineering wizard for OpenAI Codex. Follow these phases in order.

---

## Phase 0 — Resume Check

Scan for `loop-stack/*/STATUS.md`. **Skip any directory ending with `_DONE`.**

**None found:** continue to Phase 1.
**One found:** show State/Current Task/Progress, ask: Resume or Fresh?
- Resume → skip to Phase 5, output `/goal` using existing files.
- Fresh → delete `loop-stack/<loop-id>/` only (keep `.codex/agents/`), continue to Phase 1.
**Multiple found:** list all, ask which to resume or type 'fresh'.

---

## Phase 1 — Core Wizard

**Q1:** "What do you want the loop to accomplish? (1-2 sentences)"

Generate LOOP_ID: lowercase slug, first 4 meaningful words, max 24 chars.
Auto-set: `STOP_CONDITION` = "all tasks in loop-stack/<LOOP_ID>/PLAN.md checked", `MAX_TURNS` = 20.

**Q2:** "Should the loop auto-commit after each verified task? (yes / no)"

Store: `GOAL`, `LOOP_ID`, `STOP_CONDITION`, `MAX_TURNS`, `USE_GIT`.

---

## Phase 2 — State File Creation

Create `loop-stack/<LOOP_ID>/` with:

**PLAN.md** (task stub — planner fills in during /goal execution):

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

**MEMORY.md:** `# Loop Memory\nUpdated continuously.\n## Learnings\n(none yet)`
**TOOLS.md:** `# Discovered Tools\n## Status\nPENDING`
**RESEARCH.md:** `# Research Log\n## Context & Prior Work\n(pending)\n## External Knowledge & Resources\n(pending)\n## Task-Specific Research\n(pending)`
**AGENTS.md:** `# Specialized Agents\n## Status\nPENDING (agent-factory will populate after planning)`

Create `loop-stack/<LOOP_ID>/agents/` directory (agent-factory will write specialist agents here).

Create `loop-stack/.global/MEMORY.md` if missing.

---

## Phase 3 — Agent File Setup

**CRITICAL: Use shell commands — do NOT write agent files manually.**

Create `.codex/agents/` then copy agent TOML files:

**PowerShell (Windows):**
```powershell
New-Item -ItemType Directory -Force .codex\agents | Out-Null
New-Item -ItemType Directory -Force ".codex\knowledge-sources" | Out-Null
Copy-Item "$env:USERPROFILE\.codex\skills\loop-engineer\agents\*.toml" ".codex\agents\"
Copy-Item "$env:USERPROFILE\.codex\skills\loop-engineer\knowledge-sources\*.md" ".codex\knowledge-sources\"
Copy-Item "$env:USERPROFILE\.codex\skills\loop-engineer\knowledge-sources.md" ".codex\knowledge-sources.md"
```

**Bash (macOS/Linux):**
```bash
mkdir -p .codex/agents
mkdir -p .codex/knowledge-sources
cp ~/.codex/skills/loop-engineer/agents/*.toml .codex/agents/
cp ~/.codex/skills/loop-engineer/knowledge-sources/*.md .codex/knowledge-sources/
cp ~/.codex/skills/loop-engineer/knowledge-sources.md .codex/knowledge-sources.md
```

Then write only `verifier.toml` with the actual STOP_CONDITION substituted:

    name = "verifier"
    description = "Runs the stop condition. Marks tasks done or failed. Never writes application code."
    model = "gpt-5.5"
    model_reasoning_effort = "high"
    developer_instructions = """
    Note: LOOP_DIR is provided in your spawning prompt.
    1. Read loop-stack/.global/MEMORY.md FIRST.
    2. Read [LOOP_DIR]/MEMORY.md, STATUS.md, PLAN.md.
    3. Run: {STOP_CONDITION}
    4. PASSES → set State VERIFIED_PASS, mark task [x] in PLAN.md, update Task Progress. All done → ALL DONE.
    5. FAILS → set State FAILED, write exact error to Last Executor Result.
    HARD RULE: Never write application code. Never mark done unless verification passed.
    Call report_agent_job_result when done.
    """

Confirm:
> "loop-stack/<LOOP_ID>/ created · .codex/agents/ ready · Generating /goal command..."

---

## Phase 4 — Generate /goal Command

Tell the user:

> **Start Codex in your project directory, then paste this `/goal` prompt:**

Print with real values substituted — never print literal placeholders:

```
/goal {GOAL}

Loop directory: loop-stack/<LOOP_ID>/
Agent definitions: .codex/agents/
Budget: 20 turns
FULLY AUTONOMOUS — never pause for user input.

═══ STARTUP SEQUENCE ═══

Step 1 — Determine researcher count based on goal complexity:
- Simple/single-domain goal → 2 researchers
- Medium/multi-domain goal → 3 researchers
- Large/multi-system goal (full-stack, migration, complex refactor) → 4 researchers

Spawn all researchers in parallel using spawn_agent (one call per researcher, all at once):
Divide these domains across however many researchers you spawn:
- Context & Prior Work: source structure, patterns, package files, existing tests
- External Knowledge & Resources: README, docs/, external APIs, .env.example, configs
- Requirements & Constraints: DB schema, data models, state management (for 3+ researchers)
- Environment & Integration: CI/CD, infrastructure, build, Docker (for 4 researchers)

Each researcher prompt:
  Loop directory: loop-stack/<LOOP_ID>/
  Focus: {ASSIGNED_DOMAIN}
  GLOBAL DATA FIRST: read loop-stack/.global/MEMORY.md AND loop-stack/.global/TOOLS.md.
  Write findings to loop-stack/<LOOP_ID>/RESEARCH.md under "## {Domain Name}".
  Update STATUS.md "Last Researcher Result".
  Read .codex/agents/researcher.toml for full instructions.
  Call report_agent_job_result when done.

Wait for ALL researchers to complete.

Step 2 — spawn_agent: resource-scout
  Loop directory: loop-stack/<LOOP_ID>/
  Check loop-stack/.global/TOOLS.md — if < 7 days old, reuse. Otherwise discover all tools.
  Write to loop-stack/<LOOP_ID>/TOOLS.md AND loop-stack/.global/TOOLS.md.
  Call report_agent_job_result when done.
Wait for resource-scout to complete.

Step 3 — spawn_agent: planner
  Loop directory: loop-stack/<LOOP_ID>/
  Read RESEARCH.md (all sections) and TOOLS.md.
  Create 3–7 tasks with parallel group tags [G1], [G2], etc.
  Same group = can run in parallel (independent files/modules).
  Different group = sequential dependency (later groups depend on earlier ones).
  Replace "## Tasks" in PLAN.md. Update STATUS.md: Current Task = first task, Task Progress = 0/N.
  Call report_agent_job_result when done.
Wait for planner to complete.

Step 4 — spawn_agent: agent-factory
  Loop directory: loop-stack/<LOOP_ID>/
  Read PLAN.md (goal + tasks), RESEARCH.md, and TOOLS.md.
  Analyze the goal domain. Determine what specialized agents would improve execution quality.
  Create 1–3 purpose-built agent TOML files in loop-stack/<LOOP_ID>/agents/ for this goal.
  Write loop-stack/<LOOP_ID>/AGENTS.md listing each created agent and which tasks it handles.
  If generic agents sufficient, write AGENTS.md with "NONE CREATED".
  Read .codex/agents/agent-factory.toml for full instructions.
  Call report_agent_job_result when done.
Wait for agent-factory to complete.

═══ OUTER LOOP ═══

Step 5 — Loop until all tasks in PLAN.md are checked or budget reached.
Track: turns_used = 0, skipped_tasks = []
Print per iteration: [Task X/N | Turn Y/20]

Each iteration:

a. Budget check: turns_used >= 20 → stop, go to Step 6.

b. Read PLAN.md + STATUS.md. Identify current parallel group: all unchecked tasks with same [GN] tag.

c. Spawn researchers in parallel (one per task in batch, 2 if batch=1):
   For each task: spawn_agent researcher with focus on that task's implementation needs.
   Wait for all. Increment turns_used.

d. Read AGENTS.md — if specialized agents were created for any tasks in this batch, use those agent TOML files instead of executor.toml for those tasks.

   Spawn executors in parallel (one per task in batch):
   For each task: spawn_agent executor (or specialized agent if AGENTS.md designates one) with:
     Loop directory: loop-stack/<LOOP_ID>/
     GLOBAL DATA FIRST: read loop-stack/.global/MEMORY.md AND loop-stack/.global/TOOLS.md.
     Read MEMORY.md, TOOLS.md, PLAN.md, STATUS.md.
     READ BEFORE CODING: RESEARCH.md section for "{this_task}".
     Current task: {this_task}. Scope: only files for this task.
     Implement. Append discoveries to MEMORY.md directly.
     Update STATUS.md. Call report_agent_job_result when done.
     Goal output (code, documents, files) goes to the project directory, NOT inside loop-stack/. loop-stack/ is state-only.
   Wait for all. Increment turns_used.

e. Spawn memory-keeper checkpoint for each task in parallel (local only):
   Wait for all.

f. Spawn evaluators in parallel (one per task):
   Wait for all.

g. Spawn verifiers in parallel (one per task):
   Wait for all.

h. Process verifier results per task:
   - VERIFIED_PASS → proceed to auditor
   - FAILED, attempts < 3 → increment attempts, retry from (c) with error context
   - FAILED, attempts >= 3 → AUTO-SKIP: add to skipped_tasks, skip this task

i. Spawn auditors in parallel (one per passing task):
   Wait for all.

j. Process audit results per task:
   - CLEAN/WARN → proceed
   - BLOCK → AUTO-FIX: spawn executor once with BLOCK context, re-verify.
     Still BLOCK → auto-skip.

k. spawn_agent: memory-keeper (single, final consolidation)
   Distill all batch learnings to loop-stack/<LOOP_ID>/MEMORY.md.
   Append most important per-task learning to loop-stack/.global/MEMORY.md.
   Call report_agent_job_result when done.
   Wait for completion.

l. Advance: mark [x] for passed tasks. If USE_GIT=yes: commit PLAN.md + STATUS.md.
   Find next unchecked group. If none → State = ALL DONE.
   Rename: loop-stack/<LOOP_ID>/ → loop-stack/<LOOP_ID>_DONE/
   Write loop-stack/<LOOP_ID>_DONE/REPORT.md with goal, outcome, tasks, skipped, learnings.
   Stop.

Step 6 — Budget reached:
   Update STATUS.md State to BUDGET_REACHED.
   Rename: loop-stack/<LOOP_ID>/ → loop-stack/<LOOP_ID>_DONE/
   Write REPORT.md. Stop.
```

> **Requirements:**
> - Codex CLI v0.128.0+ with `features.multi_agent = true`
> - `/goal` is a TUI slash command — run `codex` first, then paste the prompt
> - Edit `.codex/agents/*.toml` to change models

---

## Rules

- Phase 0 always first. Skip `_DONE` folders.
- **File copy**: shell commands only. Never write TOML agent files manually.
- **Global data first**: every agent reads `.global/MEMORY.md` and `.global/TOOLS.md` before acting.
- **Parallel first**: startup researchers parallel, per-task researchers parallel, executors parallel, evaluators parallel, verifiers parallel, auditors parallel.
- **Researcher before executor**: always. Dynamic count based on goal complexity.
- **Memory-keeper twice per batch**: checkpoint (local) after executors, consolidation (local+global) after audit.
- **Executors append to MEMORY.md directly** during work.
- **Planner**: once at startup, creates parallel-group-tagged task list.
- **Fully autonomous**: no user pauses. 3 fails → auto-skip. BLOCK → auto-fix once → skip.
- On completion: rename to `<LOOP_ID>_DONE/`.
