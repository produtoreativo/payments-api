---
name: hack/commit
description: Stage and commit completed implementation work. Use after tests are green, lint is clean, and the Release Trail has been updated.
---

# HACK → COMMIT

Execute only the commit step of the Hack flow.

## Action

1. Run `git status` — identify all modified, staged and untracked files.
2. Review the diff (`git diff`) — confirm scope matches the task; check for
   secrets, tokens, local-only paths or unrelated changes.
3. Stage only files changed by this task using explicit paths — never `git add -A`
   or `git add .`.
4. Compose a commit message following conventional commits:
   - Format: `type(scope): description`
   - Types: `feat`, `fix`, `docs`, `test`, `refactor`, `perf`, `build`, `ci`,
     `style`, `chore`, `revert` — canonical list in `prodops/exec/manifest.yaml`
     (`vocabulary.commit_types`), enforced by the commit-msg hook
   - Scope: package or area changed (`api`, `prodops`, `workbench`, etc.)
   - Description: one line, imperative, lowercase, no period, summary within
     72 characters (`vocabulary.commit_summary_max` in the manifest)
   - Example: `fix(api): use invoiceId as externalReference to avoid mock collision`
5. Run `git commit -m "<message>"`.
6. Run `git status` to confirm the working tree is clean for committed files.

## Post-conditions

- Commit exists in local history.
- Working tree is clean for all staged files.
- No secrets or unrelated files in the commit.

## Guardrails

- Do not commit if any pre-condition is unmet — stop and surface the gap.
- Do not use `git add -A`, `git add .` or wildcard patterns.
- Do not include files from unrelated tasks in the same commit.
- Do not commit `.env`, credential files or files containing real tokens.
- Do not amend a previous commit — always create a new one.
- If a pre-commit hook fails, fix the root cause; never use `--no-verify`.
