---
name: git-commit
description: Use when the user asks to commit changes, amend a commit, or fix up the previous commit — "コミットして", "commit this", "直前のコミットを直して", "amendして", "fixupして". Encodes this user's personal policy for choosing between a new commit and amending the previous one; always default to a new commit unless the user explicitly asks to amend.
---

# Git Commit Policy

**Default: always create a new commit.** Even if the current change looks like it "belongs with" the previous commit (same files, made minutes apart), do not amend on your own judgment — commit new, or ask if genuinely unsure what the user wants.

## When to amend instead

Only amend when the user explicitly asks for it in the current request — phrases like "amendして", "直前のコミットに含めて", "fixupして". A vague "this is related to my last commit" is not by itself a request to amend; if it's ambiguous, ask before touching history.

Before amending, confirm all of the following, in order:

1. **The target is HEAD.** Amend only rewrites the tip of the branch — never use it to reach further back than the most recent commit.
2. **It's unpushed.** Check `git log @{u}..HEAD` (or that the branch has no upstream at all). If the commit is already pushed, amending means a force-push is needed afterward — stop and get explicit confirmation for that too before proceeding.
3. **Show before amending.** Run `git show --stat HEAD` (or `git log -1`) and show the user the commit you're about to change, so a wrong target gets caught before it's rewritten.

If any check fails, or the request is ambiguous, fall back to a new commit and say why.

## Otherwise

Everything else — reviewing `git status`/`git diff`/`git log` for style, drafting the message, staging specific files, the HEREDOC format, the Co-Authored-By trailer, not using `-A`/`--no-verify`/`--no-gpg-sign` unless asked, not pushing unless asked — follows the standard commit workflow already in effect.
