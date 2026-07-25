#!/usr/bin/env bash
# Symlinks every skill under .claude/skills/<name> into each agent's local
# skills directory (~/.claude/skills/<name>, ~/.codex/skills/<name>).
#
# Both ~/.claude/skills and ~/.codex/skills are real directories that may
# hold content not owned by this repo (e.g. Codex's own ".system" skills),
# so we link one skill at a time instead of symlinking the whole directory.
#
# Run this after adding, renaming, or removing a skill directory under
# .claude/skills/.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REPO_SKILLS_DIR="$REPO_ROOT/.claude/skills"

TARGET_DIRS=(
  "$HOME/.claude/skills"
  "$HOME/.codex/skills"
)

for target_dir in "${TARGET_DIRS[@]}"; do
  mkdir -p "$target_dir"

  for skill_path in "$REPO_SKILLS_DIR"/*/; do
    [ -d "$skill_path" ] || continue
    skill_name="$(basename "$skill_path")"
    target="$target_dir/$skill_name"

    if [ -L "$target" ]; then
      current="$(readlink "$target")"
      if [ "$current" = "${skill_path%/}" ]; then
        echo "ok: $target already linked"
      else
        echo "warning: $target symlink points elsewhere ($current), leaving as-is" >&2
      fi
      continue
    fi

    if [ -e "$target" ]; then
      echo "warning: $target exists and is not a symlink, skipping" >&2
      continue
    fi

    ln -s "${skill_path%/}" "$target"
    echo "linked: $target -> ${skill_path%/}"
  done
done
