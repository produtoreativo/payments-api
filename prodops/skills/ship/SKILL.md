---
name: ship
description: Prepare deploy, pull request, or release readiness. Emits Ship.Started and Ship.Completed via prodops_emit_event.
---

# SHIP

Use this skill to prepare completed work for delivery.

For detailed Codex submission mechanics, read `references/workflow.md`.

## Required input context

Ler a context capsule em `prodops/artifacts/iterations/<iteration-id>/cards/<slug>/context.md`.
Campos obrigatórios:

- `work-item-id` — campo `work-item-id` da capsule
- `iteration-id` — campo `iteration-id`
- `correlation-id` — campo `correlation-id`
- `actor-player` — campo `actor-player`
- `pr-number` — campo `pr-number` da capsule (preenchido pelo Finish); se ausente, buscar via `gh pr list`
- `reliability-path` — campo `reliability-path` (SLOs para verificação de changeset)
- `session-trail-dir` — campo `session-trail-dir`

Se invocado standalone (sem capsule), gerar novo `correlation-id`.

## Capsule update — após deploy

Após confirmar o `infra-scope` do PR (dynamo/lambda/both/none via diff), atualizar o campo na capsule:

```
infra-scope: <dynamo|lambda|both|none>
```

## Preconditions

1. `prodops/skills/prodops-emit-event/SKILL.md` has been read.
2. The tool is available at `prodops/runtime/tools/emit-event/scripts/emit-event`.

## Phase: Ship.Started

**Moment**: after input context is verified, before any ship preparation work begins.

Emit:

```json
{
  "event": "Delivery.Ship.Started",
  "work-item-id": "<work-item-id>",
  "iteration-id": "<iteration-id>",
  "correlation-id": "<correlation-id>",
  "execution-id": "<new-uuid>",
  "actor": { "player": "<player>", "agent": "ship-agent" },
  "payload": {}
}
```

If the tool returns `status: error`: report the error, fix the input, do not proceed.

## Phase: Ship.Completed

**Moment**: after all ship steps complete and PR/deploy notes are prepared — before reporting success.

Emit using the **same `correlation-id`** as Ship.Started:

```json
{
  "event": "Delivery.Ship.Completed",
  "work-item-id": "<work-item-id>",
  "iteration-id": "<iteration-id>",
  "correlation-id": "<same-uuid-as-started>",
  "execution-id": "<new-uuid>",
  "actor": { "player": "<player>", "agent": "ship-agent" },
  "payload": {}
}
```

Do not emit `Ship.Completed` if security checks, quality gates, or PR preparation is incomplete.

## Inputs

- `AGENTS.md`
- `prodops/artifacts/plans/reliability/`
- `prodops/artifacts/trails/sessions/` (active session trail)
- `prodops/framework/journeys/delivery/phases/finish/quality-gates.md`
- Current branch diff and validation evidence

## Infra scope declaration

Before waiting for the merge, declare which infrastructure stacks the issue touches. Read the PR diff:

```bash
gh pr diff <number> --name-only
```

Map changed paths to stacks:

| Changed path | Stack affected |
|---|---|
| `api/infra/dynamodb.yaml` | `dynamo` |
| `api/infra/lambda.yaml` | `lambda` |
| `api/src/**` | `lambda` |
| None of the above | `none` |

Record the declared scope in the Ship.Started payload under `"infra-scope"`: one of `dynamo`, `lambda`, `both`, or `none`. This is used in step 5 to verify that only expected stacks were deployed.

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
5a. After deploy completes, verify the changeset matches the declared infra-scope:
   ```bash
   # For the DynamoDB stack (if dynamo scope):
   aws cloudformation describe-stack-events \
     --stack-name payments-api-dynamo-staging \
     --query "StackEvents[?ResourceStatus=='UPDATE_COMPLETE'].[LogicalResourceId,ResourceType]" \
     --output table
   # For the Lambda stack (if lambda scope):
   aws cloudformation describe-stack-events \
     --stack-name payments-api-staging \
     --query "StackEvents[?ResourceStatus=='UPDATE_COMPLETE'].[LogicalResourceId,ResourceType]" \
     --output table
   ```
   If the declared scope is `none` but a stack was deployed, or if unexpected resources changed (e.g., SQS queue updated when the issue didn't modify queue configuration), flag it as a drift finding before emitting `Ship.Completed`.
6. Confirm the staging environment is responsive after deploy.
7. Record the merge SHA, deploy run ID, infra-scope declared, and actual changed resources in the Release Trail.
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
