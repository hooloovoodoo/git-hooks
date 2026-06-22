# HLV git hooks

Shared client-side git hooks for `hooloovoodoo` repos. Installed **once per
machine** (global `core.hooksPath`) — not copied into each repo. The hooks
no-op on repos whose `origin` isn't under `hooloovoodoo`, so they're safe to
leave on globally.

## Install / update

```bash
curl -sL https://raw.githubusercontent.com/hooloovoodoo/git-hooks/master/install.sh | bash
```

This sets `git config --global core.hooksPath ~/.git-hooks` and pulls the latest
release. Re-run any time to update.

## What runs

| Hook | Enforces (org repos only) |
|---|---|
| `pre-commit`  | commit email is `*@hooloovoo.rs`; **blocks committing secrets** (`.env`, `.pgpass`, `.s3cfg`, `ops.env`, `*.pem`/`*.key`, ssh/aws keys, private-key/AWS-key content) |
| `commit-msg`  | subject is `<TICKET> #comment <msg>` (e.g. `LET-2949 #comment …`); `Merge`/`Revert`/`fixup!`/`squash!` exempt |
| `pre-push`    | branch starts with `feature/ bugfix/ release/ hotfix/ docs/ chore/` |

The secret denylist is intentionally kept in sync with the Falcon Claude Code
guards (`falcon-cc-suite` `guard-files.sh` / `guard-bash.sh`) so the agent and
the human commit path block the same files.

Escape hatch for a deliberate exception: `git commit --no-verify`.

## Two layers: global policy + repo-local checks

- **Org policy** (above) is uniform for every repo → installed **once per
  machine** here.
- **Stack-specific checks** (ruff/black, spotless, eslint, type-checks) differ
  per repo → they live **in the repo**, versioned with the code.

`pre-commit` bridges the two: after the policy checks it runs an executable
`.githooks/pre-commit` from the repo root if one exists. Because the global
install already set `core.hooksPath`, a repo-local hook runs automatically for
everyone — **no per-clone `install` step** (unlike husky / pre-commit / lefthook).

Example `.githooks/pre-commit` in a Python repo:

```bash
#!/usr/bin/env bash
# Fast, staged-only linting for early local detection.
files=$(git diff --cached --name-only --diff-filter=ACM | grep '\.py$') || exit 0
[ -z "$files" ] && exit 0
ruff check $files && black --check $files
```

## These are convenience, not the gate

Client-side hooks are bypassable (`--no-verify`) and only run if installed. The
**authoritative** enforcement is server-side: GitHub branch protection + a CI
check mirroring these same rules. Treat these hooks as fast local feedback that
catches mistakes before they reach CI — not as the boundary itself.
