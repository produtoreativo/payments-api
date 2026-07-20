# Reliability Checklist

Use before promoting a capability from Upstream to Downstream, or before shipping a Downstream item.

## Behavior coverage

- [ ] OBC defined and measurable.
- [ ] All acceptance criteria covered by tests.
- [ ] Failure modes documented in `prodops/journeys/assessment/risks.md`.

## Observability

- [ ] Operations on the critical path emit structured logs.
- [ ] Error responses include correlation IDs.
- [ ] No secrets or PII in logs.
- [ ] SLO signal identified (metric- or log-based).

## Operational readiness

- [ ] Runbook exists or was updated in `prodops/journeys/operation/runbooks.md`.
- [ ] On-call team notified of new failure mode.
- [ ] Rollback plan defined.

## Evidence

- [ ] Pre-deploy test run recorded.
- [ ] Post-deploy validation completed.
- [ ] Entry added to the active session trail at `prodops/artifacts/governance/trails/sessions/YYYY-MM-DD-<session-id>.md`.
