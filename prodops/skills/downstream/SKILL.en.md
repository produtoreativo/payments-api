---
name: downstream
description: Execute governed ProdOps delivery. Use when implementing approved backlog items, following the Reliability Plan, applying TDD, updating OBCs, running quality gates, validating observability, shipping, or promoting release work.
---

# DOWNSTREAM

Use this skill for standardized, traceable delivery.

## Inputs

- `AGENTS.md`
- `prodops/artifacts/product/`
- `prodops/journeys/assessment/reliability-plans/`
- `prodops/artifacts/plans/downstream-iteration-backlog.md`
- Relevant BDD Feature in `prodops/artifacts/bdd/`
- Relevant OBC in `prodops/artifacts/obcs/`
- Relevant quality gates in `prodops/journeys/delivery/phases/finish/quality-gates.md`

## Artifact placement rules

Before coding, ensure these artifacts exist in the correct locations:

- **BDD Feature** → `prodops/artifacts/bdd/<capability>.feature`
- **OBC** → `prodops/artifacts/obcs/<capability>.md`

Do not create Downstream BDD Features in experiment directories. Downstream BDD
Features belong only in `prodops/artifacts/bdd/`.
Do not create Downstream OBCs in experiment directories. Downstream OBCs belong
only in `prodops/artifacts/obcs/`.

## Flow

1. Confirm the item has status `Entrou` in the Iteration Plan at
   `prodops/artifacts/plans/iteration-plan.md` (section "Iteration Plan recomendado")
   or has an explicit release decision.
2. Read the relevant Current State, Assessment, BDD Feature, and Reliability Plan
   if one exists (recommended but not mandatory).
3. Execute the full flow:
   `Bootstrap -> Hack -> Sync -> Finish -> Ship -> Validate -> Promote`.
4. Use TDD for behavior changes.
5. Update impacted OBCs, BDDs, Reliability Plan items, and operational artifacts.
6. Validate with concrete evidence.
7. Append delivery evidence to the active session trail (`prodops/artifacts/trails/sessions/YYYY-MM-DD-<session-id>.md`).

## Guardrails

- Do not ship work that only has Upstream evidence.
- Do not skip Quality Gates without recording the reason and risk.
- Do not duplicate product context inside skills.
- Do not promote unresolved high-risk items without explicit acceptance.

## Engineering References

| Area | File | When to read |
|---|---|---|
| Clean Code | [`../references/engineering/clean-code/`](../references/engineering/clean-code/README.md) | Naming, functions, refactoring during Hack |
| TDD ProdOps | [`../references/engineering/tdd-prodops/`](../references/engineering/tdd-prodops/README.md) | Full TDD cycle, mocking policy, quality gates |
| DDD | [`../references/engineering/ddd/`](../references/engineering/ddd/README.md) | Domain model, aggregates, ubiquitous language |
