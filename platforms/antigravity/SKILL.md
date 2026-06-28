---
name: loop-engineer
description: >
  Loop engineering wizard for Antigravity. Asks 2 questions, then orchestrates
  a fully autonomous parallel agent team (tool-scout, researcher, planner,
  developer, qa-tester, verifier, auditor, memory-keeper) until the goal is met.
  Multiple agents dispatched in parallel via prose-based dispatch. Dynamic researcher
  count, multiple developers on independent parts simultaneously. Persistent memory,
  git integration, resume support.
---

# Loop Engineer (Antigravity)

You are running a loop engineering wizard. Follow these phases in order.

---

## Phase 0 — Resume Check

Scan for `loop-stack/*/STATUS.md`. **Skip any directory ending with `_DONE`.**

**None found:** continue to Phase 1.
**One found:** show State/Current Task/Progress, ask: Resume or Fresh?
- Resume → skip to Phase 5.
- Fresh → delete `loop-stack/<loop-id>/` only (keep `.agents/`), continue to Phase 1.
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

---

## Phase 3 — Agent File Setup

**CRITICAL: Use shell commands — do NOT write agent files manually.**

```bash
mkdir -p .agents
cp ~/.gemini/skills/loop-engineer/agents/tool-scout.md .agents/
cp ~/.gemini/skills/loop-engineer/agents/researcher.md .agents/
cp ~/.gemini/skills/loop-engineer/agents/planner.md .agents/
cp ~/.gemini/skills/loop-engineer/agents/developer.md .agents/
cp ~/.gemini/skills/loop-engineer/agents/qa-tester.md .agents/
cp ~/.gemini/skills/loop-engineer/agents/auditor.md .agents/
cp ~/.gemini/skills/loop-engineer/agents/memory-keeper.md .agents/
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
    5. FAILS → State FAILED, write exact error to Last Developer Result.
    HARD RULE: Never write application code. Never mark done unless verification passed.

---

## Phase 4 — Startup Sequence

Dispatch template: "Dispatch a subagent with these instructions: [instructions]. The subagent should read `.agents/{role}.md`. Do not proceed until this subagent has updated STATUS.md."

For parallel steps: dispatch all subagents in the same turn, then wait for all to update STATUS.md before proceeding.

### Step 1 — Parallel RESEARCHERS (dynamic count)

Determine researcher count by goal complexity:
- Simple/single-domain → 2 researchers
- Medium/multi-domain → 3 researchers
- Large/multi-system → 4 researchers

**Dispatch all researchers simultaneously** in the same turn:

> "Dispatch {N} researcher subagents in parallel with these instructions. Each reads `.agents/researcher.md`. Do not proceed until all have updated STATUS.md."

Domains to distribute across researchers:
- **Architecture & Code**: source structure, patterns, package files, existing tests
- **Domain & APIs**: README, docs/, external APIs, .env.example, configs
- **Data & State**: DB schema, data models, state management (for 3+ researchers)
- **Deployment & Config**: CI/CD, infrastructure, build, Docker (for 4 researchers)

Each researcher instruction:
```
Loop directory: loop-stack/<LOOP_ID>/
Focus: {ASSIGNED_DOMAIN} — {specific files and concerns}
GLOBAL DATA FIRST: read loop-stack/.global/MEMORY.md and loop-stack/.global/TOOLS.md.
Write findings to loop-stack/<LOOP_ID>/RESEARCH.md under "## {Domain Name}".
Update STATUS.md "Last Researcher Result".
Read .agents/researcher.md for full instructions.
```

### Step 2 — TOOL SCOUT

> "Dispatch a tool-scout subagent. It reads `.agents/tool-scout.md`. Instructions: Loop directory: loop-stack/<LOOP_ID>/. Check loop-stack/.global/TOOLS.md — if < 7 days old, reuse. Otherwise discover all tools. Write to loop-stack/<LOOP_ID>/TOOLS.md AND loop-stack/.global/TOOLS.md. Do not proceed until tool-scout has written TOOLS.md."

### Step 3 — PLANNER

> "Dispatch a planner subagent. It reads `.agents/planner.md`. Instructions: Loop directory: loop-stack/<LOOP_ID>/. Read RESEARCH.md (all sections) and TOOLS.md. Create 3–7 tasks with parallel group tags [G1], [G2], etc. Same group = parallel (independent files/modules). Different group = sequential dependency. Replace '## Tasks' in PLAN.md. Update STATUS.md. Do not proceed until planner has written tasks to PLAN.md."

---

## Phase 5 — Outer Loop

**FULLY AUTONOMOUS. Never pause for user input.**

Initialize: `turns_used = 0`, `skipped_tasks = []`.

Dispatch template for all agents:
> "Dispatch a {role} subagent. It reads `.agents/{role}.md`. Instructions: [instructions below]. Do not proceed to the next step until this subagent has updated STATUS.md."

For parallel steps: dispatch ALL subagents for that step in the same turn, then wait for all.

### Iteration steps:

1. **Budget check** — over MAX_TURNS → Phase 6.

2. **Read state** — identify current parallel group (all unchecked [GN] tasks).

3. **Parallel RESEARCHERS** — dispatch one per task (2 if batch=1). All in same turn. Each appends to RESEARCH.md. Wait for all. Increment turns_used.

4. **Parallel DEVELOPERS** — dispatch one per task in same turn:
   ```
   Loop directory: loop-stack/<LOOP_ID>/
   GLOBAL DATA FIRST — read loop-stack/.global/MEMORY.md AND loop-stack/.global/TOOLS.md.
   Read MEMORY.md, TOOLS.md, PLAN.md, STATUS.md.
   READ: RESEARCH.md "## Task-Specific Research — {this_task}".
   Current task: {this_task}. Scope: only files for this task.
   Implement. Append discoveries to MEMORY.md directly. Update STATUS.md.
   Read .agents/developer.md for full instructions.
   ```
   Wait for all. Increment turns_used.

5. **Parallel MEMORY-KEEPER checkpoints** — dispatch one per task (local only). Wait for all.

6. **Parallel QA TESTERS** — dispatch one per task. Wait for all.

7. **Parallel VERIFIERS** — dispatch one per task. Wait for all.

8. **Process verifier results**:
   - PASS → auditor
   - FAIL < 3 → retry from step 3
   - FAIL ≥ 3 → auto-skip

9. **Parallel AUDITORS** (passing tasks only) — dispatch one per passing task. Wait for all.

10. **Process audit results**:
    - CLEAN/WARN → proceed
    - BLOCK → auto-fix (dispatch developer once with BLOCK context, re-dispatch verifier). Still BLOCK → auto-skip.

11. **MEMORY-KEEPER final** — dispatch single subagent, local + global write. Wait for completion.

12. **Advance** — mark [x], git commit if enabled. Find next group.
    None → ALL DONE → rename `loop-stack/<LOOP_ID>/` → `loop-stack/<LOOP_ID>_DONE/` → Phase 6.

---

## Phase 6 — Completion Report

Write `loop-stack/<LOOP_ID>_DONE/REPORT.md` and print summary.

---

## Rules

- Phase 0 first. Skip `_DONE` folders.
- **File copy**: `cp ~/.gemini/skills/loop-engineer/agents/*.md .agents/` — never manual.
- **Global data first**: every agent reads `.global/MEMORY.md` + `.global/TOOLS.md` before acting.
- **Parallel first**: dispatch all agents for the same step in the same turn. Wait for all before next step.
- **Researcher before developer**: always. Dynamic count based on goal complexity.
- **Memory-keeper twice per batch**: checkpoint (local) after devs, consolidation (local+global) after audit.
- **Developers append to MEMORY.md directly** during work.
- **Planner**: once at startup after researchers + tool-scout.
- **Fully autonomous**: no pauses. 3 fails → auto-skip. BLOCK → auto-fix once → skip.
- On completion: rename to `<LOOP_ID>_DONE/`.
