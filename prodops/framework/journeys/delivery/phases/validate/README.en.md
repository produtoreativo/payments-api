→ [Back to Delivery](../../README.md)

# Validate

---

## Overview

**What it's for:** Proves that the delivery works in the target environment with measurable evidence — tests, logs, metrics, and SLOs. Does not assume that what passed locally will pass in production.

**How it works:**

```
Identify capability/OBC → Select executable evidence
→ Run validations → Confirm BDD in target environment
→ Verify observability → Assess risks → Release Trail
```

**Main guardrails:**

- Do not invent metrics or SLOs — if absent, record the gap in the ProdOps artifact
- Prefer executable evidence over narrative assertions
- If it fails: do not promote; open a new Hack cycle with the observed behavior as Red Bar

**Position in the flow:**

```
CI Async  →  Ship → [Validate] → Promote
```

---

**Objective:** verify the delivery running in the target environment.

## Validate Capabilities

| Capability | Description |
|---|---|
| **Smoke Tests** | Quick sanity checks post-deploy |
| **Runtime Contract Validation** | Confirm that the API responds according to the OpenAPI/AsyncAPI contract |
| **Synthetic Monitoring** | Continuous execution of real scenarios against the environment |
| **Health Checks** | Verify availability of components in the target environment |
| **Observability Validation** | Confirm logs, metrics, and correlationId in the real environment |
| **SLO Validation** | Verify that the SLOs defined in the OBC are being met |
| **Business Validation** | Confirm that business behavior is correct at runtime |
| **Incident Signals** | Monitor alert signals and anomalies after deploy |

## Pre-condition

The PR was approved and the deploy to staging was performed.

## Sequence in Validate

1. Identify the capability, OBC, or risk being validated.
2. Select executable evidence: tests, logs, metrics, events, or SLO signals.
3. Run the validation commands and record the exact results.
4. Confirm that BDD Feature scenarios pass in the staging environment.
5. Verify observability: expected logs emitted, correlationId propagated, no secrets in logs.
6. Assess remaining risks and decide whether they are acceptable for promotion.
7. Record evidence in the Release Trail.

## Validate Checklist

- [ ] Smoke Tests pass in the target environment.
- [ ] BDD scenarios pass in the target environment.
- [ ] OBC satisfied with measurable evidence.
- [ ] Logs and traceability verified in the target environment (correlationId, tenantId).
- [ ] SLOs verified — no degradation introduced.
- [ ] Remaining risks assessed and documented.
- [ ] Release Trail updated with validation evidence.

## If validation fails

Do not promote. Open a new Hack cycle with the observed behavior as Red Bar. Record the gap in the Release Trail as "Validation failed — returned to Hack".

For execution mechanics, see [`prodops/skills/validate/`](../../../../../skills/validate/).
