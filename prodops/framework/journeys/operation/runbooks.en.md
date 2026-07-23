# Runbooks — Canonical Definition

A **Runbook** is a structured operational procedure that defines how to respond to
a specific incident, failure, or anomalous condition in production. Runbooks are part
of the Operation Journey and complement the Reliability Plan, SLOs, and the
product's observability plans.

> Product runbooks belong to the consumer and must be created in
> `prodops/artifacts/runbooks/`. This canonical definition describes the structure
> and requirements of a Runbook within the ProdOps Framework.

---

## Purpose

A Runbook transforms a risk scenario identified in the pre-mortem into an
executable procedure. Each Runbook:

- Reduces mean time to recovery (MTTR) by eliminating ad-hoc diagnosis.
- Distributes operational knowledge across all team members.
- Preserves traceability between incidents, decisions, and evidence.
- Links to the continuous improvement cycle via Postmortem and Assessment.

---

## Relationship with the Operation Journey

```
Reliability Plan (premortem)
       ↓ identifies risk scenarios
Runbook
       ↓ defines operational response
Production incident
       ↓ executes the Runbook
Operational Trail (record)
       ↓ feeds
Postmortem
       ↓ improves
Reliability Plan (next cycle)
```

---

## Pre-conditions for creating a Runbook

Before creating a Runbook, the following prerequisites must be met:

- The corresponding risk scenario is documented in the Reliability Plan Premortem.
- The scenario's alert signals are mapped to Observable Events in the OBCs.
- The operational team has access to the necessary diagnostic tools (logs, queues, datastores).
- There is clarity about who owns the Runbook and who can authorize containment actions.

---

## Activation signals

A Runbook is activated when:

- An SLO or SLI alert fires and the scenario matches a documented Runbook.
- An operator or agent detects symptoms matching the Runbook's alert signals.
- Support receives customer reports matching the failure pattern described.
- Observability telemetry reveals failure events above the baseline threshold.

---

## Canonical Runbook structure

### Header

```markdown
## RB-NNN — <Descriptive title of the scenario>

**Origin scenario:** <Premortem reference — e.g., PRE-NNN>

**When to use:** <Objective condition that activates this Runbook>

**Owner:** <Team or role responsible>

**Related SLO:** <SLO or SLI this Runbook protects>

**Related OBC:** <OBC whose failure events trigger this Runbook>
```

### Alert Signals

List observable symptoms that confirm this Runbook applies:

- Specific failure events in the observability platform.
- Characteristic log messages.
- Anomalous behavior of queues, datastores, or external integrations.
- Error volume above baseline threshold.

### Diagnosis

Commands and queries to confirm the root cause:

```bash
# Query <primary-datastore> to identify affected records
# Check <event-broker> queues — DLQ and main queue
# Query <observability-platform> logs by correlation
# Check <external-provider> status
```

### Immediate Containment

Actions to stabilize the system and prevent escalation:

1. Isolate or protect records in an inconsistent state.
2. Pause automated flows that could worsen the situation.
3. Communicate scope and immediate impact to the team.

### Mitigation

Actions to reduce impact while the root cause is being resolved:

1. Priority mitigation action.
2. Check for side effects.
3. Escalate if necessary.

### Recovery

Actions to restore the correct system state:

1. Reprocess affected events or records.
2. Verify data integrity.
3. Confirm that normal flow was restored.

### Rollback

Conditions and procedure for safe rollback, if applicable:

- When rollback is preferable to in-place recovery.
- Data states that must be reconciled after rollback.
- Post-rollback verification checklist.

### Post-Resolution Verification

Checklist to confirm the incident was resolved:

- [ ] Failure event no longer appears above baseline.
- [ ] Affected records are in the expected state.
- [ ] Downstream flow was not affected or was recovered.
- [ ] DLQ volume returned to baseline.

### Communication

- [ ] Affected team notified.
- [ ] Stakeholders communicated if impact is external.
- [ ] Status page updated if applicable.

### Evidence

Record for the Postmortem:

- Detection time and resolution time.
- Commands executed and their relevant outputs.
- Decisions made and justifications.

### Closure

**Record in:** `prodops/artifacts/trails/operational-trail.md` (append-only).

Required fields: date/time, Runbook executed, root cause identified, decision made, impact scope, evidence.

**Open a Postmortem if:**

- The incident caused external customer impact.
- MTTR exceeded the threshold defined in the Reliability Plan.
- The root cause was not anticipated in the Premortem.

→ Postmortem template: `prodops/templates/operation/postmortem.md`

---

## Linking with OBCs and SLOs

Each Runbook must be linked to:

- **OBC:** The OBC whose Observable Events trigger this Runbook (failure events `*_failed`, `*_rejected`).
- **SLO:** The SLO this Runbook protects (e.g., error rate < X%, MTTR < Y min).
- **Observability:** The dashboard or alert that monitors the activation signals.

---

## Ownership and updates

- **Runbook owner:** the team responsible for the affected component or flow.
- **Review:** after each Runbook execution, verify that the procedure remains valid.
- **Mandatory update:** when the component, integration, or flow covered by the Runbook is modified in a Downstream delivery.

---

## Product Runbook template

To create a product Runbook, use:
`prodops/templates/operation/runbook.md`

Product runbooks live in: `prodops/artifacts/runbooks/`
