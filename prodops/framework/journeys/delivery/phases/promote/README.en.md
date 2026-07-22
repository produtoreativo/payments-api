→ [Back to Delivery](../../README.md)

# Promote

---

## Overview

**What it's for:** It officially records the release evolution with formal approval from PM and Tech Lead, moves the artifact to the next environment, and closes the cycle with evidence recorded in the Release Trail.

**How it works:**

```
Confirm Quality Gates → Verify operational readiness
→ Release Approval (PM + Tech Lead) → Environment Promotion
→ Close Task → Record in Release Trail
```

**Main guardrails:**

- Do not promote with missing evidence
- Do not silently accept high risk — document it or move to follow-up
- Never replace Release Trail history; always add a new entry

**Position in the flow:**

```
CI Async  →  Ship → Validate → [Promote]
```

---

**Objective:** officially record the version's evolution with formal approval and registered evidence.

## Promote Capabilities

| Capability | Description |
|---|---|
| **Promotion Gates** | Verification of all criteria before promotion |
| **Environment Promotion** | Move the artifact to the next environment (staging → prod) |
| **Release Approval** | Formal approval by PM and Tech Lead |
| **Release Trail** | Definitive record of the promotion with evidence |
| **Operational Evidence** | Evidence of healthy operation post-promotion |
| **Release Documentation** | Release notes, changelog, announcement |
| **Rollback Readiness** | Confirm that the rollback plan is documented and tested |

## Pre-condition

Validation completed, risks assessed, operational readiness confirmed.

## Sequence in Promote

1. Confirm that all Quality Gates are satisfied. See [`prodops/framework/journeys/delivery/phases/finish/quality-gates.md`](../finish/quality-gates.md).
2. Verify operational readiness: runbooks exist for the new failure modes, on-call notified.
3. Execute Release Approval with PM and Tech Lead.
4. Formally accept remaining risks or move them to documented follow-up.
5. Execute Environment Promotion (staging → prod).
6. Close the Task with the template. See [`commit-workflow/templates/task-closing.md`](../../capabilities/commit-workflow/templates/task-closing.md).
7. Record the promotion in the Release Trail: what was promoted, evidence, accepted risks, and next steps.

## Promote Checklist

- [ ] Promotion Gates satisfied (Quality Gates + Done Criteria).
- [ ] Release Approval obtained (PM + Tech Lead).
- [ ] Runbooks updated for new failure modes (if applicable).
- [ ] Rollback Readiness confirmed — plan documented.
- [ ] Environment Promotion executed.
- [ ] Task closed with evidence.
- [ ] Release Trail updated with promotion entry.
- [ ] Operational Evidence recorded.

## Full CI Async flow

```
Ship (Preparation → Deployment)
  ↓
Validate (Runtime → Observability → SLO → Business)
  ↓
Promote (Gates → Approval → Promotion → Trail)
```

If Validate fails → returns to Hack with the observed behavior as Red Bar.
If Promote identifies unacceptable risk → returns to Validate or Hack depending on the nature of the risk.

For execution mechanics, see [`prodops/skills/promote/`](../../../../../skills/promote/).
