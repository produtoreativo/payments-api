---
name: finish
description: Close technical work with quality gates. Use before considering a task complete, especially after implementation or artifact updates.
---

# FINISH

Use this skill to close CI Sync: validate quality locally, ensure the automatic
PR rules are valid, publish the commits, and open the PR in auto-approval mode.

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

When invoked with a step argument (`/finish <step>`), run only that step.
Otherwise, run the full flow in order.

Finish does **not** implement or read product code (that is Hack), does **not**
run the remote pipeline (that is CI), and does **not** rewrite product decisions
(that is upstream).

## Steps

| Step | File | When to use |
|---|---|---|
| `validate` | [steps/validate/SKILL.md](steps/validate/SKILL.md) | Before push — replicate locally what the remote pipeline will run |
| `review` | [steps/review/SKILL.md](steps/review/SKILL.md) | Confirm the conditions for safe auto-approval are present in the repository |
| `request` | [steps/request/SKILL.md](steps/request/SKILL.md) | Open the PR with title and body from the template, with auto-merge configured |

If the requested step is not listed, run the full flow.

## Inputs

- `AGENTS.md`
- `prodops/framework/journeys/delivery/phases/finish/quality-gates.md`
- `prodops/framework/journeys/delivery/phases/finish/done-criteria.md`
- `prodops/exec/manifest.yaml` — canonical gate commands and criteria
- Current diff and test output

## Flow

When invoked without a step argument, run in order:

1. **[validate](steps/validate/SKILL.md)** — run the static analysis suite
   (format, lint, coverage, build) plus acceptance when behavior or contracts
   changed. If any fails locally, the step fails and **does not advance**: the
   fix belongs to Hack's TDD cycle, so return to
   [`hack tdd`](../hack/steps/tdd/SKILL.md) and only re-run `validate` after it
   closes green — `validate` writes no code. Failing on the remote pipeline
   after a push costs more (rework, notifications, red PR) than failing locally
   before.
2. **[review](steps/review/SKILL.md)** — confirm the pipeline has the required
   checks, that branch protection on the target branch enforces them, and that
   no required reviewer blocks auto-merge. A missing condition is a **blocker**
   to record before enabling auto-approval.
3. **push origin** — after a clean `validate` and a `review` with no blockers,
   publish the commits to the **origin branch** (the branch the current one was
   derived from), with no force push:

   ```bash
   git push origin HEAD:<origin-branch>
   ```
4. **[request](steps/request/SKILL.md)** — open the PR with the template filled
   with evidence and enable auto-merge immediately after creation
   (`gh pr merge <number> --auto --squash`), then update the Release Trail with
   the PR link and auto-merge status. Auto-merge queues the squash to execute
   once all required CI checks pass. The agent does **not** wait idle — it emits
   `Finish.Completed` as soon as auto-merge is enabled and the PR is confirmed
   open.

## Guardrails

- Do not mark work complete without evidence.
- Do not hide skipped tests; record why they were skipped.
- Do not expand scope during finish work.
- Do not force push.
- Do not merge manually. Auto-merge is the only authorized merge path from Finish.
- Do not enable auto-approval while branch protection is not configured.
- Do not emit `Finish.Completed` before auto-merge is successfully enabled on the PR.

## Engineering References

| Reference | When to read |
|---|---|
| [`../references/engineering/tdd-prodops/quality-gates.md`](../references/engineering/tdd-prodops/quality-gates.md) | Full quality gate definitions and Definition of Done |
