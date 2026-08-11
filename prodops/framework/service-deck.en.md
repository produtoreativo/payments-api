# Service Deck

The Service Deck is a single-page canvas that represents a service as if it were a product — with the same level of detail and the same sections as the Product Deck, but with the service as the central unit of analysis.

A service listed in the **Product Services** section of a Product Deck has exactly one Service Deck. The Service Deck is the artifact that details what the Product Deck merely enumerates.

---

## Types of Product Service

A Product Service can be one of two types, and the Service Deck applies to both:

| Type | Definition |
|---|---|
| **Service** | A single deployable unit: microservice, API, worker, queue processor. It has clear boundaries, a single responsibility, and its own SLO. |
| **Value Stream** | A logical grouping of one or more Services that together deliver a specific business outcome. The outcome is not achieved by any single service in isolation — it emerges from their collaboration. A Value Stream has a consolidated Service Deck; each constituent Service may or may not have its own Service Deck, depending on maturity and operational need. |

---

## Link to the Local OBC: the Data dimension

Each Service Deck corresponds to exactly one **Local OBC**. The OBC is where the service's data contracts live:

- Public APIs (endpoints, request/response contracts)
- Published and consumed events (event domain)
- Externally relevant persistence schemas
- Observable SLIs (Service Level Indicators)

The Service Deck does not duplicate the OBC — it **surfaces** it in the Service Endpoints section, making the Data dimension visible as part of the service's operational view. The OBC is the source of truth; the Service Deck is the consolidated reading point.

```
Service Deck
  └── consumes → Local OBC
        ├── Data: APIs, events, schemas
        ├── SLIs → reliability number (surfaced in the Product Deck)
        └── Reliability Rules → Reliability Plan
```

---

## Canonical sections

The Service Deck replicates the structure of the Product Deck, with terms adjusted for the service scope:

### 1. Service Vision

**Question:** For whom does this service exist and what value does it deliver?

Same format as Product Vision (Geoffrey Moore / Lean Inception), but the consumer may be another service, another team, or the product as a whole:

```
For [service consumer — team, service, product],
who [need or problem],
the [service name]
is a [category: API, worker, value stream…]
that [primary differentiator].
Unlike [alternative or absence],
this service [decisive benefit].
```

---

### 2. Service Endpoints (Data)

**Question:** What are the data contracts of this service?

This is the section that materializes the **Data dimension** of the Product Topology at the service level. Source: Local OBC.

| Category | Examples |
|---|---|
| **Public APIs** | `POST /payments`, `GET /invoices/{id}` — request/response contract |
| **Published events** | `payment.confirmed`, `invoice.issued` — schema and channel |
| **Consumed events** | `order.created`, `refund.requested` — consumption contract |
| **External schemas** | Data models exposed for integrations |

A service without defined Service Endpoints has no observable contract — it cannot be listed as a Product Service in the Product Deck.

---

### 3. Service Team

**Question:** Who is responsible for building and operating this service?

Same structure as the Product Team section of the Product Deck, but scoped to the service:
- **Owner:** responsible for the OBC and the SLO
- **On-call:** who to activate during incidents, with channel and expected response time
- **Consumers:** teams or services that depend on this service

---

### 4. Service Architecture

**Question:** How do the service's internal components connect and what are its dependencies?

Maps:
- Internal components of the service (API layer, workers, database, cache)
- Direct dependencies on other product services
- External dependencies (providers, third-party APIs)

Corresponds to the **`Components` Product Dimension** scoped to the service. For a Value Stream, the diagram shows how the constituent Services collaborate to produce the business outcome.

---

### 5. Service Reliability

**Question:** What is this service's reliability commitment and how is it being met?

| Field | Source | Description |
|---|---|---|
| **SLO** | Local OBC | Formal availability/latency commitment |
| **SLIs** | Local OBC | Observable metrics that prove the SLO |
| **Error Budget** | SLO − current SLI | Available margin before a violation |
| **MTTR** | Release Trail + Incidents | Mean time to recovery |

For a Value Stream, the consolidated SLO is derived from the SLOs of its constituent Services — usually the most restrictive one or the combination that reflects the critical path.

---

### 6. Service Analytics

**Question:** Is the service delivering the expected outcome to its consumers?

Business and operational metrics specific to the service:
- Throughput (volume of processed operations)
- Latency (p50, p95, p99)
- Error rate (by failure type)
- Service-specific business KPIs (e.g., payment approval rate, invoice success rate)

---

### 7. Service Consumers

**Question:** Who depends on this service and what is the impact of a failure on them?

Lists the direct consumers of the service — other services, products, teams — with the expected impact of degradation or unavailability. Feeds the Reliability Matrix in the Product Deck.

The term "internal customer" is rejected. Consumers are **contract partners** — each has explicit responsibility for the contract exposed by the OBC.

---

## Canonical path

```
prodops/artifacts/services/<service-slug>/service-deck.md
```

A service has exactly one Service Deck. For Value Streams:

```
prodops/artifacts/services/<value-stream-slug>/service-deck.md
prodops/artifacts/services/<value-stream-slug>/services/<service-slug>/service-deck.md  ← optional per constituent
```

---

## Lifecycle

The Service Deck is a **living artifact**, updated whenever the service state or its OBC changes:

| Moment | Expected update |
|---|---|
| **Local OBC committed** | Create or update Service Endpoints with OBC contracts |
| **New capability becomes Operational** | Update Service Endpoints, Service Reliability, and Service Analytics |
| **SLO change** | Update Service Reliability and reflect in the reliability number in the Product Deck |
| **Service architecture change** | Update Service Architecture |
| **New consumer** | Update Service Consumers and the Product Deck's Reliability Matrix |
| **Incident** | Update Service Reliability (MTTR, Error Budget) after postmortem |

---

## Relationship with other ProdOps artifacts

```
Service Deck
  ├── is referenced by → Product Deck  [Product Services]
  ├── consumes → Local OBC  [Service Endpoints: APIs, events, schemas, SLIs]
  ├── consumes → Reliability Plan  [Service Reliability: SLOs, risk analysis]
  ├── consumes → Release Trail  [Service Analytics: post-delivery metrics]
  ├── references → Product Topology: Components  [Service Architecture]
  ├── references → Product Topology: Data  [Service Endpoints — via Local OBC]
  └── feeds → Product Deck Reliability Matrix  [Service Consumers + SLO]
```

---

## References

→ [Product Deck](product-deck.en.md) — the product-level artifact that references the Service Deck
→ [OBC: Observable Business Contract](obc.en.md) — source of truth for data contracts and SLIs
→ [Reliability Plan](artifact-types.en.md#reliability-plan) — detailed risk analysis and SLOs
→ [Product Topology](product-topology.en.md) — the structural dimensions (Components, Data, Team, Flow)
→ [Reliability Matrix — Produto Reativo](https://produtoreativo.com.br/matriz-de-confiabilidade/)
