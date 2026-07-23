# Skills

Skills represent executable behavior used by agents. Each skill is self-contained — it describes what to do, when to enter, what to read, and what to produce.

Skills are **not** conceptual documentation, templates, or capabilities.

## Delivery Skills (CI Sync / CI Async phases)

| Skill | Phase | Link |
|---|---|---|
| Bootstrap | Prepare context, branch, and environment before Hack | [bootstrap/SKILL.md](bootstrap/SKILL.md) |
| Hack | TDD implementation: start → tdd → commit | [hack/SKILL.md](hack/SKILL.md) |
| Sync | Synchronize branch with base or artifacts with implementation | [sync/SKILL.md](sync/SKILL.md) |
| Finish | Evaluate done criteria and quality gates at completion | [finish/SKILL.md](finish/SKILL.md) |
| Ship | Prepare PR, release, deploy, and final readiness | [ship/SKILL.md](ship/SKILL.md) |
| Validate | Validate behavior with evidence, SLOs, and metrics | [validate/SKILL.md](validate/SKILL.md) |
| Promote | Approve and close a release stage | [promote/SKILL.md](promote/SKILL.md) |

### Hack Steps

| Step | Responsibility | Link |
|---|---|---|
| `hack/start` | Clean working tree, sync base, create branch | [hack/steps/start/SKILL.md](hack/steps/start/SKILL.md) |
| `hack/tdd` | Red → Green → Refactor cycle against BDD Feature | [hack/steps/tdd/SKILL.md](hack/steps/tdd/SKILL.md) |
| `hack/commit` | Review diff, create Conventional Commits commit | [hack/steps/commit/SKILL.md](hack/steps/commit/SKILL.md) |

## Journey Skills

| Skill | Journey | Link |
|---|---|---|
| Upstream | Discovery — exploration, experiments, prototypes | [upstream/SKILL.md](upstream/SKILL.md) |
| Downstream | Downstream mode — readiness and governed delivery | [downstream/SKILL.md](downstream/SKILL.md) |
| Diligence | Diligence — synchronization, drift, and workspace reconciliation | [diligence/SKILL.md](diligence/SKILL.md) |

### Upstream Steps

| Step | Responsibility | Link |
|---|---|---|
| `upstream/move-to-downstream` | Promote a completed experiment to Downstream | [upstream/steps/move-to-downstream/SKILL.md](upstream/steps/move-to-downstream/SKILL.md) |
| `upstream/deploy-to-sandbox` | Deploy experimental branch to AWS sandbox | [upstream/steps/deploy-to-sandbox/SKILL.md](upstream/steps/deploy-to-sandbox/SKILL.md) |

### Diligence Commands

| Command | Responsibility | Link |
|---|---|---|
| `diligence-sync` | Capture → Attach → Promote → Close for one OBC | [diligence/diligence-sync/SKILL.md](diligence/diligence-sync/SKILL.md) |
| `diligence-async` | Scan → Flag → Repair across all active OBCs and Issues | [diligence/diligence-async/SKILL.md](diligence/diligence-async/SKILL.md) |
| `workspace-reconciliation` | Inspect → Reconcile → Verify the GitHub Workspace | [diligence/workspace-reconciliation/SKILL.md](diligence/workspace-reconciliation/SKILL.md) |

## Product Skills (`skills/local/`)

Skills maintained in this repository. They are not part of the canonical
Framework and must not be distributed to other products. They may consume the
Framework; the Framework does not depend on them. See [`local/README.en.md`](local/README.en.md).

| Skill | Purpose | Link |
|---|---|---|
| `payments-api-local-testing` | Run and validate local tests with payment contracts | [local/payments-api-local-testing/SKILL.md](local/payments-api-local-testing/SKILL.md) |

## Engineering References

Knowledge bases used by agents — these are not executable skills. See [`references/README.en.md`](references/README.en.md) for the full index.

### Canonical References (Framework)

| Reference | Content | Link |
|---|---|---|
| TDD ProdOps | TDD practice in the ProdOps context | [references/engineering/tdd-prodops/](references/engineering/tdd-prodops/) |

### Product-local References

Literature and conventions adopted by this product. Framework Skills do **not** depend on them as requirements; they are optional guidance available at [`references/local/`](references/local/).

| Reference | Content | Link |
|---|---|---|
| Clean Code | Clean code principles and practices | [references/local/engineering/clean-code/](references/local/engineering/clean-code/) |
| DDD | Domain-Driven Design applied to the product | [references/local/engineering/ddd/](references/local/engineering/ddd/) |

## Skill Structure

Each Skill must contain:
- **Objective** — what the skill does
- **When to use** — entry condition
- **Inputs** — consumed artifacts
- **Outputs** — produced artifacts
- **Steps** — execution sequence with links to step files
