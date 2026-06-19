#!/usr/bin/env bash
#
# Symlink every skill in this repo into ~/.claude/skills so Claude Code and
# the Claude desktop app (Cowork) pick them up. Both read from ~/.claude/skills.
#
# Idempotent: safe to re-run after adding or renaming skills.
# Run from anywhere: ./claude/link-skills.sh

set -euo pipefail

# Resolve this script's directory so the repo path is correct regardless of cwd.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$SCRIPT_DIR/skills"
DEST="$HOME/.claude/skills"

mkdir -p "$DEST"

for dir in "$SRC"/*/; do
  [ -d "$dir" ] || continue
  name="$(basename "$dir")"
  ln -sfn "$dir" "$DEST/$name"
  echo "linked $name -> $DEST/$name"
done

echo "Done. Restart your Claude session/app to load skill changes."
