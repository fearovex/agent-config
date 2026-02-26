#!/usr/bin/env bash
# install.sh — Deploys repo configuration to ~/.claude/ (the Claude Code runtime).
#
# Direction : repo/  →  ~/.claude/
# Scope     : ALL directories (CLAUDE.md, settings.json, skills/, hooks/, openspec/, ai-context/, memory/)
# Note      : memory/ flows the REVERSE direction via sync.sh — run sync.sh periodically
#             to capture Claude's automatic memory updates back into the repo.
#
# When to run:
#   Workflow A (config changes): edit repo → bash install.sh → git commit
#   New machine setup          : git clone → bash install.sh

set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "Installing claude-config → $CLAUDE_DIR ..."

mkdir -p "$CLAUDE_DIR"
mkdir -p "$CLAUDE_DIR/memory"
mkdir -p "$CLAUDE_DIR/skills"
mkdir -p "$CLAUDE_DIR/hooks"
mkdir -p "$CLAUDE_DIR/openspec"
mkdir -p "$CLAUDE_DIR/ai-context"

# Copy single files
cp "$REPO_DIR/CLAUDE.md"      "$CLAUDE_DIR/CLAUDE.md"
cp "$REPO_DIR/settings.json"  "$CLAUDE_DIR/settings.json"

# Copy directories (cross-platform: no rsync required)
copy_dir() {
  local src="$1"
  local dst="$2"
  if [ -d "$src" ]; then
    mkdir -p "$dst"
    cp -r "$src/." "$dst/"
  fi
}

copy_dir "$REPO_DIR/memory"     "$CLAUDE_DIR/memory"
copy_dir "$REPO_DIR/skills"     "$CLAUDE_DIR/skills"
copy_dir "$REPO_DIR/hooks"      "$CLAUDE_DIR/hooks"
copy_dir "$REPO_DIR/openspec"   "$CLAUDE_DIR/openspec"
copy_dir "$REPO_DIR/ai-context" "$CLAUDE_DIR/ai-context"

echo ""
echo "Registering MCP servers at user level..."
claude mcp remove github     2>/dev/null || true
claude mcp remove filesystem 2>/dev/null || true
claude mcp add -s user github \
  -e GITHUB_TOKEN="${GITHUB_TOKEN}" \
  -- cmd /c npx -y @modelcontextprotocol/server-github
claude mcp add -s user filesystem \
  -- cmd /c npx -y @modelcontextprotocol/server-filesystem .

echo ""
echo "Done! Claude Code is ready with:"
echo "  - CLAUDE.md (SDD orchestrator)"
echo "  - $(ls "$CLAUDE_DIR/skills/" | wc -l) skills loaded"
echo "  - Memory at $CLAUDE_DIR/memory/"
echo "  - SDD config at $CLAUDE_DIR/openspec/"
echo "  - AI context at $CLAUDE_DIR/ai-context/"
echo "  - MCP: github + filesystem"
echo ""
echo "Note: settings.local.json is NOT restored — Claude Code generates it automatically."
echo "Note: ensure GITHUB_TOKEN is defined as a system environment variable."
