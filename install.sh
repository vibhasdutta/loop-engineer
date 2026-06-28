#!/bin/bash
# Loop Engineer — skill installer
# Usage:
#   bash install.sh              → Claude Code (default)
#   bash install.sh --cursor     → Cursor
#   bash install.sh --gemini     → Gemini CLI
#   bash install.sh --antigravity → Antigravity (agy)
#   bash install.sh --codex      → OpenAI Codex CLI
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
  echo "Gemini CLI: installed to $dir"
  echo "Run: gemini extension install $dir"
}

install_antigravity() {
  local dir="${HOME}/.gemini/skills/loop-engineer"
  mkdir -p "$dir/agents"
  cp "$REPO_DIR/platforms/antigravity/SKILL.md" "$dir/SKILL.md"
  cp "$REPO_DIR/platforms/antigravity/agents/"*.md "$dir/agents/"
  echo "Antigravity: installed to $dir"
  echo "Copy platforms/antigravity/AGENTS.md to your project root."
}

install_codex() {
  local dir="${HOME}/.codex/skills/loop-engineer"
  mkdir -p "$dir/agents"
  cp "$REPO_DIR/platforms/codex/SKILL.md" "$dir/SKILL.md"
  cp "$REPO_DIR/platforms/codex/agents/"*.toml "$dir/agents/"
  echo "Codex CLI: installed to $dir"
  echo "Use /loop-engineer in any Codex session."
}

case "$MODE" in
  --cursor)      install_cursor ;;
  --gemini)      install_gemini ;;
  --antigravity) install_antigravity ;;
  --codex)       install_codex ;;
  --all)         install_claude && install_cursor && install_gemini && install_codex ;;
  *)             install_claude ;;
esac
