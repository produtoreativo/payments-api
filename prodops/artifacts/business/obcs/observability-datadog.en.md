# OBC - Datadog Observability in Production

## Status

Downstream. Status `Entrou` in `prodops/artifacts/governance/plans/iteration-plan.md` — operational capability derived from EXP-010.

## Business Outcome

The Payments API emits traces, metrics, and structured logs to Datadog in production. The team can diagnose failures by `correlationId`, `invoiceId`, and `tenantId` directly in Datadog without manually querying CloudWatch. Mean time to diagnose incidents decreases because the complete payment journey — creation, confirmation, webhook — is traceable in a single dashboard.

### In executive language

Today, when a customer reports that a payment was not confirmed, the team must query raw logs in CloudWatch without business context. With Datadog active, every request generates a trace connecting the Checkout call to the Asaas provider response — the team sees exactly where the journey stopped, in seconds, without manual database access.

It is the difference between searching a problem in a text file and seeing a map of the problem on a screen.

## Observable Events

| Event | Meaning | Required dimensions |
|---|---|---|
| `dd.trace.request` | API request traced end-to-end in Datadog APM. | `service`, `env`, `http.method`, `http.url`, `correlationId`, `tenantId` |
| `dd.log.injected` | Structured log with injected `dd.trace_id` — automatic log ↔ trace correlation. | `dd.trace_id`, `dd.span_id`, `invoiceId`, `correlationId` |
| `dd.metric.runtime` | Lambda runtime metrics emitted (memory, cold starts, duration). | `service`, `env`, `function_name` |

## Initial SLIs

| SLI | Initial target |
|---|---|
| API requests with trace visible in Datadog APM within 60s. | 99% |
| Logs with injected `dd.trace_id` — log ↔ trace correlation active. | 100% |
| Lambda runtime metrics available in Datadog. | 99% |
| No secret or sensitive payload exposed in Datadog traces or logs. | 100% |

## Reliability Rules

- `DD_LOGS_INJECTION=true` and `DD_TRACE_ENABLED=true` must be present in the production Lambda environment on every deploy.
- `DatadogApiKey` must be injected only via deploy secret — never stored in `samconfig.toml` or committed to the repository.
- The Datadog Extension Layer (`Datadog-Extension:97`) must be declared as an explicit version parameter — no `latest` to prevent uncontrolled updates.
- The service must be identified as `payments-api` with `DD_ENV=production` and `DD_VERSION` matching the deployed version.
- Extension failure must not prevent Lambda from responding — the extension operates as a sidecar, not as a critical function dependency.

## Related Artifacts

- BDD: `prodops/artifacts/business/bdd/observability-datadog.feature`
- Experiment: `prodops/artifacts/experiments/010-datadog-activation/experiment.md`
- Iteration Plan: `prodops/artifacts/governance/plans/iteration-plan.md`
- Related OBCs: `prodops/artifacts/business/obcs/production-cicd-pipeline.md`
