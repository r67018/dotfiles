---
name: git-commit
description: Use when the user asks to commit changes, amend a commit, or fix up the previous commit — "コミットして", "commit this", "直前のコミットを直して", "amendして", "fixupして". Encodes this user's personal policy for choosing between a new commit and amending the previous one, and for splitting a diff that contains several unrelated changes into one commit per change; always default to a new commit unless the user explicitly asks to amend, and refuse to commit secrets found in the diff.
---

# Git Commit Policy

**Default: always create a new commit.** Even if the current change looks like it "belongs with" the previous commit (same files, made minutes apart), do not amend on your own judgment — commit new, or ask if genuinely unsure what the user wants.

## First: scan the diff for secrets

**Before staging anything, read the diff and check for credentials or other sensitive
data. If you find any, do not stage or commit it — stop and warn the user.** This check
comes before everything else on this page, and it applies even when the user says "全部
コミットして" or has already approved a split.

What to stop on:

- API keys, tokens, session cookies, OAuth client secrets, webhook URLs with tokens
- Passwords, and connection strings that embed credentials (`postgres://user:pass@…`)
- Private keys and certificate/keystore files (`-----BEGIN … PRIVATE KEY-----`, `.pem`,
  `.p12`, `.key`, `id_rsa`, `.jks`)
- Cloud credentials (`AKIA…`, service-account JSON, `~/.aws/credentials`, kubeconfigs)
- Files that normally hold secrets: `.env`, `.env.*`, `credentials.json`, `secrets.yaml`,
  `*.tfstate`
- Personal data that doesn't belong in a public repo: real email addresses of third
  parties, phone numbers, home addresses, license keys

High-entropy strings that merely *look* like keys, obvious placeholders
(`YOUR_API_KEY_HERE`, `xxxx`), test fixtures, and public identifiers (client IDs, public
keys) are not secrets — don't block on them.

**When the diff is clean, say nothing about the scan.** No "機密情報はありませんでした",
no "✅ secrets check passed", no mention of having looked. The check is silent by default;
it only ever produces output when something is actually found. If a borderline case is
genuinely worth a second opinion, raise that one item in a sentence — but never report a
clean result.

How to warn:

1. **Don't commit.** Leave the change unstaged (`git restore --staged <path>` if you
   already staged it). Never "commit it for now and fix it later".
2. **Name the location, not the value.** Report `path:line` and what kind of secret it
   looks like. Do not echo the secret itself into your reply, a commit message, or a file.
3. **Suggest the fix**: move it to an environment variable / secret manager / `sops`-style
   encrypted file, add the path to `.gitignore`, and replace it with a placeholder.
4. **Check history too.** If the same secret is already in an earlier commit, say so —
   removing it from the working tree does not remove it from history, and the credential
   should be treated as leaked and rotated regardless of what happens to the repo.
5. **Commit the rest if it's clean.** Unrelated, secret-free groups can still be committed;
   say explicitly which files you held back and why.

Only commit a flagged change if the user explicitly confirms it's safe (e.g. it's an
encrypted value, or a deliberately public test key) in the current request.

## One commit per logical change

**Before committing, read the full diff and check whether it contains more than one
logical change.** If it does, split it into separate commits — one per feature, fix, or
refactor — instead of dumping everything into a single commit. This applies even when the
user just says "コミットして" without mentioning splitting.

Signals that a diff holds multiple changes:

- Unrelated features or bug fixes touching different areas of the codebase
- A refactor/rename mixed in with a behavior change
- Formatting or dependency/lockfile churn alongside real logic changes
- Changes whose commit message would need "and" or a bullet list to describe honestly

How to split:

1. Group the hunks by logical change and decide the commit order — put prerequisites
   (refactors, helpers, dependency bumps) before the changes that build on them.
2. Show the user the planned split (one line per commit: message + files) before starting.
3. Stage each group explicitly with `git add <paths>` — never `git add -A`/`.`. When a
   single file contains hunks belonging to different groups, split within the file rather
   than lumping it in: `git add -p` is not available in this environment, so use
   `git apply --cached` with a filtered patch, or commit the file with whichever group it
   truly belongs to and say so.
4. Commit each group, then verify with `git status` that nothing was left staged or
   forgotten.

Don't over-split: a change and the test that covers it, or a rename and the call sites it
touches, belong in one commit. If a clean split isn't possible without breaking the build
at intermediate commits, keep them together and say why.

## When to amend instead

Only amend when the user explicitly asks for it in the current request — phrases like "amendして", "直前のコミットに含めて", "fixupして". A vague "this is related to my last commit" is not by itself a request to amend; if it's ambiguous, ask before touching history.

Before amending, confirm all of the following, in order:

1. **The target is HEAD.** Amend only rewrites the tip of the branch — never use it to reach further back than the most recent commit.
2. **It's unpushed.** Check `git log @{u}..HEAD` (or that the branch has no upstream at all). If the commit is already pushed, amending means a force-push is needed afterward — stop and get explicit confirmation for that too before proceeding.
3. **Show before amending.** Run `git show --stat HEAD` (or `git log -1`) and show the user the commit you're about to change, so a wrong target gets caught before it's rewritten.

If any check fails, or the request is ambiguous, fall back to a new commit and say why.

## Message format

**Do not add a `Co-Authored-By: Claude ...` trailer or any other AI-authorship note.** This user does not want commits to record that they were made with AI assistance — omit that trailer even though it's part of the generic default commit workflow.

## After committing: offer the push command

**Never run `git push` yourself** unless the user explicitly asked you to push in the
current request. Instead, once the commit(s) are made, end your reply with the exact push
command in its own ```bash fenced block, so the user can run it with one click if they
want to:

````
```bash
git push
```
````

Rules for the offered command:

- **One command, one fenced block** — no leading `$`, no comments, nothing else inside the
  fence. If several commits were made, still offer a single `git push`; it pushes them all.
- **No upstream yet?** Offer `git push -u origin <branch>` with the real branch name filled
  in, not a placeholder.
- **After amending a commit that was already pushed**, offer
  `git push --force-with-lease` (never plain `--force`), and say in one line that this
  rewrites remote history.
- Add at most one short sentence of context above the block (e.g. which branch it goes to).
  Don't explain what `git push` does.

## Otherwise

Everything else — reviewing `git status`/`git diff`/`git log` for style, drafting the message, staging specific files, the HEREDOC format, not using `-A`/`--no-verify`/`--no-gpg-sign` unless asked — follows the standard commit workflow already in effect.
