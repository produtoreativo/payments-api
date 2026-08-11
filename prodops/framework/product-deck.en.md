# Product Deck

The Product Deck is a single-page canvas that aggregates the essential information about a digital product — what it does, what it doesn't do, who builds it, how it's structured, and which metrics drive decisions and contextual evaluations.

It was born during the Deploy First Development era, inspired by **Toyota's A3 Report** — a method for problem-solving and activity coordination that promotes structured thinking and evidence-based decision-making. Like the A3, the Product Deck enforces synthesis: everything that matters fits on one page.

> **Core principle:** any team member, stakeholder, or external collaborator should be able to understand the product, its state, and its risks by reading the Product Deck — without relying on additional documentation for an operational-level view.

---

## Relationship with ProdOps journeys

The Product Deck doesn't belong to a single journey — it's a **cross-cutting artifact**, consumed and updated across multiple journeys:

| Journey | How the Product Deck is used |
|---|---|
| **Assessment** | Primary context source for maturity evaluation and premortems; Execution Architecture and Reliability Matrix are direct inputs |
| **Discovery** | Reference for validating whether a new capability aligns with the product's scope and vision |
| **Delivery** | Consulted during Bootstrap for architecture and dependency context; updated at Promote when services or team change |
| **Operation** | Product Analytics and Reliability Matrix are continuously updated with operational data |
| **Diligence** | Verifies consistency between the state declared in the Product Deck and the actual operational state (backlogs, OBCs, Issues) |

---

## Canonical sections

The Product Deck is composed of seven sections. Each answers one central question:

### 1. Product Vision

**Question:** For whom does this product exist and what value does it deliver?

Uses Geoffrey Moore's product vision format (*Crossing the Chasm*), complemented by the Lean Inception approach:

```
For [persona/target customer],
who [need or problem],
the [product name]
is a [product category]
that [primary differentiator].
Unlike [current alternative],
our product [decisive benefit].
```

The Product Vision keeps the team focused on the expected outcome — not on features.

---

### 2. Product Services

**Question:** What are the services that make up this product and what is their operational health?

Each entry in Product Services represents a **Service Deck** — an independent artifact that treats the service as a product and describes it with the same level of detail as the Product Deck. The Product Deck lists services with their health indicators; the Service Deck details each one.

A Product Service can be one of two types:

| Type | Definition | When to use |
|---|---|---|
| **Service** | A single deployable unit: microservice, API, worker, queue processor | The service has clear boundaries, a single responsibility, and its own SLO |
| **Value Stream** | A logical grouping of one or more Services that together deliver a specific business outcome | The outcome is only achieved through collaboration between multiple Services that the team treats as a single operational unit |

In the Product Deck, each entry is listed with two mandatory indicators:

| Field | Description | Source |
|---|---|---|
| **Reliability number** | Current SLO in production (e.g., 99.5%) | Local OBC → SLI |
| **Lead-time** | Average time to deliver changes to the service | Release Trail → DORA |

**Link to the Data dimension:** each Product Service has exactly one **Local OBC**. The OBC is where the service's data contracts live — APIs, published and consumed events, schemas, SLIs. The Service Deck exposes these contracts in the Service Endpoints section, making the Data dimension visible at the service level without duplicating the OBC.

```
Product Service (listed in the Product Deck)
    └── references → Service Deck
          ├── consumes → Local OBC  [Data: APIs, events, schemas, SLIs]
          └── consumes → Reliability Plan  [SLOs, risk analysis]
```

A service without a committed Local OBC must not appear as a Product Service — it must be flagged as pending an observable contract.

→ Full definition of Service Deck: [`service-deck.en.md`](service-deck.en.md)

---

### 3. Product Team

**Question:** Who is responsible for building and operating this product?

Distinguishes two layers:
- **Core Team:** members who execute the product — direct responsibility for OBCs, BDD Features, and Reliability Plan.
- **Decision Participants:** stakeholders with decision-making power over roadmap and operations — not "internal customers", but governance agents.

Includes activation information (channel, availability, expected response time) — essential during incidents and premortems.

---

### 4. Product Execution Architecture

**Question:** How do the product's parts connect and what are the critical dependencies?

Maps relationships between:
- Applications and microservices
- Infrastructure components (databases, caches, queues)
- Internal services (other platform products)
- External services (third-party integrations)

Corresponds directly to the **`Components` Product Dimension** of the Product Topology.

This is the central input for Assessment premortems: identifying risks requires understanding dependencies. An outdated architecture diagram invalidates any risk analysis.

---

### 5. Reliability Matrix

**Question:** Which applications are critical and how do they behave under failure?

Evolution of the Resilience Matrix (inspired by Shopify's model). A table that maps:
- Which applications receive code changes
- Which dependencies (direct and indirect) each application has
- Impact of each component's unavailability on the customer experience

In the Product Deck, the Reliability Matrix functions as a **dashboard** — not merely a static document. It feeds intelligent alerting systems and reduces MTTR by making dependencies visible during incidents.

→ Full definition: [`reliability-matrix`](https://produtoreativo.com.br/matriz-de-confiabilidade/)

---

### 6. Product Analytics

**Question:** Is the product delivering the promised value?

Presents the business metrics associated with the product's services — conversion, revenue, retention, adoption — and the operational reliability metrics (SLIs, error budget, MTTR).

Connects business and engineering in a unified view. A service with a green SLO but declining business KPIs signals a value problem — not a reliability one.

---

### 7. Stakeholders

**Question:** Who governs and evolves this product beyond the core team?

Lists those responsible for management and evolution who impact roadmap and operations — product leadership, business representatives, regulatory partners, consuming squads.

The term "internal customer" is rejected. In ProdOps, every relationship between teams is a **product partnership** — each party has explicit responsibility for the shared outcome.

---

## Flow: from Origin Stream to Release Trail

The **Flow** dimension of the Product Topology, applied to the Product Deck scope, represents the complete traceability trail of a capability — from the origin of the need to the delivery evidence in production.

The Product Deck consolidates the current state of the product. Flow records how that state was built and how each change traversed it:

```
Origin Stream (Business | Enterprise | Team | Technology)
    ↓  classifies the origin of the need
Business Signal  ·····  [Product Tracking List]
    ↓  Owner Approval
Business Intent + Local OBC Draft  ·····  [Icebox — Refining]
    ↓  Discovery: Upstream or Downstream
Local OBC Committed + BDD Feature  ·····  [Iteration Backlog]
    ↓  enters the Iteration Plan
Delivery
  ├── CI Sync:   Bootstrap → Hack → Sync → Finish
  └── CI Async:  Ship → Validate → Promote
    ↓
Release Trail  ·····  [formal evidence of completion]
    ↓  feeds
Product Analytics + Reliability Matrix  ·····  [Product Deck updated]
```

**What Flow records for each Product Service:**

| Flow point | Artifact | What it records |
|---|---|---|
| Origin | Business Signal | Which need originated the capability |
| Commitment | Business Intent + Local OBC | What was contracted and by whom |
| Contracts | Local OBC Committed | APIs, events, schemas, SLIs — Data dimension |
| Specification | BDD Feature | Expected behavior in Gherkin |
| Delivery | Release Trail | Evidence of completion with quality gates |
| Outcome | Product Analytics | Business KPIs and post-delivery SLIs |

This complete traceability is what allows Assessment to reconstruct the product's maturity history — not just its current state. Diligence uses this trail to verify that the state declared in the Product Deck matches the OBC portfolio and the Release Trail history.

---

## Canonical path

```
prodops/artifacts/product/product-deck.md
```

A product has exactly one Product Deck. There is no Product Deck per feature, per release, or per iteration. The Product Deck represents the product as a whole in its current state.

---

## Lifecycle

The Product Deck is a **living artifact** — it has no "done" state:

| Moment | Expected update |
|---|---|
| **New capability becomes Operational** | Update Product Services, Reliability Matrix, and Product Analytics |
| **Architecture change** | Update Execution Architecture and Reliability Matrix |
| **Team change** | Update Product Team and Stakeholders |
| **New committed SLO** | Update reliability number in Product Services |
| **Maturity Assessment** | Review Product Analytics and Reliability Matrix as baseline |
| **Premortem** | Consumption: Execution Architecture and Reliability Matrix are read as input |

Diligence periodically verifies whether the Product Deck is synchronized with the actual operational state of OBCs and services.

---

## Relationship with other ProdOps artifacts

```
Product Deck
  ├── references → Service Deck  (one per Product Service)
  │     ├── consumes → Local OBC  [Data: APIs, events, schemas, SLIs]
  │     └── consumes → Reliability Plan  [SLOs, risk analysis]
  ├── consumes → Release Trail  [Product Analytics: post-delivery metrics + Flow]
  ├── references → Product Topology: Components  [Execution Architecture]
  ├── references → Product Topology: Team  [Product Team + Stakeholders]
  ├── references → Product Topology: Flow  [Origin Stream → Release Trail per capability]
  └── is consumed by → Premortem, Assessment, Bootstrap  [architecture and risk context]
```

---

## References

- [Product Deck — Produto Reativo](https://produtoreativo.com.br/product-deck/)
- [Reliability Matrix — Produto Reativo](https://produtoreativo.com.br/matriz-de-confiabilidade/)
- [ProdOps Vision and Mission — Produto Reativo](https://produtoreativo.com.br/visao-e-missao-do-prodops/)
- [Observability First — Produto Reativo](https://produtoreativo.com.br/observabilidade-em-primeiro-lugar/)
- Geoffrey Moore — *Crossing the Chasm* (Product Vision format)
- Toyota A3 Problem Solving (canvas format inspiration)
- Shopify Resilience Matrix (Reliability Matrix inspiration)
