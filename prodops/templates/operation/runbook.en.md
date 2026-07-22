# Runbook — [Scenario Name]

Canonical location: new section in `prodops/framework/journeys/operation/runbooks.md`

---

## When to use

Describe the symptom or alert that triggers this runbook.

Examples:

- "Pix paid without confirmation in N minutes"
- "Primary gateway error rate above X%"

---

## Impact

| Dimension | Description |
|---|---|
| Customer | |
| Business (GMV/conversion) | |
| Affected SLO | |
| Suggested severity | SEV1 / SEV2 / SEV3 |

---

## Diagnosis

Steps to confirm the problem.

```bash
# Verification command 1
# Verification command 2
```

Expected logs / observability queries:

---

## Probable root cause

List the most common causes and how to distinguish them.

| Cause | How to identify |
|---|---|
| | |

---

## Immediate mitigation

Actions that reduce impact without resolving the root cause.

```bash
# Command or action
```

---

## Resolution

Steps to fix the root cause.

```bash
# Command or action
```

---

## Post-resolution verification

How to confirm that the service has returned to normal.

- [ ]
- [ ]

---

## Rollback

If necessary, how to revert the change that caused the problem.

---

## Escalation

| Situation | Engage |
|---|---|
| Problem persists after mitigation | |
| Impact on more than X% of transactions | |

---

## Usage history

| Date | Incident | Who triggered | Resolution |
|---|---|---|---|
| | | | |
