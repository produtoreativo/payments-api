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

- `prodops/framework/journeys/delivery/capabilities/commit-workflow/templates/pull_request.md`
  — the PR template to fill
- The branch diff and the evidence from `validate` (lint/build/acceptance output,
  the acceptance-suite coverage, and the dependency scan)
- The target (origin) branch confirmed by `review`
- The active session trail in `prodops/artifacts/trails/sessions/`

## Action

### 1. Fill the body from the template

Fill the [PR template](../../../../framework/journeys/delivery/capabilities/commit-workflow/templates/pull_request.md)
with real evidence — objective, summary, changed contracts, tests run (with the
`validate` output), updated ProdOps artifacts, and pending items. It is not a
commit log; it is what the change delivers and how it was verified.

### 2. Check the auto-merge gates

Before arming auto-merge, run the auto-merge gates. All must release for
auto-merge to be armed — if **any** does not, auto-merge stays disarmed (the PR
opens anyway; see step 4).

**Coverage** (`gates.coverage` in the manifest — currently **100% of branches**):

```bash
./scripts/check-coverage-threshold.sh
```

Consumes the XML produced by the `acceptance` gate, so run it after `validate`.
Exit 0 releases; exit 1 **blocks** auto-merge.

**Dependencies / SCA** (`gates.dependencies` in the manifest — Snyk, severity
threshold **high**):

```bash
./scripts/check-dependencies.sh
```

Exit 0 releases; exit 1 **blocks** (vulnerabilities >= high). Exit 2 means the
gate **could not run** (no `SNYK_TOKEN`) — treat it as not-released: keep
auto-merge disarmed and record the reason. Creating the secret is an admin
action, like `allow_auto_merge`.

### 3. Open the PR

First check whether a PR is **already open** for this branch — the step is
idempotent: running it again (because a gate did not release, or the Finish was
re-run) must not create a second PR.

```bash
gh pr list --head "$(git branch --show-current)" --state open
```

If a PR **already exists**, operate on it (steps 4 and 5 update that PR) — do not
create another. Only if **none** exists:

```bash
gh pr create --base <target-branch> --fill-first --body-file <file>
```

The PR is opened **always** — regardless of step 2's result. The auto-merge gates
are not a condition for opening the PR nor for merging it; they are a condition
only for **automating** the merge.

### 4. Arm auto-merge — only if every step-2 gate released

```bash
# only when check-coverage-threshold.sh AND check-dependencies.sh exited 0
gh pr merge --auto --squash
```

`--auto` arms the merge: the PR merges only once all required checks are green.
`--squash` keeps history linear on the target branch, consistent with the
repository's flow.

**If any step-2 gate did not release** (coverage below threshold, a
vulnerability >= high, or the dependency gate could not run for lack of
`SNYK_TOKEN`), do not run `gh pr merge --auto`. Record on the PR the reason —
specific to the gate that blocked:

```bash
gh pr comment <n> --body "Auto-merge not armed: <reason>. Manual merge remains
available after review."
# <reason>, e.g.:
#   branch coverage below the 100% threshold (gates.coverage)
#   vulnerabilities of severity >= high in dependencies (gates.dependencies)
#   SNYK_TOKEN missing — dependency gate could not run (gates.dependencies)
```

The PR stays open, green and **manually mergeable** by a human. The gates govern
automation only — never the ability to merge. That is why `gates.coverage` and
`gates.dependencies` are **not** required status checks: as required checks they
would also block the manual merge, which is precisely what must be preserved.

### 5. Update the Release Trail

Record the PR link in the active session trail
(`prodops/artifacts/trails/sessions/`), closing the Finish loop.

## Criterion

Complete when: the PR is open against the correct target branch, the body follows
the template filled with evidence, auto-merge is armed (`--auto --squash`) **when
every step-2 auto-merge gate released** — or deliberately not armed, with the
reason recorded on the PR, when one did not — and the Release Trail has the PR
link. Exactly **one** PR for the branch: before creating, `gh pr list --head
<branch>` confirms none is already open.

## Guardrails

- Do not open the PR without a clean `validate` and a blocker-free `review`.
- Do not open a PR with auto-merge when branch protection is not configured
  (`review` would have flagged it — respect the blocker).
- Do not arm auto-merge when a step-2 gate did not release (low coverage, a
  vulnerability >= high, or the dependency gate unable to run) — and do not
  withhold the PR because of it: that disarms the automation, not the PR.
- Do not turn `gates.coverage` or `gates.dependencies` into required status
  checks: that would block the manual merge, defeating the gates' purpose.
- Do not push, do not commit, do not validate here — only open the PR.
- Do not open duplicate PRs: run `gh pr list --head <branch>` before creating; if
  a PR is already open for the branch, operate on it. One Finish opens one PR.
