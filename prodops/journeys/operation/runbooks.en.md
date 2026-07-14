# Runbooks

Operational procedures for supporting the Payments API release.

The scenarios covered here were identified in the release pre-mortem:
[`prodops/journeys/assessment/reliability-plans/premortem.md`](../assessment/reliability-plans/premortem.md)

For each runbook: diagnosis → immediate containment → resolution → verification.

---

## RB-001 — New Gateway Feature Flag Rollback

**Origin scenario:** PMT-PRE-005 — Feature Flag does not allow a clean rollback.

**When to use:** after disabling the new gateway Feature Flag in Checkout, orders already initiated in Payments continue receiving events or become orphaned.

### Alert Signals

- Orders with `invoiceId` created in Payments continue receiving webhooks after the flag is turned off.
- Checkout creates new orders in the old flow, but continues sending events to Payments.
- `payment.confirmed` emitted without a corresponding invoice in Payments.

### Diagnosis

```bash
# Check events arriving at Payments without a corresponding invoice
# CloudWatch Logs — filter by:
#   message: "invoice not found" OR "uncorrelated webhook"
#   correlationId: present in webhook logs

# Check webhook volume in the SQS DLQ
aws sqs get-queue-attributes \
  --queue-url "$STAGING_WEBHOOK_DLQ_URL" \
  --attribute-names ApproximateNumberOfMessages
```

### Immediate Containment

1. Do not disable the flag abruptly if there are orders with status `OPEN` or `CANCEL_REQUESTED` — these invoices need to be reconciled.
2. Record the exact flag disable time to delimit the scope of affected orders.
3. Keep Payments processing webhooks even with the flag turned off for Checkout — confirmation events for already-initiated orders must be completed.

### Reconciliation Policy

| Invoice State | Action After Rollback |
|---|---|
| `OPEN` | Wait for confirmation or cancellation webhook from the provider. Do not cancel manually without confirmation. |
| `CANCEL_REQUESTED` | Wait for `PAYMENT_DELETED` webhook. If it does not arrive within 24h, check in the Asaas panel. |
| `CONFIRMED` | No action needed. Event already emitted. |
| `CANCELLED` | No action needed. |

### Post-Resolution Verification

- [ ] No invoice in `OPEN` status created after rollback without resolution.
- [ ] DLQ message volume returned to baseline.
- [ ] Logs without `uncorrelated webhook` above baseline.

**Record:** date/time, scope of affected orders, decision made → [`prodops/journeys/operation/operational-trail.md`](operational-trail.md)

---

## RB-002 — Invoice Creation Failure / Provider Timeout

**Origin scenario:** PMT-PRE-001 — Checkout enables the new gateway and some orders do not create an invoice. PMT-PRE-007 — Invoice creation generates a duplicate charge.

**When to use:** `POST /invoices` returns 4xx/5xx at abnormal volume, or the same `orderId` appears with more than one invoice in the provider.

### Alert Signals

- Error rate on `POST /invoices` above baseline (>1% in a 5 min window).
- Same `orderId` with more than one invoice with status `OPEN` in DynamoDB.
- Logs with `provider returned error` or AsaasService timeout.

### Diagnosis

```bash
# CloudWatch Logs — filter creation errors
# message: "provider returned error" OR level: "error" AND service: "invoices"
# Check: is it a 4xx error (contract) or 5xx (provider instability)?
```

### Containment — Provider 4xx (Contract Error)

1. Identify the rejected payload (check `message` in the response body).
2. If it is a Payments validation error, create a fix with a new Hack cycle.
3. Do not retry automatically — 4xx retries create duplicates.

### Containment — Provider 5xx (Provider Instability)

1. Check Asaas public status.
2. Retries with `Idempotency-Key` are safe — Payments rejects duplicates by `orderId + tenantId`.
3. If instability persists >15 min, notify Checkout to pause new creations.

### Containment — Duplicate Invoice

1. Identify both invoices by `orderId`.
2. Cancel the duplicate invoice via `DELETE /invoices/{invoiceId}` with a unique `Idempotency-Key`.
3. Confirm that only one invoice remains with status `OPEN` for the `orderId`.

### Post-Resolution Verification

- [ ] Error rate on `POST /invoices` returned to baseline.
- [ ] No `orderId` with two `OPEN` invoices in DynamoDB.
- [ ] Idempotency verified: same `orderId` + same `Idempotency-Key` returns 201 with the original invoice.

**Record:** → [`prodops/journeys/operation/operational-trail.md`](operational-trail.md)

---

## RB-003 — Confirmed Payment Without Customer Notification

**Origin scenario:** PMT-PRE-002 — Customer pays but does not receive confirmation.

**When to use:** `payment.confirmed` was emitted by Payments but the customer did not receive communication, or the Notification Service reported a failure.

### Alert Signals

- Invoice with status `CONFIRMED` in DynamoDB but no notification entry in Notification Service logs.
- Increase in tickets: "I paid but did not receive confirmation".
- `payment.confirmed` event in Payments logs without a corresponding event in Notification Service.

### Diagnosis

```bash
# 1. Check if the event was emitted by Payments
# CloudWatch Logs — Payments
# Search for: invoiceId + "payment.confirmed" (structured log)
# Confirm: tenantId, orderId, invoiceId, correlationId present

# 2. Check if the event reached Notification Service
# Search for the same correlationId or invoiceId in Notification Service logs
# If absent: event delivery problem
# If present but without send: Notification Service processing failure

# 3. Check DLQ
aws sqs get-queue-attributes \
  --queue-url "$STAGING_WEBHOOK_DLQ_URL" \
  --attribute-names ApproximateNumberOfMessages
```

### Containment

| Cause | Action |
|---|---|
| Event did not reach Notification Service | Check SQS/EventBridge queue; reprocess from DLQ after resolving the root cause |
| Event arrived but was not processed | Contact Notification Service team with `correlationId` and `invoiceId` |
| Duplicate notification | Check idempotency by `invoiceId` in Notification Service |

### Last-Resort Manual Action

If there is no immediate resolution, support can confirm payment status by querying `GET /invoices/{invoiceId}` with the affected tenant's token.

### Post-Resolution Verification

- [ ] `payment.confirmed` with the affected `invoiceId` appears in Notification Service logs.
- [ ] Customer received communication (confirmed by send log or by support).
- [ ] DLQ event volume returned to baseline.

**Record:** → [`prodops/journeys/operation/operational-trail.md`](operational-trail.md)

---

## RB-004 — Provider Webhook Not Processed

**When to use:** an Asaas event (`PAYMENT_CONFIRMED`, `PAYMENT_DELETED`) arrived at the `/webhook/payments` endpoint but the invoice was not updated.

### Alert Signals

- Invoice remains in `OPEN` or `CANCEL_REQUESTED` for more than 10 min after expected event.
- Logs with `webhook received` but without `invoice updated`.
- Messages accumulating in the webhook DLQ.

### Diagnosis

```bash
# 1. Check if the webhook arrived
# CloudWatch Logs — filter by path "/webhook/payments" AND method "POST"
# Search for the providerPaymentId of the affected order

# 2. Check signature (401 in logs = incorrect token)
# Compare ASAAS_WEBHOOK_TOKEN configured in Lambda with the value in the Asaas panel

# 3. Check DLQ
aws sqs receive-message \
  --queue-url "$STAGING_WEBHOOK_DLQ_URL" \
  --max-number-of-messages 10
```

### Containment

| Cause | Action |
|---|---|
| Incorrect webhook token | Fix `ASAAS_WEBHOOK_TOKEN` in Lambda and re-register the webhook in Asaas |
| Invoice not found by `providerPaymentId` | Check if `providerPaymentId` was correctly saved during invoice creation |
| Event in DLQ | Manually reprocess after resolving the root cause |
| Asaas not retrying | Manually re-register the status transition via `PUT /invoices/{invoiceId}` (internal use) |

### Post-Resolution Verification

- [ ] Invoice with correct status in DynamoDB.
- [ ] Event recorded in `RawProviderEvents` table with corresponding `eventKey`.
- [ ] DLQ at baseline volume.

**Record:** → [`prodops/journeys/operation/operational-trail.md`](operational-trail.md)

---

## RB-005 — Diagnosis Guide by Identifiers

**Origin scenario:** PMT-PRE-006 — Teams cannot diagnose failures quickly.

Use this guide to locate any event in the Checkout → Payments → Asaas → Notification Service chain.

### Available Identifiers

| Identifier | Origin | Where to Search |
|---|---|---|
| `orderId` | Checkout | InvoicesTable (OrderIdIndex), Payments logs |
| `invoiceId` | Payments (prefix `inv_`) | InvoicesTable (primary key), all Payments logs |
| `providerPaymentId` | Asaas (prefix `pay_`) | InvoicesTable, Payments logs, Asaas panel |
| `correlationId` | Header `X-Correlation-Id` | All request logs and emitted events |
| `tenantId` | Header / payload | InvoicesTable, all Payments logs |
| `tokenId` | ApiTokensTable | Authentication logs (never the raw token) |

### Recommended Search Sequence

```
1. Start from the available identifier (orderId, invoiceId or providerPaymentId)
2. Locate the invoice in DynamoDB
3. Obtain correlationId and providerPaymentId from the invoice
4. Search CloudWatch Logs by correlationId to trace the entire chain
5. Check in the Asaas panel by providerPaymentId if necessary
```

### Required Fields in All Logs

Every Payments log must have: `correlationId`, `tenantId`, `invoiceId` (when applicable), `level`, `msg`.

If a log does not have these fields, the problem is in instrumentation — open an item in the Repository Tracking List (`TL-003`).
