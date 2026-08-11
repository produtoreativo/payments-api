---
name: hack/start
description: Prepare the working branch before implementation. Check for incomplete work, sync the base branch, and create a correctly named feature branch.
---

# HACK → START

Prepare the git working context before the TDD cycle begins.

## Action

### 1. Check for incomplete work

Run `git status`. If the working tree is not clean, surface the options and wait for the developer's choice:

- **Commit** — if the current work is complete enough: run `/hack commit`, then return here.
- **Stash** — if the work is unrelated or not ready to commit: `git stash -u`
- **Stop** — if the scope of the uncommitted changes is unclear: surface as a blocker and do not proceed.

Never discard uncommitted work silently. Do not proceed until the working tree is clean.

### 2. Identify and checkout the base branch

Accept the base branch as a parameter. If not provided, ask:

> "What is the base branch for this work? (e.g. `main`, or a parent feature branch)"

Checkout the base branch:

```bash
git checkout <base-branch>
```

### 3. Sync the base branch

Bring the local base up to date with the remote:

```bash
git fetch origin --prune
git merge --ff-only origin/<base-branch>
```

If fast-forward fails, the base has diverged from remote. Surface the conflict — do not force-merge. Resolve before continuing.

### 4. Create the feature branch

Ask the developer:

> "What type of change is this? (`feat`, `fix`, `chore`, `refactor`, `docs`, `test`)"
> "Short slug for this capability? (e.g. `api-token-db`, `invoice-boleto`, `prodops-tdd-steps`)"

Create the branch from the updated base, setting the tracking upstream explicitly:

```bash
git checkout -b <type>/<short-slug> --track origin/<base-branch>
```

If a branch for this capability already exists, switch to it and surface any divergence:

```bash
git checkout <existing-branch>
git log --oneline -5
```

If the existing branch has diverged from the base, run `/sync` before continuing.

### 5. Confirm the starting point

```bash
git log --oneline -5
git status
```

Confirm the branch diverges from the correct base commit and the working tree is clean.

## Post-conditions

- Working tree is clean.
- Base branch is up-to-date with `origin`.
- Current branch is the correct feature branch, diverging from the updated base.
- Developer confirmed the branch type and slug.

## Guardrails

- Do not start implementation on `master`, `main`, or a shared base branch.
- Do not carry uncommitted changes from a previous task into the new branch.
- Do not create the branch from a stale local base — always sync first.
- If the feature branch already exists and has diverged, run `/sync` before continuing.
- Do not choose stash silently — always present the options and let the developer decide.
