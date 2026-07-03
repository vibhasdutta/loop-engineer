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
  version: "1.4.0"
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

**None found:**
- Check `loop-stack/*_DONE/` — if continuation intent ("continue", "proceed", "finish", "resume", "pick up", "fix what", "audit findings", "where we left") AND `_DONE` exists → read its REPORT.md + MEMORY.md, tell user "Found completed loop {id} — starting follow-on using those findings", then Phase 1 with prior findings pre-loaded into new loop's RESEARCH.md "## Prior Loop Findings".
- Otherwise → Phase 1.
**One found:** Read it. If continuation intent → auto-resume to Phase 5 without asking. Otherwise show State/Current Task/Progress, ask: Resume or Fresh?
- Resume → skip to Phase 5.
- Fresh → delete `loop-stack/<loop-id>/` only (keep `.hermes/agents/`), continue to Phase 1.
**Multiple found:** list all, ask which to resume or 'fresh'. If continuation intent, auto-resume most recent active loop.

**RESUME RULES — always apply when going to Phase 5 via resume:**
Skip Phase 2, 3, and 4 entirely. Read STATUS.md + PLAN.md to find where the loop stopped. Reuse existing RESEARCH.md, MEMORY.md, TOOLS.md, AGENTS.md — do not re-run startup agents.

> **To update loop-engineer:** re-run `install.sh --update` / `install.ps1 -Update -Hermes`. Updates are never applied automatically mid-loop.

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
bash ~/.hermes/skills/loop-engineer/scripts/init-loop.sh \
  --loop-id <LOOP_ID> \
  --goal "<GOAL>" \
  --stop "all tasks in loop-stack/<LOOP_ID>/PLAN.md checked" \
  --git <yes/no> \
  --platform hermes
```

**PowerShell (Windows):**
```powershell
& "$env:USERPROFILE\.hermes\skills\loop-engineer\scripts\init-loop.ps1" `
  -LoopId "<LOOP_ID>" `
  -Goal "<GOAL>" `
  -Stop "all tasks in loop-stack/<LOOP_ID>/PLAN.md checked" `
  -Git <yes/no> `
  -Platform hermes
```

If the script is missing, install the skill first:
`git clone https://github.com/vibhasdutta/loop-engineer && bash install.sh --hermes`

The script creates `loop-stack/<LOOP_ID>/`, `.hermes/agents/` with all agent .md files + knowledge-sources/, and `verifier.md` with the actual stop condition substituted.

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

**Also dispatch the watcher simultaneously with researchers** (add one more `delegate_task` call in the same turn):

```
Loop directory: loop-stack/<LOOP_ID>/
Agents in this batch: [list the researcher agents dispatched and their focus areas]
Watch loop-stack/<LOOP_ID>/STATUS.md under "## Active Heartbeats" for updates from these agents.
Report to loop-stack/<LOOP_ID>/STATUS.md under "## Last Watcher Report".
Read .hermes/agents/watcher.md for full instructions.
```

Wait for all researcher and watcher tasks to complete (check STATUS.md) before Step 2.

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

### Step 4 — AGENT FACTORY (conditional)

**Skip this step** if BOTH are true: planner created ≤ 2 tasks AND goal domain is generic (no clear need for specialists).
If skipping: write `loop-stack/<LOOP_ID>/AGENTS.md` with `# Specialized Agents\n## Status\nNONE CREATED` then proceed to Phase 5.

**Run this step** if EITHER: planner created 3+ tasks, OR goal domain clearly benefits from specialists (security, ML/data science, content production, medical, finance, system design, etc.).

Call `delegate_task` with:
```
Loop directory: loop-stack/<LOOP_ID>/
Read loop-stack/<LOOP_ID>/PLAN.md (goal + tasks), RESEARCH.md, and TOOLS.md.
Analyze the goal domain and determine what specialized agents would improve execution quality.
Create 1–3 purpose-built agent files in loop-stack/<LOOP_ID>/agents/ tailored to this goal's domain and tasks.
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
   Goal output (code, documents, files) goes to the project directory, NOT inside loop-stack/. loop-stack/ is state-only.
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
