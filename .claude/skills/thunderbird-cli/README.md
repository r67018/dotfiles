# thunderbird-cli (vendored skill)

`SKILL.md` is copied verbatim from upstream — do not hand-edit it, or the diff
against upstream stops being meaningful.

- **Upstream**: <https://github.com/vitalio-sh/thunderbird-cli> (MIT), `skills/thunderbird-cli/`
- **Pinned rev**: `807f837060b3e611168f749bf47181566c6f99b8` (v1.0.2 + the skill commit)

The same rev is pinned in [`home-manager/modules/thunderbird-cli.nix`](../../../home-manager/modules/thunderbird-cli.nix),
which builds `tb` / `tb-bridge` / `tb-mcp`. **Bump both together.**

Upstream's own README described an `npm install -g` setup that does not apply
here, so it has been replaced by this note.

## How it reaches each agent

| Agent | Path | Managed by |
|---|---|---|
| Claude Code / Codex | `~/.claude/skills/thunderbird-cli`, `~/.codex/skills/thunderbird-cli` | `.claude/scripts/sync-skills.sh` (symlink) |
| Claude Desktop | Settings → Capabilities → Skills | manual zip upload — see below |

Claude Desktop's skills live on the Claude account and are synced down to a local
cache (`~/Library/Application Support/Claude/local-agent-mode-sessions/skills-plugin/`),
so that side cannot be managed from this repo — build a zip and upload it:

```bash
cd ~/dotfiles/.claude/skills && zip -r /tmp/thunderbird-cli-skill.zip thunderbird-cli
```

The skill only supplies usage recipes. The capability comes from the `thunderbird`
MCP server, which the nix module registers in `claude_desktop_config.json`.
