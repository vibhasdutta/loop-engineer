# Loop Engineer

When the user asks to run an autonomous loop, orchestrate a multi-agent team,
or start a goal-driven task loop, activate the loop-engineer skill.

The skill is installed at:
- Antigravity CLI: ~/.gemini/antigravity-cli/skills/loop-engineer/SKILL.md
- Antigravity 2.0 desktop: ~/.agents/skills/loop-engineer/SKILL.md

Loop state files are stored in loop-stack/<loop-id>/.
Agent instruction files are copied to .agents/ when a loop starts.

## Activation

Antigravity CLI (`agy`): type `/skills` to list, then use `/goal` to describe your task.
Antigravity 2.0 desktop: use `/skills` command in the chat interface.
Or simply describe a multi-step goal — the agent will activate the loop-engineer skill automatically.

Examples:
- "I want to run an autonomous loop to add authentication to my API."
- "Help me orchestrate a multi-agent team to refactor this codebase."
- "Start a loop-engineer session and help me build X."

## How subagents work

Antigravity supports true parallel subagents — multiple agents can run simultaneously.
The main orchestrating agent dispatches subagents in prose: "Dispatch N subagents in parallel
with these instructions." Each subagent reads its role file from .agents/{role}.md and writes
results back to loop-stack/.
Manage running subagents with `/agents` (Ctrl+J to approve, Ctrl+K to reject in CLI TUI).

## State files

All loop state lives in loop-stack/<loop-id>/:
- PLAN.md — goal, tasks with [G1]/[G2] parallel group tags, stop condition
- STATUS.md — current state, attempts, last results from each agent
- MEMORY.md — accumulated learnings (grows smarter each iteration)
- TOOLS.md — discovered MCP servers, skills, plugins, project tooling
- RESEARCH.md — researcher findings per task

loop-stack/.global/ — shared across all loops in this project:
- MEMORY.md — cross-loop project learnings
- TOOLS.md — cached tool discovery (7-day TTL)

## Configuration paths

MCP servers (Antigravity CLI):     ~/.gemini/antigravity-cli/mcp_config.json
MCP servers (Antigravity 2.0):     ~/.agents/mcp_config.json
MCP servers (workspace, both):     .agents/mcp_config.json
Hooks (CLI):                       ~/.gemini/antigravity-cli/hooks.json
Hooks (workspace, both):           .agents/hooks.json
Skills (CLI global):               ~/.gemini/antigravity-cli/skills/
Skills (2.0 global):               ~/.agents/skills/
Skills (workspace, both):          .agents/skills/
CLI settings + permissions:        ~/.gemini/antigravity-cli/settings.json

Note: Remote MCP servers use "serverUrl" key (not "url" or "httpUrl").

## Useful slash commands

- `/agents`  — view and manage running subagents
- `/skills`  — view and manage installed skills
- `/mcp`     — view and manage connected MCP servers
- `/rewind`  — roll back conversation turns if context gets polluted mid-loop
- `/fork`    — branch the conversation to safely explore a risky refactor
- `/context` — inspect what is currently in the agent's context window (CLI)
- `/goal`    — submit a fully autonomous goal (spawns subagents automatically)

## Migration from Gemini CLI

If migrating from Gemini CLI, run once:
  agy plugin import gemini
This converts Gemini CLI extensions to Antigravity plugins, converting commands to skills.
Skills must move from ~/.gemini/skills/ to ~/.gemini/antigravity-cli/skills/ (CLI)
or ~/.agents/skills/ (2.0). Workspace skills move from .gemini/skills/ to .agents/skills/.

## Resume

If a loop is in progress (loop-stack/*/STATUS.md exists, not ending in _DONE),
the skill offers to resume it before starting fresh.
