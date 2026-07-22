# Observability Policy

Observability is a first-class deliverable. Code that alters observable behavior must validate log output, error structure, and traceability before being considered complete.

## Logging rules

- Use structured JSON logging (pino). Do not use `console.log`.
- Every request must carry `correlationId` and `tenantId` in the log context.
- Log at `info` level: request received, provider call initiated, result persisted.
- Log at `warn` level: retries, degraded provider response, fallback activated.
- Log at `error` level: unhandled exceptions, provider errors that affect the client.
- Never log secrets, tokens, or PII. `X-Api-Token` and `ADMIN_SECRET` must be in pino's redact paths.

## Error responses

- HTTP 4xx errors must return a `message` field with a human-readable description.
- HTTP 5xx errors must not expose internal stack traces or provider details.
- All error responses must include the `correlationId` for support traceability.

## Traceability

- The `X-Correlation-Id` header must be propagated from the request to all downstream calls and log entries.
- `tenantId` must be present in every log line that records a business action.
- Provider payment IDs (`providerPaymentId`) must be logged when known.

## Metrics

- Record business metrics on critical events: invoice creation, payment confirmation, authorization rejection.
- Metrics must have `tenantId` and `status` dimensions to allow aggregation by tenant and by result.
- Do not block the main flow in case of metric failure.

## Health checks

- Health check endpoints (`/health`) must verify availability of DynamoDB and SQS.
- Health check must not include tenant data — only infrastructure availability.

## Observability First (principle)

Before implementing, define:
- Which logs will be emitted and at what level.
- Which `correlationId` will propagate through the call chain.
- Which metrics will be recorded.

Observability is not a post-implementation step. It is planned alongside the contract. See [ProdOps TDD — Observability First](../practices/prodops-tdd.md).

## Validation in tests

Observability validation is part of the [Hack Flow](../phases/hack/README.md). After the Green Bar, verify that:
- Expected log entries are emitted (use the Log String pattern).
- Error responses have the expected `message` and structure.
- No sensitive data appears in logs.
