→ [Back to Delivery](../../README.md)

# Promote

---

## Overview

**What it's for:** Promotes the Feature from the Staging environment (ephemeral per Feature) to the Sandbox environment (shared, Release Candidate). Starts only after Ship.Completed.

**What Promote is NOT:** Promote does NOT publish to Production. Production is outside the Delivery Journey.

**How it works:**

```
Confirm Ship.Completed → Confirm Quality Gates and Validate
→ Confirm risks resolved
→ Promote Feature from Staging to Sandbox
→ Record in Release Trail
```

**Main guardrails:**

- Do not promote with missing evidence
- Do not start before Ship.Completed
- Do not silently accept high risk — document it or move to follow-up
- Never replace Release Trail history; always add a new entry
- Do not promote to Production — Promote targets Sandbox only

**Position in the flow:**

```
CI Async  →  Ship → Validate → [Promote]
```

---

**Objective:** promote the Feature from the Staging environment to the Sandbox environment (Release Candidate), with evidence recorded.

## Environments

| Environment | Type | Purpose |
|---|---|---|
| Staging | Ephemeral per Feature/OBC | Exclusive Feature validation. Destroyed after promotion. |
| Sandbox | Shared | Release Candidate. Origin of promotion to Production. |
| Production | Operational | Outside the Delivery Journey. |

Promote moves the Feature from **Staging → Sandbox**.

Sandbox receives only Ship-promoted Features. Production belongs to the subsequent operational process.

## Promote Capabilities

| Capability | Description |
|---|---|
| **Promotion Gates** | Verification of all criteria before promotion |
| **Environment Promotion** | Move the Feature from Staging to Sandbox (Release Candidate) |
| **Release Trail** | Definitive record of the promotion with evidence |
| **Rollback Readiness** | Confirm that the rollback plan is documented |

## Pre-condition

Ship.Completed emitted for the work-item: Feature available in Staging and merge confirmed.

## Sequence in Promote

1. Confirm Ship.Completed was emitted for the correct work-item.
2. Confirm all Quality Gates are satisfied. See [`prodops/framework/journeys/delivery/phases/finish/quality-gates.md`](../finish/quality-gates.md).
3. Confirm Validate has completed and risks have been assessed.
4. Formally accept remaining risks or move them to documented follow-up.
5. Execute Environment Promotion (Staging → Sandbox).
6. Close the Task with the template. See [`commit-workflow/templates/task-closing.md`](../../capabilities/commit-workflow/templates/task-closing.md).
7. Record the promotion in the Release Trail: what was promoted, evidence, accepted risks, and next steps.

## Promote Checklist

- [ ] Ship.Completed confirmed for the work-item.
- [ ] Promotion Gates satisfied (Quality Gates + Done Criteria).
- [ ] Validate completed successfully.
- [ ] Remaining risks accepted or moved to follow-up.
- [ ] Rollback Readiness confirmed — plan documented.
- [ ] Environment Promotion executed (Staging → Sandbox).
- [ ] Task closed with evidence.
- [ ] Release Trail updated with promotion entry.

## Full CI Async flow

```
Ship (observes PR → merge → Staging deploy)
  ↓
Validate (Runtime → Observability → SLO → Business)
  ↓
Promote (Gates → Staging→Sandbox Promotion → Trail)
```

If Validate fails → returns to Hack with the observed behavior as Red Bar.
If Promote identifies unacceptable risk → returns to Validate or Hack depending on the nature of the risk.

For execution mechanics, see [`prodops/skills/promote/`](../../../../../skills/promote/).
