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
#   bash install.sh --copilot    → VS Code GitHub Copilot
#   bash install.sh --all        → all platforms
#   bash install.sh --update     → git pull + re-install Claude Code
#   bash install.sh --update --cursor → git pull + re-install Cursor
#   curl -s https://raw.githubusercontent.com/vibhasdutta/loop-engineer/main/install.sh | bash

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

UPDATE=false
MODE=""
for arg in "$@"; do
  case "$arg" in
    --update) UPDATE=true ;;
    *) [ -z "$MODE" ] && MODE="$arg" ;;
  esac
done

if $UPDATE; then
  if [ -d "$REPO_DIR/.git" ]; then
    echo "Pulling latest changes..."
    git -C "$REPO_DIR" pull
  fi
fi

_copy_scripts() {
  local dir="$1"
  mkdir -p "$dir/scripts"
  cp "$REPO_DIR/scripts/init-loop.sh"  "$dir/scripts/" 2>/dev/null || true
  cp "$REPO_DIR/scripts/init-loop.ps1" "$dir/scripts/" 2>/dev/null || true
}

_copy_knowledge_sources() {
  local platform_agents_dir="$1"
  local dest_agents_dir="$2"
  mkdir -p "$dest_agents_dir/knowledge-sources"
  cp "$platform_agents_dir/knowledge-sources/"*.md "$dest_agents_dir/knowledge-sources/" 2>/dev/null || true
}

install_claude() {
  local dir="${HOME}/.claude/skills/loop-engineer"
  mkdir -p "$dir/agents"
  cp "$REPO_DIR/platforms/claude/SKILL.md" "$dir/SKILL.md"
  cp "$REPO_DIR/platforms/claude/agents/"*.md "$dir/agents/"
  _copy_knowledge_sources "$REPO_DIR/platforms/claude/agents" "$dir/agents"
  _copy_scripts "$dir"
  echo "Claude Code: installed to $dir"
  echo "Restart Claude Code, then use /loop-engineer in any project."
}

install_cursor() {
  local dir="${HOME}/.cursor/skills/loop-engineer"
  mkdir -p "$dir/agents"
  cp "$REPO_DIR/platforms/cursor/SKILL.md" "$dir/SKILL.md"
  cp "$REPO_DIR/platforms/cursor/agents/"*.md "$dir/agents/"
  _copy_knowledge_sources "$REPO_DIR/platforms/cursor/agents" "$dir/agents"
  _copy_scripts "$dir"
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
  _copy_knowledge_sources "$REPO_DIR/platforms/gemini/agents" "$dir/agents"
  _copy_scripts "$dir"
  if [ -d "$REPO_DIR/platforms/gemini/commands" ]; then
    mkdir -p "${HOME}/.gemini/commands"
    cp "$REPO_DIR/platforms/gemini/commands/"*.toml "${HOME}/.gemini/commands/" 2>/dev/null || true
  fi
  echo "Gemini CLI: installed to $dir"
  echo "Restart Gemini CLI or run '/skills reload' inside a session to activate."
}

_install_antigravity_surface() {
  local dest="$1"
  mkdir -p "$dest/agents"
  cp "$REPO_DIR/platforms/antigravity/SKILL.md" "$dest/SKILL.md"
  cp "$REPO_DIR/platforms/antigravity/AGENTS.md" "$dest/AGENTS.md"
  cp "$REPO_DIR/platforms/antigravity/agents/"*.md "$dest/agents/"
  _copy_knowledge_sources "$REPO_DIR/platforms/antigravity/agents" "$dest/agents"
  _copy_scripts "$dest"
}

install_antigravity() {
  local cli_dir="${HOME}/.gemini/antigravity-cli/skills/loop-engineer"
  _install_antigravity_surface "$cli_dir"
  echo "Antigravity CLI (agy): installed to $cli_dir"

  local ide_dir="${HOME}/.gemini/antigravity/skills/loop-engineer"
  _install_antigravity_surface "$ide_dir"
  echo "Antigravity IDE: installed to $ide_dir"

  local app_dir="${HOME}/.gemini/config/skills/loop-engineer"
  _install_antigravity_surface "$app_dir"
  echo "Antigravity 2.0 desktop: installed to $app_dir"

  echo "Copy platforms/antigravity/AGENTS.md to your project root for workspace context."
}

install_opencode() {
  local dir="${HOME}/.config/opencode/skills/loop-engineer"
  mkdir -p "$dir/agents"
  cp "$REPO_DIR/platforms/opencode/SKILL.md" "$dir/SKILL.md"
  cp "$REPO_DIR/platforms/opencode/AGENTS.md" "$dir/AGENTS.md"
  cp "$REPO_DIR/platforms/opencode/agents/"*.md "$dir/agents/"
  _copy_knowledge_sources "$REPO_DIR/platforms/opencode/agents" "$dir/agents"
  _copy_scripts "$dir"
  if [ -d "$REPO_DIR/platforms/opencode/commands" ]; then
    mkdir -p "${HOME}/.config/opencode/commands"
    cp "$REPO_DIR/platforms/opencode/commands/"*.md "${HOME}/.config/opencode/commands/" 2>/dev/null || true
  fi
  echo "OpenCode: installed to $dir"
  echo "Restart OpenCode or use /loop-engineer in any session."
}

install_codex() {
  local dir="${HOME}/.codex/skills/loop-engineer"
  mkdir -p "$dir/agents" "$dir/knowledge-sources"
  cp "$REPO_DIR/platforms/codex/SKILL.md" "$dir/SKILL.md"
  cp "$REPO_DIR/platforms/codex/agents/"*.toml "$dir/agents/"
  cp "$REPO_DIR/platforms/codex/knowledge-sources/"*.md "$dir/knowledge-sources/" 2>/dev/null || true
  cp "$REPO_DIR/platforms/codex/knowledge-sources.md" "$dir/knowledge-sources.md" 2>/dev/null || true
  _copy_scripts "$dir"
  echo "Codex CLI: installed to $dir"
  echo "Use /loop-engineer in any Codex session."
}

install_hermes() {
  local dir="${HOME}/.hermes/skills/loop-engineer"
  mkdir -p "$dir/agents"
  cp "$REPO_DIR/platforms/hermes/SKILL.md" "$dir/SKILL.md"
  cp "$REPO_DIR/platforms/hermes/HERMES.md" "$dir/HERMES.md"
  cp "$REPO_DIR/platforms/hermes/agents/"*.md "$dir/agents/"
  _copy_knowledge_sources "$REPO_DIR/platforms/hermes/agents" "$dir/agents"
  _copy_scripts "$dir"
  echo "Hermes Agent: installed to $dir"
  echo "Copy platforms/hermes/HERMES.md to your project root for workspace context."
  echo "Use /loop-engineer in any Hermes session."
}

install_copilot() {
  local dir="${HOME}/.config/loop-engineer/copilot"
  mkdir -p "$dir/agents"
  cp "$REPO_DIR/platforms/copilot/SKILL.md" "$dir/SKILL.md"
  cp "$REPO_DIR/platforms/copilot/copilot-instructions.md" "$dir/copilot-instructions.md"
  cp "$REPO_DIR/platforms/copilot/agents/"*.md "$dir/agents/"
  _copy_scripts "$dir"
  echo "VS Code Copilot: installed to $dir"
  echo ""
  echo "Per-project setup (run from your project root):"
  echo "  bash $dir/scripts/init-loop.sh --loop-id <id> --goal \"<goal>\" --stop \"all tasks in loop-stack/<id>/PLAN.md checked\" --platform copilot"
  echo ""
  echo "Then in VS Code: open Copilot Chat in Agent mode, attach .github/prompts/loop-engineer.prompt.md via #, and describe your goal."
}

case "$MODE" in
  --cursor)      install_cursor ;;
  --gemini)      install_gemini ;;
  --antigravity) install_antigravity ;;
  --codex)       install_codex ;;
  --opencode)    install_opencode ;;
  --hermes)      install_hermes ;;
  --copilot)     install_copilot ;;
  --all)         install_claude && install_cursor && install_gemini && install_codex && install_opencode && install_hermes && install_copilot ;;
  *)             install_claude ;;
esac

if $UPDATE; then
  echo "loop-engineer updated to latest"
fi
