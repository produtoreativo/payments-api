# SYNC Workflow

SYNC is the synchronization phase. The agent repeats the work engineers did manually: fetch newest code, update local branches, integrate current base, resolve conflicts, preserve TDD evidence, validate.

## Preflight

```sh
git status --short
git branch --show-current
git remote -v
git remote show origin
```

If the worktree has uncommitted changes:

- Continue only when the changes are clearly yours and part of the current task.
- Otherwise stop and ask how to handle them.

## Fetch and Inspect

```sh
git fetch --all --prune
git branch -vv
git status --short --branch
```

Infer base branch in this order:

1. Upstream branch of the current branch, when it is a base branch.
2. `origin/HEAD`.
3. `origin/main`.
4. `origin/master`.
5. Repo-specific branch named by the user.

Compare:

```sh
git log --oneline --decorate --graph --max-count=30 --all
git rev-list --left-right --count <base>...HEAD
```

## Update Base

Switch to the local base and fast-forward only:

```sh
git switch <base>
git pull --ff-only
```

If fast-forward fails, do not force it. Report the branch divergence.

## Integrate Base into Work Branch

Switch back:

```sh
git switch <work-branch>
```

Prefer merge unless the repo or user explicitly prefers rebase:

```sh
git merge <base>
```

Use rebase only when requested or clearly established:

```sh
git rebase <base>
```

## Resolve Conflicts

For each conflict:

```sh
git status --short
git diff --name-only --diff-filter=U
```

Open conflicted files, understand both sides, edit to a coherent final state, then:

```sh
git add <resolved-paths>
```

For merge:

```sh
git commit
```

For rebase:

```sh
git rebase --continue
```

## Preserve TDD

- Keep tests that document the feature branch behavior.
- Keep upstream tests that document new base behavior.
- When expectations conflict, write or update the test first to define the merged expected behavior.
- Then change production code to satisfy the merged test suite.
- Never remove assertions, skip tests, or loosen checks only to complete a sync.

## Validate

- Run tests/builds for touched packages.
- Run broader validation when shared contracts, lockfiles, config, or generated artifacts changed.
- Finish with:

```sh
git status --short --branch
```
