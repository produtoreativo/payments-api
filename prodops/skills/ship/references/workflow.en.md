# SHIP Workflow

SHIP is the observation and orchestration phase. The agent observes the execution of the autonomous Pull Request created by Finish — checks, approval, merge, Staging deploy — without executing any of these steps directly.

**Who executes approval, merge, and workflows:** GitHub
**Who executes pipelines and deploy:** GitHub Actions
**Ship:** observes, emits events, reacts to failures

## Environments

| Environment | Type | Ship observes? |
|---|---|---|
| Staging | Ephemeral per Feature/OBC | Yes — target of the observed deploy |
| Sandbox | Shared (Release Candidate) | No — Promote's responsibility |
| Production | Operational | No — outside the Delivery Journey |

## Detect the PR Created by Finish

```sh
gh pr list --head <branch> --state open --json number,url,title,statusCheckRollup
gh pr view <pr-number> --json number,url,title,state,mergeable,statusCheckRollup,autoMergeRequest
```

Confirm the PR was created by Finish for the correct work-item before emitting Ship.Started.

## Observe Checks and Workflows

```sh
gh pr checks <pr-number> --watch
gh run list --branch <branch>
gh run view <run-id>
```

If any check fails: record the run-id and failure reason. **Stop progression.** Do not proceed to merge or deploy. Report — Finish must be reopened.

## Observe Automatic Approval

Verify whether the repository has auto-approval configured (via GitHub Apps or CODEOWNERS with auto-approve):

```sh
gh pr view <pr-number> --json reviews,autoMergeRequest
```

If auto-approval does not occur within a reasonable time after checks pass: report as a blocker and wait for investigation.

## Observe Automatic Merge

```sh
gh pr view <pr-number> --json state,mergedAt,mergeCommit
```

Wait for `state: MERGED`. If merge does not occur after approval and checks pass: report as a blocker.

## Observe Staging Deploy

After merge, observe triggering of the Staging deploy pipeline:

```sh
gh run list --branch main --workflow <staging-deploy-workflow>
gh run view <run-id> --log
```

Wait for the pipeline to complete successfully. If the pipeline fails: record run-id and reason. **Stop progression.**

## Record Evidence and Emit Ship.Completed

After merge is confirmed **AND** Staging deploy completes successfully:

1. Record in the Release Trail:
   - Merged PR: number, commit, date
   - Staging deploy: run-id, version, environment
   - Result: success

2. Emit `Delivery.Ship.Completed` using the same `correlation-id` as Ship.Started.

## Failure Response

| Failure | Ship Action |
|---|---|
| CI check fails | Stop. Report run-id and reason. Finish must be reopened. |
| Auto-approval does not occur | Report as blocker. Wait for investigation. |
| Merge does not occur | Report as blocker. Wait for investigation. |
| Staging deploy fails | Stop. Report run-id and reason. Finish must be reopened. |

**Ship does NOT emit Ship.Completed in failure scenarios.**
