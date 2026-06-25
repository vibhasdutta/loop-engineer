# What is Loop Engineering?

> "You should not be prompting coding agents anymore — you should be designing loops that prompt your agents." — Peter Steinberger

> "My job is to write loops, not individual prompts." — Boris Cherny, Anthropic (Claude Code lead)

Loop engineering emerged in June 2026, coined by Addy Osmani (Google), as the next evolution past prompt engineering and context engineering.

The idea: instead of typing each prompt yourself, you build a **system** that discovers work, prompts the agent, verifies results, persists state, and decides next steps — autonomously, until a goal is met.

---

## The Three-Layer Stack

| Layer | What you optimize | Who prompts |
|---|---|---|
| **Prompt engineering** | How you phrase one instruction | You, manually |
| **Context engineering** | What goes in the context window | You, curated |
| **Loop engineering** | The system that decides what to prompt, when, and whether the result is valid | The system itself |

---

## The Inner Loop vs the Outer Loop

Every agent already runs an **inner loop** internally:
```
Reason → Act → Observe → Repeat
```

Loop engineering adds the **outer loop**:
```
Discover work → Assign to agent → Verify result → Persist state → Next task → Repeat
```

This skill implements the outer loop for you.

---

## Why It Matters for Coding

Coding is inherently iterative. Single-shot generation fails on runtime errors, environment-specific issues, and unverifiable output. The ReAct pattern (Reason + Act, from Princeton/Google research) is what makes agents actually converge — they run code, observe output, reason about failures, and revise. A loop harnesses this at scale.

---

## The Ralph Insight (Geoffrey Huntley, 2026)

Long agent sessions degrade. The context window fills with dead ends and stale state. The fix: reset context on every iteration and read current state from disk. Each agent turn starts fresh; intelligence lives in clear specs and files on disk, not in a single long session.

This skill implements Ralph automatically — every agent starts with a clean context and reads `loop-stack/STATUS.md` + `loop-stack/PLAN.md` for ground truth.

---

## The Maker/Checker Split

The biggest loop engineering insight: **the agent that does the work should not verify its own work**. Self-grading is how loops hallucinate progress.

This skill enforces the split: the developer agent implements, the verifier agent runs the stop condition. The verifier is explicitly forbidden from writing application code.

---

## Research & References

| Source | Link |
|---|---|
| Kilo.ai — What Is Loop Engineering? | https://kilo.ai/articles/what-is-loop-engineering |
| Lushbinary — Full Guide (5 building blocks) | https://lushbinary.com/blog/loop-engineering-ai-coding-agents-guide/ |
| MindStudio — ReAct pattern & loop anatomy | https://www.mindstudio.ai/blog/what-is-loop-engineering-ai-coding-agents |
| Cobus Greyling — Loop Engineering overview | https://cobusgreyling.medium.com/loop-engineering-62926dd6991c |
| 36kr — Critical analysis & economics | https://eu.36kr.com/en/p/3864390159366791 |

Key concepts implemented:
- **ReAct pattern** (Princeton/Google) — the inner loop that makes agents converge
- **Ralph technique** (Geoffrey Huntley) — fresh context per iteration, state on disk
- **Maker/checker split** — separate agents for doing and verifying
- **Verifiable stop conditions** — no vague goals, only testable contracts
- **Failure checkpointing** — human in the loop only when the loop is stuck
