---
name: promote
description: Promote the Feature from Staging to Sandbox (Release Candidate). Use when moving a Ship-completed Feature from its ephemeral Staging environment to the shared Sandbox.
---

# PROMOTE

Use this skill to promote a Feature from its ephemeral Staging environment to the shared Sandbox environment (Release Candidate).

## What Promote Is and Is NOT

**Promote does NOT publish to Production.**

**Promote starts only after Ship.Completed.**

Promote responsibilities:

- Confirm Ship.Completed was emitted before starting
- Promote the Feature from Staging to Sandbox
- Sandbox represents the **Release Candidate** — it is shared and receives only Ship-promoted Features
- Record promotion evidence in the Release Trail

**Production remains outside the Delivery Journey.** Production belongs to the subsequent operational process.

## Environments

| Environment | Type | Purpose |
|---|---|---|
| Staging | Ephemeral per Feature/OBC | Exclusive Feature validation. Destroyed after promotion. |
| Sandbox | Shared | Release Candidate. Origin of promotion to Production. |
| Production | Operational | Outside the Delivery Journey. |

## Inputs

- `AGENTS.md`
- `prodops/artifacts/plans/reliability/`
- `prodops/artifacts/trails/sessions/` (active session trail)
- `prodops/framework/journeys/delivery/phases/finish/done-criteria.md`
- Ship.Completed evidence for the work-item

## Flow

1. Confirm Ship.Completed was emitted for the correct work-item.
2. Confirm validation and quality gates are complete.
3. Confirm unresolved risks are accepted, mitigated, or moved to follow-up.
4. Execute promotion of the Feature from Staging to Sandbox.
5. Record approval, evidence, and next steps.
6. Append promotion entry to the Release Trail.

## Guardrails

- Do not promote when required evidence is missing.
- Do not promote before Ship.Completed is confirmed.
- Do not silently accept unresolved high-risk items.
- Do not replace Release Trail history; append a new entry.
- Do not promote to Production. Promote targets Sandbox only. Production is outside the Delivery Journey.
- Sandbox is the Release Candidate. It receives only Ship-promoted Features.
