→ [Back to Delivery](../../README.md)

# Ship

---

## Overview

**What it's for:** Observes and orchestrates the autonomous Pull Request flow created by Finish — checks, approval, merge, and deploy to the Feature's Staging environment.

**What Ship is NOT:** Ship does NOT perform deploy. Ship does NOT execute CI. Ship does NOT approve the PR.

**Who executes:** GitHub (approval, merge, workflows) and GitHub Actions (pipelines, deploy).

**Ship:** observes execution, emits events, reacts to failures.

**How it works:**

```
Detect PR created by Finish
→ Observe checks and workflows
→ Observe automatic approval
→ Observe automatic merge
→ Observe deploy to Staging
→ Ship.Completed (only after merge + successful deploy)
```

**Main guardrails:**

- Do not perform deploy — GitHub Actions executes it
- Do not approve the PR — GitHub executes it
- Do not merge the PR — GitHub executes it
- Do not emit Ship.Completed without confirmed merge AND completed Staging deploy
- If any CI step fails: stop progression, report. Finish must be reopened.

**Position in the flow:**

```
CI Async  →  [Ship] → Validate → Promote
                 ↑
        preceded by the CI Sync Finish
```

---

**Objective:** observe the autonomous PR execution and confirm the Feature is available in its Staging environment.

## Environments

| Environment | Type | Ship observes? |
|---|---|---|
| Staging | Ephemeral per Feature/OBC | Yes — target of the observed deploy |
| Sandbox | Shared (Release Candidate) | No — Promote's responsibility |
| Production | Operational | No — outside the Delivery Journey |

Ship.Completed means: Feature available in its Staging environment (ephemeral per Feature/OBC).

## Responsibilities by Actor

| Actor | Responsibility |
|---|---|
| **Finish** | Creates the autonomous PR (before Ship) |
| **GitHub** | Executes approval, merge, and branch protection validations |
| **GitHub Actions** | Executes CI pipelines and Staging deploy |
| **Ship** | Observes execution, emits Ship.Started and Ship.Completed, reacts to failures |
| **Promote** | Promotes the Feature from Staging to Sandbox after Ship.Completed |

## Pre-condition

Finish.Completed emitted: PR created, quality gates satisfied, auto-approval and auto-merge configured.

## Sequence in Ship

1. Detect the PR created by Finish for the correct work-item.
2. Emit Ship.Started.
3. Observe execution of GitHub checks and workflows on the PR.
4. Observe automatic approval on the PR.
5. Observe automatic merge of the PR.
6. If any check or workflow fails: stop progression and report.
7. After merge: observe triggering of the Staging deploy pipeline.
8. Observe the Staging deploy result.
9. If deploy fails: stop progression and report.
10. After successful deploy: record evidence in the Release Trail.
11. Emit Ship.Completed.

## Ship Checklist

- [ ] PR created by Finish detected and confirmed.
- [ ] GitHub checks and workflows observed — all passed.
- [ ] Automatic approval observed.
- [ ] Automatic merge observed and confirmed.
- [ ] Staging deploy pipeline observed and completed successfully.
- [ ] Release Trail updated with ship entry.
- [ ] Ship.Completed emitted.

## Failure Response

| Failure | Action |
|---|---|
| CI check fails | Stop. Report. Finish must be reopened. |
| Auto-approval does not occur | Report as blocker. Wait for investigation. |
| Merge does not occur | Report as blocker. Wait for investigation. |
| Staging deploy fails | Stop. Report. Finish must be reopened. |

For execution mechanics, see [`prodops/skills/ship/`](../../../../../skills/ship/).
