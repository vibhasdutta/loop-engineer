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
  *)
    echo "Unknown platform: $PLATFORM (claude|cursor|gemini|antigravity|opencode|hermes|codex)" >&2
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
## Last Evaluator Result
(none)
## Last Audit Result
(none)
## Last Watcher Report
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
PENDING (agent-factory will populate after planning)
AGENTS

[[ ! -f "$GLOBAL_DIR/MEMORY.md" ]] && cat > "$GLOBAL_DIR/MEMORY.md" <<'GMEM'
# Global Loop Memory
Shared across all loops in this project.
## Learnings
(none yet)
GMEM

# ── Copy agent files ──────────────────────────────────────────────────────────

if [[ -n "$SKILL_DIR" && -d "$SKILL_DIR" ]]; then
  if [[ "$PLATFORM" == "codex" ]]; then
    cp "$SKILL_DIR/agents/"*.toml "$AGENTS_DIR/" 2>/dev/null || true
    cp "$SKILL_DIR/knowledge-sources/"*.md "$KNOWLEDGE_DIR/" 2>/dev/null || true
    [[ -f "$SKILL_DIR/knowledge-sources.md" ]] && cp "$SKILL_DIR/knowledge-sources.md" ".codex/knowledge-sources.md"
  else
    cp "$SKILL_DIR/agents/"*.md "$AGENTS_DIR/" 2>/dev/null || true
    cp "$SKILL_DIR/agents/knowledge-sources/"*.md "$AGENTS_DIR/knowledge-sources/" 2>/dev/null || true
  fi
else
  echo "⚠ Skill dir not found for platform '$PLATFORM' — agent files not copied. Run install.sh first." >&2
fi

# ── Write verifier with actual STOP_CONDITION ─────────────────────────────────

case "$PLATFORM" in
  claude|cursor)
    cat > "$AGENTS_DIR/verifier.md" <<VERIFIER
---
name: verifier
description: Runs the stop condition. Marks tasks done or failed. Never executes the goal itself.
---
You are the verifier agent.
1. Read loop-stack/.global/MEMORY.md FIRST.
2. Read [LOOP_DIR]/MEMORY.md, STATUS.md, PLAN.md.
3. Run: $STOP_CONDITION
4. PASSES → set State VERIFIED_PASS, mark task [x] in PLAN.md, update Task Progress. If all done: ALL DONE.
5. FAILS → set State FAILED, write exact error to Last Executor Result.
HARD RULE: Never execute the goal or write output files for the goal.
HARD RULE: Never mark done unless verification actually passed.
VERIFIER
    ;;
  gemini)
    cat > "$AGENTS_DIR/verifier.md" <<VERIFIER
---
name: verifier
description: Runs the stop condition. Marks tasks done or failed.
kind: local
max_turns: 15
temperature: 0.1
---
1. Read loop-stack/.global/MEMORY.md FIRST.
2. Read [LOOP_DIR]/MEMORY.md, STATUS.md, PLAN.md.
3. Run: $STOP_CONDITION
4. PASSES → State VERIFIED_PASS, mark [x], update Task Progress. All done → ALL DONE.
5. FAILS → State FAILED, write exact error to Last Executor Result.
HARD RULE: Never write application code. Never mark done unless verification passed.
VERIFIER
    ;;
  antigravity|hermes)
    cat > "$AGENTS_DIR/verifier.md" <<VERIFIER
# Verifier Agent
You are the verifier agent. Never write application code.

1. Read loop-stack/.global/MEMORY.md FIRST.
2. Read [LOOP_DIR]/MEMORY.md, STATUS.md, PLAN.md.
3. Run: $STOP_CONDITION
4. PASSES → State VERIFIED_PASS, mark [x], update Task Progress. All done → ALL DONE.
5. FAILS → State FAILED, write exact error to Last Executor Result.
HARD RULE: Never write application code. Never mark done unless verification passed.
VERIFIER
    ;;
  opencode)
    cat > "$AGENTS_DIR/verifier.md" <<VERIFIER
---
name: verifier
description: Runs the stop condition. Marks tasks done or failed.
mode: subagent
steps: 15
temperature: 0.1
permission:
  edit: allow
  write: allow
  bash: allow
---
1. Read loop-stack/.global/MEMORY.md FIRST.
2. Read [LOOP_DIR]/MEMORY.md, STATUS.md, PLAN.md.
3. Run: $STOP_CONDITION
4. PASSES → set State VERIFIED_PASS, mark [x] in PLAN.md, update Task Progress. If all done: ALL DONE.
5. FAILS → set State FAILED, write exact error to Last Executor Result.
HARD RULE: Never write application code. Never mark done unless verification actually passed.
VERIFIER
    ;;
  codex)
    cat > "$AGENTS_DIR/verifier.toml" <<VERIFIER
name = "verifier"
description = "Runs the stop condition. Marks tasks done or failed. Never writes application code."
model = "gpt-5.5"
model_reasoning_effort = "high"
developer_instructions = """
Note: LOOP_DIR is provided in your spawning prompt.
1. Read loop-stack/.global/MEMORY.md FIRST.
2. Read [LOOP_DIR]/MEMORY.md, STATUS.md, PLAN.md.
3. Run: $STOP_CONDITION
4. PASSES → set State VERIFIED_PASS, mark task [x] in PLAN.md, update Task Progress. All done → ALL DONE.
5. FAILS → set State FAILED, write exact error to Last Executor Result.
HARD RULE: Never write application code. Never mark done unless verification passed.
Call report_agent_job_result when done.
"""
VERIFIER
    ;;
esac

# ── Done ──────────────────────────────────────────────────────────────────────

echo "✓ loop-stack/$LOOP_ID/ created (PLAN.md · STATUS.md · MEMORY.md · TOOLS.md · RESEARCH.md · AGENTS.md · agents/)"
echo "✓ $AGENTS_DIR/ ready"
echo "✓ loop-stack/.global/ initialized"
