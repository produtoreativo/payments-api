# Service Deck

The Service Deck is a single-page canvas that represents a service as if it were a product — with the same level of detail and the same sections as the Product Deck, but with the service as the central unit of analysis.

A service listed in the **Product Services** section of a Product Deck has exactly one Service Deck. The Service Deck is the artifact that details what the Product Deck merely enumerates.

A Service Deck brings together **one or more Local OBCs**. Each OBC is a **node** of the service — a capability with its own observable contract — and the set of nodes listed in the Service Deck is the **complete list** of what makes up that service.

---

## Types of Product Service

A Product Service can be one of two types, and the Service Deck applies to both:

| Type | Definition |
|---|---|
| **Service** | A single deployable unit: microservice, API, worker, queue processor. It has clear boundaries, a single responsibility, and its own SLO. |
| **Value Stream** | A logical grouping of one or more Services that together deliver a specific business outcome. The outcome is not achieved by any single service in isolation — it emerges from their collaboration. A Value Stream has a consolidated Service Deck; each constituent Service may or may not have its own Service Deck, depending on maturity and operational need. |

---

## Link to the Local OBCs: the nodes of the service

A Service Deck consumes **one or more Local OBCs**. Each OBC represents a **node** of the service: a capability with its own observable contract (for example, create invoice, confirm payment, cancel invoice). The Service Deck's list of nodes is the **complete list** of what makes up the service — a service behavior that has no node (OBC) has no observable contract.

| Situation | Nodes (OBCs) in the Service Deck |
|---|---|
| Service with a single capability | 1 |
| Service with several capabilities | N — one per capability |
| Value Stream | N — the nodes of the constituent Services that collaborate toward the business outcome |

Rules:

- **Node map.** The Service Deck lists all nodes at the start of the Service Endpoints section (node, OBC, OBC state, role in the service, contracts surfaced in the deck).
- **A node is a Local OBC.** The OBC remains the contract of **one** capability and belongs to a single product.
- **Shared node.** An OBC may be a node of more than one Service Deck when the capability is shared across services or Value Streams (for example, payment confirmation used by several payment methods). The OBC remains the single source of truth; each Service Deck only references it.
- **No OBC, no node.** A service needs at least one node with a committed Local OBC to be a Product Service. A capability of the service that has no committed OBC yet is flagged as a node pending an observable contract.

The data contracts of the service live in the OBC of each node:

- Public APIs (endpoints, request/response contracts)
- Published and consumed events (event domain)
- Externally relevant persistence schemas
- Observable SLIs (Service Level Indicators)

The Service Deck does not duplicate the OBCs — it **surfaces** them in the Service Endpoints section, organized by node, making the Data dimension visible as part of the service's operational view. The OBCs are the source of truth; the Service Deck is the consolidated reading point.

```
Service Deck
  ├── node 1 → Local OBC A
  │     ├── Data: APIs, events, schemas
  │     ├── SLIs ─────────────┐
  │     └── Reliability Rules → Reliability Plan
  ├── node 2 → Local OBC B
  │     ├── Data: APIs, events, schemas
  │     ├── SLIs ─────────────┤
  │     └── Reliability Rules → Reliability Plan
  └── service SLO  ←──── derived from the nodes' SLIs
        └── reliability number (surfaced in the Product Deck)
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

This is the section that materializes the **Data dimension** of the Product Topology at the service level. Source: the Local OBCs of the nodes. The section starts with the **node map** and organizes the contracts below it, **by node**:

| Node | Local OBC | OBC state | Role in the service | Contracts in this deck |
|---|---|---|---|---|
| `<capability name>` | `prodops/artifacts/obcs/<slug>.md` | Committed / In Delivery / Operational | `<what this node does in the service>` | ✅ complete / ⚠️ partial / ❌ not surfaced |

The **Contracts in this deck** column says whether the events, APIs and SLIs of the node's OBC are already surfaced in this Service Deck. A node with a committed OBC and unsurfaced contracts is a deck gap, not an OBC gap.


| Category | Examples |
|---|---|
| **Public APIs** | `POST /payments`, `GET /invoices/{id}` — request/response contract |
| **Published events** | `payment.confirmed`, `invoice.issued` — schema and channel |
| **Consumed events** | `order.created`, `refund.requested` — consumption contract |
| **External schemas** | Data models exposed for integrations |

A service without defined Service Endpoints (at least one node with a committed Local OBC) has no observable contract — it cannot be listed as a Product Service in the Product Deck.

---

### 3. Service Team

**Question:** Who is responsible for building and operating this service?

Same structure as the Product Team section of the Product Deck, but scoped to the service:
- **Owner:** responsible for the OBCs (nodes) and the SLO
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
| **SLO** | Local OBCs (per node) | Formal availability/latency commitment |
| **SLIs** | Local OBCs (per node) | Observable metrics that prove the SLO |
| **Error Budget** | SLO − current SLI | Available margin before a violation |
| **MTTR** | Release Trail + Incidents | Mean time to recovery |

When the service has more than one node, the consolidated SLO is derived from the nodes' SLOs and SLIs — usually the most restrictive one or the combination that reflects the critical path. For a Value Stream, the nodes are those of the constituent Services. The Service Deck records the SLO of each node and the consolidated SLO of the service; the consolidated one is what the Product Deck shows as the reliability number.

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
prodops/artifacts/product/context/service-decks/<service-slug>.md
```

A service has exactly one Service Deck. For Value Streams:

```
prodops/artifacts/product/context/service-decks/<value-stream-slug>.md
prodops/artifacts/product/context/service-decks/<service-slug>.md  ← optional per constituent
```

---

## Lifecycle

The Service Deck is a **living artifact**, updated whenever the service state or its OBC changes:

| Moment | Expected update |
|---|---|
| **Local OBC committed (new or existing node)** | Add or update the node in the node map and the Service Endpoints with the OBC contracts |
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
  ├── consumes → Local OBCs  [one per node — Service Endpoints: APIs, events, schemas, SLIs]
  ├── consumes → Reliability Plan  [Service Reliability: SLOs, risk analysis]
  ├── consumes → Release Trail  [Service Analytics: post-delivery metrics]
  ├── references → Product Topology: Components  [Service Architecture]
  ├── references → Product Topology: Data  [Service Endpoints — via Local OBCs]
  └── feeds → Product Deck Reliability Matrix  [Service Consumers + SLO]
```

---

## References

→ [Product Deck](product-deck.en.md) — the product-level artifact that references the Service Deck
→ [OBC: Observable Business Contract](obc.en.md) — source of truth for data contracts and SLIs
→ [Reliability Plan](artifact-types.en.md#reliability-plan) — detailed risk analysis and SLOs
→ [Product Topology](product-topology.en.md) — the structural dimensions (Components, Data, Team, Flow)
→ [Reliability Matrix — Produto Reativo](https://produtoreativo.com.br/matriz-de-confiabilidade/)
