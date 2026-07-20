---
name: ship
description: Prepare deploy, pull request, or release readiness. Use when packaging completed work for review, release, deployment, handoff, final quality gates, TDD evidence review, security checks, or PR preparation.
---

# SHIP

Use this skill to prepare completed work for delivery.

For detailed Codex submission mechanics, read `references/workflow.md`.

## Inputs

- `AGENTS.md`
- `prodops/journeys/assessment/reliability-plans/`
- `prodops/artifacts/governance/trails/sessions/` (active session trail)
- `prodops/journeys/delivery/phases/finish/quality-gates.md`
- Current branch diff and validation evidence

## Flow

1. Confirm the change maps to the current Reliability Plan or documented
   follow-up.
2. Confirm the branch and diff against the intended base.
3. Verify TDD evidence for behavior changes.
4. Run final quality gates: format, lint, build and tests appropriate to the
   changed files.
5. Run security checks for secrets, unsafe config, dependency changes and
   accidental environment leakage.
6. Review the diff as if doing code review.
7. Summarize changed behavior, impacted artifacts and deployment risk.
8. Identify rollback, monitoring and operational notes when applicable.
9. Prepare PR or deploy notes.
10. Append shipping evidence to the Release Trail.

## Guardrails

- Do not ship undocumented behavior changes.
- Do not present missing evidence as complete.
- Do not change business scope during ship preparation.
- Do not include unrelated changes in the PR or deployment package.
- Do not commit secrets, real tokens, personal credentials or local-only paths.
- Tests must cover changed behavior or the residual test gap must be explicit.
- Behavior changes must show TDD evidence or explain why TDD was not applicable.
- PR or deploy notes must explain behavior, validation and risk.

## Engineering References

| Reference | When to read |
|---|---|
| [`../references/engineering/tdd-prodops/workflow.md`](../references/engineering/tdd-prodops/workflow.md) | TDD evidence standards (what counts as red/green/refactor proof) |
| [`../references/engineering/tdd-prodops/quality-gates.md`](../references/engineering/tdd-prodops/quality-gates.md) | Delivery gates checklist before creating a PR |
