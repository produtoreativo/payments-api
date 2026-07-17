# Mapping: OBC Observable Events → DORA Metrics

This document maps the 41 Observable Events from the 7 committed OBCs of payments-api to the 7 extended DORA metrics.

---

## How to read this mapping

Each event can **directly feed** a metric (the event alone is the signal) or **contribute indirectly** (the event is part of a calculation that requires correlation with another event or with pipeline data).

Identified gaps indicate where current instrumentation is insufficient and what needs to be added to cover the metric completely.

---

## 1. Lead Time for Change

**What it measures:** time between a code commit and it running in production.

**Nature:** pipeline metric — not directly mapped to OBC events.

**Signal available in OBCs:** no domain event signals "code was just deployed". The first event from any OBC after a deploy indicates the change reached production, but the commit timestamp must come from CI/CD.

**Gap:** absence of a deployment event in OBCs. Lead Time requires pipeline integration (e.g.: GitHub Actions → DataDog deploy timestamp).

| OBC | Event | Contribution |
|---|---|---|
| All | First event after deploy | ⚠ Indirect — marks "reached production", but not the initial commit |

---

## 2. Release Frequency

**What it measures:** frequency of successful deploys to production.

**Nature:** pipeline metric — not mapped to OBC events.

**Gap:** no OBC event records a deploy. Requires CI/CD instrumentation.

| OBC | Event | Contribution |
|---|---|---|
| — | — | ✗ Not mappable via OBC events |

---

## 3. Change Fail Rate

**What it measures:** percentage of changes that cause observable failure or degradation in production.

**Nature:** hybrid — part pipeline (deploy × incident correlation), part OBC (post-deploy failure rate).

**Signal available in OBCs:** capability failure events that can be correlated with recent deploys.

| OBC | Event | Contribution |
|---|---|---|
| create-invoice | `invoice.creation_failed` | ✅ Direct — capability failure; spike after deploy = change failure |
| create-invoice | `invoice.provider_rejected` | ✅ Direct — rejection due to invalid data; new after deploy = regression |
| create-invoice | `invoice.access_rejected` | ✅ Direct — tenant without access to provider; new behavior after deploy |
| create-invoice-boleto | `payment.boleto.creation_failed` | ✅ Direct — boleto creation failure |
| cancel-invoice | `invoice.cancel_provider_not_found` | ✅ Direct — provider 404; may indicate a change that broke correlation |
| payment-confirmation | `webhook.rejected` | ✅ Direct — rejected webhook; high rate after deploy indicates auth regression |
| credit-card | `payment.card.refused` | ⚠ Indirect — refusal can be business or regression; correlate with deploy |
| webhook-configuration | `webhook.delivery.failed` | ✅ Direct — delivery failure; spike after deploy = change failure |
| api-token-validation | `api.token.rejected` | ⚠ Indirect — may be invalid attempt or regression; monitor rate |

**Note:** Change Fail Rate at deploy level requires correlating the deploy timestamp with an increase in the rate of these events. Monitor for 30 minutes after each deploy.

---

## 4. Mean Time to Recovery (MTTR)

**What it measures:** average time from failure detection to complete recovery.

**Nature:** operational — requires incident management tooling (PagerDuty, DataDog incidents) correlated with recovery events.

**Signal available in OBCs:** failure → success event pairs that bound the recovery window per attempt.

| OBC | Event pair | Contribution |
|---|---|---|
| create-invoice | `invoice.creation_failed` → `invoice.created` (retry) | ✅ Direct — time gap = individual creation recovery |
| cancel-invoice | `invoice.cancel_provider_not_found` → `payment.cancelled` | ✅ Direct — gap = time to reconciliation/recovery |
| webhook-configuration | `webhook.delivery.failed` → `webhook.delivery.sent` | ✅ Direct — gap = delivery recovery time |
| payment-confirmation | `webhook.received` without `payment.confirmed` → later `payment.confirmed` | ⚠ Indirect — requires correlation by `correlationId` |

**Gap:** absence of "incident declared" and "incident resolved" events in OBCs. Service-level incident MTTR requires integration with incident management.

---

## 5. Reaction Time

**What it measures:** time between the arrival of an external signal and the first action processed by the system.

**Nature:** directly mappable via OBC event timestamps.

| OBC | Event pair | What it measures |
|---|---|---|
| payment-confirmation | `webhook.received` → `payment.confirmed` | Time between webhook arrival and processed confirmation |
| payment-confirmation | `webhook.received` → `webhook.rejected` | Immediate rejection — security reaction time |
| payment-confirmation | `webhook.received` → `webhook.deduplicated` | Immediate deduplication — idempotency reaction time |
| payment-confirmation | `webhook.received` → `webhook.correlated_by_reference` | Reference correlation time |
| api-token-validation | `api.token.validated` | Validation latency — authentication reaction time |
| webhook-configuration | `webhook.delivery.sent` | Delivery latency after event — notification reaction time |
| credit-card | `payment.card.authorization.requested` → `payment.card.authorized` | Card authorization time |
| credit-card | `payment.card.authorization.requested` → `payment.card.refused` | Refusal time — reaction time even on failure |

**Existing SLI that directly feeds Reaction Time:**
- `webhook.delivery.sent` within 5s after event — 95% (webhook-configuration OBC)
- Card attempts with terminal outcome within 5 min — 99% (credit-card OBC)
- Card confirmations within 30s — 99% (credit-card OBC)

---

## 6. Rate of Return

**What it measures:** rate of defects escaped to production and rework generated.

**Nature:** directly mappable — retries and chargeback requests are rework signals.

| OBC | Event | What it measures |
|---|---|---|
| create-invoice | `invoice.idempotency_hit` | Customer retried — may indicate previous ambiguous response or failure |
| create-invoice-boleto | `payment.boleto.idempotency_hit` | Customer retried boleto creation |
| cancel-invoice | `invoice.cancel_idempotency_hit` | Customer retried cancellation |
| credit-card | `payment.card.refund.requested` | Refund requested after confirmation — escaped post-delivery defect |
| credit-card | `payment.card.refund.required` | Refund required due to impossibility of cancellation — operational rework |

**Note:** `idempotency_hit` alone does not confirm rework (may be a legitimate network retry). Correlate with absence of a prior successful response to differentiate network retry from failure-driven retry.

---

## 7. Availability

**What it measures:** percentage of time the service is available and responding correctly.

**Nature:** directly mappable via success/failure ratio per time window.

| OBC | Numerator | Denominator | SLI |
|---|---|---|---|
| create-invoice | `invoice.created` | `invoice.created` + `invoice.creation_failed` + `invoice.provider_rejected` | 99.9% target |
| create-invoice-boleto | `payment.boleto.created` | `payment.boleto.created` + `payment.boleto.creation_failed` | 99.9% target |
| payment-confirmation | `payment.confirmed` (published 1x) | `PAYMENT_CONFIRMED` webhooks received | 100% target |
| webhook-configuration | `webhook.delivery.sent` | `webhook.delivery.sent` + `webhook.delivery.failed` | 95% within 5s |
| api-token-validation | `api.token.validated` | `api.token.validated` + `api.token.rejected` (genuine invalid token excluded) | 99.9% target |
| cancel-invoice | `payment.cancelled` | `payment.cancelled` + unresolved states | 99.9% target |
| credit-card | `payment.confirmed` | Attempts initiated with `payment.card.authorization.requested` | 99% within 5min |

**Note:** `api.token.rejected` for absent or invalid tokens is not an Availability failure — it is correct behavior. Authentication availability = % of valid tokens authorized without excessive latency.

---

## Summary: coverage by metric

| DORA Metric | Coverage via OBC Events | Gap |
|---|---|---|
| Lead Time for Change | ⚠ Partial — first event post-deploy | Requires CI/CD integration for commit timestamp |
| Release Frequency | ✗ Not covered | Requires CI/CD instrumentation |
| Change Fail Rate | ✅ Covered — 9 failure events mapped | Requires temporal correlation with deploys |
| MTTR | ✅ Covered — 4 failure→recovery pairs mapped | Requires incident management for service-level MTTR |
| Reaction Time | ✅ Covered — 8 event pairs mapped | Existing SLIs already aligned |
| Rate of Return | ✅ Covered — 5 rework events mapped | Distinguish legitimate retry from failure-driven retry |
| Availability | ✅ Covered — 7 success/failure ratios mapped | Existing SLIs already aligned |

---

## Instrumentation gaps identified

For complete coverage of the 7 DORA metrics, the following events are absent from OBCs:

| Gap | Affected metrics | Recommended action |
|---|---|---|
| Deployment event (deploy started / deploy completed) | Lead Time for Change, Release Frequency, Change Fail Rate | Integrate CI/CD pipeline with DataDog or equivalent |
| Incident event (declared / resolved) | MTTR | Integrate PagerDuty or incident management |
| Rollback event | Change Fail Rate, MTTR | Add to pipeline and to gateway configuration OBC |
