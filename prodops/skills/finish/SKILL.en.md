---
name: finish
description: Close technical work with quality gates. Use before considering a task complete, especially after implementation or artifact updates.
---

# FINISH

Use this skill to close a task with explicit quality evidence.

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
     --body "<description and issue reference>" \
     --base master
   ```
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
