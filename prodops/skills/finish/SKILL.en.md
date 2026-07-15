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

Finish does **not** implement or read product code (that is Hack), does **not**
run the remote pipeline (that is CI), and does **not** rewrite product decisions
(that is upstream).

## Steps

Finish has **three invocable steps** plus a publish step, each with a single
responsibility and an explicit boundary of what it is **not** responsible for —
so each step is auditable in isolation, with no cross-cutting side effects (a
validation step does not commit, a review step does not run the pipeline, etc.):

- **`validate` — static quality analysis** (runs all static analysis steps; the
  single dynamic exception is acceptance/integration).
- **`review` — pipeline inspection** (ensures the rules for an automatic PR are
  valid, without running the pipeline).
- **push origin** — publishes the commits to the origin branch (git, no force push).
- **`request` — opens the PR in auto-approval mode** (auto-merge if CI passes).

| Step | File | When to use |
|---|---|---|
| `validate` | [steps/validate/SKILL.md](steps/validate/SKILL.md) | Before push — replicate locally what the remote pipeline will run |
| `review` | [steps/review/SKILL.md](steps/review/SKILL.md) | Confirm the conditions for safe auto-approval are present in the repository |
| `request` | [steps/request/SKILL.md](steps/request/SKILL.md) | Open the PR with title and body from the template, with auto-merge configured |

When invoked with a step argument (`/finish <step>`), run only that step.
Otherwise, run the full flow in order. If the requested step is not listed, run
the full flow.

## Inputs

- `AGENTS.md`
- `prodops/framework/journeys/delivery/phases/finish/quality-gates.md`
- `prodops/framework/journeys/delivery/phases/finish/done-criteria.md`
- `prodops/exec/manifest.yaml` — canonical gate commands and criteria
- Current diff and test output

## Flow

When invoked without a step argument, run in order:

1. Verify input context (work-item-id, iteration-id, actor, correlation-id).
2. Emit Finish.Started.
3. **[validate](steps/validate/SKILL.md)** — run the static analysis suite
   (format, lint, coverage, build) plus acceptance when behavior or contracts
   changed. If any fails locally, the step fails and does not advance — fix
   first. Failing on the remote pipeline after a push costs more (rework,
   notifications, red PR) than failing locally before.
4. Confirm ProdOps artifacts were updated only where impacted.
5. Confirm Release Trail evidence exists.
6. **[review](steps/review/SKILL.md)** — confirm the pipeline has the required
   checks, that branch protection on the target branch enforces them, and that
   no required reviewer blocks auto-merge. A missing condition is a **blocker**
   to record before enabling auto-approval.
7. **push origin** — after a clean `validate` and a `review` with no blockers,
   publish the commits to the **origin branch** (the branch the current one was
   derived from), with no force push:

   ```bash
   git push origin HEAD:<origin-branch>
   ```
8. **[request](steps/request/SKILL.md)** — open the PR with the template filled
   with evidence, execute auto-approval and enable auto-merge immediately after
   creation (`gh pr merge <number> --auto --squash`), then update the Release
   Trail with the PR link and auto-merge status. Auto-merge queues the squash to
   execute once all required CI checks pass. The agent does **not** wait idle.
9. Verify that existing workflows are valid and the repository is ready for automated execution.
10. Record any incomplete item explicitly — Finish does NOT complete with open items.
11. Emit Finish.Completed as soon as auto-merge is enabled, the PR is confirmed
    open, and all requirements are satisfied.

## Guardrails

- Do not mark work complete without evidence.
- Do not hide skipped tests; record why they were skipped.
- Do not expand scope during finish work.
- If any requirement cannot be satisfied, Finish does NOT complete. Stop and investigate.
- Do not emit Finish.Completed before the PR is created and all quality gates pass.
- Auto-approval and auto-merge failures are blockers — investigate before proceeding.
- Do not force push.
- Do not merge manually. Auto-merge is the only authorized merge path from Finish.
- Do not enable auto-approval while branch protection is not configured.
- Do not emit `Finish.Completed` before auto-merge is successfully enabled on the PR.

## Engineering References

| Reference | When to read |
|---|---|
| [`../references/engineering/tdd-prodops/quality-gates.md`](../references/engineering/tdd-prodops/quality-gates.md) | Full quality gate definitions and Definition of Done |
