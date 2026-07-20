---
name: promote
description: Approve and close a release stage. Use when moving a release forward after validation, quality gates, and operational readiness are complete.
---

# PROMOTE

Use this skill to move a release to the next stage or close it.

## Inputs

- `AGENTS.md`
- `prodops/journeys/assessment/reliability-plans/`
- `prodops/artifacts/governance/trails/sessions/` (active session trail)
- `prodops/journeys/delivery/phases/finish/done-criteria.md`
- `prodops/journeys/operation/`

## Flow

1. Confirm required validation and quality gates are complete.
2. Confirm unresolved risks are accepted, mitigated, or moved to follow-up.
3. Check operational readiness: incidents, runbooks, postmortems, and
   operational trail.
4. Record approval, evidence, and remaining next steps.
5. Append promotion or closure notes to the Release Trail.

## Guardrails

- Do not promote when required evidence is missing.
- Do not silently accept unresolved high-risk items.
- Do not replace Release Trail history; append a new entry.
