# OBC - Datadog Observability in Production

## Metadata

| Field | Value |
|---|---|
| Owner | [to be determined] |
| DS-ID | DS-50 |
| Iteration | v0.9.0 |
| Last updated | 2026-11-10 |

## Status

**State:** In Delivery
**Tracked in:** DS-50 (#44) — v0.9.0, PR #122 e PR #123. Previous record: Downstream. Status `Entrou` in `prodops/artifacts/plans/iteration-plan.md` — operational capability derived from EXP-010.
**Pending:** iteration completed (PR #122 e PR #123); candidate for `Operational` — confirm production rollout before promoting. Source: `prodops/artifacts/plans/iteration-plan.md`.

## Origin

| Link | Reference |
|---|---|
| Business Signal | [BS-004](../business-signals/BS-004.md) |
| Business Intent | [PI-010](../business-intents/PI-010.md) |
| Product Tracking Item | issue #44 (DS-50), see `prodops/artifacts/plans/iteration-plan.md` |
| Experiment | [EXP-010](../experiments/010-datadog-activation/experiment.md) |

## Business Outcome

The Payments API emits traces, metrics, and structured logs to Datadog in production. The team can diagnose failures by `correlationId`, `invoiceId`, and `tenantId` directly in Datadog without manually querying CloudWatch. Mean time to diagnose incidents decreases because the complete payment journey — creation, confirmation, webhook — is traceable in a single dashboard.

### In executive language

Today, when a customer reports that a payment was not confirmed, the team must query raw logs in CloudWatch without business context. With Datadog active, every request generates a trace connecting the Checkout call to the Asaas provider response — the team sees exactly where the journey stopped, in seconds, without manual database access.

It is the difference between searching a problem in a text file and seeing a map of the problem on a screen.

## Scope

**In scope**

- [to be determined]

**Out of scope**

- [to be determined]

## Business Rules

- [to be determined]

## Acceptance Criteria

Derived from the scenarios in `prodops/artifacts/bdd/observability-datadog.feature`; tick after verification.

- [ ] Requisicao gera trace visivel no Datadog APM
- [ ] Log estruturado contem dd.trace_id injetado
- [ ] Metricas de runtime Lambda aparecem no Datadog
- [ ] DatadogApiKey nao e exposta em logs ou traces
- [ ] Falha na extensao Datadog nao impede resposta da API

## Enterprise Context

| Item | Content |
|---|---|
| Value Stream / Product Service | n/a — platform/framework capability, not a Product Service |
| Stakeholders | [to be determined] |
| Compliance | [to be determined] |

## Observable Events

| Event | Status | Meaning | Required dimensions |
|---|---|---|---|
| `dd.trace.request` | [to be determined] | API request traced end-to-end in Datadog APM. | `service`, `env`, `http.method`, `http.url`, `correlationId`, `tenantId` |
| `dd.log.injected` | [to be determined] | Structured log with injected `dd.trace_id` — automatic log ↔ trace correlation. | `dd.trace_id`, `dd.span_id`, `invoiceId`, `correlationId` |
| `dd.metric.runtime` | [to be determined] | Lambda runtime metrics emitted (memory, cold starts, duration). | `service`, `env`, `function_name` |

## Initial SLIs

| SLI | Initial target | Source |
|---|---|---|
| API requests with trace visible in Datadog APM within 60s. | 99% | [to be determined] |
| Logs with injected `dd.trace_id` — log ↔ trace correlation active. | 100% | [to be determined] |
| Lambda runtime metrics available in Datadog. | 99% | [to be determined] |
| No secret or sensitive payload exposed in Datadog traces or logs. | 100% | [to be determined] |

## Reliability Rules

- `DD_LOGS_INJECTION=true` and `DD_TRACE_ENABLED=true` must be present in the production Lambda environment on every deploy.
- `DatadogApiKey` must be injected only via deploy secret — never stored in `samconfig.toml` or committed to the repository.
- The Datadog Extension Layer (`Datadog-Extension:97`) must be declared as an explicit version parameter — no `latest` to prevent uncontrolled updates.
- The service must be identified as `payments-api` with `DD_ENV=production` and `DD_VERSION` matching the deployed version.
- Extension failure must not prevent Lambda from responding — the extension operates as a sidecar, not as a critical function dependency.

## Risks

| Risk | Severity | Handling |
|---|---|---|
| [to be determined] | [to be determined] | see `prodops/artifacts/risks/risks.md` |

## Dependencies

| Type | Dependency | Note |
|---|---|---|
| — | [to be determined] | [to be determined] |

## Decisions

| Date | Decision | Rationale | Source |
|---|---|---|---|
| 2026-11-10 | Migration to the `local-obc.en.md` template: sections added, Status normalized, events classified by Status and SLIs with Source. | Template adherence and the rule that the event name is the one emitted in the code. Fields without a source marked `[to be determined]`. | `obc` skill (`fix` mode); `check-obc.sh` |

## Related Artifacts

- BDD: `prodops/artifacts/bdd/observability-datadog.feature`
- Experiment: `prodops/artifacts/experiments/010-datadog-activation/experiment.md`
- Iteration Plan: `prodops/artifacts/plans/iteration-plan.md`
- Related OBCs: `prodops/artifacts/obcs/production-cicd-pipeline.md`
