---
name: finish/review
description: Inspect the pipeline and confirm the rules for a safe automatic PR are valid — without running the pipeline. Use before enabling auto-approval, to catch a missing branch-protection condition as a blocker instead of after merge.
---

# FINISH → REVIEW

Execute only the pipeline-inspection step of the Finish flow.

**Responsibility:** ensure the **rules for an automatic PR are valid** — that the
conditions for safe auto-approval are present in the repository. This is an
**inspection** step, not an execution one: it does not run the pipeline, it only
checks that the pipeline and branch protection are configured so a PR with all
checks green can merge on its own, safely.

**Not the responsibility of `review`:** running pipelines; committing; writing
or reading product code; writing to artifacts other than GitHub Actions ones;
pushing; opening the PR (that is `request`).

## Inputs

- `.github/workflows/pr-gates.yml` — the checks the pipeline exposes as gates
- `prodops/journeys/delivery/phases/finish/quality-gates.md` — branch-protection
  conditions for safe auto-approval
- `prodops/exec/manifest.yaml` — the canonical gates the checks must mirror
- The PR's target branch (the origin branch of the current branch)

## Action

Confirm, without running the pipeline, that **all** the conditions below are
present. Inspect via `gh` and config reads — do not trigger workflows.

### 1. The pipeline exposes the required gates as status checks

The `pr-gates.yml` jobs must cover lint, test (acceptance), and build — the same
gates as `manifest.yaml`. List the checks GitHub knows for the branch:

```bash
gh api "repos/{owner}/{repo}/commits/$(git rev-parse HEAD)/check-runs" \
  --jq '.check_runs[].name'
```

- [ ] `lint`, `acceptance`, and `build` appear as checks.

### 2. Branch protection on the target branch requires the checks

The target (origin) branch must **require** those checks to pass before merge —
otherwise `request`'s auto-merge would merge without a gate:

```bash
gh api "repos/{owner}/{repo}/branches/<target-branch>/protection" \
  --jq '.required_status_checks.contexts'
```

- [ ] Branch protection requires all mandatory checks to pass.

### 3. No required reviewer blocks auto-merge

A required human reviewer prevents the automatic merge of a PR with green
checks. Confirm there is no required review, or that a bot auto-approves:

```bash
gh api "repos/{owner}/{repo}/branches/<target-branch>/protection" \
  --jq '.required_pull_request_reviews'
```

- [ ] No required reviewer for PRs with all checks green (or a bot-approved
      reviewer).

## Criterion

Each missing condition is a **blocker**: record it in Finish before enabling
auto-approval and **do not advance to push/request** with auto-merge until it is
resolved. Enabling auto-merge without branch protection would merge ungated
code — the opposite of what Finish protects.

If branch-protection conditions cannot be read (insufficient permission) or are
not configured, treat that as an explicit blocker, not as "probably fine".

## Guardrails

- Do not run pipelines — only inspect configuration.
- Do not commit, do not write/read product code, do not push, do not open a PR.
- Do not enable auto-approval while branch protection is not configured.
- Do not assume a missing check is "fine"; a missing condition is a blocker.
