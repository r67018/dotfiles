---
name: suggest-command
description: Use when an installed skill or slash command covers the request you just handled and its name has not come up yet in this session — either nobody invoked it (the user said "コミットして" and you hand-rolled the commit instead of using `git-commit`) or it fired on its own from plain wording and the user never saw the name. Skip it entirely once every applicable command has already been named. Also use when the user asks outright which command they should have used — "今のってコマンドあった?", "もっといいやり方あった?", "使えるスキルある?", "was there a command for that?". Emits one `use command: /name` line, without redoing the work.
---

# Name the command behind what just happened

Tell the user, in one line, which command covers the request they just made — so they can
reach for it by name next time. Nothing more: no redoing the work, no lecture on how skills
work, no apology.

Two cases, both in scope:

- **Nobody used it.** You hand-rolled work that a skill was written for.
- **It fired on its own.** The skill triggered from the user's plain wording and they never
  typed the slash. **This still gets a line.** The user cannot type a command they don't
  know exists, and auto-triggering is not guaranteed — mentioning it is the whole point of
  this skill, not a redundancy.

## First: if it isn't too late, use it — then still name it

**Noticing before or while doing the work is not a suggestion opportunity — it's an
instruction to invoke the skill.** Call it with the Skill tool and carry on. Telling the
user "`/git-commit` の方が良かったですね" *after* hand-rolling the commit is strictly worse
for them than just having used it.

Invoking it doesn't end the job: name it once at the end anyway, in the format below.

## Only suggest what is actually installed

**Never invent a command name.** A suggestion the user can't type is worse than silence.

1. **Start from the available-skills listing already in your context.** That is the
   authoritative set for this session and it costs nothing to consult.
2. **Shell out only for what that listing doesn't cover** — user-defined slash commands and
   prompt files. Resolve the project paths from the repo root, not the cwd, or a session
   started in a subdirectory silently misses them:
   ```bash
   root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
   ls ~/.claude/skills ~/.claude/commands "$root"/.claude/skills "$root"/.claude/commands 2>/dev/null
   ls ~/.codex/skills ~/.codex/prompts "$root"/.codex/prompts 2>/dev/null
   ```
3. **Read the candidate's `description` before naming it.** The name lies often enough to
   matter: `/review` reviews a GitHub pull request and does nothing for the working tree,
   which `/code-review` handles. If the description doesn't actually cover what the user
   asked for, there is no line to emit.

## Match the invocation to the agent the user is in

This file is shared between Claude Code and Codex (`~/dotfiles/.codex` → `.claude`), so the
same skill fires in both. You know which one you are; `CLAUDECODE` is set in the
environment under Claude Code.

- **Claude Code** — personal and project skills are `/<name>`, plugin skills are
  `/<plugin>:<name>`, custom commands are the `.md` basename under `commands/`.
- **Codex** — files under `~/.codex/prompts/` are `/<basename>`; skills under
  `~/.codex/skills/` are picked up from their description, so name the skill
  ("`git-commit` スキル") rather than promising a slash command that may not exist.

Suggest only what exists in **the agent currently running**. A Claude Code plugin command
is not available to a Codex session, and vice versa.

## When it's worth saying

The bar is **does a real command own this request** — a skill whose description actually
covers what the user asked for, whether or not it ran.

Worth a line:

- **A skill handled the request without being asked for by name.** Say which one, so the
  user learns it. This is the common case and the reason the skill exists.
- The skill encodes the user's own policy that you didn't follow — splitting a diff into
  one commit per change, leaving off the `Co-Authored-By` trailer, the secret scan.
- You did several steps by hand that the skill does in one, and the hand-rolled version is
  visibly rougher.

Stay quiet:

- The skill merely overlaps the topic but doesn't actually cover the request.
- **The user invoked it themselves** by typing `/name` — they obviously know it.
- **You already named it once in this session.** One mention per command, ever. After that
  the user knows; repeating it is nagging.
- Built-ins the user obviously knows (`/clear`, `/help`, `/init`).

## How to say it

**One plain-text line, last, exactly this shape:**

use command: /git-diff

- **`use command:` is a literal fixed prefix** — lowercase `u`, in English, even when the
  rest of the reply is Japanese. It is a marker, not a sentence — a constant string stays
  scannable and never blends into the prose above it.
- **Plain text, never a code fence.** The line above is the literal output, not a sample to
  wrap in backticks. Fencing it would add a block to a reply that may already end with one.
- **Nothing else on the line.** No reason, no "次からは", no apology, no description of what
  the command does, no praise for the skill. Both cases — it fired on its own, and nobody
  used it — get the same bare line. If the user wants the why, they'll ask.
- **No slash form** — a Codex skill that is only picked up from its description — takes
  `use skill: git-commit` instead, lowercase the same way. Same rules otherwise.

### Where it goes

It is the **last line of prose** in the reply, below any other trailing line (a `git-commit`
offer, a "next step" sentence).

**One exception, and only this one:** when the reply is required to end with a fenced
command block — `git-commit` mandates a closing ```bash push block so the user can run it
with one click — that block stays at the very bottom and the marker sits directly above it.
Pushing a fence off the end of a reply costs the user a click; a marker line one row higher
costs nothing.

### More than one line

Only when the user asked outright what was available ("今の会話で使えたコマンドある?"): one
marker line per command, most relevant first, at most three, consecutive, with no prose
between them. Every other situation emits exactly one line, or none.

## When nothing covers it

No installed command fits → **emit no marker line at all**, and don't stretch for a near
match. Say "該当するコマンドはない" in one sentence only if the user asked outright;
otherwise say nothing.

If the same uncovered request keeps recurring across the session, that's worth one sentence
offering to build a skill for it with `skill-manager` — **don't create it unprompted**,
that's a bigger action than the user asked for.

## Never

- **Don't redo the work under the skill** to prove the point.
- **Don't apologize** for not having used it, and don't explain what skills are or how they
  trigger.
- **Don't emit the line twice for the same command** in one session, in any form.
