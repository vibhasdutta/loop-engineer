# Installation

## Requirements

| Skill | Platform | Minimum version |
|---|---|---|
| `/loop-engineer` | [Claude Code](https://claude.ai/code) (CLI or desktop app) | any |
| `/loop-engineer-codex` | [Codex CLI](https://github.com/openai/codex) | 0.128.0+ |

---

## Claude Code

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

### Plugin system (recommended — auto-updates)

Paste into your Claude Code session:

> Add `loop-engineer` from `https://github.com/vibhasdutta/loop-engineer.git` to my Claude Code plugins and enable it.

Or add manually to `~/.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "loop-engineer-market": {
      "source": {
        "source": "git",
        "url": "https://github.com/vibhasdutta/loop-engineer.git"
      }
    }
  },
  "enabledPlugins": {
    "loop-engineer@loop-engineer-market": true
  }
}
```

### Manual (macOS / Linux)

```bash
git clone https://github.com/vibhasdutta/loop-engineer.git
cd loop-engineer && bash install.sh
```

### Verify

Restart Claude Code, then type `/loop-engineer` in any project.

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

### Manual (macOS / Linux)

```bash
mkdir -p ~/.codex/skills/loop-engineer-codex
curl -s https://raw.githubusercontent.com/vibhasdutta/loop-engineer/main/skills/loop-engineer-codex/SKILL.md \
  > ~/.codex/skills/loop-engineer-codex/SKILL.md
```

### Verify

In a Codex session, type `/loop-engineer-codex` in any project.

---

## Install both at once

**macOS / Linux:**
```bash
git clone https://github.com/vibhasdutta/loop-engineer.git
cd loop-engineer && bash install.sh --both
```

**Windows (PowerShell):**
```powershell
git clone https://github.com/vibhasdutta/loop-engineer.git
cd loop-engineer
.\install.ps1 -Both
```
