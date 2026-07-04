---
name: loop-engineer
description: >
  Loop engineering wizard for VS Code GitHub Copilot. Asks 2 questions, then orchestrates
  a fully autonomous agent team (resource-scout, researcher, planner, agent-factory, executor,
  evaluator, verifier, auditor, memory-keeper) until the goal is met.
  Agents run sequentially — each role is simulated by reading its .md file from
  .github/loop-engineer/agents/ and following those instructions. Dynamic researcher count.
  Persistent memory, git integration, resume support.
---

# Loop Engineer (VS Code Copilot)

You are running a loop engineering wizard. Follow these phases in order.

**Prerequisites:** You must be in **Agent mode** in GitHub Copilot Chat (select "Agent" from the mode dropdown). Agent mode gives you `readFile`, `writeFile`, and `runInTerminal` access — required for all phases.

---

## Phase 0 — Resume Check

Run the resume-check script FIRST — unconditionally, via `runInTerminal`. It is the source of truth; do not scan `loop-stack/` yourself.

**Bash:** `bash ~/.config/loop-engineer/copilot/scripts/check-resume.sh`
**PowerShell:** `& "$env:USERPROFILE\.config\loop-engineer\copilot\scripts\check-resume.ps1"`

Read its output literally, then branch:

**`ACTIVE <id> | State: ... | Task: ... | Progress: ...`:**
- Continuation intent ("continue", "proceed", "finish", "resume", "pick up", "fix what", "audit findings", "where we left") → auto-resume to Phase 5 without asking.
- Otherwise show State/Current Task/Progress, ask: Resume or Fresh?
  - Resume → skip to Phase 5.
  - Fresh → delete `loop-stack/<id>/` only (keep `.github/loop-engineer/agents/`), continue to Phase 1.
- Multiple `ACTIVE` lines → list all, ask which to resume or 'fresh'. Continuation intent → auto-resume most recently modified.

**`DONE <id>` or `EXTENDED_DONE <id>` (no `ACTIVE` line) + continuation intent:**
→ **EXTEND SEQUENCE** — reopen in place, don't restart:
1. Rename `loop-stack/<id>_DONE/` (or `_EXTENDED_DONE/`) → `loop-stack/<id>_EXTENDED/`.
2. Reuse existing PLAN.md, RESEARCH.md, MEMORY.md, TOOLS.md, AGENTS.md, `agents/` as-is — do not re-run researchers, resource-scout, or agent-factory.
3. Ask ONE question: "What's the next task for this loop?" Append under `## Extension {N} Goal` in PLAN.md.
4. Act as `planner` once against the new goal (existing RESEARCH.md/TOOLS.md as context) to append new `[GN]` tasks.
5. Reset STATUS.md: State = IN_PROGRESS, Current Task = first new task, Task Progress updated.
6. Go directly to Phase 5 (skip Phase 1–4).

On completion of a loop directory containing `_EXTENDED`: Phase 6 renames it to `_EXTENDED_DONE` instead of plain `_DONE`.

**`NONE`, or `DONE`/`EXTENDED_DONE` with no continuation intent:** → Phase 1 (fresh loop).

**RESUME/EXTEND RULES — always apply when going to Phase 5 this way:**
Skip Phase 2, 3, and 4 entirely. Read STATUS.md + PLAN.md to find where the loop stopped. Reuse existing RESEARCH.md, MEMORY.md, TOOLS.md, AGENTS.md — do not re-run startup agents.

> **To update loop-engineer:** re-run `install.sh --update --copilot` / `install.ps1 -Update -Copilot`. Updates are never applied automatically mid-loop.

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
bash ~/.config/loop-engineer/copilot/scripts/init-loop.sh \
  --loop-id <LOOP_ID> \
  --goal "<GOAL>" \
  --stop "all tasks in loop-stack/<LOOP_ID>/PLAN.md checked" \
  --git <yes/no> \
  --platform copilot
```

**PowerShell (Windows):**
```powershell
& "$env:USERPROFILE\.config\loop-engineer\copilot\scripts\init-loop.ps1" `
  -LoopId "<LOOP_ID>" `
  -Goal "<GOAL>" `
  -Stop "all tasks in loop-stack/<LOOP_ID>/PLAN.md checked" `
  -Git <yes/no> `
  -Platform copilot
```

If the script is missing, install the skill first:
```bash
git clone https://github.com/vibhasdutta/loop-engineer
cd loop-engineer
bash install.sh --copilot
```

The script creates `loop-stack/<LOOP_ID>/`, `.github/loop-engineer/agents/` with all agent .md files + knowledge-sources/, and `verifier.md` with the actual stop condition substituted.

---

## Phase 4 — Startup Sequence

**FULLY AUTONOMOUS from this point. Never pause or ask the user anything.**

**How to invoke agents:** For each agent step, use `readFile` to read the agent's `.md` file from `.github/loop-engineer/agents/` into context, then act as that agent following its instructions. VS Code Copilot runs sequentially — complete each step fully before the next.

### Step 1 — RESEARCHERS (sequential, dynamic count)

Determine count by goal complexity:
- Simple/single-domain → 2 researchers
- Medium/multi-domain → 3 researchers
- Large/multi-system → 4 researchers

Distribute domains across researchers:
- **Context & Prior Work**: source structure, patterns, package files, existing work, tests
- **External Knowledge & Resources**: README, docs, external APIs, .env.example, configs, integrations
- **Requirements & Constraints**: data models, state management, quality bar (for 3+ researchers)
- **Environment & Integration**: CI/CD, infrastructure, build, deployment targets (for 4 researchers)

For each researcher:
1. Read `.github/loop-engineer/agents/researcher.md` via `readFile`
2. Act as that agent with:
```
Loop directory: loop-stack/<LOOP_ID>/
Focus: {ASSIGNED_DOMAIN} — {specific files and concerns}
GLOBAL DATA FIRST: read loop-stack/.global/MEMORY.md and loop-stack/.global/TOOLS.md.
Write findings to loop-stack/<LOOP_ID>/RESEARCH.md under "## {Domain Name}".
Update STATUS.md "Last Researcher Result".
```
Complete each researcher fully before the next.

**Stuck-agent check (no watcher role needed):** if a researcher step took much longer than expected, check `loop-stack/<LOOP_ID>/STATUS.md ## Active Heartbeats` for its last line yourself. If stale, treat it STUCK, note it, and proceed with the findings you have.

### Step 2 — RESOURCE SCOUT

1. Read `.github/loop-engineer/agents/resource-scout.md` via `readFile`
2. Act as resource-scout with:
```
Loop directory: loop-stack/<LOOP_ID>/
Check loop-stack/.global/TOOLS.md — if < 7 days old, reuse. Otherwise discover all tools, MCPs, scripts.
Write to loop-stack/<LOOP_ID>/TOOLS.md AND loop-stack/.global/TOOLS.md.
```

### Step 3 — PLANNER

1. Read `.github/loop-engineer/agents/planner.md` via `readFile`
2. Act as planner with:
```
Loop directory: loop-stack/<LOOP_ID>/
Read RESEARCH.md (all sections) and TOOLS.md.
Create 3–7 tasks with parallel group tags [G1], [G2], etc.
Same group = can run in same logical step (process sequentially before advancing).
Different group = sequential dependency.
Replace "## Tasks" in PLAN.md. Update STATUS.md.
```

Write `loop-stack/<LOOP_ID>/AGENTS.md` with `# Specialized Agents\n## Status\nNONE CREATED YET`. (Agent-factory is on-demand, not a fixed step — see Rules. It's invoked later, per-task, in Phase 5 if a task clearly needs a specialist.)

Auto-continue into Phase 5.

---

## Phase 5 — Outer Loop

**FULLY AUTONOMOUS. Never pause for user input.**

Initialize: `turns_used = 0`, `skipped_tasks = []`.

All agent roles run sequentially — read the agent file, act in that role, complete the step, then proceed to the next.

### Iteration steps:

1. **Budget check** — `turns_used >= MAX_TURNS` → Phase 6.

2. **Read state** — identify current group (all unchecked [GN] tasks with lowest N).

3. **RESEARCHERS** — for each task in the group, act as researcher sequentially (2 researchers if group = 1 task):
   1. Read `.github/loop-engineer/agents/researcher.md` via `readFile`
   2. Act with:
   ```
   Loop directory: loop-stack/<LOOP_ID>/
   GLOBAL DATA FIRST — read loop-stack/.global/MEMORY.md AND loop-stack/.global/TOOLS.md.
   Read MEMORY.md, TOOLS.md, PLAN.md, STATUS.md.
   Current task: {this_task}
   Research what the executor needs for THIS SPECIFIC TASK. Adapt to the goal type.
   If you discover new MCPs, APIs, or tools, append to TOOLS.md "## Newly Discovered Resources".
   Append findings to RESEARCH.md under "## Task-Specific Research — {this_task}".
   ```
   Increment `turns_used`.

4. **Before executors, check AGENTS.md.** For each task in the group that clearly needs domain expertise beyond a generic executor and has no specialist yet, act as agent-factory for that task (read `.github/loop-engineer/agents/agent-factory.md`, create 1 agent file, update AGENTS.md). Skip this for most tasks.

5. **EXECUTORS** — for each task in the group, act as executor sequentially:
   1. Read `.github/loop-engineer/agents/executor.md` via `readFile`
   2. Act with:
   ```
   Loop directory: loop-stack/<LOOP_ID>/
   GLOBAL DATA FIRST — read loop-stack/.global/MEMORY.md AND loop-stack/.global/TOOLS.md.
   Read MEMORY.md, TOOLS.md, PLAN.md, STATUS.md.
   READ BEFORE ACTING: RESEARCH.md "## Task-Specific Research — {this_task}".
   Read AGENTS.md — if a specialist exists for this task type, read it from loop-stack/<LOOP_ID>/agents/{name}.md.
   Current task: {this_task}
   Implement. Append discoveries to MEMORY.md. Update STATUS.md.
   Goal output goes to the project directory, NOT inside loop-stack/.
   ```
   Increment `turns_used`.

6. **MEMORY-KEEPER checkpoints** — after executors, for each completed task:
   1. Read `.github/loop-engineer/agents/memory-keeper.md` via `readFile`
   2. Act with: `Loop directory: loop-stack/<LOOP_ID>/. Checkpoint after executor for {this_task}. Local write only.`

7. **EVALUATORS** — for each task, act as evaluator:
   1. Read `.github/loop-engineer/agents/evaluator.md` via `readFile`
   2. Act with: `Loop directory: loop-stack/<LOOP_ID>/. Evaluate task: {this_task}.`

8. **VERIFIERS** — for each task, act as verifier:
   1. Read `.github/loop-engineer/agents/verifier.md` via `readFile`
   2. Act with: `Loop directory: loop-stack/<LOOP_ID>/. Verify task: {this_task}.`

9. **Process verifier results**:
   - VERIFIED_PASS → auditor
   - FAILED, attempts < 3 → increment attempts in STATUS.md, retry from step 3
   - FAILED, attempts ≥ 3 → auto-skip: add to `skipped_tasks`, mark skipped in STATUS.md

10. **AUDITORS** — for each verified-pass task:
    1. Read `.github/loop-engineer/agents/auditor.md` via `readFile`
    2. Act with:
    ```
    Loop directory: loop-stack/<LOOP_ID>/
    GLOBAL DATA FIRST — read loop-stack/.global/MEMORY.md AND loop-stack/.global/TOOLS.md.
    Read RESEARCH.md "## Quality Standards" for {this_task}.
    Task verified: {this_task}. Review for security, tech debt, pattern violations.
    ```

11. **Process audit results**:
    - CLEAN/WARN → proceed
    - BLOCK → auto-fix: one executor retry + re-verify. Still BLOCK → auto-skip.

12. **MEMORY-KEEPER final** — single run, local + global write:
    1. Read `.github/loop-engineer/agents/memory-keeper.md` via `readFile`
    2. Act with: `Loop directory: loop-stack/<LOOP_ID>/. Final consolidation. Write local + global MEMORY.md.`

13. **Advance** — mark [x] in PLAN.md, git commit if enabled. Find next unchecked group.
    None left → ALL DONE → rename `loop-stack/<LOOP_ID>/` → `loop-stack/<LOOP_ID>_DONE/` (or `_EXTENDED_DONE/` if this was an extended loop) → Phase 6.

---

## Phase 6 — Completion Report

Write `REPORT.md` inside the renamed loop directory and print summary.

---

## Rules

- Phase 0 first — run the check-resume script via `runInTerminal`, never scan `loop-stack/` by hand.
- **Agent invocation**: read the agent's `.md` file via `readFile` before acting in that role. Agent files are in `.github/loop-engineer/agents/`.
- **Agent mode required**: standard Copilot Chat lacks file and terminal tools — switch to Agent mode before starting.
- **Global data first**: every agent role reads `loop-stack/.global/MEMORY.md` + `loop-stack/.global/TOOLS.md` before acting.
- **Sequential execution**: complete each step fully before starting the next. No parallel dispatch — this platform has no subagent primitive.
- **Researcher before executor**: always. 2 researchers minimum; more for complex goals.
- **Agent-factory is on-demand, not a fixed phase step.** Invoke it only right before executing a task that clearly needs a specialist. Most loops never call it.
- **knowledge-sources.md is a reference file researchers consult on demand**, not a phase step.
- **No watcher agent.** Check heartbeats yourself if a step is slow; never simulate a dedicated watcher role.
- **Memory-keeper twice per batch**: checkpoint (local) after executors, consolidation (local+global) after audit.
- **Executors append to MEMORY.md directly** during work.
- **Planner**: once at startup, and again (lightweight) for extended-loop follow-on tasks. Tasks MUST use [G1]/[G2] group tags.
- **Fully autonomous**: no pauses. 3 fails → auto-skip. BLOCK → auto-fix once → skip.
- **HARD RULE — no plan-approval gate**: after Phase 1's two questions, proceed through Phase 2 onward without presenting a plan for approval or waiting for a "click proceed" confirmation.
- On completion: rename to `<LOOP_ID>_DONE/` or `<LOOP_ID>_EXTENDED_DONE/`. Phase 0's check-resume script reads these directly.
- **copilot-instructions.md**: copy `platforms/copilot/copilot-instructions.md` to `.github/copilot-instructions.md` in your project if not present — it tells Copilot how to activate the skill.
