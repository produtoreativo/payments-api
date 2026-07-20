---
name: validate
description: Validate release behavior with evidence, metrics, SLOs, and operational signals. Use when proving that an OBC, BDD scenario, or Reliability Plan item is satisfied.
---

# VALIDATE

Use this skill to prove release readiness with evidence.

## Inputs

- `AGENTS.md`
- Relevant OBCs under `prodops/`
- Relevant BDD Features in `prodops/artifacts/business/bdd/` (committed) or `prodops/journeys/discovery/experiments/<NNN-slug>/features/` (exploratory)
- `prodops/journeys/assessment/reliability-plans/`
- `prodops/journeys/delivery/phases/finish/quality-gates.md`

## Flow

1. Identify the capability, OBC, or risk being validated.
2. Select tests, metrics, logs, events, or SLO evidence that prove it.
3. Run validation commands or inspect existing evidence.
4. Record exact commands, observed result, and remaining risk.
5. Update only impacted validation or reliability artifacts.
6. Append evidence to the Release Trail.

## Guardrails

- Do not invent metrics or SLOs.
- If an SLO is absent, record the gap in the appropriate ProdOps artifact.
- Prefer executable evidence over narrative claims.

## Engineering References

| Reference | When to read |
|---|---|
| [`../references/engineering/tdd-prodops/quality-gates.md`](../references/engineering/tdd-prodops/quality-gates.md) | Evidence standards, Definition of Done, Test Quality Gates |
| [`../references/engineering/tdd-prodops/observability.md`](../references/engineering/tdd-prodops/observability.md) | What to verify in logs, traces, and correlation IDs |
