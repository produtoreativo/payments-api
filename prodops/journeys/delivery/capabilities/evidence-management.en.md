# Capability — Evidence Management

## Objective

Capture, preserve, and present evidence from each step of the delivery flow, ensuring traceability from decision to deploy.

## Responsibilities

- Record test evidence (Red Bar confirmed, Green Bar, acceptance)
- Record lint and build evidence
- Update the Release Trail after each relevant Downstream step
- Record post-deploy validation evidence
- Record promotion with formal approval

## Consuming flows

| Flow | Evidence produced |
|---|---|
| Hack | Red Bar confirmed, Green Bar, lint |
| Finish | Quality Gates evidence (lint, tests, build) |
| Validate | Logs, metrics, SLO signals, BDD scenarios in staging |
| Promote | Release Trail entry, approval, Rollback Readiness |

## Produced artifacts

- Release Trail entries: `prodops/artifacts/governance/trails/sessions/YYYY-MM-DD-<session-id>.md` (active session trail)
- Upstream Trail entries: `prodops/journeys/discovery/experiments/<id>/upstream-trail.md`
- PR filled with evidence (template: `prodops/journeys/delivery/capabilities/commit-workflow/templates/pull_request.md`)

## Dependencies

- Release Trail: `prodops/artifacts/governance/trails/sessions/` (active session trail)
- Task-closing template: `prodops/journeys/delivery/capabilities/commit-workflow/templates/task-closing.md`
