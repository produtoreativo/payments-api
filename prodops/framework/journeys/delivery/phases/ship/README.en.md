→ [Back to Delivery](../../README.md)

# Ship

---

## Overview

**What it's for:** Transforms the implementation approved by Finish into an executable, versioned, and published artifact, and conducts its delivery to the target environment via deployment.

**How it works:**

```
Preparation: Build → Package → Version → Sign → SBOM → Publish Artifact
Deployment:  Deploy → Progressive Delivery → Rollout
```

**Main guardrails:**

- Do not ship undocumented behavior changes
- Do not include secrets, real tokens, or local paths in the diff
- TDD evidence is mandatory for behavior changes — absence must be justified
- Do not change business scope during ship

**Position in the flow:**

```
CI Async  →  [Ship] → Validate → Promote
                 ↑
        preceded by the CI Sync Finish
```

---

**Objective:** transform the finalized implementation into an executable, publishable, and deployable artifact, conducting its delivery to the target environment.

Ship is organized into two families of capabilities:

## Preparation

Capabilities responsible for producing the artifact:

| Capability | Description |
|---|---|
| **Build** | Compile, transpile, and package the code |
| **Package** | Create the distributable artifact (container, ZIP, layer) |
| **Version** | Apply semantic versioning to the artifact |
| **Sign** | Sign the artifact to ensure integrity and provenance |
| **Generate SBOM** | Produce the Software Bill of Materials |
| **Publish Artifact** | Publish the artifact to the registry (ECR, S3, npm) |

Build, Package, and Publish are internal capabilities of Ship. They are not independent steps of the main flow.

## Deployment

Capabilities responsible for delivering the artifact to the environment:

| Capability | Description |
|---|---|
| **Deploy** | Execute the deployment of the artifact to the target environment |
| **Progressive Delivery** | Gradual delivery strategies (canary, blue-green) |
| **Feature Flags** | Runtime feature activation control |
| **Rollout** | Progressive expansion of traffic to the new version |
| **Rollback** | Revert to the previous version in case of failure |
| **Infrastructure Validation** | Verify that the infrastructure is correct after deploy |

## Pre-condition

The Finish phase was completed: lint, build, tests, and Definition of Done satisfied. See [finish/README.md](../finish/README.md).

## Sequence in Ship

1. Confirm that the change is mapped to the Reliability Plan or a documented follow-up.
2. Review the final diff as if it were an external code review.
3. Verify TDD evidence: every behavior change needs a confirmed Red Bar or documented justification.
4. Run security checks: no secrets, real tokens, personal credentials, or local paths.
5. Fill the PR template with evidence. See [`commit-workflow/templates/pull_request.md`](../../capabilities/commit-workflow/templates/pull_request.md).
6. Publish the Pull Request.
7. Execute Preparation (Build → Package → Version → Publish Artifact).
8. Execute Deployment (Deploy → Progressive Delivery per strategy).
9. Record ship evidence in the Release Trail.

## Ship Checklist

- [ ] Diff reviewed — no unintentional changes included.
- [ ] TDD evidence present or absence justified.
- [ ] No secrets, credentials, or local paths in the diff.
- [ ] PR filled with: behavior, validation, risk, and rollback.
- [ ] Artifact produced and published.
- [ ] Deploy performed in the target environment.
- [ ] Release Trail updated with ship entry.

For execution mechanics, see [`prodops/skills/ship/`](../../../../../skills/ship/).
