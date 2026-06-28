# Loop Engineer

When the user asks to run an autonomous loop, orchestrate a multi-agent team,
or start a goal-driven task loop, the loop-engineer skill will activate automatically.

The skill is installed at ~/.gemini/skills/loop-engineer/SKILL.md.
Loop state files are stored in loop-stack/<loop-id>/.
Agent definitions are copied to .gemini/agents/ when a loop starts.

To activate: describe your goal — loop-engineer will activate automatically via semantic matching.
To force: use `/skills enable loop-engineer`.

Activation examples:
- "I want to run an autonomous loop to add authentication to my API."
- "Help me orchestrate a multi-agent team to refactor this codebase."
- "Start a loop-engineer session for this project."
