---
name: ship
description: Observe and orchestrate the autonomous PR flow — merge, CI, and Staging deploy. Use when observing the PR created by Finish traversing checks, approval, merge, and Staging deployment.
---

# SHIP

Use this skill to observe and orchestrate the autonomous Pull Request flow created by Finish.

For detailed Ship observation mechanics, read `references/workflow.md`.

## What Ship Is and Is NOT

**Ship does NOT perform deploy. Ship does NOT execute CI. Ship does NOT approve the PR.**

Ship is an **orchestrator and observer**.

- Who executes approval, merge, and workflows: **GitHub**
- Who executes pipelines and deploy: **GitHub Actions**
- Ship: **observes execution, emits events, reacts to failures**

**Trigger:** Pull Request created by Finish.
**Ship.Started:** emitted upon detecting the created PR — before observing any execution.
**Ship.Completed:** emitted only after merge is confirmed AND Staging deploy completes successfully.
**Ship.Completed means:** Feature available in its Staging environment (ephemeral per Feature/OBC).

If any CI step fails: Ship detects it, stops progression, and reports. Finish must be reopened for investigation.

## Environments

| Environment | Type | Purpose |
|---|---|---|
| Staging | Ephemeral per Feature/OBC | Validate exclusively the Feature in question. Destroyed after promotion. |
| Sandbox | Shared | Release Candidate. Receives only Ship-promoted Features via Promote. |
| Production | Operational | Outside the Delivery Journey. |

Ship observes the deploy to **Staging**. Sandbox and Production are outside Ship's scope.

## Inputs

- `AGENTS.md`
- `prodops/artifacts/plans/reliability/`
- `prodops/artifacts/trails/sessions/` (active session trail)
- PR created by Finish (number, URL, check status)

## Flow

1. Verify input context (work-item-id, iteration-id, actor, correlation-id).
2. Detect the PR created by Finish for the correct work-item.
3. Emit Ship.Started.
4. Observe execution of GitHub checks and workflows on the PR.
5. Observe automatic approval on the PR (executed by GitHub per repository rules).
6. Observe automatic merge of the PR (executed by GitHub per repository rules).
7. If any check or workflow fails: detect, stop progression, report failure. Finish must be reopened.
8. After merge is confirmed: observe triggering of the Staging deploy pipeline.
9. Observe the Staging deploy result.
10. If Staging deploy fails: detect, stop progression, report failure.
11. After Staging deploy completes successfully: record evidence in the Release Trail.
12. Emit Ship.Completed.

## Guardrails

- Do not perform deploy. Deploy is executed by GitHub Actions.
- Do not approve the PR. Approval is executed by GitHub.
- Do not merge the PR. Merge is executed by GitHub.
- Do not emit Ship.Completed before merge AND Staging deploy succeed.
- If any CI step fails: stop progression. Do not proceed to Promote. Report for investigation.
- Staging is ephemeral per Feature. Do not conflate Staging with Sandbox or Production.

## Engineering References

| Reference | When to read |
|---|---|
| [`references/workflow.md`](references/workflow.md) | Ship observation mechanics — how to detect PR, observe checks, merge and deploy |
