# Installation

## Requirements

| Skill | Platform | Minimum version |
|---|---|---|
| `/loop-engineer` | [Claude Code](https://claude.ai/code) (CLI or desktop app) | any |
| `/loop-engineer` | [Cursor](https://cursor.com) | any |
| `/loop-engineer` | [Gemini CLI](https://github.com/google-gemini/gemini-cli) | any |
| `/loop-engineer` | [Antigravity CLI (`agy`)](https://antigravity.google/docs/cli-overview) | any |
| `/loop-engineer` | [Antigravity 2.0 (desktop)](https://antigravity.google/download) | any |
| `/loop-engineer` | [OpenCode](https://opencode.ai) | any |
| `/loop-engineer` | [Hermes Agent](https://hermes-agent.nousresearch.com) | any |
| `/loop-engineer` | [Codex CLI](https://github.com/openai/codex) | 0.128.0+ |

---

## Claude Code

### Plugin system (recommended — auto-updates)

```bash
claude plugin add https://github.com/vibhasdutta/loop-engineer
```

Installs via the Claude Code plugin system and auto-updates when new versions are published.

### One-liner (macOS / Linux)

```bash
curl -s https://raw.githubusercontent.com/vibhasdutta/loop-engineer/main/install.sh | bash
```

### Windows (PowerShell)

```powershell
git clone https://github.com/vibhasdutta/loop-engineer.git
cd loop-engineer
.\install.ps1
```

### Manual (macOS / Linux)

```bash
git clone https://github.com/vibhasdutta/loop-engineer.git
cd loop-engineer && bash install.sh
```

### Verify

Restart Claude Code, then type `/loop-engineer` in any project.

---

## Cursor

Installs to `~/.cursor/skills/loop-engineer/`.

### Windows (PowerShell)

```powershell
git clone https://github.com/vibhasdutta/loop-engineer.git
cd loop-engineer
.\install.ps1 -Cursor
```

### macOS / Linux

```bash
git clone https://github.com/vibhasdutta/loop-engineer.git
cd loop-engineer && bash install.sh --cursor
```

### Verify

Restart Cursor, then type `/loop-engineer` in any project.

---

## Gemini CLI

Installs to `~/.gemini/skills/loop-engineer/`.

### macOS / Linux

```bash
git clone https://github.com/vibhasdutta/loop-engineer.git
cd loop-engineer && bash install.sh --gemini
```

### Windows (PowerShell)

```powershell
git clone https://github.com/vibhasdutta/loop-engineer.git
cd loop-engineer
.\install.ps1 -Gemini
```

### Verify

Restart Gemini CLI or run `/skills reload` inside a session, then describe a multi-step goal — the skill activates automatically. Use `/loop-engineer` as a shortcut (installed to `~/.gemini/commands/`).

---

## Antigravity

Each surface has its own global skills directory. The installer covers all three:
- **Antigravity CLI** (`agy`): `~/.gemini/antigravity-cli/skills/loop-engineer/`
- **Antigravity IDE** (VS Code / JetBrains): `~/.gemini/antigravity/skills/loop-engineer/`
- **Antigravity 2.0** (desktop): `~/.gemini/config/skills/loop-engineer/`

### macOS / Linux

```bash
git clone https://github.com/vibhasdutta/loop-engineer.git
cd loop-engineer && bash install.sh --antigravity
```

### Windows (PowerShell)

```powershell
git clone https://github.com/vibhasdutta/loop-engineer.git
cd loop-engineer
.\install.ps1 -Antigravity
```

### Post-install

Copy `platforms/antigravity/AGENTS.md` to your project root for workspace context:
```bash
cp platforms/antigravity/AGENTS.md /path/to/your/project/AGENTS.md
```

### Verify

**CLI**: type `/loop-engineer` in the `agy` prompt, or describe a multi-step goal.
**IDE**: open the agent panel → `...` → Customizations → Skills — confirm `loop-engineer` is listed.
**2.0**: open Settings → Customizations → Skills — confirm `loop-engineer` is listed.

---

## OpenCode

Installs to `~/.config/opencode/skills/loop-engineer/`.

> Note: OpenCode auto-discovers skills from `~/.claude/skills/` too — if you have Claude Code installed, the skill is already available. The OpenCode-specific install adds native `task`-tool agent files and the `/loop-engineer` command.

### macOS / Linux

```bash
git clone https://github.com/vibhasdutta/loop-engineer.git
cd loop-engineer && bash install.sh --opencode
```

### Windows (PowerShell)

```powershell
git clone https://github.com/vibhasdutta/loop-engineer.git
cd loop-engineer
.\install.ps1 -OpenCode
```

### Verify

Restart OpenCode, then type `/loop-engineer` in any project. Or describe a multi-step goal — the skill activates via the native `skill` tool.

---

## Hermes Agent

Installs to `~/.hermes/skills/loop-engineer/`.

### macOS / Linux

```bash
git clone https://github.com/vibhasdutta/loop-engineer.git
cd loop-engineer && bash install.sh --hermes
```

### Windows (PowerShell)

```powershell
git clone https://github.com/vibhasdutta/loop-engineer.git
cd loop-engineer
.\install.ps1 -Hermes
```

### Post-install

Copy `platforms/hermes/HERMES.md` to your project root for workspace context:
```bash
cp platforms/hermes/HERMES.md /path/to/your/project/HERMES.md
```

This file is auto-injected into every Hermes session in that project directory.

### Verify

In any Hermes session, type `/loop-engineer` or describe a multi-step goal. Use `hermes skills` in the terminal to confirm the skill appears.

---

## Codex CLI

Installs to `~/.codex/skills/loop-engineer/`. Requires Codex CLI v0.128.0+ with `features.multi_agent = true` in your Codex config.

### One-liner (macOS / Linux)

```bash
curl -s https://raw.githubusercontent.com/vibhasdutta/loop-engineer/main/install.sh | bash -s -- --codex
```

### Windows (PowerShell)

```powershell
git clone https://github.com/vibhasdutta/loop-engineer.git
cd loop-engineer
.\install.ps1 -Codex
```

### Verify

In a Codex session, type `/loop-engineer`. The skill scaffolds state files and prints the `/goal` command to paste for the actual loop run.

---

## Install all platforms at once

Installs Claude Code, Cursor, Gemini CLI, Codex CLI, OpenCode, and Hermes Agent.

**macOS / Linux:**
```bash
git clone https://github.com/vibhasdutta/loop-engineer.git
cd loop-engineer && bash install.sh --all
```

**Windows (PowerShell):**
```powershell
git clone https://github.com/vibhasdutta/loop-engineer.git
cd loop-engineer
.\install.ps1 -All
```
