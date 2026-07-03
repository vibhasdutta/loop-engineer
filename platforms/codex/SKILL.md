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

**None found:**
- Check `loop-stack/*_DONE/` — if continuation intent ("continue", "proceed", "finish", "resume", "pick up", "fix what", "audit findings", "where we left") AND `_DONE` exists → read its REPORT.md + MEMORY.md, tell user "Found completed loop {id} — starting follow-on using those findings", then Phase 1 with prior findings pre-loaded into new loop's RESEARCH.md "## Prior Loop Findings".
- Otherwise → Phase 1.
**One found:** Read it. If continuation intent → auto-resume to Phase 5 without asking, output `/goal` using existing files. Otherwise show State/Current Task/Progress, ask: Resume or Fresh?
- Resume → skip to Phase 5, output `/goal` using existing files.
- Fresh → delete `loop-stack/<loop-id>/` only (keep `.codex/agents/`), continue to Phase 1.
**Multiple found:** list all, ask which to resume or 'fresh'. If continuation intent, auto-resume most recent active loop.

**RESUME RULES — always apply when going to Phase 5 via resume:**
Skip Phase 2, 3, and 4 entirely. Read STATUS.md + PLAN.md to find where the loop stopped. Reuse existing RESEARCH.md, MEMORY.md, TOOLS.md, AGENTS.md — do not re-run startup agents.

> **To update loop-engineer:** re-run `install.sh --update` / `install.ps1 -Update -Codex`. Updates are never applied automatically mid-loop.

---

## Phase 1 — Core Wizard

**Q1:** "What do you want the loop to accomplish? (1-2 sentences)"

Generate LOOP_ID: lowercase slug, first 4 meaningful words, max 24 chars.
Auto-set: `STOP_CONDITION` = "all tasks in loop-stack/<LOOP_ID>/PLAN.md checked", `MAX_TURNS` = 20.

**Q2:** "Should the loop auto-commit after each verified task? (yes / no)"

Store: `GOAL`, `LOOP_ID`, `STOP_CONDITION`, `MAX_TURNS`, `USE_GIT`.

---

## Phase 2+3 — Initialize Loop

Run the init script — creates all state files, copies TOML agent files + knowledge-sources, and writes verifier in one command:

**PowerShell (Windows):**
```powershell
& "$env:USERPROFILE\.codex\skills\loop-engineer\scripts\init-loop.ps1" `
  -LoopId "<LOOP_ID>" `
  -Goal "<GOAL>" `
  -Stop "all tasks in loop-stack/<LOOP_ID>/PLAN.md checked" `
  -Git <yes/no> `
  -Platform codex
```

**Bash (macOS/Linux):**
```bash
bash ~/.codex/skills/loop-engineer/scripts/init-loop.sh \
  --loop-id <LOOP_ID> \
  --goal "<GOAL>" \
  --stop "all tasks in loop-stack/<LOOP_ID>/PLAN.md checked" \
  --git <yes/no> \
  --platform codex
```

If the script is missing, install the skill first:
`git clone https://github.com/vibhasdutta/loop-engineer && bash install.sh --codex`

The script creates `loop-stack/<LOOP_ID>/`, `.codex/agents/` with all TOML agent files, `.codex/knowledge-sources/` with all reference .md files, and `verifier.toml` with the actual stop condition substituted.

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

Spawn watcher immediately after researchers complete:
  Loop directory: loop-stack/<LOOP_ID>/
  Agents watched: researchers (just completed in Step 1)
  Check loop-stack/<LOOP_ID>/STATUS.md ## Active Heartbeats for signs of incomplete work.
  If any researcher shows incomplete heartbeat, report STUCK in ## Last Watcher Report.
  Read .codex/agents/watcher.toml for full instructions.
  Call report_agent_job_result when done.
Wait for watcher to complete.

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

Step 4 — Agent-factory (conditional):
Read PLAN.md to count tasks. Assess goal domain.
- SKIP if BOTH: task count ≤ 2 AND goal domain is generic (no clear need for specialists).
  If skipping: write loop-stack/<LOOP_ID>/AGENTS.md with "# Specialized Agents\n## Status\nNONE CREATED". Proceed to outer loop.
- RUN if EITHER: task count ≥ 3 OR goal domain clearly benefits from specialists (security, ML/data science, content production, medical, finance, system design, etc.).

If running: spawn_agent: agent-factory
  Loop directory: loop-stack/<LOOP_ID>/
  Read PLAN.md (goal + tasks), RESEARCH.md, and TOOLS.md.
  Analyze the goal domain. Determine what specialized agents would improve execution quality.
  Create 1–3 purpose-built agent TOML files in loop-stack/<LOOP_ID>/agents/ for this goal.
  Write loop-stack/<LOOP_ID>/AGENTS.md listing each created agent and which tasks it handles.
  If generic agents sufficient, write AGENTS.md with "NONE CREATED".
  Read .codex/agents/agent-factory.toml for full instructions.
  Call report_agent_job_result when done.
Wait for agent-factory to complete (if spawned).

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
