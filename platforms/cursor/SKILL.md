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

**None found:**
- Check `loop-stack/*_DONE/` — if continuation intent ("continue", "proceed", "finish", "resume", "pick up", "fix what", "audit findings", "where we left") AND `_DONE` exists → read its REPORT.md + MEMORY.md, tell user "Found completed loop {id} — starting follow-on using those findings", then Phase 1 with prior findings pre-loaded into new loop's RESEARCH.md "## Prior Loop Findings".
- Otherwise → Phase 1.
**One found:** Read it. If continuation intent → auto-resume to Phase 5 without asking. Otherwise show State/Current Task/Progress, ask: Resume or Fresh?
- Resume → skip to Phase 5 using existing files.
- Fresh → delete `loop-stack/<loop-id>/` only (keep `.cursor/agents/`), continue to Phase 1.
**Multiple found:** list all, ask which to resume or 'fresh'. If continuation intent, auto-resume most recent active loop.

**RESUME RULES — always apply when going to Phase 5 via resume:**
Skip Phase 2, 3, and 4 entirely. Read STATUS.md + PLAN.md to find where the loop stopped. Reuse existing RESEARCH.md, MEMORY.md, TOOLS.md, AGENTS.md — do not re-run startup agents.

> **To update loop-engineer:** re-run `install.sh --update` / `install.ps1 -Update -Cursor` (manual install). Updates are never applied automatically mid-loop.

---

## Phase 1 — Core Wizard

**Q1:** "What do you want the loop to accomplish? (1-2 sentences)"

Generate LOOP_ID: lowercase slug, first 4 meaningful words, max 24 chars.
Auto-set: `STOP_CONDITION` = "all tasks in loop-stack/<LOOP_ID>/PLAN.md checked", `MAX_TURNS` = 20.

**Q2:** "Should the loop auto-commit after each verified task? (yes / no)"

---

## Phase 2+3 — Initialize Loop

Run the init script — creates all state files, copies agent files, and writes verifier in one command:

**Bash (macOS/Linux):**
```bash
bash ~/.cursor/skills/loop-engineer/scripts/init-loop.sh \
  --loop-id <LOOP_ID> \
  --goal "<GOAL>" \
  --stop "all tasks in loop-stack/<LOOP_ID>/PLAN.md checked" \
  --git <yes/no> \
  --platform cursor
```

**PowerShell (Windows):**
```powershell
& "$env:USERPROFILE\.cursor\skills\loop-engineer\scripts\init-loop.ps1" `
  -LoopId "<LOOP_ID>" `
  -Goal "<GOAL>" `
  -Stop "all tasks in loop-stack/<LOOP_ID>/PLAN.md checked" `
  -Git <yes/no> `
  -Platform cursor
```

If the script is missing, install the skill first:
`git clone https://github.com/vibhasdutta/loop-engineer && bash install.sh --cursor`

The script creates `loop-stack/<LOOP_ID>/`, `.cursor/agents/` with all agent .md files + knowledge-sources/, and `verifier.md` with the actual stop condition substituted.

---

## Phase 4 — Startup Sequence

**FULLY AUTONOMOUS from this point. Never pause or ask the user anything.**

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

**Also spawn the watcher simultaneously with researchers** (add one more Agent call in the same response):

```
Loop directory: loop-stack/<LOOP_ID>/
Agents in this batch: [list the researcher agents you just spawned and their focus areas]
Watch loop-stack/<LOOP_ID>/STATUS.md under "## Active Heartbeats" for updates from these agents.
Report to loop-stack/<LOOP_ID>/STATUS.md under "## Last Watcher Report".
Follow .cursor/agents/watcher.md.
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

### Step 4 — AGENT FACTORY (conditional)

**Skip this step** if BOTH are true: planner created ≤ 2 tasks AND goal domain is generic (no clear need for specialists — e.g. simple script, config edit, single-file change).
If skipping: write `loop-stack/<LOOP_ID>/AGENTS.md` with `# Specialized Agents\n## Status\nNONE CREATED` then go directly to Phase 5.

**Run this step** if EITHER: planner created 3+ tasks, OR goal domain clearly benefits from specialists (security, ML/data science, content production, medical, finance, system design, etc.).

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
