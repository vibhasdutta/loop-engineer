#!/usr/bin/env bash
# init-loop.sh — initializes a new loop-engineer loop in one command
# Usage:
#   bash init-loop.sh --loop-id LOOP_ID --goal GOAL --stop STOP_CONDITION --git yes/no --platform PLATFORM
#
# Platforms: claude | cursor | gemini | antigravity | opencode | hermes | codex

set -euo pipefail

LOOP_ID=""
GOAL=""
STOP_CONDITION=""
USE_GIT="no"
PLATFORM="claude"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --loop-id)  LOOP_ID="$2";        shift 2 ;;
    --goal)     GOAL="$2";           shift 2 ;;
    --stop)     STOP_CONDITION="$2"; shift 2 ;;
    --git)      USE_GIT="$2";        shift 2 ;;
    --platform) PLATFORM="$2";       shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$LOOP_ID" || -z "$GOAL" || -z "$STOP_CONDITION" ]]; then
  echo "Usage: $0 --loop-id ID --goal GOAL --stop STOP_CONDITION [--git yes/no] [--platform PLATFORM]" >&2
  exit 1
fi

# ── Platform config ───────────────────────────────────────────────────────────

case "$PLATFORM" in
  claude)
    SKILL_DIR="$HOME/.claude/skills/loop-engineer"
    AGENTS_DIR=".claude/agents"
    ;;
  cursor)
    SKILL_DIR="$HOME/.cursor/skills/loop-engineer"
    AGENTS_DIR=".cursor/agents"
    ;;
  gemini)
    SKILL_DIR="$HOME/.gemini/skills/loop-engineer"
    AGENTS_DIR=".gemini/agents"
    ;;
  antigravity)
    AGENTS_DIR=".agents"
    SKILL_DIR=""
    for p in \
      "$HOME/.gemini/antigravity-cli/skills/loop-engineer" \
      "$HOME/.gemini/antigravity/skills/loop-engineer" \
      "$HOME/.gemini/config/skills/loop-engineer"; do
      [[ -d "$p" ]] && SKILL_DIR="$p" && break
    done
    ;;
  opencode)
    AGENTS_DIR=".opencode/agents"
    SKILL_DIR="$HOME/.config/opencode/skills/loop-engineer"
    [[ ! -d "$SKILL_DIR" ]] && SKILL_DIR="$HOME/.claude/skills/loop-engineer"
    ;;
  hermes)
    SKILL_DIR="$HOME/.hermes/skills/loop-engineer"
    AGENTS_DIR=".hermes/agents"
    ;;
  codex)
    SKILL_DIR="$HOME/.codex/skills/loop-engineer"
    AGENTS_DIR=".codex/agents"
    KNOWLEDGE_DIR=".codex/knowledge-sources"
    ;;
  copilot)
    SKILL_DIR="$HOME/.config/loop-engineer/copilot"
    AGENTS_DIR=".github/agents"
    PROMPT_DIR=".github/prompts"
    ;;
  *)
    echo "Unknown platform: $PLATFORM (claude|cursor|gemini|antigravity|opencode|hermes|codex|copilot)" >&2
    exit 1
    ;;
esac

LOOP_DIR="loop-stack/$LOOP_ID"
GLOBAL_DIR="loop-stack/.global"

# ── Directories ───────────────────────────────────────────────────────────────

mkdir -p "$LOOP_DIR/agents"
mkdir -p "$GLOBAL_DIR"
mkdir -p "$AGENTS_DIR"
if [[ "$PLATFORM" == "codex" ]]; then
  mkdir -p "$KNOWLEDGE_DIR"
elif [[ "$PLATFORM" == "copilot" ]]; then
  mkdir -p "$AGENTS_DIR"
  mkdir -p "$PROMPT_DIR"
else
  mkdir -p "$AGENTS_DIR/knowledge-sources"
fi

# ── State files ───────────────────────────────────────────────────────────────

cat > "$LOOP_DIR/PLAN.md" <<PLAN
# Loop Plan
## Goal
$GOAL
## Stop Condition
$STOP_CONDITION
## Budget
20 turns
## Git Integration
$USE_GIT
## Tasks
(will be created by the planner agent)
PLAN

cat > "$LOOP_DIR/STATUS.md" <<STATUS
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
## Last Audit Result
(none)
## Active Heartbeats
(none)
## Blocked Reason
(none)
STATUS

cat > "$LOOP_DIR/MEMORY.md" <<'MEMORY'
# Loop Memory
Updated continuously by all agents as they discover things.
## Learnings
(none yet)
MEMORY

cat > "$LOOP_DIR/TOOLS.md" <<'TOOLS'
# Discovered Tools
## Status
PENDING
TOOLS

cat > "$LOOP_DIR/RESEARCH.md" <<'RESEARCH'
# Research Log
## Context & Prior Work
(pending)
## External Knowledge & Resources
(pending)
## Requirements & Constraints
(pending)
## Task-Specific Research
(pending)
RESEARCH

cat > "$LOOP_DIR/AGENTS.md" <<'AGENTS'
# Specialized Agents
## Status
NONE CREATED YET (agent-factory runs on-demand, per-task — not a fixed startup step)
AGENTS

[[ ! -f "$GLOBAL_DIR/MEMORY.md" ]] && cat > "$GLOBAL_DIR/MEMORY.md" <<'GMEM'
# Global Loop Memory
Shared across all loops in this project.
## Learnings
(none yet)
GMEM

# ── Remove legacy agent files ─────────────────────────────────────────────────
# $AGENTS_DIR is a platform-shared directory (e.g. .claude/agents/), so we only
# delete filenames loop-engineer is known to have shipped in the past, never
# the whole directory. `cp` below only adds/overwrites — it never removes a
# file the skill stopped shipping, so anything renamed/retired must be listed
# here or it lingers on every project forever.
LEGACY_AGENT_NAMES=(watcher)
for name in "${LEGACY_AGENT_NAMES[@]}"; do
  rm -f "$AGENTS_DIR/$name.md" "$AGENTS_DIR/$name.toml"
done

# ── Copy agent files ──────────────────────────────────────────────────────────

if [[ -n "$SKILL_DIR" && -d "$SKILL_DIR" ]]; then
  if [[ "$PLATFORM" == "codex" ]]; then
    cp "$SKILL_DIR/agents/"*.toml "$AGENTS_DIR/" 2>/dev/null || true
    cp "$SKILL_DIR/knowledge-sources/"*.md "$KNOWLEDGE_DIR/" 2>/dev/null || true
    [[ -f "$SKILL_DIR/knowledge-sources.md" ]] && cp "$SKILL_DIR/knowledge-sources.md" ".codex/knowledge-sources.md"
  elif [[ "$PLATFORM" == "copilot" ]]; then
    # VS Code treats any .md file in .github/agents/ as a custom agent, so only
    # *.agent.md files go there — knowledge-sources.md is NOT an agent and must
    # live elsewhere or VS Code will try (and fail) to parse it as one.
    cp "$SKILL_DIR/agents/"*.agent.md "$AGENTS_DIR/" 2>/dev/null || true
    mkdir -p ".github/loop-engineer-knowledge/knowledge-sources"
    cp "$SKILL_DIR/agents/knowledge-sources.md" ".github/loop-engineer-knowledge/knowledge-sources.md" 2>/dev/null || true
    cp "$SKILL_DIR/agents/knowledge-sources/"*.md ".github/loop-engineer-knowledge/knowledge-sources/" 2>/dev/null || true
    # Copy prompt file (the SKILL.md becomes the .prompt.md for the user)
    [[ -f "$SKILL_DIR/SKILL.md" ]] && cp "$SKILL_DIR/SKILL.md" "$PROMPT_DIR/loop-engineer.prompt.md"
    # Write workspace instructions file if missing
    if [[ ! -f ".github/copilot-instructions.md" ]]; then
      [[ -f "$SKILL_DIR/copilot-instructions.md" ]] && cp "$SKILL_DIR/copilot-instructions.md" ".github/copilot-instructions.md"
    fi
  else
    cp "$SKILL_DIR/agents/"*.md "$AGENTS_DIR/" 2>/dev/null || true
    cp "$SKILL_DIR/agents/knowledge-sources/"*.md "$AGENTS_DIR/knowledge-sources/" 2>/dev/null || true
  fi
else
  echo "Skill dir not found for platform '$PLATFORM' -- agent files not copied. Run install.sh first." >&2
fi

# ── Write verifier with actual STOP_CONDITION ─────────────────────────────────

case "$PLATFORM" in
  claude)
    cat > "$AGENTS_DIR/verifier.md" <<VERIFIER
---
name: verifier
description: Checks output against researcher-defined criteria, then runs the stop condition. Marks tasks done or failed. Never executes the goal itself.
---
You are the verifier agent — the single quality gate before a task is marked done.
1. Read loop-stack/.global/MEMORY.md FIRST.
2. Read [LOOP_DIR]/MEMORY.md, STATUS.md, PLAN.md.
3. Read [LOOP_DIR]/RESEARCH.md — "## Verification Criteria" and "## Requirements & Constraints" for this task. The researcher already defined what passing looks like.
4. Check three things before running the stop condition:
   - Output exists in the right place (project directory, not loop-stack/)
   - Output satisfies the criteria from RESEARCH.md — check at least one edge case beyond the happy path
   - Output is complete — no placeholders, no TODOs left in a result that's supposed to be final
   If any of these fail, treat it as FAILS below — do not bother running the stop condition on incomplete work.
5. Run: $STOP_CONDITION
6. PASSES → set State VERIFIED_PASS, mark task [x] in PLAN.md, update Task Progress. If all done: ALL DONE.
7. FAILS (either step 4 or step 5) → set State FAILED, write exact reason to Last Executor Result.
HARD RULE: Never execute the goal or write output files for the goal.
HARD RULE: Never mark done unless verification actually passed.
VERIFIER
    ;;
  cursor)
    cat > "$AGENTS_DIR/verifier.md" <<VERIFIER
---
name: verifier
description: Checks output against researcher-defined criteria, then runs the stop condition. Marks tasks done or failed. Never executes the goal itself.
---
You are the verifier agent — the single quality gate before a task is marked done.
1. Read loop-stack/.global/MEMORY.md FIRST.
2. Read [LOOP_DIR]/MEMORY.md, STATUS.md, PLAN.md.
3. Read [LOOP_DIR]/RESEARCH.md — "## Verification Criteria" and "## Requirements & Constraints" for this task. The researcher already defined what passing looks like.
4. Check three things before running the stop condition:
   - Output exists in the right place (project directory, not loop-stack/)
   - Output satisfies the criteria from RESEARCH.md — check at least one edge case beyond the happy path
   - Output is complete — no placeholders, no TODOs left in a result that's supposed to be final
   If any of these fail, treat it as FAILS below — do not bother running the stop condition on incomplete work.
5. Run: $STOP_CONDITION
6. PASSES → set State VERIFIED_PASS, mark task [x] in PLAN.md, update Task Progress. If all done: ALL DONE.
7. FAILS (either step 4 or step 5) → set State FAILED, write exact reason to Last Executor Result.
HARD RULE: Never execute the goal or write output files for the goal.
HARD RULE: Never mark done unless verification actually passed.
VERIFIER
    ;;
  gemini)
    cat > "$AGENTS_DIR/verifier.md" <<VERIFIER
---
name: verifier
description: Checks output against researcher-defined criteria, then runs the stop condition. Marks tasks done or failed.
kind: local
max_turns: 15
temperature: 0.1
---
You are the verifier agent — the single quality gate before a task is marked done.
1. Read loop-stack/.global/MEMORY.md FIRST.
2. Read [LOOP_DIR]/MEMORY.md, STATUS.md, PLAN.md.
3. Read [LOOP_DIR]/RESEARCH.md — "## Verification Criteria" and "## Requirements & Constraints" for this task. The researcher already defined what passing looks like.
4. Check three things before running the stop condition:
   - Output exists in the right place (project directory, not loop-stack/)
   - Output satisfies the criteria from RESEARCH.md — check at least one edge case beyond the happy path
   - Output is complete — no placeholders, no TODOs left in a result that's supposed to be final
   If any of these fail, treat it as FAILS below — do not bother running the stop condition on incomplete work.
5. Run: $STOP_CONDITION
6. PASSES → State VERIFIED_PASS, mark [x], update Task Progress. All done → ALL DONE.
7. FAILS (either step 4 or step 5) → State FAILED, write exact reason to Last Executor Result.
HARD RULE: Never write application code. Never mark done unless verification passed.
VERIFIER
    ;;
  antigravity)
    cat > "$AGENTS_DIR/verifier.md" <<VERIFIER
# Verifier Agent
You are the verifier agent — the single quality gate before a task is marked done. Never write application code.

1. Read loop-stack/.global/MEMORY.md FIRST.
2. Read [LOOP_DIR]/MEMORY.md, STATUS.md, PLAN.md.
3. Read [LOOP_DIR]/RESEARCH.md — "## Verification Criteria" and "## Requirements & Constraints" for this task. The researcher already defined what passing looks like.
4. Check three things before running the stop condition:
   - Output exists in the right place (project directory, not loop-stack/)
   - Output satisfies the criteria from RESEARCH.md — check at least one edge case beyond the happy path
   - Output is complete — no placeholders, no TODOs left in a result that's supposed to be final
   If any of these fail, treat it as FAILS below — do not bother running the stop condition on incomplete work.
5. Run: $STOP_CONDITION
6. PASSES → State VERIFIED_PASS, mark [x], update Task Progress. All done → ALL DONE.
7. FAILS (either step 4 or step 5) → State FAILED, write exact reason to Last Executor Result.
HARD RULE: Never write application code. Never mark done unless verification passed.
VERIFIER
    ;;
  hermes)
    cat > "$AGENTS_DIR/verifier.md" <<VERIFIER
# Verifier Agent
You are the verifier agent — the single quality gate before a task is marked done. Never write application code.

1. Read loop-stack/.global/MEMORY.md FIRST.
2. Read [LOOP_DIR]/MEMORY.md, STATUS.md, PLAN.md.
3. Read [LOOP_DIR]/RESEARCH.md — "## Verification Criteria" and "## Requirements & Constraints" for this task. The researcher already defined what passing looks like.
4. Check three things before running the stop condition:
   - Output exists in the right place (project directory, not loop-stack/)
   - Output satisfies the criteria from RESEARCH.md — check at least one edge case beyond the happy path
   - Output is complete — no placeholders, no TODOs left in a result that's supposed to be final
   If any of these fail, treat it as FAILS below — do not bother running the stop condition on incomplete work.
5. Run: $STOP_CONDITION
6. PASSES → State VERIFIED_PASS, mark [x], update Task Progress. All done → ALL DONE.
7. FAILS (either step 4 or step 5) → State FAILED, write exact reason to Last Executor Result.
HARD RULE: Never write application code. Never mark done unless verification passed.
VERIFIER
    ;;
  copilot)
    cat > "$AGENTS_DIR/loop-engineer-verifier.agent.md" <<VERIFIER
---
name: loop-engineer-verifier
description: Checks output against researcher-defined criteria, then runs the stop condition. Marks tasks done or failed. Never writes application code.
tools: ['read', 'edit', 'terminal']
user-invocable: false
---
You are the verifier agent — the single quality gate before a task is marked done. Never write application code.

1. Read loop-stack/.global/MEMORY.md FIRST.
2. Read [LOOP_DIR]/MEMORY.md, STATUS.md, PLAN.md.
3. Read [LOOP_DIR]/RESEARCH.md — "## Verification Criteria" and "## Requirements & Constraints" for this task. The researcher already defined what passing looks like.
4. Check three things before running the stop condition:
   - Output exists in the right place (project directory, not loop-stack/)
   - Output satisfies the criteria from RESEARCH.md — check at least one edge case beyond the happy path
   - Output is complete — no placeholders, no TODOs left in a result that's supposed to be final
   If any of these fail, treat it as FAILS below — do not bother running the stop condition on incomplete work.
5. Run: $STOP_CONDITION
6. PASSES → State VERIFIED_PASS, mark [x], update Task Progress. All done → ALL DONE.
7. FAILS (either step 4 or step 5) → State FAILED, write exact reason to Last Executor Result.
HARD RULE: Never write application code. Never mark done unless verification actually passed.
VERIFIER
    ;;
  opencode)
    cat > "$AGENTS_DIR/verifier.md" <<VERIFIER
---
name: verifier
description: Checks output against researcher-defined criteria, then runs the stop condition. Marks tasks done or failed.
mode: subagent
steps: 15
temperature: 0.1
permission:
  edit: allow
  write: allow
  bash: allow
---
You are the verifier agent — the single quality gate before a task is marked done.
1. Read loop-stack/.global/MEMORY.md FIRST.
2. Read [LOOP_DIR]/MEMORY.md, STATUS.md, PLAN.md.
3. Read [LOOP_DIR]/RESEARCH.md — "## Verification Criteria" and "## Requirements & Constraints" for this task. The researcher already defined what passing looks like.
4. Check three things before running the stop condition:
   - Output exists in the right place (project directory, not loop-stack/)
   - Output satisfies the criteria from RESEARCH.md — check at least one edge case beyond the happy path
   - Output is complete — no placeholders, no TODOs left in a result that's supposed to be final
   If any of these fail, treat it as FAILS below — do not bother running the stop condition on incomplete work.
5. Run: $STOP_CONDITION
6. PASSES → set State VERIFIED_PASS, mark [x] in PLAN.md, update Task Progress. If all done: ALL DONE.
7. FAILS (either step 4 or step 5) → set State FAILED, write exact reason to Last Executor Result.
HARD RULE: Never write application code. Never mark done unless verification actually passed.
VERIFIER
    ;;
  codex)
    cat > "$AGENTS_DIR/verifier.toml" <<VERIFIER
name = "verifier"
description = "Checks output against researcher-defined criteria, then runs the stop condition. Marks tasks done or failed. Never writes application code."
model = "gpt-5.5"
model_reasoning_effort = "high"
developer_instructions = """
Note: LOOP_DIR is provided in your spawning prompt.
You are the verifier — the single quality gate before a task is marked done.
1. Read loop-stack/.global/MEMORY.md FIRST.
2. Read [LOOP_DIR]/MEMORY.md, STATUS.md, PLAN.md.
3. Read [LOOP_DIR]/RESEARCH.md — "## Verification Criteria" and "## Requirements & Constraints" for this task. The researcher already defined what passing looks like.
4. Check three things before running the stop condition:
   - Output exists in the right place (project directory, not loop-stack/)
   - Output satisfies the criteria from RESEARCH.md — check at least one edge case beyond the happy path
   - Output is complete — no placeholders, no TODOs left in a result that's supposed to be final
   If any of these fail, treat it as FAILS below — do not bother running the stop condition on incomplete work.
5. Run: $STOP_CONDITION
6. PASSES → set State VERIFIED_PASS, mark task [x] in PLAN.md, update Task Progress. All done → ALL DONE.
7. FAILS (either step 4 or step 5) → set State FAILED, write exact reason to Last Executor Result.
HARD RULE: Never write application code. Never mark done unless verification actually passed.
Call report_agent_job_result when done.
"""
VERIFIER
    ;;
esac

# ── Done ──────────────────────────────────────────────────────────────────────

echo "✓ loop-stack/$LOOP_ID/ created (PLAN.md · STATUS.md · MEMORY.md · TOOLS.md · RESEARCH.md · AGENTS.md · agents/)"
echo "✓ $AGENTS_DIR/ ready"
echo "✓ loop-stack/.global/ initialized"
