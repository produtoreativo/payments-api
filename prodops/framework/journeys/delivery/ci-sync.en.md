# CI Sync

CI Sync is the synchronous grouping of ProdOps Delivery. It represents work that is **local, collaborative, and engineer-driven**.

```
CI Sync: Bootstrap → Hack → Sync → Finish
```

## Purpose

CI Sync produces:
- Closed task
- PR with implementation narrative
- Test and lint evidence
- Organized commits following Conventional Commits
- Local validations executed

## Stages

### Bootstrap

Prepares the environment, creates the branch, and establishes the product context. Does not produce code — produces context.

Output: clean branch + ready environment + ProdOps artifacts read + contract verified.

→ [phases/bootstrap/README.md](phases/bootstrap/README.md)

### Hack

Implements with ProdOps TDD: Red Bar → Green Bar → Refactor → Commit.

Consumes:
- **Practice:** [ProdOps TDD](practices/prodops-tdd.md)
- **Capability:** [Commit Workflow](capabilities/commit-workflow/README.md)

→ [phases/hack/README.md](phases/hack/README.md)

### Sync

Two independent steps:

- **rebase** — synchronizes the feature branch with the base (fetch, integration, conflicts, validation)
- **align** — aligns ProdOps artifacts with the implementation (BDD Feature, Event Storming, architecture, Release Trail)

→ [phases/sync/README.md](phases/sync/README.md)

### Finish

Executes final Quality Gates and creates the PR with evidence.

→ [phases/finish/README.md](phases/finish/README.md)

## Capabilities used

| Capability | Stage |
|---|---|
| [Commit Workflow](capabilities/commit-workflow/README.md) | Hack, Sync, Finish |
| [Contract Management](capabilities/contract-management.md) | Bootstrap, Hack, Sync |
| [Evidence Management](capabilities/evidence-management.md) | Hack, Finish |
| [Observability](capabilities/observability.md) | Hack |
| [Reliability](capabilities/reliability.md) | Bootstrap, Hack, Finish |
