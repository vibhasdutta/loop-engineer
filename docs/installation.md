# Installation

## Requirements

| Skill | Platform | Minimum version |
|---|---|---|
| `/loop-engineer` | [Claude Code](https://claude.ai/code) (CLI or desktop app) | any |
| `/loop-engineer` | [Cursor](https://cursor.com) | any |
| `/loop-engineer` | [Gemini CLI](https://github.com/google-gemini/gemini-cli) | any |
| `/loop-engineer` | [Antigravity](https://deepmind.google/technologies/gemini/antigravity/) | any |
| `/loop-engineer-codex` | [Codex CLI](https://github.com/openai/codex) | 0.128.0+ |

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

Then register the extension:
```bash
gemini extension install ~/.gemini/skills/loop-engineer
```

### Verify

Describe a multi-step goal to Gemini CLI — the skill activates automatically.

---

## Antigravity

Installs to `~/.gemini/skills/loop-engineer/`.

### macOS / Linux

```bash
git clone https://github.com/vibhasdutta/loop-engineer.git
cd loop-engineer && bash install.sh --antigravity
```

Also copy `platforms/antigravity/AGENTS.md` to your project root for workspace context.

---

## Codex CLI

Installs to `~/.codex/skills/loop-engineer-codex/`.

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

In a Codex session, type `/loop-engineer-codex` in any project.

---

## Install all platforms at once

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
