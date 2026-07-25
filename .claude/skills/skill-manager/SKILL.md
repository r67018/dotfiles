---
name: skill-manager
description: Use when the user wants to create, add, register, remove, or sync a personal Claude Code / Codex skill that should live in the ~/dotfiles repo and be available globally (not just in one project) — e.g. "新しいスキルを作って", "このスキルをdotfilesに追加して", "スキルをグローバルに使えるようにして", "skill-managerでスキル作って". Also use when skills stop showing up after being added or edited, since that usually means the sync step was skipped. This skill only handles *where a skill lives and how it gets linked*; for guidance on writing high-quality SKILL.md content itself, pair it with the general-purpose skill-creator skill.
---

# Skill Manager

Manages personal skills stored in `~/dotfiles/.claude/skills/`, shared between Claude Code and Codex.

## How this repo is wired

- **Canonical source**: `~/dotfiles/.claude/skills/<skill-name>/SKILL.md` (plus optional `scripts/`, `references/`, `assets/` subdirs).
- **`~/dotfiles/.codex` is a symlink to `~/dotfiles/.claude`** (repo-root level), so anything under `.claude/` is automatically mirrored under `.codex/` too. Never create real files directly under `.codex/` — always write under `.claude/`.
- **`~/.claude/skills` and `~/.codex/skills` are real directories on the user's machine**, not symlinked wholesale — they may contain content this repo doesn't own (Codex's own `.system/` skills, skills from other repos, etc). So each skill gets its own individual symlink into those two directories, via `.claude/scripts/sync-skills.sh`.

```
~/dotfiles/.claude/skills/<name>/SKILL.md   <- canonical, edit here
~/dotfiles/.codex/skills/<name>/SKILL.md    <- same file, via .codex -> .claude
~/.claude/skills/<name>  -> ~/dotfiles/.claude/skills/<name>   (per-skill symlink)
~/.codex/skills/<name>   -> ~/dotfiles/.codex/skills/<name>    (per-skill symlink)
```

## Creating a new skill

1. **Check for name collisions**: `ls ~/dotfiles/.claude/skills` and skim `~/.claude/skills` / `~/.codex/skills` for anything similar. Pick a distinct kebab-case name.
2. **Scaffold the directory**: `~/dotfiles/.claude/skills/<name>/SKILL.md`, with YAML frontmatter (`name`, `description`) and a body. If you want deeper guidance on writing an effective description and body (trigger phrasing, when-to-use vs when-to-skip, splitting long reference material into `references/`), invoke the `skill-creator` skill for that part — this skill only covers placement and distribution.
3. **Register + sync**: run the sync script so the skill becomes usable globally, not just when Claude/Codex happens to be pointed at the dotfiles repo:
   ```bash
   ~/dotfiles/.claude/scripts/sync-skills.sh
   ```
   It is idempotent — safe to re-run any time. It links every skill under `.claude/skills/` into `~/.claude/skills/<name>` and `~/.codex/skills/<name>`, skipping anything already linked correctly, and warns (without overwriting) if `<target>/<name>` already exists as a real file or directory.
4. **Verify**: confirm both symlinks exist and resolve into the dotfiles repo:
   ```bash
   ls -la ~/.claude/skills/<name> ~/.codex/skills/<name>
   ```

## Editing an existing skill

Edit the file under `~/dotfiles/.claude/skills/<name>/` directly — the symlinks mean the change is already live everywhere. No sync needed unless the skill's directory name changes.

## Renaming or removing a skill

The sync script only ever creates links; it does not clean up stale ones.

- **Rename**: `mv` the directory under `.claude/skills/`, then re-run `sync-skills.sh` to create the new link, then manually `rm ~/.claude/skills/<old-name> ~/.codex/skills/<old-name>`.
- **Remove**: `rm -rf ~/dotfiles/.claude/skills/<name>`, then manually remove the now-dangling symlinks: `rm ~/.claude/skills/<name> ~/.codex/skills/<name>`.

## Committing

`~/dotfiles` is a git repo. After adding or changing a skill, stage and commit the files under `.claude/skills/` (the `.codex` entries are the same files via the symlink, so git only tracks the `.claude/` side) — but only commit when the user asks for it.
