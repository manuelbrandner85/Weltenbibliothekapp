#!/bin/bash
# SessionStart hook: linkt alle Skills aus .agents/skills/ nach .claude/skills/
# Dynamisch — neue Skills in .agents/skills/ werden automatisch mitgelinkt.
# Idempotent — bereits vorhandene Symlinks/Ordner bleiben unangetastet.
# Custom-Skills (echte Ordner) werden nicht überschrieben.
set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
AGENTS_DIR="$PROJECT_DIR/.agents/skills"
CLAUDE_DIR="$PROJECT_DIR/.claude/skills"

if [ ! -d "$AGENTS_DIR" ]; then
  echo "[session-start] .agents/skills/ nicht gefunden — überspringe Skill-Linking." >&2
  exit 0
fi

mkdir -p "$CLAUDE_DIR"

linked=0
existing=0

for skill_dir in "$AGENTS_DIR"/*/; do
  [ -d "$skill_dir" ] || continue
  skill_name=$(basename "$skill_dir")
  target="$CLAUDE_DIR/$skill_name"

  if [ -L "$target" ] || [ -d "$target" ]; then
    existing=$((existing + 1))
    continue
  fi

  ln -s "$AGENTS_DIR/$skill_name" "$target"
  linked=$((linked + 1))
done

echo "[session-start] Skills: $linked neu verlinkt, $existing bereits vorhanden."
