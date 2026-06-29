#!/bin/bash
# Loop Engineer — skill installer
# Usage:
#   bash install.sh              → Claude Code (default)
#   bash install.sh --cursor     → Cursor
#   bash install.sh --gemini     → Gemini CLI
#   bash install.sh --antigravity → Antigravity (agy)
#   bash install.sh --codex      → OpenAI Codex CLI
#   bash install.sh --opencode   → OpenCode
#   bash install.sh --hermes     → Hermes Agent
#   bash install.sh --all        → all platforms
#   curl -s https://raw.githubusercontent.com/vibhasdutta/loop-engineer/main/install.sh | bash

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
MODE="${1:-}"

install_claude() {
  local dir="${HOME}/.claude/skills/loop-engineer"
  mkdir -p "$dir/agents"
  cp "$REPO_DIR/platforms/claude/SKILL.md" "$dir/SKILL.md"
  cp "$REPO_DIR/platforms/claude/agents/"*.md "$dir/agents/"
  echo "Claude Code: installed to $dir"
  echo "Restart Claude Code, then use /loop-engineer in any project."
}

install_cursor() {
  local dir="${HOME}/.cursor/skills/loop-engineer"
  mkdir -p "$dir/agents"
  cp "$REPO_DIR/platforms/cursor/SKILL.md" "$dir/SKILL.md"
  cp "$REPO_DIR/platforms/cursor/agents/"*.md "$dir/agents/"
  echo "Cursor: installed to $dir"
  echo "Restart Cursor, then use /loop-engineer in any project."
}

install_gemini() {
  local dir="${HOME}/.gemini/skills/loop-engineer"
  mkdir -p "$dir/agents"
  cp "$REPO_DIR/platforms/gemini/SKILL.md" "$dir/SKILL.md"
  cp "$REPO_DIR/platforms/gemini/GEMINI.md" "$dir/GEMINI.md"
  cp "$REPO_DIR/platforms/gemini/gemini-extension.json" "$dir/gemini-extension.json"
  cp "$REPO_DIR/platforms/gemini/agents/"*.md "$dir/agents/"
  if [ -d "$REPO_DIR/platforms/gemini/commands" ]; then
    mkdir -p "${HOME}/.gemini/commands"
    cp "$REPO_DIR/platforms/gemini/commands/"*.toml "${HOME}/.gemini/commands/" 2>/dev/null || true
  fi
  echo "Gemini CLI: installed to $dir"
  echo "Restart Gemini CLI or run '/skills reload' inside a session to activate."
}

install_antigravity() {
  # CLI (agy): ~/.gemini/antigravity-cli/skills/
  local cli_dir="${HOME}/.gemini/antigravity-cli/skills/loop-engineer"
  mkdir -p "$cli_dir/agents"
  cp "$REPO_DIR/platforms/antigravity/SKILL.md" "$cli_dir/SKILL.md"
  cp "$REPO_DIR/platforms/antigravity/AGENTS.md" "$cli_dir/AGENTS.md"
  cp "$REPO_DIR/platforms/antigravity/agents/"*.md "$cli_dir/agents/"
  echo "Antigravity CLI (agy): installed to $cli_dir"

  # IDE (VS Code / JetBrains extension): ~/.gemini/antigravity/skills/
  local ide_dir="${HOME}/.gemini/antigravity/skills/loop-engineer"
  mkdir -p "$ide_dir/agents"
  cp "$REPO_DIR/platforms/antigravity/SKILL.md" "$ide_dir/SKILL.md"
  cp "$REPO_DIR/platforms/antigravity/AGENTS.md" "$ide_dir/AGENTS.md"
  cp "$REPO_DIR/platforms/antigravity/agents/"*.md "$ide_dir/agents/"
  echo "Antigravity IDE: installed to $ide_dir"

  # 2.0 desktop: ~/.gemini/config/skills/
  local app_dir="${HOME}/.gemini/config/skills/loop-engineer"
  mkdir -p "$app_dir/agents"
  cp "$REPO_DIR/platforms/antigravity/SKILL.md" "$app_dir/SKILL.md"
  cp "$REPO_DIR/platforms/antigravity/AGENTS.md" "$app_dir/AGENTS.md"
  cp "$REPO_DIR/platforms/antigravity/agents/"*.md "$app_dir/agents/"
  echo "Antigravity 2.0 desktop: installed to $app_dir"

  echo "Copy platforms/antigravity/AGENTS.md to your project root for workspace context."
}

install_opencode() {
  local dir="${HOME}/.config/opencode/skills/loop-engineer"
  mkdir -p "$dir/agents"
  cp "$REPO_DIR/platforms/opencode/SKILL.md" "$dir/SKILL.md"
  cp "$REPO_DIR/platforms/opencode/AGENTS.md" "$dir/AGENTS.md"
  cp "$REPO_DIR/platforms/opencode/agents/"*.md "$dir/agents/"
  if [ -d "$REPO_DIR/platforms/opencode/commands" ]; then
    mkdir -p "${HOME}/.config/opencode/commands"
    cp "$REPO_DIR/platforms/opencode/commands/"*.md "${HOME}/.config/opencode/commands/" 2>/dev/null || true
  fi
  echo "OpenCode: installed to $dir"
  echo "Restart OpenCode or use /loop-engineer in any session."
}

install_codex() {
  local dir="${HOME}/.codex/skills/loop-engineer"
  mkdir -p "$dir/agents"
  cp "$REPO_DIR/platforms/codex/SKILL.md" "$dir/SKILL.md"
  cp "$REPO_DIR/platforms/codex/agents/"*.toml "$dir/agents/"
  echo "Codex CLI: installed to $dir"
  echo "Use /loop-engineer in any Codex session."
}

install_hermes() {
  local dir="${HOME}/.hermes/skills/loop-engineer"
  mkdir -p "$dir/agents"
  cp "$REPO_DIR/platforms/hermes/SKILL.md" "$dir/SKILL.md"
  cp "$REPO_DIR/platforms/hermes/HERMES.md" "$dir/HERMES.md"
  cp "$REPO_DIR/platforms/hermes/agents/"*.md "$dir/agents/"
  echo "Hermes Agent: installed to $dir"
  echo "Copy platforms/hermes/HERMES.md to your project root for workspace context."
  echo "Use /loop-engineer in any Hermes session."
}

case "$MODE" in
  --cursor)      install_cursor ;;
  --gemini)      install_gemini ;;
  --antigravity) install_antigravity ;;
  --codex)       install_codex ;;
  --opencode)    install_opencode ;;
  --hermes)      install_hermes ;;
  --all)         install_claude && install_cursor && install_gemini && install_codex && install_opencode && install_hermes ;;
  *)             install_claude ;;
esac
