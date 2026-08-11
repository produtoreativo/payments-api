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
- The commits are already published on the working branch (the `push origin`
  step) — on the current branch, never on the PR's target branch.

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

The three auto-merge gates — `gates.coverage`, `gates.dependencies` and
`gates.code-analysis` — **run in `validate`**, the static-analysis step. Here the
verdict `validate` produced in this session is only **read**. All must have
released for auto-merge to be armed; if **any** did not, auto-merge stays
disarmed (the PR still opens; see step 4).

**Do not run the gate scripts here.** This step's responsibility is opening the
PR — running `check-coverage-threshold.sh`, `check-dependencies.sh` or
`check-code-analysis.sh` would be executing quality analysis, which belongs to
`validate`. Running acceptance to regenerate the coverage XML would be worse
still: dynamic analysis inside the PR-opening step.

| Gate | Verdict expected from `validate` |
|---|---|
| `gates.coverage` | branch coverage >= threshold (currently 100%) |
| `gates.dependencies` | no vulnerabilities >= high |
| `gates.code-analysis` | SonarQube quality gate green |

For each one, `validate` reports released, blocked, or **could not run** (no
`SNYK_TOKEN`, no Docker, missing XML). The last two count the same here: **not
released** — keep auto-merge disarmed and record the reason.

**If there is no verdict from `validate` in this session** — because `request`
was invoked on its own, or `validate` ran on a different HEAD — treat all three
gates as **not released**. Do not try to recover them: open the PR without arming
auto-merge and record that the gates were not verified in this flow. Re-running
`validate` is the path to arming it.

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
# only when `validate` reported all three gates released
# (gates.coverage, gates.dependencies AND gates.code-analysis)
gh pr merge --auto --squash
```

`--auto` arms the merge: the PR merges only once all required checks are green.
`--squash` keeps history linear on the target branch, consistent with the
repository's flow.

**If any step-2 gate did not release** (coverage below threshold, a
vulnerability >= high, a red SonarQube quality gate, or a gate that could not run
for lack of `SNYK_TOKEN`/Docker), do not run `gh pr merge --auto`. Record on the PR
the reason — specific to the gate that blocked:

```bash
gh pr comment <n> --body "Auto-merge not armed: <reason>. Manual merge remains
available after review."
# <reason>, e.g.:
#   branch coverage below the 100% threshold (gates.coverage)
#   vulnerabilities of severity >= high in dependencies (gates.dependencies)
#   SNYK_TOKEN missing — dependency gate could not run (gates.dependencies)
#   red SonarQube quality gate on api/src (gates.code-analysis)
#   Docker unavailable — code analysis gate could not run (gates.code-analysis)
```

The PR stays open, green and **manually mergeable** by a human. The gates govern
automation only — never the ability to merge. That is why `gates.coverage`,
`gates.dependencies` and `gates.code-analysis` are **not** required status checks: as
required checks they would also block the manual merge, which is precisely what
must be preserved.

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
  vulnerability >= high, a red SonarQube quality gate, or a gate unable to run) —
  and do not withhold the PR because of it: that disarms the automation, not the PR.
- Do not turn `gates.coverage`, `gates.dependencies` or `gates.code-analysis` into
  required status checks: that would block the manual merge, defeating the
  gates' purpose.
- Do not push, do not commit, do not validate here — only open the PR.
- Do not open duplicate PRs: run `gh pr list --head <branch>` before creating; if
  a PR is already open for the branch, operate on it. One Finish opens one PR.
