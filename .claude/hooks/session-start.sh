#!/bin/bash
# SessionStart hook: linkt 16 externe Skills aus .agents/skills/ nach .claude/skills/
# Idempotent — bereits vorhandene Symlinks/Ordner bleiben unangetastet.
set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
SRC_DIR="$PROJECT_DIR/.agents/skills"
DST_DIR="$PROJECT_DIR/.claude/skills"

REQUIRED_SKILLS=(
  cloudflare
  dart-add-unit-test
  dart-fix-runtime-errors
  dart-resolve-package-conflicts
  dart-run-static-analysis
  durable-objects
  flutter-add-integration-test
  flutter-add-widget-test
  flutter-apply-architecture-best-practices
  flutter-build-responsive-layout
  flutter-fix-layout-issues
  flutter-implement-json-serialization
  livekit-agents
  supabase
  supabase-postgres-best-practices
  wrangler
)

if [ ! -d "$SRC_DIR" ]; then
  echo "[session-start] .agents/skills/ nicht vorhanden — überspringe Skill-Linking." >&2
  exit 0
fi

mkdir -p "$DST_DIR"

linked=0
existing=0
missing_source=0

for skill in "${REQUIRED_SKILLS[@]}"; do
  src="$SRC_DIR/$skill"
  dst="$DST_DIR/$skill"

  if [ -e "$dst" ] || [ -L "$dst" ]; then
    existing=$((existing + 1))
    continue
  fi

  if [ ! -d "$src" ]; then
    echo "[session-start] WARN: Source fehlt für '$skill' ($src)" >&2
    missing_source=$((missing_source + 1))
    continue
  fi

  ln -s "../../.agents/skills/$skill" "$dst"
  linked=$((linked + 1))
done

echo "[session-start] $linked Skills verlinkt, $existing bereits vorhanden$([ $missing_source -gt 0 ] && echo ", $missing_source Source-Ordner fehlen" || echo "")."
