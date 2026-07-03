---
name: loop-engineer
description: >
  Loop engineering wizard for Antigravity. Asks 2 questions, then orchestrates
  a fully autonomous parallel agent team (resource-scout, researcher, planner,
  agent-factory, executor, evaluator, verifier, auditor, memory-keeper) until the goal is met.
  Uses invoke_subagent for true parallel dispatch. Researcher agents use the
  built-in research TypeName. Persistent memory, git integration, resume support.
---

# Loop Engineer (Antigravity)

You are running a loop engineering wizard. Follow these phases in order.

---

## Phase 0 — Resume Check

Scan for `loop-stack/*/STATUS.md`. **Skip any directory ending with `_DONE`.**

**None found:**
- Check `loop-stack/*_DONE/` — if continuation intent ("continue", "proceed", "finish", "resume", "pick up", "fix what", "audit findings", "where we left") AND `_DONE` exists → read its REPORT.md + MEMORY.md, tell user "Found completed loop {id} — starting follow-on using those findings", then Phase 1 with prior findings pre-loaded into new loop's RESEARCH.md "## Prior Loop Findings".
- Otherwise → Phase 1.
**One found:** Read it. If continuation intent → auto-resume to Phase 5 without asking. Otherwise show State/Current Task/Progress, ask: Resume or Fresh?
- Resume → skip to Phase 5.
- Fresh → delete `loop-stack/<loop-id>/` only (keep `.agents/`), continue to Phase 1.
**Multiple found:** list all, ask which to resume or 'fresh'. If continuation intent, auto-resume most recent active loop.

**RESUME RULES — always apply when going to Phase 5 via resume:**
Skip Phase 2, 3, and 4 entirely. Read STATUS.md + PLAN.md to find where the loop stopped. Reuse existing RESEARCH.md, MEMORY.md, TOOLS.md, AGENTS.md — do not re-run startup agents.

> **To update loop-engineer:** re-run `install.sh --update` / `install.ps1 -Update -Antigravity`. Updates are never applied automatically mid-loop.

---

## Phase 1 — Core Wizard

**Q1:** "What do you want the loop to accomplish? (1-2 sentences)"

Generate LOOP_ID: lowercase slug, first 4 meaningful words, max 24 chars.
Auto-set: `STOP_CONDITION` = "all tasks in loop-stack/<LOOP_ID>/PLAN.md checked", `MAX_TURNS` = 20.

**Q2:** "Should the loop auto-commit after each verified task? (yes / no)"

---

## Phase 2+3 — Initialize Loop

Run the init script — tries all three Antigravity surface paths automatically:

**Bash (macOS/Linux):**
```bash
INIT_SCRIPT="$(ls \
  "$HOME/.gemini/antigravity-cli/skills/loop-engineer/scripts/init-loop.sh" \
  "$HOME/.gemini/antigravity/skills/loop-engineer/scripts/init-loop.sh" \
  "$HOME/.gemini/config/skills/loop-engineer/scripts/init-loop.sh" 2>/dev/null | head -1)"
bash "$INIT_SCRIPT" \
  --loop-id <LOOP_ID> \
  --goal "<GOAL>" \
  --stop "all tasks in loop-stack/<LOOP_ID>/PLAN.md checked" \
  --git <yes/no> \
  --platform antigravity
```

**PowerShell (Windows):**
```powershell
$init = @(
  "$env:USERPROFILE\.gemini\antigravity-cli\skills\loop-engineer\scripts\init-loop.ps1",
  "$env:USERPROFILE\.gemini\antigravity\skills\loop-engineer\scripts\init-loop.ps1",
  "$env:USERPROFILE\.gemini\config\skills\loop-engineer\scripts\init-loop.ps1"
) | Where-Object { Test-Path $_ } | Select-Object -First 1
& $init -LoopId "<LOOP_ID>" -Goal "<GOAL>" `
  -Stop "all tasks in loop-stack/<LOOP_ID>/PLAN.md checked" `
  -Git <yes/no> -Platform antigravity
```

If the script is missing, install the skill first:
`git clone https://github.com/vibhasdutta/loop-engineer && bash install.sh --antigravity`

The script creates `loop-stack/<LOOP_ID>/`, `.agents/` with all agent .md files + knowledge-sources/, and `verifier.md` with the actual stop condition substituted.

---

## Phase 4 — Startup Sequence

Use `invoke_subagent` to spawn parallel agents. Pass multiple entries in the `Subagents` array to run them simultaneously. Wait for all subagents to send completion messages before proceeding to the next step.

**IMPORTANT:** Subagents start with a clean slate — no parent context. Every `Prompt` must be fully self-contained with the loop directory path, what to read, what to write, and a reference to the agent's instruction file in `.agents/`.

### Step 1 — Parallel RESEARCHERS (dynamic count)

Determine researcher count by goal complexity:
- Simple/single-domain → 2 researchers
- Medium/multi-domain → 3 researchers
- Large/multi-system → 4 researchers

Call `invoke_subagent` once with all researchers in the Subagents array (they run in parallel).
Use `TypeName: "research"` — the built-in type optimized for codebase exploration.

Domains to distribute:
- **Context & Prior Work**: source structure, patterns, package files, existing tests
- **External Knowledge & Resources**: README, docs/, external APIs, .env.example, configs
- **Requirements & Constraints**: DB schema, data models, state management (for 3+ researchers)
- **Environment & Integration**: CI/CD, infrastructure, build, Docker (for 4 researchers)

Each researcher Prompt:
```
Loop directory: loop-stack/<LOOP_ID>/
Focus: {ASSIGNED_DOMAIN} — {specific files and concerns}
GLOBAL DATA FIRST: read loop-stack/.global/MEMORY.md and loop-stack/.global/TOOLS.md.
Write findings to loop-stack/<LOOP_ID>/RESEARCH.md under "## {Domain Name}".
Update loop-stack/<LOOP_ID>/STATUS.md "Last Researcher Result".
Read .agents/researcher.md for full instructions.
```

**Also add the watcher as an additional Subagent in the same `invoke_subagent` call** (alongside the researchers):

```
Prompt:
Loop directory: loop-stack/<LOOP_ID>/
Agents in this batch: [list the researcher agents spawned and their focus areas]
Watch loop-stack/<LOOP_ID>/STATUS.md under "## Active Heartbeats" for updates from these agents.
Report to loop-stack/<LOOP_ID>/STATUS.md under "## Last Watcher Report".
Read .agents/watcher.md for full instructions.
TypeName: "self"
```

Wait for all subagents (researchers + watcher) to complete before Step 2.

### Step 2 — RESOURCE SCOUT

Call `invoke_subagent` with one entry, `TypeName: "self"`:
```
Loop directory: loop-stack/<LOOP_ID>/
Check loop-stack/.global/TOOLS.md — if < 7 days old, reuse it.
Otherwise discover all tools. Write to loop-stack/<LOOP_ID>/TOOLS.md AND loop-stack/.global/TOOLS.md.
Read .agents/resource-scout.md for full instructions.
```
Wait for resource-scout to send its completion message.

### Step 3 — PLANNER

Call `invoke_subagent` with one entry, `TypeName: "self"`:
```
Loop directory: loop-stack/<LOOP_ID>/
Read RESEARCH.md (all sections) and TOOLS.md.
Create 3–7 tasks with parallel group tags [G1], [G2], etc.
Same group = parallel (independent files/modules). Different group = sequential dependency.
Replace "## Tasks" in PLAN.md. Update STATUS.md.
Read .agents/planner.md for full instructions.
```
Wait for planner to send its completion message.

### Step 4 — AGENT FACTORY (conditional)

**Skip this step** if BOTH are true: planner created ≤ 2 tasks AND goal domain is generic (no clear need for specialists).
If skipping: write `loop-stack/<LOOP_ID>/AGENTS.md` with `# Specialized Agents\n## Status\nNONE CREATED` then proceed to Phase 5.

**Run this step** if EITHER: planner created 3+ tasks, OR goal domain clearly benefits from specialists (security, ML/data science, content production, medical, finance, system design, etc.).

Call `invoke_subagent` with one entry, `TypeName: "self"`:
```
Loop directory: loop-stack/<LOOP_ID>/
Read loop-stack/<LOOP_ID>/PLAN.md (goal + tasks), RESEARCH.md, and TOOLS.md.
Analyze the goal domain. Determine what specialized agents would improve execution quality.
Create 1–3 purpose-built agent files in loop-stack/<LOOP_ID>/agents/ tailored to this goal's domain and tasks.
Write loop-stack/<LOOP_ID>/AGENTS.md listing each created agent and which tasks it handles.
If generic agents are sufficient, write AGENTS.md with "NONE CREATED".
Read .agents/agent-factory.md for full instructions.
```
Wait for completion before proceeding to Phase 5.

---

## Phase 5 — Outer Loop

**FULLY AUTONOMOUS. Never pause for user input.**

Initialize: `turns_used = 0`, `skipped_tasks = []`.

For parallel steps: pass all agents as entries in one `invoke_subagent` call. Wait for all to send completion messages before proceeding.

### Iteration steps:

1. **Budget check** — over MAX_TURNS → Phase 6.

2. **Read state** — identify current parallel group (all unchecked [GN] tasks).

3. **Parallel RESEARCHERS** — one per task (2 if batch=1). Single `invoke_subagent` call, `TypeName: "research"`:
   ```
   Loop directory: loop-stack/<LOOP_ID>/
   GLOBAL DATA FIRST — read loop-stack/.global/MEMORY.md AND loop-stack/.global/TOOLS.md.
   Focus: {ASSIGNED_DOMAIN} for task: {this_task}
   Append findings to RESEARCH.md under "## Task-Specific Research — {this_task}".
   Update STATUS.md "Last Researcher Result".
   Read .agents/researcher.md for full instructions.
   ```
   Wait for all. Increment turns_used.

4. **Parallel EXECUTORS** — one per task. Single `invoke_subagent` call, `TypeName: "self"`:
   ```
   Loop directory: loop-stack/<LOOP_ID>/
   GLOBAL DATA FIRST — read loop-stack/.global/MEMORY.md AND loop-stack/.global/TOOLS.md.
   Read MEMORY.md, TOOLS.md, PLAN.md, STATUS.md.
   READ: RESEARCH.md "## Task-Specific Research — {this_task}".
   Current task: {this_task}. Scope: only files for this task.
   Implement. Append discoveries to MEMORY.md directly. Update STATUS.md.
   Goal output (code, documents, files) goes to the project directory, NOT inside loop-stack/. loop-stack/ is state-only.
   Read .agents/executor.md for full instructions.
   ```
   Wait for all. Increment turns_used.

5. **Parallel MEMORY-KEEPER checkpoints** — one per task (local only). `TypeName: "self"`. Wait for all.

6. **Parallel EVALUATORS** — one per task. `TypeName: "self"`. Wait for all.

7. **Parallel VERIFIERS** — one per task. `TypeName: "self"`. Wait for all.

8. **Process verifier results**:
   - PASS → auditor
   - FAIL < 3 → retry from step 3
   - FAIL ≥ 3 → auto-skip

9. **Parallel AUDITORS** (passing tasks only) — one per task. `TypeName: "self"`. Wait for all.

10. **Process audit results**:
    - CLEAN/WARN → proceed
    - BLOCK → auto-fix (one executor with BLOCK context, `TypeName: "self"`, re-run verifier). Still BLOCK → auto-skip.

11. **MEMORY-KEEPER final** — single `invoke_subagent`, `TypeName: "self"`, local + global write. Wait.

12. **Advance** — mark [x], git commit if enabled. Find next group.
    None → ALL DONE → rename `loop-stack/<LOOP_ID>/` → `loop-stack/<LOOP_ID>_DONE/` → Phase 6.

---

## Phase 6 — Completion Report

Write `loop-stack/<LOOP_ID>_DONE/REPORT.md` and print summary.

---

## Rules

- Phase 0 first. Skip `_DONE` folders.
- **File copy**: try CLI path (`~/.gemini/antigravity-cli/skills/`), then IDE path (`~/.gemini/antigravity/skills/`), then 2.0 path (`~/.gemini/config/skills/`). Never write manually.
- **Global data first**: every agent reads `.global/MEMORY.md` + `.global/TOOLS.md` before acting.
- **invoke_subagent**: parallel = multiple Subagents entries in one call. Sequential = separate calls. Wait for completion messages between steps.
- **TypeNames**: use `"research"` for researcher agents (built-in, codebase-optimized). Use `"self"` for all others.
- **Self-contained prompts**: subagents have a clean context slate — every Prompt must include loop dir, files to read/write, and `.agents/{role}.md` reference.
- **Researcher before executor**: always. Dynamic count based on goal complexity.
- **Memory-keeper twice per batch**: checkpoint (local) after executors, consolidation (local+global) after audit.
- **Executors append to MEMORY.md directly** during work.
- **Planner**: once at startup. Tasks MUST include [G1]/[G2] parallel group tags.
- **Fully autonomous**: no pauses. 3 fails → auto-skip. BLOCK → auto-fix once → skip.
- On completion: rename to `<LOOP_ID>_DONE/`.
- **Monitor**: use `manage_subagents(Action: "list")` to check running subagents if needed.
- **AGENTS.md**: ensure `AGENTS.md` is in the project root for workspace context.
- **MCP config**: remote servers require `serverUrl` field (not `url` or `httpUrl`).
