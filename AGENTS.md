# dotfiles

## Claude Code / Codex skills

Personal skills do **not** live in this repo — they live in the private
`my-skills` repo (`~/my-skills`, github.com/r67018/my-skills), since skills may
contain personal information that shouldn't be in a public dotfiles repo. See
`~/my-skills/README.md` and its `skill-manager` skill for how they're wired up
and synced into `~/.claude/skills` / `~/.codex/skills`.

`.codex` is still a symlink to `.claude` at this repo's root for anything else
placed under `.claude/` (e.g. `settings.local.json`) — always edit under
`.claude/`, never write directly under `.codex/`.
