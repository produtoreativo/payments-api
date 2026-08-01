---
name: finish
description: Close technical work with quality gates. Emits Finish.Started and Finish.Completed via prodops_emit_event.
---

# FINISH

Use this skill to close a task with explicit quality evidence.

## Required input context

Ler a context capsule em `prodops/artifacts/iterations/<iteration-id>/cards/<slug>/context.md`.
Campos obrigatórios:

- `work-item-id` — campo `work-item-id` da capsule
- `iteration-id` — campo `iteration-id`
- `correlation-id` — campo `correlation-id`
- `actor-player` — campo `actor-player`
- `feature-branch` — campo `feature-branch` (branch a fazer push/PR)
- `base-branch` — campo `base-branch`
- `session-trail-dir` — campo `session-trail-dir` (onde gravar o trail)

Se invocado standalone (sem capsule), gerar novo `correlation-id`.

## Capsule update — após PR criado

Após abrir o PR com sucesso, atualizar o campo `pr-number` na capsule:

```
pr-number: <número do PR criado>
```

Isso elimina a necessidade de Ship e Promote buscarem o PR via `gh pr list`.

## Preconditions

1. `prodops/skills/prodops-emit-event/SKILL.md` has been read.
2. The tool is available at `prodops/runtime/tools/emit-event/scripts/emit-event`.

## Phase: Finish.Started

**Moment**: after input context is verified, before any quality gate work begins.

Emit:

```json
{
  "event": "Delivery.Finish.Started",
  "work-item-id": "<work-item-id>",
  "iteration-id": "<iteration-id>",
  "correlation-id": "<correlation-id>",
  "execution-id": "<new-uuid>",
  "actor": { "player": "<player>", "agent": "finish-agent" },
  "payload": {}
}
```

If the tool returns `status: error`: report the error, fix the input, do not proceed.

## Phase: Finish.Completed

**Moment**: after all quality gates pass and Release Trail evidence is appended — before reporting success.

Emit using the **same `correlation-id`** as Finish.Started:

```json
{
  "event": "Delivery.Finish.Completed",
  "work-item-id": "<work-item-id>",
  "iteration-id": "<iteration-id>",
  "correlation-id": "<same-uuid-as-started>",
  "execution-id": "<new-uuid>",
  "actor": { "player": "<player>", "agent": "finish-agent" },
  "payload": {}
}
```

Do not emit `Finish.Completed` if any quality gate fails or evidence is incomplete.

## Inputs

- `AGENTS.md`
- `prodops/framework/journeys/delivery/phases/finish/quality-gates.md`
- `prodops/framework/journeys/delivery/phases/finish/done-criteria.md`
- Current diff and test output

## Flow

1. Review changed files and confirm scope.
2. Check quality gates relevant to the task.
3. Run targeted validation and broader validation when risk warrants it.
4. Confirm ProdOps artifacts were updated only where impacted.
5. Confirm Release Trail evidence exists.
6. Push the feature branch and open the PR:
   ```bash
   git push origin <branch>
   gh pr create --title "[DS-<id>]: <slug>" \
     --body "<description>\n\nRelated to #<work-item-id>" \
     --base master
   ```
   Use `Related to #<n>` — **never** `Closes #<n>`. The issue must remain open
   until `Promote.Completed`: Ship, Validate, and Promote still need to run.
7. Enable auto-merge on the PR immediately after creation:
   ```bash
   gh pr merge <number> --auto --squash
   ```
   This queues the squash merge to execute automatically once all required
   CI checks pass. The agent does **not** wait idle — it emits `Finish.Completed`
   as soon as auto-merge is enabled and the PR is confirmed open.
8. Record the PR number and auto-merge status in the Release Trail.
9. Leave explicit next steps for any incomplete item.

## Guardrails

- Do not mark work complete without evidence.
- Do not hide skipped tests; record why they were skipped.
- Do not expand scope during finish work.
- Do not merge manually. Auto-merge is the only authorized merge path from Finish.
- Do not emit `Finish.Completed` before auto-merge is successfully enabled on the PR.

## Engineering References

| Reference | When to read |
|---|---|
| [`../references/engineering/tdd-prodops/quality-gates.md`](../references/engineering/tdd-prodops/quality-gates.md) | Full quality gate definitions and Definition of Done |
