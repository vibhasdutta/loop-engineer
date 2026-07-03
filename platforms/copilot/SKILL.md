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

Scan for `loop-stack/*/STATUS.md`. **Skip any directory ending with `_DONE`.**

**None found:**
- Check `loop-stack/*_DONE/` — if continuation intent ("continue", "proceed", "finish", "resume", "pick up", "fix what", "audit findings", "where we left") AND `_DONE` exists → read its REPORT.md + MEMORY.md, tell user "Found completed loop {id} — starting follow-on using those findings", then Phase 1 with prior findings pre-loaded into new loop's RESEARCH.md "## Prior Loop Findings".
- Otherwise → Phase 1.
**One found:** Read it. If continuation intent → auto-resume to Phase 5 without asking. Otherwise show State/Current Task/Progress, ask: Resume or Fresh?
- Resume → skip to Phase 5.
- Fresh → delete `loop-stack/<loop-id>/` only (keep `.github/loop-engineer/agents/`), continue to Phase 1.
**Multiple found:** list all, ask which to resume or 'fresh'. If continuation intent, auto-resume most recent active loop.

**RESUME RULES — always apply when going to Phase 5 via resume:**
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

After researchers complete, act as the watcher:
1. Read `.github/loop-engineer/agents/watcher.md` via `readFile`
2. Check `loop-stack/<LOOP_ID>/STATUS.md ## Active Heartbeats` for researcher completions.

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

### Step 4 — AGENT FACTORY (conditional)

**Skip if** BOTH: planner created ≤ 2 tasks AND goal domain is generic.
If skipping: write `loop-stack/<LOOP_ID>/AGENTS.md` with `# Specialized Agents\n## Status\nNONE CREATED` then auto-continue into Phase 5.

**Run if** EITHER: planner created 3+ tasks OR goal clearly benefits from specialists.

1. Read `.github/loop-engineer/agents/agent-factory.md` via `readFile`
2. Act as agent-factory with:
```
Loop directory: loop-stack/<LOOP_ID>/
Read PLAN.md (goal + tasks), RESEARCH.md, and TOOLS.md.
Create 1–3 specialist agent files in loop-stack/<LOOP_ID>/agents/ if beneficial.
Write AGENTS.md manifest.
```

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

4. **EXECUTORS** — for each task in the group, act as executor sequentially:
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

5. **MEMORY-KEEPER checkpoints** — after executors, for each completed task:
   1. Read `.github/loop-engineer/agents/memory-keeper.md` via `readFile`
   2. Act with: `Loop directory: loop-stack/<LOOP_ID>/. Checkpoint after executor for {this_task}. Local write only.`

6. **EVALUATORS** — for each task, act as evaluator:
   1. Read `.github/loop-engineer/agents/evaluator.md` via `readFile`
   2. Act with: `Loop directory: loop-stack/<LOOP_ID>/. Evaluate task: {this_task}.`

7. **VERIFIERS** — for each task, act as verifier:
   1. Read `.github/loop-engineer/agents/verifier.md` via `readFile`
   2. Act with: `Loop directory: loop-stack/<LOOP_ID>/. Verify task: {this_task}.`

8. **Process verifier results**:
   - VERIFIED_PASS → auditor
   - FAILED, attempts < 3 → increment attempts in STATUS.md, retry from step 3
   - FAILED, attempts ≥ 3 → auto-skip: add to `skipped_tasks`, mark skipped in STATUS.md

9. **AUDITORS** — for each verified-pass task:
   1. Read `.github/loop-engineer/agents/auditor.md` via `readFile`
   2. Act with:
   ```
   Loop directory: loop-stack/<LOOP_ID>/
   GLOBAL DATA FIRST — read loop-stack/.global/MEMORY.md AND loop-stack/.global/TOOLS.md.
   Read RESEARCH.md "## Quality Standards" for {this_task}.
   Task verified: {this_task}. Review for security, tech debt, pattern violations.
   ```

10. **Process audit results**:
    - CLEAN/WARN → proceed
    - BLOCK → auto-fix: one executor retry + re-verify. Still BLOCK → auto-skip.

11. **MEMORY-KEEPER final** — single run, local + global write:
    1. Read `.github/loop-engineer/agents/memory-keeper.md` via `readFile`
    2. Act with: `Loop directory: loop-stack/<LOOP_ID>/. Final consolidation. Write local + global MEMORY.md.`

12. **Advance** — mark [x] in PLAN.md, git commit if enabled. Find next unchecked group.
    None left → ALL DONE → rename `loop-stack/<LOOP_ID>/` → `loop-stack/<LOOP_ID>_DONE/` → Phase 6.

---

## Phase 6 — Completion Report

Write `loop-stack/<LOOP_ID>_DONE/REPORT.md` and print summary.

---

## Rules

- Phase 0 first. Skip `_DONE` folders (but check them for follow-on context when continuation intent detected).
- **Agent invocation**: read the agent's `.md` file via `readFile` before acting in that role. Agent files are in `.github/loop-engineer/agents/`.
- **Agent mode required**: standard Copilot Chat lacks file and terminal tools — switch to Agent mode before starting.
- **Global data first**: every agent role reads `loop-stack/.global/MEMORY.md` + `loop-stack/.global/TOOLS.md` before acting.
- **Sequential execution**: complete each step fully before starting the next. No parallel dispatch.
- **Researcher before executor**: always. 2 researchers minimum; more for complex goals.
- **Memory-keeper twice per batch**: checkpoint (local) after executors, consolidation (local+global) after audit.
- **Executors append to MEMORY.md directly** during work.
- **Planner**: once at startup. Tasks MUST use [G1]/[G2] group tags.
- **Fully autonomous**: no pauses. 3 fails → auto-skip. BLOCK → auto-fix once → skip.
- On completion: rename to `<LOOP_ID>_DONE/`. Phase 0 skips these.
- **copilot-instructions.md**: copy `platforms/copilot/copilot-instructions.md` to `.github/copilot-instructions.md` in your project if not present — it tells Copilot how to activate the skill.
