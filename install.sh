#!/bin/bash
# Loop Engineer — skill installer
# Usage:
#   bash install.sh              → installs for Claude Code
#   bash install.sh --codex      → installs for Codex CLI
#   bash install.sh --both       → installs for both
#   curl -s https://raw.githubusercontent.com/vibhasdutta/loop-engineer/main/install.sh | bash

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
MODE="${1:-}"

install_claude() {
  local dir="${HOME}/.claude/skills/loop-engineer"
  mkdir -p "$dir"
  cp "$REPO_DIR/skills/loop-engineer/SKILL.md" "$dir/SKILL.md"
  echo "Claude Code: installed to $dir"
  echo "Restart Claude Code, then use /loop-engineer in any project."
}

install_codex() {
  local dir="${HOME}/.codex/skills/loop-engineer-codex"
  mkdir -p "$dir"
  cp "$REPO_DIR/skills/loop-engineer-codex/SKILL.md" "$dir/SKILL.md"
  echo "Codex CLI: installed to $dir"
  echo "Use /loop-engineer-codex in any Codex session."
}

case "$MODE" in
  --codex) install_codex ;;
  --both)  install_claude && install_codex ;;
  *)       install_claude ;;
esac
