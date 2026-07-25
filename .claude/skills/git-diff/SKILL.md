---
name: git-diff
description: Use when the user asks what the current uncommitted changes are or wants them explained — "git-diff", "差分を説明して", "今の変更を教えて", "何を変えたっけ", "explain my diff", "what changed", "review my working tree". Reads the working tree (staged, unstaged, and untracked) and reports the facts of the change, grouped by logical change, in as few words as possible. Read-only: never stages, commits, or edits anything.
---

# Explain the current diff

State **what changed**, factually and briefly. Group the hunks so the reader can see the
shape of the change without reading the patch — then stop. No assessment of the code, no
speculation about intent, no advice that wasn't asked for.

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
4. **Say they're untracked**, once, since that's the part `git commit -a` would silently
   miss and a reviewer needs to know.
5. **Don't skip the boring ones**, but do scale the detail: generated output, lockfiles,
   build artifacts, and files that `.gitignore` should probably cover get one line each —
   and flag the ones that look like they were never meant to be committed.

Binary or very large untracked files: report path, kind, and size instead of reading them.

## Structure the explanation by logical change

Group the hunks into logical changes — one feature, fix, or refactor per group — and lead
with those groups. The file list is supporting detail, not the outline.

Each group is **one bullet**: what changed, in the imperative like a commit subject, plus
the files as clickable `path:line` references. Add a second sentence only when the bullet
is unreadable without it — a renamed symbol's old and new name, which of several files
carries the real change.

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
- **Short bullets, no tables**, no per-file walkthrough of every hunk, no closing summary
  that repeats the bullets.
- **Don't paste the diff back.** Quote at most a line or two when the exact expression is
  the point.
- **Length follows the diff**: a typo fix gets one sentence; a large feature branch gets a
  handful of bullets. A summary longer than the diff it describes is a failure.
- Say plainly what the diff doesn't tell you — "この変更の意図は diff からは読み取れない" —
  instead of filling the gap with a plausible story.
