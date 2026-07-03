# init-loop.ps1 - initializes a new loop-engineer loop in one command
# Usage:
#   .\init-loop.ps1 -LoopId ID -Goal GOAL -Stop STOP_CONDITION [-Git yes/no] [-Platform PLATFORM]
#
# Platforms: claude | cursor | gemini | antigravity | opencode | hermes | codex

param(
  [Parameter(Mandatory)][string]$LoopId,
  [Parameter(Mandatory)][string]$Goal,
  [Parameter(Mandatory)][string]$Stop,
  [string]$Git      = "no",
  [string]$Platform = "claude"
)

$ErrorActionPreference = "Stop"

# ── Platform config ───────────────────────────────────────────────────────────

switch ($Platform) {
  "claude" {
    $SkillDir  = "$env:USERPROFILE\.claude\skills\loop-engineer"
    $AgentsDir = ".claude\agents"
  }
  "cursor" {
    $SkillDir  = "$env:USERPROFILE\.cursor\skills\loop-engineer"
    $AgentsDir = ".cursor\agents"
  }
  "gemini" {
    $SkillDir  = "$env:USERPROFILE\.gemini\skills\loop-engineer"
    $AgentsDir = ".gemini\agents"
  }
  "antigravity" {
    $AgentsDir = ".agents"
    $SkillDir  = $null
    foreach ($p in @(
      "$env:USERPROFILE\.gemini\antigravity-cli\skills\loop-engineer",
      "$env:USERPROFILE\.gemini\antigravity\skills\loop-engineer",
      "$env:USERPROFILE\.gemini\config\skills\loop-engineer"
    )) {
      if (Test-Path $p) { $SkillDir = $p; break }
    }
  }
  "opencode" {
    $AgentsDir = ".opencode\agents"
    $SkillDir  = "$env:USERPROFILE\.config\opencode\skills\loop-engineer"
    if (-not (Test-Path $SkillDir)) { $SkillDir = "$env:USERPROFILE\.claude\skills\loop-engineer" }
  }
  "hermes" {
    $SkillDir  = "$env:USERPROFILE\.hermes\skills\loop-engineer"
    $AgentsDir = ".hermes\agents"
  }
  "codex" {
    $SkillDir       = "$env:USERPROFILE\.codex\skills\loop-engineer"
    $AgentsDir      = ".codex\agents"
    $KnowledgeDir   = ".codex\knowledge-sources"
  }
  "copilot" {
    $SkillDir  = "$env:USERPROFILE\.config\loop-engineer\copilot"
    $AgentsDir = ".github\loop-engineer\agents"
    $PromptDir = ".github\prompts"
  }
  default {
    Write-Error "Unknown platform: $Platform (claude|cursor|gemini|antigravity|opencode|hermes|codex|copilot)"
    exit 1
  }
}

$LoopDir   = "loop-stack\$LoopId"
$GlobalDir = "loop-stack\.global"

# ── Directories ───────────────────────────────────────────────────────────────

New-Item -ItemType Directory -Force "$LoopDir\agents" | Out-Null
New-Item -ItemType Directory -Force $GlobalDir         | Out-Null
New-Item -ItemType Directory -Force $AgentsDir         | Out-Null
if ($Platform -eq "codex") {
  New-Item -ItemType Directory -Force $KnowledgeDir | Out-Null
} elseif ($Platform -eq "copilot") {
  New-Item -ItemType Directory -Force $AgentsDir  | Out-Null
  New-Item -ItemType Directory -Force $PromptDir  | Out-Null
} else {
  New-Item -ItemType Directory -Force "$AgentsDir\knowledge-sources" | Out-Null
}

# ── State files ───────────────────────────────────────────────────────────────

@"
# Loop Plan
## Goal
$Goal
## Stop Condition
$Stop
## Budget
20 turns
## Git Integration
$Git
## Tasks
(will be created by the planner agent)
"@ | Set-Content "$LoopDir\PLAN.md" -Encoding utf8

@"
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
"@ | Set-Content "$LoopDir\STATUS.md" -Encoding utf8

@"
# Loop Memory
Updated continuously by all agents as they discover things.
## Learnings
(none yet)
"@ | Set-Content "$LoopDir\MEMORY.md" -Encoding utf8

@"
# Discovered Tools
## Status
PENDING
"@ | Set-Content "$LoopDir\TOOLS.md" -Encoding utf8

@"
# Research Log
## Context & Prior Work
(pending)
## External Knowledge & Resources
(pending)
## Requirements & Constraints
(pending)
## Task-Specific Research
(pending)
"@ | Set-Content "$LoopDir\RESEARCH.md" -Encoding utf8

@"
# Specialized Agents
## Status
PENDING (agent-factory will populate after planning)
"@ | Set-Content "$LoopDir\AGENTS.md" -Encoding utf8

if (-not (Test-Path "$GlobalDir\MEMORY.md")) {
  @"
# Global Loop Memory
Shared across all loops in this project.
## Learnings
(none yet)
"@ | Set-Content "$GlobalDir\MEMORY.md" -Encoding utf8
}

# ── Copy agent files ──────────────────────────────────────────────────────────

if ($SkillDir -and (Test-Path $SkillDir)) {
  if ($Platform -eq "codex") {
    try { Copy-Item "$SkillDir\agents\*.toml" $AgentsDir -ErrorAction SilentlyContinue } catch {}
    try { Copy-Item "$SkillDir\knowledge-sources\*.md" $KnowledgeDir -ErrorAction SilentlyContinue } catch {}
    $ksIndex = "$SkillDir\knowledge-sources.md"
    if (Test-Path $ksIndex) { Copy-Item $ksIndex ".codex\knowledge-sources.md" }
  } elseif ($Platform -eq "copilot") {
    try { Copy-Item "$SkillDir\agents\*.md" $AgentsDir -ErrorAction SilentlyContinue } catch {}
    $promptSrc = "$SkillDir\SKILL.md"
    if (Test-Path $promptSrc) { Copy-Item $promptSrc "$PromptDir\loop-engineer.prompt.md" -Force }
    if (-not (Test-Path ".github\copilot-instructions.md")) {
      $instrSrc = "$SkillDir\copilot-instructions.md"
      if (Test-Path $instrSrc) { Copy-Item $instrSrc ".github\copilot-instructions.md" }
    }
  } else {
    try { Copy-Item "$SkillDir\agents\*.md" $AgentsDir -ErrorAction SilentlyContinue } catch {}
    try { Copy-Item "$SkillDir\agents\knowledge-sources\*.md" "$AgentsDir\knowledge-sources\" -ErrorAction SilentlyContinue } catch {}
  }
} else {
  Write-Warning "Skill dir not found for platform '$Platform' - agent files not copied. Run install.ps1 first."
}

# ── Write verifier with actual STOP_CONDITION ─────────────────────────────────

switch ($Platform) {
  { $_ -in "claude","cursor" } {
    @"
---
name: verifier
description: Runs the stop condition. Marks tasks done or failed. Never executes the goal itself.
---
You are the verifier agent.
1. Read loop-stack/.global/MEMORY.md FIRST.
2. Read [LOOP_DIR]/MEMORY.md, STATUS.md, PLAN.md.
3. Run: $Stop
4. PASSES ->set State VERIFIED_PASS, mark task [x] in PLAN.md, update Task Progress. If all done: ALL DONE.
5. FAILS ->set State FAILED, write exact error to Last Executor Result.
HARD RULE: Never execute the goal or write output files for the goal.
HARD RULE: Never mark done unless verification actually passed.
"@ | Set-Content "$AgentsDir\verifier.md" -Encoding utf8
  }
  "gemini" {
    @"
---
name: verifier
description: Runs the stop condition. Marks tasks done or failed.
kind: local
max_turns: 15
temperature: 0.1
---
1. Read loop-stack/.global/MEMORY.md FIRST.
2. Read [LOOP_DIR]/MEMORY.md, STATUS.md, PLAN.md.
3. Run: $Stop
4. PASSES ->State VERIFIED_PASS, mark [x], update Task Progress. All done ->ALL DONE.
5. FAILS ->State FAILED, write exact error to Last Executor Result.
HARD RULE: Never write application code. Never mark done unless verification passed.
"@ | Set-Content "$AgentsDir\verifier.md" -Encoding utf8
  }
  { $_ -in "antigravity","hermes","copilot" } {
    @"
# Verifier Agent
You are the verifier agent. Never write application code.

1. Read loop-stack/.global/MEMORY.md FIRST.
2. Read [LOOP_DIR]/MEMORY.md, STATUS.md, PLAN.md.
3. Run: $Stop
4. PASSES ->State VERIFIED_PASS, mark [x], update Task Progress. All done ->ALL DONE.
5. FAILS ->State FAILED, write exact error to Last Executor Result.
HARD RULE: Never write application code. Never mark done unless verification passed.
"@ | Set-Content "$AgentsDir\verifier.md" -Encoding utf8
  }
  "opencode" {
    @"
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
3. Run: $Stop
4. PASSES ->set State VERIFIED_PASS, mark [x] in PLAN.md, update Task Progress. If all done: ALL DONE.
5. FAILS ->set State FAILED, write exact error to Last Executor Result.
HARD RULE: Never write application code. Never mark done unless verification actually passed.
"@ | Set-Content "$AgentsDir\verifier.md" -Encoding utf8
  }
  "codex" {
    @"
name = "verifier"
description = "Runs the stop condition. Marks tasks done or failed. Never writes application code."
model = "gpt-5.5"
model_reasoning_effort = "high"
developer_instructions = """
Note: LOOP_DIR is provided in your spawning prompt.
1. Read loop-stack/.global/MEMORY.md FIRST.
2. Read [LOOP_DIR]/MEMORY.md, STATUS.md, PLAN.md.
3. Run: $Stop
4. PASSES -> set State VERIFIED_PASS, mark task [x] in PLAN.md, update Task Progress. All done -> ALL DONE.
5. FAILS -> set State FAILED, write exact error to Last Executor Result.
HARD RULE: Never write application code. Never mark done unless verification passed.
Call report_agent_job_result when done.
"""
"@ | Set-Content "$AgentsDir\verifier.toml" -Encoding utf8
  }
}

# ── Done ──────────────────────────────────────────────────────────────────────

Write-Host "[OK] loop-stack/$LoopId/ created (PLAN.md - STATUS.md - MEMORY.md - TOOLS.md - RESEARCH.md - AGENTS.md - agents/)"
Write-Host "[OK] $AgentsDir/ ready"
Write-Host "[OK] loop-stack/.global/ initialized"
