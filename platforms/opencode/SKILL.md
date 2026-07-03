---
name: loop-engineer
description: >
  Loop engineering wizard for OpenCode. Asks 2 questions, then orchestrates
  a fully autonomous agent team (resource-scout, researcher, planner, agent-factory, executor,
  evaluator, verifier, auditor, memory-keeper) until the goal is met.
  Agents run sequentially via the task tool. Dynamic researcher count.
  Persistent memory, git integration, resume support.
---

# Loop Engineer (OpenCode)

You are running a loop engineering wizard. Follow these phases in order.

---

## Phase 0 — Resume Check

Scan for `loop-stack/*/STATUS.md`. **Skip any directory ending with `_DONE`.**

**None found:**
- Check `loop-stack/*_DONE/` — if continuation intent ("continue", "proceed", "finish", "resume", "pick up", "fix what", "audit findings", "where we left") AND `_DONE` exists → read its REPORT.md + MEMORY.md, tell user "Found completed loop {id} — starting follow-on using those findings", then Phase 1 with prior findings pre-loaded into new loop's RESEARCH.md "## Prior Loop Findings".
- Otherwise → Phase 1.
**One found:** Read it. If continuation intent → auto-resume to Phase 5 without asking. Otherwise show State/Current Task/Progress, ask: Resume or Fresh?
- Resume → skip to Phase 5.
- Fresh → delete `loop-stack/<loop-id>/` only (keep `.opencode/agents/`), continue to Phase 1.
**Multiple found:** list all, ask which to resume or 'fresh'. If continuation intent, auto-resume most recent active loop.

**RESUME RULES — always apply when going to Phase 5 via resume:**
Skip Phase 2, 3, and 4 entirely. Read STATUS.md + PLAN.md to find where the loop stopped. Reuse existing RESEARCH.md, MEMORY.md, TOOLS.md, AGENTS.md — do not re-run startup agents.

> **To update loop-engineer:** re-run `install.sh --update` / `install.ps1 -Update -OpenCode`. Updates are never applied automatically mid-loop.

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
# try opencode path first, fall back to claude path
INIT="$HOME/.config/opencode/skills/loop-engineer/scripts/init-loop.sh"
[ ! -f "$INIT" ] && INIT="$HOME/.claude/skills/loop-engineer/scripts/init-loop.sh"
bash "$INIT" \
  --loop-id <LOOP_ID> \
  --goal "<GOAL>" \
  --stop "all tasks in loop-stack/<LOOP_ID>/PLAN.md checked" \
  --git <yes/no> \
  --platform opencode
```

**PowerShell (Windows):**
```powershell
$init = "$env:USERPROFILE\.config\opencode\skills\loop-engineer\scripts\init-loop.ps1"
if (-not (Test-Path $init)) { $init = "$env:USERPROFILE\.claude\skills\loop-engineer\scripts\init-loop.ps1" }
& $init -LoopId "<LOOP_ID>" -Goal "<GOAL>" `
  -Stop "all tasks in loop-stack/<LOOP_ID>/PLAN.md checked" `
  -Git <yes/no> -Platform opencode
```

If the script is missing, install the skill first:
`git clone https://github.com/vibhasdutta/loop-engineer && bash install.sh --opencode`

The script creates `loop-stack/<LOOP_ID>/`, `.opencode/agents/` with all agent .md files + knowledge-sources/, and `verifier.md` with the actual stop condition substituted.

---

## Phase 4 — Startup Sequence

Use the `task` tool to invoke each agent. Agents run sequentially — invoke each, wait for completion, then invoke the next.

### Step 1 — RESEARCHERS (dynamic count, sequential)

Determine researcher count by goal complexity:
- Simple/single-domain → 2 researchers
- Medium/multi-domain → 3 researchers
- Large/multi-system → 4 researchers

Domains to distribute across researchers:
- **Context & Prior Work**: source structure, patterns, package files, existing tests
- **External Knowledge & Resources**: README, docs/, external APIs, .env.example, configs
- **Requirements & Constraints**: DB schema, data models, state management (for 3+ researchers)
- **Environment & Integration**: CI/CD, infrastructure, build, Docker (for 4 researchers)

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

After all researchers complete, invoke the `watcher` agent using the `task` tool:
```
agent: watcher
prompt: |
  Loop directory: loop-stack/<LOOP_ID>/
  Agents watched: researchers (just completed)
  Check loop-stack/<LOOP_ID>/STATUS.md ## Active Heartbeats for signs of incomplete work.
  If any researcher shows incomplete heartbeat, report STUCK in ## Last Watcher Report.
```
Wait for watcher to complete.

### Step 2 — RESOURCE SCOUT

Invoke using the `task` tool:
```
agent: resource-scout
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

### Step 4 — AGENT FACTORY (conditional)

**Skip this step** if BOTH are true: planner created ≤ 2 tasks AND goal domain is generic (no clear need for specialists).
If skipping: write `loop-stack/<LOOP_ID>/AGENTS.md` with `# Specialized Agents\n## Status\nNONE CREATED` then auto-continue into outer loop.

**Run this step** if EITHER: planner created 3+ tasks, OR goal domain clearly benefits from specialists (security, ML/data science, content production, medical, finance, system design, etc.).

Invoke using the `task` tool:
```
agent: agent-factory
prompt: |
  Loop directory: loop-stack/<LOOP_ID>/
  Read loop-stack/<LOOP_ID>/PLAN.md (goal + tasks), RESEARCH.md, and TOOLS.md.
  Analyze the goal domain. Determine what specialized agents would improve execution quality.
  Create 1–3 purpose-built agent files in loop-stack/<LOOP_ID>/agents/ tailored to this goal's domain.
  Write loop-stack/<LOOP_ID>/AGENTS.md listing each created agent and which tasks it handles.
  If generic agents are sufficient, write AGENTS.md with "NONE CREATED".
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
     Research what the executor needs for THIS SPECIFIC TASK.
     Append findings to loop-stack/<LOOP_ID>/RESEARCH.md under "## Task-Specific Research — {this_task}".
   ```
   Increment turns_used.

4. **EXECUTORS** — invoke one per task sequentially:
   ```
   agent: executor
   prompt: |
     Loop directory: loop-stack/<LOOP_ID>/
     GLOBAL DATA FIRST — read loop-stack/.global/MEMORY.md AND loop-stack/.global/TOOLS.md.
     Read MEMORY.md, TOOLS.md, PLAN.md, STATUS.md.
     READ: RESEARCH.md "## Task-Specific Research — {this_task}".
     Current task: {this_task}. Scope: only files for this task.
     Implement. Append discoveries to MEMORY.md. Update STATUS.md.
     Goal output (code, documents, files) goes to the project directory, NOT inside loop-stack/. loop-stack/ is state-only.
   ```
   Increment turns_used.

5. **MEMORY-KEEPER checkpoints** — invoke one per task sequentially. Local only.

6. **EVALUATORS** — invoke one per task sequentially.

7. **VERIFIERS** — invoke one per task sequentially.

8. **Process verifier results**:
   - VERIFIED_PASS → auditor
   - FAILED, attempts < 3 → increment attempts in STATUS.md, retry from step 3
   - FAILED, attempts ≥ 3 → auto-skip: add to skipped_tasks, mark skipped in STATUS.md

9. **AUDITORS** — invoke one per passing task sequentially.

10. **Process audit results**:
    - CLEAN/WARN → proceed
    - BLOCK → auto-fix: invoke executor once more with BLOCK context + re-verify. Still BLOCK → auto-skip.

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
- **Researcher before executor**: always. Dynamic count based on goal complexity.
- **Memory-keeper twice per batch**: checkpoint (local) after executors, consolidation (local+global) after audit.
- **Executors append to MEMORY.md directly** during work.
- **Planner**: once at startup after researchers + resource-scout. Tasks MUST use [G1]/[G2] group tags.
- **Fully autonomous**: no pauses. 3 fails → auto-skip. BLOCK → auto-fix once → skip.
- **doom_loop**: if OpenCode triggers doom_loop detection (3 identical tool calls), the executor agent has `doom_loop: allow` — the loop continues.
- On completion: rename to `<LOOP_ID>_DONE/`.
- **AGENTS.md**: copy `platforms/opencode/AGENTS.md` to the project root if not present — it gives OpenCode context about the loop.
