# dotfiles

## Claude Code / Codex skills

Personal skills live under `.claude/skills/<skill-name>/SKILL.md`. `.codex` is a
symlink to `.claude` at this repo's root, so the same files are visible under
`.codex/skills/` too — always edit under `.claude/`, never write directly under
`.codex/`.

`~/.claude/skills` and `~/.codex/skills` on the machine are real directories
(they hold content this repo doesn't own, e.g. Codex's own `.system/` skills),
so each skill gets its own symlink into those two directories rather than the
whole directory being symlinked.

**After adding, renaming, or removing a skill under `.claude/skills/`, run:**

```bash
.claude/scripts/sync-skills.sh
```

Idempotent — safe to re-run any time. Only creates missing links; renames/removals
need their stale symlinks removed manually (see the `skill-manager` skill for
details).

The `skill-manager` skill (`.claude/skills/skill-manager/`) automates this whole
workflow — use it whenever you want to add a new personal skill.
