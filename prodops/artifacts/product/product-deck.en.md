# Product Deck - Payments

> Template applied to the Payments product mentioned in the ProdOps course material, in the Magazine Siara context. Use as a starting point and adjust team names, systems, links and real indicators.

## 1. Identification

| Field | Content |
| --- | --- |
| Product name | Payments |
| Short description | Product responsible for enabling, authorizing, confirming and observing payments in ecommerce purchase journeys. |
| Business context | Magazine Siara, high-volume ecommerce, checkout dependency, Pix, payment gateway, anti-fraud, order and notification. |
| Product owner | `[Product Manager Payments]` |
| Technical owner | `[Tech Lead Payments]` |
| Main teams | Payments, Checkout, Order Management, Anti-fraud, Platform/SRE, Customer Service, Operations. |
| Main channel | `[Slack/Teams: #payments-prodops]` |
| Last updated | `2026-07-12` |

## 2. Product Vision

For customers who shop at Magazine Siara's ecommerce, the Payments product must enable reliable, fast, traceable and interchangeable payments, ensuring that every payment attempt has a clear response, observable confirmation and operational continuity even in the face of failures in gateways, Pix, anti-fraud or external integrations.

Payments exists to protect conversion, GMV, customer trust and checkout operational capacity. The product must reduce entropy in the payment journey, allow rapid diagnosis and support changes such as payment method migration, new gateway, fallback and new commercial modalities.

### Payments as the System of Record

Payments is the internal, auditable and reconcilable source for invoices, charges and payment transitions associated with orders. Providers such as Asaas are external PSPs: they execute charges and send events, but do not govern Magazine Siara's operational truth.

Payments maintains internal identifiers, order, tenant and customer associations, the selected provider, external identifiers, idempotency and transition history. External states and events must be translated into the canonical model without losing data required for audit and reconciliation.

The technical boundary and currently implemented state are documented in the [Architecture Overview](../../journeys/assessment/architecture/overview.en.md). This vision does not automatically approve states, events or behaviors absent from committed OBCs and BDD Features.

## 3. Problems and opportunities

| Item | Description | Dimension |
| --- | --- | --- |
| New payment gateway | Migrate or integrate new gateway without breaking checkout, orders and reconciliation. | Company, Technology |
| Single-item Pix purchase | Create reliability for a critical journey, simple enough to map end to end. | Customer, Technology |
| Checkout problem | GMV can fall even with campaign increases if payment/checkout degrades. | Customer, Company |
| Low traceability | Payment failures must be explained by a domain event, not just by technical status. | Data, Flows |
| Interchangeability | Gateway must be replaceable via fallback, clear contracts and preserved observability. | Technology, Team |
| Poor alerts | Generic or context-free alerts increase MTTR and operational fatigue. | Data, Team |

## 4. Services

| Service / Journey | Customer/User | Expected result | Criticality | Service Deck | Status — v0.0.1 |
| --- | --- | --- | --- | --- | --- |
| Purchase with Pix | Buying customer | Pix generated, paid, confirmed and order released. | Critical | [compra-com-pix.md](service-decks/compra-com-pix.md) | Under development |
| Purchase with Boleto | Buying customer | Boleto generated with typed line and PDF link, confirmed by provider webhook. | High | — | Under development |
| Purchase with Credit Card | Buying customer | Card authorized via hosted flow, confirmed and order released. | High | — | Planned |
| Payment confirmation | Checkout, Order Management | Payment confirmed via webhook; order advances in the flow without manual intervention. | Critical | — | Under development |
| Payment result notification to customer | Customer, integrating systems | Customer and systems receive status update via webhook with verifiable signature. | High | — | Under development (MVP) |
| Pending invoice cancellation | Operations, customer | Inactive charge eliminated; no value processed after cancellation. | High | — | Implemented — deferred to post v0.0.1 |
| Authentication via API Token | Integrating systems | Only authorized systems access the API; access traceable by tenant and token. | Critical | — | Under development |
| Webhook configuration | Integrating systems | Consumer registers endpoint and receives payment events without polling. | High | — | Under development |
| Payment status query | Customer Service, customer, operations | Current status consistent between Payments, provider and Order Management. | High | — | Planned |
| Gateway fallback | Checkout, operations | Alternative gateway handles primary failures without loss of traceability. | High | — | Not planned — v0.0.1 |
| Payment reconciliation | Finance, operations | Payments reconciled with orders and provider transactions. | High | — | Not planned — v0.0.1 |

## 5. Product team

| Role | Name/team | Responsibility | Channel |
| --- | --- | --- | --- |
| Product Manager | `[PM Payments]` | Prioritize journeys, risk, outcome and Payments roadmap. | `[link]` |
| Tech Lead | `[Tech Lead Payments]` | Architecture, contracts, reliability and technical decision. | `[link]` |
| Payments Engineering | `[Squad Payments]` | APIs, events, integrations, logs, metrics and tests. | `[link]` |
| Checkout | `[Squad Checkout]` | Payment experience in the purchase flow. | `[link]` |
| Order Management | `[Squad Orders]` | Order creation/release after confirmation. | `[link]` |
| Anti-fraud | `[Squad Anti-fraud]` | Risk analysis and blocking. | `[link]` |
| Platform/SRE | `[SRE/Platform]` | Observability, incidents, SLO, dashboards and runbooks. | `[link]` |
| Customer Service | `[CX/Customer Service]` | Handling of impacted customers and operational feedback. | `[link]` |
| Finance/Reconciliation | `[Finance Ops]` | Reconciliation, chargeback and financial divergences. | `[link]` |

## 6. Product architecture

> Component diagram: [`prodops/journeys/assessment/architecture/overview.md`](../../journeys/assessment/architecture/overview.md)
>
> The diagram is the canonical source of the system structure. Update whenever
> there is a structural change (new module, route, external dependency, table or
> event topic). See the complete rule in `AGENTS.md`.

| Piece | Type | Owner | Criticality | Note |
| --- | --- | --- | --- | --- |
| Checkout Web/App | Frontend/BFF | Checkout | Critical | Initiates payment attempt and presents response to customer. |
| Payments API | API | Payments | Critical | Orchestrates payment methods, contracts and status. |
| Pix Provider | External integration | Payments/Finance | Critical | Generates QR Code, receives confirmation and queries status. |
| Primary Gateway | External integration | Payments | Critical | Authorization/card/other methods. |
| Fallback Gateway | External integration | Payments | High | Must handle primary gateway failures with a clear contract. |
| Anti-fraud API | API/integration | Anti-fraud | High | Can approve, deny or place transaction under analysis. |
| Order Management | API/event consumer | Orders | Critical | Releases order after confirmed payment. |
| Message Broker | Queue/events | Platform | Critical | Distributes payment and order events. |
| Payments DB | Database | Payments | Critical | Transactional payment state. |
| Observability Stack | Logs/metrics/traces | Platform/SRE | Critical | Dashboards, alerts, traces and correlation id. |
| Notification Service | API/event consumer | Communications | Medium | Notifies customer about result. |

## 7. Reliability matrix

| Journey | Piece/dependency | Possible failure | Impact | Signal | Escalation |
| --- | --- | --- | --- | --- | --- |
| Purchase with Pix | Pix Provider | QR Code not generated | Customer cannot complete purchase; conversion drop. | Error rate on `PixQRCodeGerado`; 5xx/timeout error. | Payments + Platform |
| Purchase with Pix | Pix Provider | Payment made but not confirmed | Order stalled; support tickets opened. | `PixPago` event without `PagamentoConfirmado` within N minutes. | Payments + Orders |
| Authorization | Primary Gateway | Timeout or unavailability | Checkout degrades; GMV impacted. | Increased latency/timeout per gateway. | Payments + SRE |
| Authorization | Fallback Gateway | Fallback not triggered | Failure becomes non-interchangeable. | Primary failure without `GatewayFallbackAcionado` event. | Payments |
| Anti-fraud | Anti-fraud API | Analysis unavailable | Payments blocked or increased risk. | Error/timeout on anti-fraud decision. | Anti-fraud + Payments |
| Confirmation | Message Broker | Event not published | Orders does not release order. | Absence of `PagamentoConfirmado` in the expected topic. | Platform + Payments |
| Confirmation | Order Management | Order not updated | Customer pays and order does not advance. | `PagamentoConfirmado` without `PedidoLiberado`. | Orders + Payments |
| Customer Service | Status Query | Inconsistent status | Support without a reliable answer. | Divergence Payments DB x Gateway x Orders. | Payments + Customer Service |

## 8. Product Analytics

| Indicator | Type | Question it answers | Source | Cadence |
| --- | --- | --- | --- | --- |
| Authorization rate by payment method | Customer/Company | Can customers pay? | Payments/Gateway | Real-time + daily |
| Checkout conversion after payment selection | Customer/Company | Is payment impacting GMV? | Analytics/Checkout | Real-time + daily |
| p95/p99 authorization latency | Technology | Is the flow fast enough? | Traces/APM | Real-time |
| Error rate per gateway | Technology | Which dependency is degrading? | Metrics/APM | Real-time |
| Percentage of fallback triggered | Technology/Company | Is interchangeability working? | Payments events | Real-time + weekly |
| Confirmed payments without order released | Flow/Data | Is there a break between Payments and Orders? | Events/consistency | Real-time |
| Pix paid without confirmation on time | Customer/Technology | Did customer pay and get no response? | Pix/Payments events | Real-time |
| MTTR of Payments incidents | Team/Technology | Does the team recover the journey quickly? | Incident tool | Monthly |
| Actionable alerts vs noisy alerts | Team/Data | Is observability generating action or noise? | Alert manager | Bi-weekly |

## 9. Domain events

| Event | Description | Producer | Consumers | Minimum observability |
| --- | --- | --- | --- | --- |
| `PagamentoIniciado` | Customer chose payment method and initiated attempt. | Checkout/Payments | Payments, Analytics | correlationId, paymentId, orderId, method |
| `PixQRCodeGerado` | Pix QR Code was created successfully. | Payments | Checkout, Analytics | provider, expiration, latency |
| `PagamentoAutorizado` | Gateway authorized payment. | Payments | Orders, Analytics, Notifications | gateway, amount, method, latency |
| `PagamentoRecusado` | Payment was refused with a known reason. | Payments | Checkout, Analytics, Customer Service | reasonCode, gateway, method |
| `PagamentoConfirmado` | Payment was confirmed and can release the order. | Payments | Orders, Notifications, Analytics | paymentId, orderId, amount, confirmedAt |
| `PagamentoExpirado` | Payment window expired. | Payments | Checkout, Orders, Customer Service | method, expiration, orderId |
| `GatewayFallbackAcionado` | Flow used alternative gateway. | Payments | SRE, Analytics | gatewayOrigem, gatewayDestino, reason |
| `PagamentoFalhou` | Technical or unexpected failure in processing. | Payments | SRE, Customer Service | errorCode, dependency, traceId |

## 10. Observable Business Contracts

| Event | SLI | Initial SLO/limit | Impact | Response | Owner |
| --- | --- | --- | --- | --- | --- |
| `PagamentoConfirmado` | Percentage of confirmed payments reflected in Orders. | 99% within 30s | Order stalled after payment. | Escalate Payments + Orders; check broker and consumer. | Payments/Orders |
| `PixQRCodeGerado` | Percentage of QR Codes generated successfully. | 99.5% within 3s | Customer cannot pay with Pix. | Escalate Payments; evaluate provider and operational fallback. | Payments |
| `GatewayFallbackAcionado` | Percentage of eligible failures with fallback executed. | 95% of eligible failures | Gateway failure becomes unavailability. | Escalate Payments; check routing rules. | Payments |
| `PagamentoRecusado` | Percentage of refusals with mapped business reason. | 99% with known reasonCode | Customer and support without explanation. | Escalate Payments + Anti-fraud/Gateway. | Payments |
| `PagamentoFalhou` | Time to actionable alert with context. | Alert within 2min | High MTTR and slow troubleshooting. | Escalate SRE + Payments with runbook. | SRE/Payments |

## 11. Initial SLOs

| SLO | Window | Rationale |
| --- | --- | --- |
| 99.5% of payment attempts respond with success, known refusal or handled error. | 30 days | The customer must receive a clear response, not stay in an unknown state. |
| 99% of confirmed payments release the order within 30 seconds. | 30 days | Avoids customer paying without order advancing. |
| p95 of authorization below 3 seconds for primary gateway. | 7 days | Latency impacts checkout conversion. |
| 95% of eligible failures trigger fallback automatically. | 30 days | Ensures gateway interchangeability. |
| 100% of Payments SEV1/SEV2 incidents generate a postmortem and artifact update. | Monthly | Closes the ProdOps learning cycle. |

## 12. Dashboards

| Dashboard | Questions it should answer | Link |
| --- | --- | --- |
| Payments - Checkout Journey | Can the customer pay? Where is the drop? | `[link]` |
| Payments - Pix | Are QR Code, expiry, confirmation and divergences healthy? | `[link]` |
| Payments - Gateways | Which gateway is slow, refusing or failing? | `[link]` |
| Payments - Orders Consistency | Did confirmed payment become a released order? | `[link]` |
| Payments - Incidents | Which incidents occurred, MTTR and recurrence? | `[link]` |

## 13. Runbooks

| Runbook | When to use | Link |
| --- | --- | --- |
| Pix paid without confirmation | Customer paid, but order did not advance. | `[link]` |
| Primary gateway unavailable | Increase of timeout/5xx on the gateway. | `[link]` |
| Fallback not triggered | Eligible failure without fallback event. | `[link]` |
| Payment confirmed without order | Payments event not reflected in Orders. | `[link]` |
| Status divergence | Customer Service queries divergent status. | `[link]` |

## 14. Stakeholders

| Stakeholder | Interest | Decision made | Channel |
| --- | --- | --- | --- |
| Ecommerce Board | GMV, conversion, trust on Black Friday. | Risk and investment prioritization. | `[link]` |
| Checkout Product | Experience and conversion. | UX and journey prioritization. | `[link]` |
| Payments Product | Payments methods roadmap and reliability. | Payments product priority. | `[link]` |
| Finance | Reconciliation, cost, chargeback. | Financial rules and risk acceptance. | `[link]` |
| Customer Service | Reduced tickets and reliable responses. | Support procedures. | `[link]` |
| Platform/SRE | Operability, SLO, incidents. | Observability and response standards. | `[link]` |
| Security/Anti-fraud | Risk, fraud and compliance. | Approval and blocking policies. | `[link]` |

## 15. Links

| Type | Link |
| --- | --- |
| Payments API Repository | `[link]` |
| Checkout/BFF Repository | `[link]` |
| Payments Pipelines | `[link]` |
| OpenAPI/Contracts | `[link]` |
| Topics/Events | `[link]` |
| Dashboards | `[link]` |
| Alerts | `[link]` |
| Runbooks | `[link]` |
| Backlog | `[link]` |
| Postmortems | `[link]` |

## 16. Initial Repository Tracking List

| Item | Origin | Dimension | Owner | Status | Next action |
| --- | --- | --- | --- | --- | --- |
| Confirm Pix SLO with business. | Continuous Assessment | Customer/Company | PM Payments | Open | Validate initial target. |
| Map contracts with primary and fallback gateway. | Service Deck | Technology/Pieces | Tech Lead Payments | Open | Review OpenAPI and errors. |
| Create alert for Pix paid without confirmation. | ODD | Data/Flows | SRE + Payments | Open | Define query and runbook. |
| Validate `GatewayFallbackAcionado` event. | Reliability Plan | Technology/Data | Payments | Open | Implement or confirm event. |
| Review PagamentoConfirmado -> PedidoLiberado flow. | Reliability Matrix | Flows/Teams | Payments + Orders | Open | Draw Service Blueprint. |

## 17. Recommended next artifacts

- Service Deck for the `Compra com Pix` journey.
- Detailed Reliability Matrix for `PagamentoConfirmado -> PedidoLiberado`.
- Reliability Plan for migration or adoption of a new payment gateway.
- Observable Business Contract for `PagamentoConfirmado`.
- Runbook `Pix paid without confirmation`.
