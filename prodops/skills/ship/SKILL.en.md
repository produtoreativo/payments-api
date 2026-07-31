---
name: ship
description: Prepare deploy, pull request, or release readiness. Use when packaging completed work for review, release, deployment, handoff, final quality gates, TDD evidence review, security checks, or PR preparation.
---

# SHIP

Use this skill to prepare completed work for delivery.

For detailed Codex submission mechanics, read `references/workflow.md`.

## Inputs

- `AGENTS.md`
- `prodops/artifacts/plans/reliability/`
- `prodops/artifacts/trails/sessions/` (active session trail)
- `prodops/framework/journeys/delivery/phases/finish/quality-gates.md`
- Current branch diff and validation evidence

## Flow

Ship observes — it does not execute the merge. The merge is performed
automatically by GitHub once all CI checks pass (auto-merge was enabled during
Finish). Ship's job is to confirm the merge happened and the staging deploy
succeeded.

1. Confirm `Finish.Completed` was emitted for this work item (check timeline).
2. Confirm the PR has auto-merge enabled:
   ```bash
   gh pr view <number> --json autoMergeRequest
   ```
   If auto-merge is not enabled, re-enable it:
   ```bash
   gh pr merge <number> --auto --squash
   ```
3. Poll until the PR is merged:
   ```bash
   gh pr view <number> --json state,mergedAt
   ```
   Check every 30 seconds; timeout after 20 minutes. If CI fails, surface the
   failing check and stop — do not force-merge.
4. Once the PR is merged, confirm the staging deploy workflow started:
   ```bash
   gh run list --workflow staging-deploy.yml --limit 3
   ```
5. Wait for the staging deploy to complete:
   ```bash
   gh run watch <run-id>
   ```
6. Confirm the staging environment is responsive after deploy.
7. Record the merge SHA, deploy run ID and result in the Release Trail.
8. Append shipping evidence to the Release Trail.

## Guardrails

- Do not merge manually. The only authorized merge path is GitHub auto-merge
  triggered by CI passing.
- Do not emit `Ship.Completed` if CI checks failed or the staging deploy failed.
- Do not force-push or bypass branch protection to unblock a failing CI check.
- Do not change business scope during ship observation.
- Do not commit secrets, real tokens, personal credentials or local-only paths.

## Engineering References

| Reference | When to read |
|---|---|
| [`../references/engineering/tdd-prodops/workflow.md`](../references/engineering/tdd-prodops/workflow.md) | TDD evidence standards (what counts as red/green/refactor proof) |
| [`../references/engineering/tdd-prodops/quality-gates.md`](../references/engineering/tdd-prodops/quality-gates.md) | Delivery gates checklist before creating a PR |
