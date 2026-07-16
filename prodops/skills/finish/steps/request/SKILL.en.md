---
name: finish/request
description: Open the PR in auto-approval mode — filled from the PR template with evidence, with auto-merge configured so it merges on its own once CI passes. Use as the last Finish step, after validate is clean, review has no blockers, and the commits are pushed.
---

# FINISH → REQUEST

Execute only the PR-opening step of the Finish flow.

**Responsibility:** open **one** Pull Request in auto-approval mode — if all
GitHub Actions checks pass, the PR merges automatically without manual
intervention. That is this step's only responsibility.

**Not the responsibility of `request`:** any action other than opening the PR —
it does not validate (that is `validate`), does not inspect the pipeline (that is
`review`), does not push (that is the `push origin` step), does not commit, does
not write/read code.

## Preconditions

Do not open the PR before:

- `validate` is clean (lint + build + acceptance when applicable).
- `review` has no blockers (branch protection and required checks present).
- The commits are already published on the origin branch (the `push origin` step).

If any is unmet, stop and surface it — opening the PR with auto-merge without
these prerequisites can merge ungated code.

## Inputs

- `prodops/journeys/delivery/capabilities/commit-workflow/templates/pull_request.md`
  — the PR template to fill
- The branch diff and the evidence from `validate` (lint/build/acceptance output
  and the acceptance-suite coverage)
- The target (origin) branch confirmed by `review`
- The active session trail in `prodops/artifacts/trails/sessions/`

## Action

### 1. Fill the body from the template

Fill the [PR template](../../../../journeys/delivery/capabilities/commit-workflow/templates/pull_request.md)
with real evidence — objective, summary, changed contracts, tests run (with the
`validate` output), updated ProdOps artifacts, and pending items. It is not a
commit log; it is what the change delivers and how it was verified.

### 2. Open the PR and configure auto-merge

```bash
gh pr create --base <target-branch> --fill-first --body-file <file>
gh pr merge --auto --squash
```

`--auto` arms the merge: the PR merges only once all required checks are green.
`--squash` keeps history linear on the target branch, consistent with the
repository's flow.

### 3. Update the Release Trail

Record the PR link in the active session trail
(`prodops/artifacts/trails/sessions/`), closing the Finish loop.

## Criterion

Complete when: the PR is open against the correct target branch, the body follows
the template filled with evidence, auto-merge is armed (`--auto --squash`), and
the Release Trail has the PR link. A single PR — do not open duplicates.

## Guardrails

- Do not open the PR without a clean `validate` and a blocker-free `review`.
- Do not open a PR with auto-merge when branch protection is not configured
  (`review` would have flagged it — respect the blocker).
- Do not push, do not commit, do not validate here — only open the PR.
- Do not open duplicate PRs; one Finish opens one PR.
