---
name: sync/rebase
description: Synchronize the feature branch with its base. Use when the branch is behind origin, has conflicts to resolve, or needs to incorporate upstream changes before Finish.
---

# SYNC → REBASE

Execute only the branch synchronization step of the Sync flow.

**Responsabilidade:** garantir a **integridade do repositório git** — tornar o repositório pronto para merge, incorporando o estado mais recente da base na feature branch sem conflitos e sem enfraquecer testes. Este é um step de **git**, não de produto: ele não muda comportamento nem alinha artefatos ProdOps (isso é `align`).

For detailed mechanics, read [`../../references/workflow.md`](../../references/workflow.md).

## Action

### 1. Preflight — inspect working tree

```bash
git status --short
git branch --show-current
```

If the worktree has uncommitted changes, stop and surface the options:

- **Commit** — if the work is complete enough: run `/hack commit`, then return here.
- **Stash** — if the work is unrelated or not ready: `git stash -u`
- **Stop** — if the scope is unclear: surface as a blocker. Do not proceed.

Never discard uncommitted work silently.

### 2. Fetch and inspect

```bash
git fetch --all --prune
git branch -vv
git log --oneline --decorate --graph --max-count=30 --all
git rev-list --left-right --count <base>...HEAD
```

Infer the base branch in this order: upstream of current branch → `origin/HEAD` → `origin/main` → `origin/master`.

### 3. Update the base (fast-forward only)

```bash
git switch <base>
git pull --ff-only
```

If fast-forward fails, report the divergence — do not force it.

### 4. Integrate base into the feature branch

```bash
git switch <work-branch>
git rebase <base>     # prefer rebase; use merge only when explicitly requested
```

If the branch has already been pushed to `origin`, follow the rebase with:

```bash
git push --force-with-lease
```

`--force-with-lease` is safe: it aborts the push if anyone else has modified the remote branch since the last fetch. Only use bare `--force` if explicitly requested.

### 5. Resolve conflicts

For each conflict:

```bash
git status --short
git diff --name-only --diff-filter=U
```

Open conflicted files, understand both sides, edit to a coherent final state, then stage and continue:

```bash
git add <resolved-paths>
git commit             # for merge
# git rebase --continue  # for rebase
```

### 6. Preserve TDD

- Keep tests that document the feature branch behavior.
- Keep upstream tests that document new base behavior.
- When expectations conflict, write or update the test first to define the merged expected behavior, then change production code to satisfy it.
- Never remove assertions, skip tests, or loosen checks only to complete a sync.

### 7. Validate — post-integration smoke, not quality gates

This validation only certifies that the integration did not break the green history left by Hack. It is **not** a quality gate: do not add new coverage, fix inherited code smells, or refactor here. If the integrated history is red, the conflict resolution is incomplete — return to step 5.

Run tests and lint for all touched packages:

```bash
cd api && npm run lint
cd api && npm run test
```

Run broader validation when shared contracts, lockfiles, config, or generated artifacts changed.

Finish with:

```bash
git status --short --branch
```

## Post-conditions

**Critério de conclusão — integridade do repositório git:** concluído quando **todos** os itens abaixo são verdadeiros, simultaneamente:

- Working tree is clean.
- Base branch is up-to-date with `origin`.
- Feature branch incorporates the latest base.
- All tests pass on the merged/rebased history.
- No assertions were removed or weakened to complete the sync.

## Guardrails

- Do not discard uncommitted changes without developer approval.
- Do not force-push or rewrite shared branch history.
- Do not auto-stash unknown user work without surfacing the choice.
- Do not remove or weaken tests just to make synchronization pass.
- If conflicts occur, inspect both sides before editing.

## Out of scope — not the responsibility of `rebase`

- `rebase` **does not** open a pull request — that is Finish.
- `rebase` **does not** run the full CI pipeline — that is Ship.
- `rebase` **does not** add test coverage or fix code smells inherited from the base — it only verifies that the integration did not break the green history left by Hack. New coverage belongs to Hack (Yellow Bar); quality gates belong to Finish.
- `rebase` **does not** rewrite product decisions or align ProdOps artifacts — that is `align`.
- `rebase` **does not** touch artifacts in `prodops/` to satisfy a conflict resolution. A conflict that requires changing a committed BDD Feature or OBC must surface as a blocker, not be silently rewritten here.
