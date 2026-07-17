# Service Deck - Purchase with Pix

> Template applied to the Purchase with Pix Value Stream of the Payments product. Use as a basis to detail the Service Blueprint, events, observable contracts, risks and escalations.

## 1. Identification

| Field | Content |
| --- | --- |
| Value Stream name | Purchase with Pix |
| Main product | Payments |
| Related products | Checkout, Order Management, Notification Service, Customer Service, Finance/Reconciliation |
| Expected result | Customer selects Pix, receives QR Code/copy-paste, makes payment, has payment confirmed and order released. |
| Criticality | Critical |
| Product owner | `[PM Payments]` |
| Technical owner | `[Tech Lead Payments]` |
| Last updated | `[YYYY-MM-DD]` |

## 2. Journey delimitation

| Item | Description |
| --- | --- |
| Start | Customer selects Pix as payment method at checkout. |
| End | Order is released in Order Management and customer receives confirmation. |
| Customer/user | Buying customer on ecommerce. |
| Expected success | QR Code generated, payment identified, confirmation published, order released and customer notified. |
| Relevant failure | Customer pays, but order does not advance; QR Code not generated; Pix expires without clarity; status becomes inconsistent. |
| Critical window | Black Friday, high-traffic campaigns, peak hours and Payments/Checkout releases. |

## 3. Service Blueprint

| Layer | Elements |
| --- | --- |
| Contact points | Checkout Web/App, Pix payment screen, QR Code, copy-paste, confirmation screen, email/push/WhatsApp. |
| Customer actions | Selects Pix, confirms purchase, copies/scans QR Code, pays at the bank, waits for confirmation. |
| Business actions | Create payment intent, reserve order, generate QR Code, await settlement, confirm payment, release order. |
| Domain events | `PagamentoIniciado`, `PixQRCodeGerado`, `PixPago`, `PagamentoConfirmado`, `PedidoLiberado`, `PagamentoExpirado`, `PagamentoFalhou`. |
| Systems and dependencies | Checkout, Payments API, Pix Provider, Payments DB, Message Broker, Order Management, Notification Service, Observability Stack. |
| Teams and escalations | Payments, Checkout, Orders, Platform/SRE, Customer Service, Finance. |

## 4. Main flow

1. Customer chooses Pix at checkout.
2. Checkout creates request in Payments.
3. Payments creates payment intent.
4. Payments requests QR Code from Pix Provider.
5. Pix Provider returns QR Code and expiry.
6. Checkout displays QR Code/copy-paste.
7. Customer makes payment at the bank.
8. Pix Provider sends confirmation or Payments queries status.
9. Payments publishes `PagamentoConfirmado`.
10. Order Management consumes event and releases order.
11. Notification Service informs customer.

## 5. Event Storming

| Event | Cause | Result | Producer system | Observability |
| --- | --- | --- | --- | --- |
| `PagamentoIniciado` | Customer selects Pix and confirms purchase. | Payment intent created. | Checkout/Payments | correlationId, orderId, paymentId, amount, method=Pix |
| `PixQRCodeGerado` | Payments receives QR Code from provider. | Customer can pay. | Payments | provider, expiration, latency, status |
| `PixQRCodeFalhou` | Provider returns error/timeout. | Customer does not receive QR Code. | Payments | errorCode, provider, retryable, traceId |
| `PixPago` | Provider reports payment made. | Payments can confirm payment. | Pix Provider/Payments | providerEventId, paymentId, paidAt |
| `PagamentoConfirmado` | Payments validates paid Pix. | Orders can release order. | Payments | paymentId, orderId, amount, confirmedAt |
| `PedidoLiberado` | Orders processes confirmation. | Order proceeds to fulfillment. | Order Management | orderId, paymentId, releasedAt |
| `PagamentoExpirado` | QR Code expires without payment. | Customer needs a new attempt. | Payments | expiration, paymentId, orderId |
| `PagamentoFalhou` | Unexpected failure in the flow. | Journey enters handled error. | Payments | dependency, errorCode, traceId |

## 6. Observable Business Contract

| Event | SLI | Initial SLO/limit | Impact | Response | Owner |
| --- | --- | --- | --- | --- | --- |
| `PixQRCodeGerado` | Percentage of QR Codes generated successfully. | 99.5% within 3s | Customer cannot pay with Pix. | Check Pix Provider, Payments API and timeout. | Payments |
| `PixPago` | Percentage of Pix payments received by Payments after settlement. | 99% within 10s after provider notification | Customer pays and gets no response. | Check provider webhook/query and queue. | Payments + Finance |
| `PagamentoConfirmado` | Percentage of paid Pix that generate confirmation. | 99% within 30s | Order stalled. | Escalate Payments; check Payments DB consistency. | Payments |
| `PedidoLiberado` | Percentage of confirmed payments reflected in Orders. | 99% within 30s | Customer paid, but order did not advance. | Escalate Orders + Payments; check broker/consumer. | Orders + Payments |
| `PagamentoExpirado` | Percentage of expirations communicated correctly. | 99% with clear response to customer | Customer tries to pay with expired Pix. | Check expiry and Checkout communication. | Payments + Checkout |

## 7. Reliability matrix

| Node/edge | Possible failure | Impact | Signal | Escalation | Runbook |
| --- | --- | --- | --- | --- | --- |
| Checkout -> Payments | Error creating Pix payment | Customer cannot initiate payment. | 5xx/4xx unexpected on `POST /payments/pix`. | Checkout + Payments | `[link]` |
| Payments -> Pix Provider | Timeout generating QR Code | QR Code not displayed. | p95/p99 latency and timeout rate. | Payments + SRE | `[link]` |
| Pix Provider -> Payments | Webhook not received | Pix paid without confirmation. | `PixPago` absent after provider confirms. | Payments + Finance | `[link]` |
| Payments DB | Inconsistent state | Divergent status. | paymentId in invalid/stagnant state. | Payments | `[link]` |
| Payments -> Broker | Event not published | Orders does not release order. | `PagamentoConfirmado` without publish/ack. | Payments + Platform | `[link]` |
| Broker -> Orders | Consumer stopped or with error | Order does not advance. | Lag/error in Orders consumer. | Orders + Platform | `[link]` |
| Orders -> Notification | Confirmation not notified | Customer without response. | `PedidoLiberado` without notification. | Orders + Communications | `[link]` |

## 8. Indicators and dashboards

| Indicator | Question it answers | Source | Dashboard |
| --- | --- | --- | --- |
| Pix QR Code generation rate | Can customer initiate Pix? | Payments/Pix Provider | `[link]` |
| Latency to generate QR Code | Is Pix fast? | Traces/APM | `[link]` |
| Pix paid without confirmation | Is there a break between provider and Payments? | Events/consistency | `[link]` |
| Confirmed payment without order released | Is there a break between Payments and Orders? | Events/Broker | `[link]` |
| Pix expirations | Are customers losing the payment window? | Payments | `[link]` |
| Errors per provider | Is the Pix dependency degraded? | Metrics/APM | `[link]` |
| Pix support tickets | Is the customer noticing failures? | Customer Service | `[link]` |

## 9. Risks

| Risk | Dimension | Probability | Impact | Action |
| --- | --- | --- | --- | --- |
| Unstable Pix provider at peak. | Technology/Pieces | Medium | High | Timeout, controlled retry, operational fallback and actionable alert. |
| Customer pays, but order does not release. | Customer/Flows | Medium | High | `PagamentoConfirmado -> PedidoLiberado` contract with SLO and reconciliation. |
| Divergent status between Payments, Provider and Orders. | Data | High | High | Reconciliation job/query and divergence dashboard. |
| QR Code expires without a clear message. | Customer | Medium | Medium | Expiry contract and retry UX. |
| Alerts without orderId/paymentId context. | Team/Data | High | High | Structured logs with correlationId, paymentId and orderId. |

## 10. Tests and validations

| Scenario | Type | Expected result |
| --- | --- | --- |
| Create Pix with valid payload | Starter/One Step | HTTP 201, paymentId and QR Code returned. |
| Create Pix with invalid contract | Explanation/Contract | HTTP 400 with clear contract error. |
| Pix Provider unavailable | Crash Test Dummy | Handled error, alert, log and no inconsistent state. |
| Pix paid and confirmed | End-to-end | `PixPago`, `PagamentoConfirmado`, `PedidoLiberado`. |
| Pix paid without Orders event | Regression | Confirmation-without-order alert. |
| Expired QR Code | Boundary | `PagamentoExpirado` event and clear response to customer. |

## 11. Runbooks

| Runbook | When to use | Link |
| --- | --- | --- |
| Pix QR Code not generated | Increase in error/timeout on generation. | `[link]` |
| Pix paid without confirmation | Customer paid, but Payments did not confirm. | `[link]` |
| Confirmed payment without order | Orders did not release order after confirmation. | `[link]` |
| Pix status divergence | Provider, Payments and Orders diverge. | `[link]` |

## 12. Links

| Type | Link |
| --- | --- |
| Product Deck Payments | `prodops/artifacts/product/context/product-deck.md` |
| OpenAPI Payments Pix | `[link]` |
| Pix Dashboard | `[link]` |
| Topics/events | `[link]` |
| Alerts | `[link]` |
| Runbooks | `[link]` |
| Backlog | `[link]` |

## 13. Definition of done

- Service Blueprint reviewed with Payments, Checkout, Orders and SRE.
- Main events defined and published in the catalog.
- Initial Observable Business Contract approved.
- Pix dashboard with success, error, latency and divergence.
- Alert for Pix paid without confirmation.
- Minimum runbook for critical scenarios.
- Backlog with prioritized reliability actions.
