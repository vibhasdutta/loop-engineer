# Loop Engineer

When the user asks to run an autonomous loop, orchestrate a multi-agent team,
or start a goal-driven task loop, activate the loop-engineer skill.

The skill is installed at ~/.gemini/skills/loop-engineer/SKILL.md.
Loop state files are stored in loop-stack/<loop-id>/.
Agent definitions are stored in .agents/ when a loop starts.

To activate: describe your goal — the manager agent will detect the intent automatically.
Agent team: tool-scout, developer, qa-tester, verifier, auditor, memory-keeper.

Activation examples:
- "I want to run an autonomous loop to add authentication to my API."
- "Help me orchestrate a multi-agent team to refactor this codebase."
- "Start a loop-engineer session and help me build X."
