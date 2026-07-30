---
name: finish
description: Close technical work by delivering a fully autonomous Pull Request. Use before considering a task complete, especially after implementation or artifact updates.
---

# FINISH

Use this skill to close a task by delivering a fully autonomous Pull Request with explicit quality evidence.

## What Finish Is and Is NOT

**Finish does NOT deliver software.**

Finish delivers a fully autonomous Pull Request — a PR that traverses the entire remaining flow (Ship → Validate → Promote) **without human intervention**.

To achieve that, Finish ensures:

- final commits organized and valid
- quality evidence recorded
- quality gates satisfied (lint, build, tests, contracts)
- PR created with complete narrative
- auto-approval configured and executed (when the repository supports it)
- auto-merge enabled (when the repository supports it)
- existing workflows verified and valid
- repository confirmed ready for automated execution

**If any requirement cannot be satisfied: Finish does NOT complete. Stop and investigate.**

## Inputs

- `AGENTS.md`
- `prodops/framework/journeys/delivery/phases/finish/quality-gates.md`
- `prodops/framework/journeys/delivery/phases/finish/done-criteria.md`
- Current diff and test output

## Flow

1. Verify input context (work-item-id, iteration-id, actor, correlation-id).
2. Emit Finish.Started.
3. Review changed files and confirm scope.
4. Check quality gates relevant to the task (lint, build, tests, contracts).
5. Run targeted validation and broader validation when risk warrants it.
6. Confirm ProdOps artifacts were updated only where impacted.
7. Confirm Release Trail evidence exists.
8. Create the Pull Request filling the template with evidence.
9. Execute auto-approval on the PR (when the repository supports it; record result).
10. Enable auto-merge on the PR (when the repository supports it; record result).
11. Verify that existing workflows are valid and the repository is ready for automated execution.
12. Record any incomplete item explicitly — Finish does NOT complete with open items.
13. Emit Finish.Completed after all requirements are satisfied.

## Guardrails

- Do not mark work complete without evidence.
- Do not hide skipped tests; record why they were skipped.
- Do not expand scope during finish work.
- If any requirement cannot be satisfied, Finish does NOT complete. Stop and investigate.
- Do not emit Finish.Completed before the PR is created and all quality gates pass.
- Auto-approval and auto-merge failures are blockers — investigate before proceeding.

## Engineering References

| Reference | When to read |
|---|---|
| [`../references/engineering/tdd-prodops/quality-gates.md`](../references/engineering/tdd-prodops/quality-gates.md) | Full quality gate definitions and Definition of Done |
