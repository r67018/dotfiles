---
name: git-diff
description: Use when the user asks what the current uncommitted changes are or wants them explained — "git-diff", "差分を説明して", "今の変更を教えて", "何を変えたっけ", "explain my diff", "what changed", "review my working tree". Reads the working tree (staged, unstaged, and untracked) and reports the facts: an overview of each logical change, then — for the groups whose behavior needs it — the key code quoted in syntax-highlighted blocks with inline comments explaining how it behaves. Read-only: never stages, commits, or edits anything.
---

# Explain the current diff

State **what changed** and **how the new code behaves** — first as a short overview, then as
annotated code where the behavior isn't already clear from the overview. Facts only: no
assessment of the code, no speculation about intent, no advice that wasn't asked for.

## Read-only

**This skill never modifies anything.** No `git add`, `git commit`, `git stash`,
`git checkout`, no edits to files. If the user wants the changes committed afterwards,
that's the `git-commit` skill's job — offer it in one line, don't do it unprompted.

## Gather the whole picture

Run these before saying anything (they're cheap, and skipping one is how untracked files
get missed):

```bash
git status --short --branch --untracked-files=all
git diff --stat
git diff
git diff --staged
git ls-files --others --exclude-standard
```

- **Staged and unstaged are different diffs.** Look at both, and say which is which when
  it matters (e.g. "this part is already staged").
- **If the diff is large**, work from `git diff --stat` first to find the shape of the
  change, then read the interesting hunks in full. Don't summarize from filenames alone.
- The tree counts as clean only when there is **no** diff *and* no untracked file. If it's
  clean, say so and stop — don't fall back to explaining the last commit unless asked.

## Untracked files get explained, not just listed

New files never show up in `git diff`, and plain `git status --short` collapses a whole new
directory into a single `dir/` line — so an untracked file is the easiest thing to
under-report and usually the most important part of the change. Treat every untracked path
as an addition diff of the entire file.

1. **Enumerate them individually.** `--untracked-files=all` / `git ls-files --others
   --exclude-standard` expand collapsed directories. Never report a directory as one item.
2. **Read every one of them** with the Read tool before writing the summary — the whole
   file if it's small, the structure plus the substantive parts if it's large. A file you
   created earlier in this same session still gets read back; don't summarize it from
   memory.
3. **State what each file contains** — its role and entry points, in a line or two — in the
   same logical-change grouping as the tracked edits, not in a separate "新規ファイル" list.
   A whole new file is all "added" lines, so if it earns an annotated block at all, quote
   only its core (the exported entry point, the main branch) — never the entire file.
4. **Say they're untracked**, once, since that's the part `git commit -a` would silently
   miss and a reviewer needs to know.
5. **Don't skip the boring ones**, but do scale the detail: generated output, lockfiles,
   build artifacts, and files that `.gitignore` should probably cover get one line each —
   and flag the ones that look like they were never meant to be committed.

Binary or very large untracked files: report path, kind, and size instead of reading them.

## Output shape: overview first, then annotated code

Two passes over the same material, in this order. Don't interleave them — the reader
should be able to stop after the overview.

### 1. Overview

Group the hunks into logical changes — one feature, fix, or refactor per group — and open
with those groups, **one bullet each**: what changed, in the imperative like a commit
subject, plus the files as clickable `path:line` references. The file list is supporting
detail, not the outline. Add a second sentence only when the bullet is unreadable without
it — a renamed symbol's old and new name, which of several files carries the real change.

### 2. Annotated code — when the change is code

**Decide per group whether a block earns its place.** This pass is for groups whose behavior
isn't already conveyed by the overview bullet. Skip it, and end after the overview, when:

- **The changed file is prose** — Markdown, plain text, a `SKILL.md`, a commit template.
  Prose has no comment syntax to annotate with, and a block of quoted paragraphs explains
  nothing the bullet didn't. Quote at most a phrase inline when the exact wording is the
  point.
- **The change is mechanical** — a typo, a rename, a version bump, a moved line. There is no
  behavior to explain.
- **The bullet already said it.** A block that restates its own overview line is noise.

For the groups that do earn one, quote the lines that carry the change in a fenced block and
explain the behavior **in comments on the code itself**:

- **Tag the fence with the source language** (`ts`, `nix`, `bash`, `py`) so it gets syntax
  highlighting. Use a `diff` fence only when a removal is the point of the change, since
  `diff` highlighting shows +/- but loses the language colors.
- **If the quoted lines themselves contain a fence** — a code block inside a Markdown or
  YAML file — open and close the outer block with **four** backticks so the inner fence
  doesn't terminate it early. If nesting still garbles it, drop the block and describe the
  lines in prose.
- **Show the post-change state**, not the raw patch. Strip the `+` markers.
- **Excerpt, don't dump.** Only the lines that carry the change, plus whatever surrounding
  line makes them parse. Elide the rest with a comment (`// …`, `# …`). Never reproduce a
  whole file this way.
- **Comment only what isn't already obvious from the line** — the condition being guarded,
  what a flag changes, what an early return skips, which branch the common case takes.
  Every line does not need a comment.
- Write the comments in the file's own comment syntax and in the user's language.
- **The `path:line` reference lives in the overview bullet, not above the block.** Repeat it
  over a block only when the group spans several files and the block would otherwise be
  ambiguous.
- **These comments are annotations for the reply, not a proposed edit.** Never write them
  into the file.

State the stated reason for a change only when the diff itself carries it (a comment, a
docstring, a removed workaround). Otherwise report the change and stop; **don't infer
motives, don't guess at the bug being fixed.** If the user wants the why, they'll ask.

Only these get flagged, and only when actually present, one line each:

- **Secrets or credentials** in the diff — `path:line` and the kind, **never the value**.
- **Facts that are invisible in the patch** but true of it: a behavior change under
  existing call sites, a config key added in one place and read in another, an untracked
  file that `git commit -a` would skip.
- **Several unrelated changes in one tree** — say so and name the groups.

## Style

- **Match the user's language.** They write Japanese → answer in Japanese.
- **Facts only.** No evaluation of the code (clean, well-structured, careful), no praise,
  no suggestions for improvement, no "問題ありません" reassurance. Nothing about the process
  you used to gather the diff.
- **Short bullets, no tables**, no closing summary that repeats the overview.
- **The quoted code is an excerpt, never a replay of the patch.** If the annotated blocks
  add up to most of the diff, you're quoting too much — cut back to the lines that carry
  the change.
- **Length follows the diff**: a typo fix gets one sentence; a large feature branch gets a
  bullet per group. How many of those groups also get a block is decided by the gate in
  "Annotated code", not by the size of the diff — a big prose-only change still gets none.
- Say plainly what the diff doesn't tell you — "この変更の意図は diff からは読み取れない" —
  instead of filling the gap with a plausible story.
