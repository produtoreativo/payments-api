[Português](product-topology.md)

# Product Topology

**Product Topology** represents the permanent structural organization of a product. It describes the dimensions that coexist in any product and over which OBCs produce changes.

**Product Topology does NOT represent:** backlog, journey, pipeline, flow, cycle, or process.
**Product Topology represents:** the structure of the product — the dimensions that always exist, regardless of the state of work.

→ [OBC: Observable Business Contract](obc.en.md)
→ [Origin Streams: intent origins](origin-streams.en.md)
→ [Framework Ontology](ontology.en.md)
→ [Glossary](glossary.en.md)

---

## Ontological separation: Origin Streams vs. Product Topology

These are two entirely different concepts:

| Concept | Question it answers | Examples |
|---|---|---|
| **Origin Streams** | Where did this need come from? | Business, Enterprise, Team, Technology |
| **Product Topology** | Which parts of the product will be impacted? | Team, Flow, Data, Components |

**Origin Streams** (Business, Enterprise, Team, Technology) classify the **origin** of a Business Signal — where the need came from, who owns it, what the creation context is.

**Product Topology** (Team, Flow, Data, Components) describes the **permanent structure of the product** — the dimensions that any OBC can modify, regardless of where the intent originated.

> **Separation example:** An OBC originating from the "Business" Origin Stream (a market need) can simultaneously impact the Flow dimension (records the delivery lifecycle across journeys), Data dimension (new invoice schema), and Components dimension (new invoice service). The origin does not determine the impact.

---

## Positioning in the Framework

```
Origin Streams (Business | Enterprise | Team | Technology)
       ↓  classify the origin of the need
Business Signals
       ↓
Business Intent (+ Global OBC)
       ↓  OBC Partitioning or Owner Approval
Local OBC committed
       ↓  implementation via Delivery
Product Topology     ← permanent structure of the product (not a flow)
    ├── Team
    ├── Flow
    ├── Data
    └── Components
```

**How to read the diagram:**

- The vertical axis (Origin Streams → Local OBC) describes the **intent flow** — how a need becomes an observable contract.
- **Product Topology** is positioned after the OBC because it is the OBC that materializes changes over the product structure via Delivery.
- Product Topology is **not part of the flow** — it is permanent. The work flow ends; the product structure continues to exist and is modified by each delivered OBC.

---

## The four Product Dimensions

The four dimensions coexist in any product. They are not hierarchical. They do not represent phases or cycles. Any OBC can impact one or more dimensions simultaneously.

### Team

**What it is:** The organizational dimension of the product.

**Describes:** Ownership, responsibilities, capabilities, roles, collaboration, governance, and the operational model of the team that builds and operates the product.

**Examples of OBC impact:**
- Creation of a new operational responsibility for a team (e.g.: monitoring invoice issuance failures)
- Redefinition of roles between teams in a shared flow
- Adoption of a new capability that changes the on-call or duty model

**Critical distinction:** Do not confuse with the "Team" Origin Stream — which classifies the *origin* of a need (the team identified the problem). The "Team" Product Dimension describes the *impact* on the product's organizational structure, regardless of where the OBC originated.

---

### Flow

**What it is:** The temporal dimension of the product.

**Describes:** How the other Product Dimensions (Team, Data, Components) evolve across Framework journeys — Discovery, Delivery, Operation, and Diligence. Flow records the passage of changes through the product lifecycle: when an OBC is born, traverses the Delivery Journey, enters Operation, and goes through Diligence.

**Examples of OBC impact:**
- An OBC modifies the Team dimension → Flow records how that change traversed Discovery, Delivery, Operation
- A change to the Data dimension → Flow records its evolution through the Framework journeys
- A new element in Components → Flow records when it was born, evolved, or ceased to exist in the product

**Critical distinction:** Flow is not product functional behavior. It does not describe business journeys, processes, business rules, machine states, or automations. Flow is the temporal axis of Product Topology — it describes *when* and *how* dimensions evolve, not *what* the product does functionally.

---

### Data

**What it is:** The informational dimension of the product.

**Describes:** Business entities, data contracts, schemas, persistence, integrations, domain events, and APIs that compose the product's informational model.

**Examples of OBC impact:**
- New invoice schema with fiscal traceability fields
- New domain event emitted upon payment confirmation (e.g.: `invoice.confirmed`)
- New API contract exposed for external integrations
- New reconciliation entity with its own persistence model

---

### Components

**What it is:** The physical dimension of the product.

**Describes:** Applications, services, microservices, databases, queues, data pipelines, infrastructure, and repositories that compose the product's technical platform.

**Examples of OBC impact:**
- New Pix provider as an independent service within the platform
- New message queue for asynchronous confirmation processing
- New database to store reconciliation states
- New data pipeline for transaction auditing

---

## OBC → Product Topology relationship

An OBC does **not belong** to a single Product Dimension. An OBC can simultaneously modify all four dimensions — the impact depends on the scope of the intent, not its origin.

**Example: OBC "Create Pix Invoice"**

| Product Dimension | Concrete impact |
|---|---|
| **Team** | New operational responsibility: the team now monitors invoice issuance failures |
| **Flow** | Delivery lifecycle: born in Discovery, implemented in Delivery, entered Operation with monitoring, and validated through Diligence |
| **Data** | New contracts: invoice schema, `invoice.created` event, status query API |
| **Components** | New provider: Pix invoice issuance service integrated with the payment gateway |

**Rule:** When writing or refining an OBC, identify which Product Dimensions will be impacted. This informs architecture, responsibilities, risks, and the need for a Reliability Plan — but does not change the OBC's origin or the Delivery flow.

---

## What Product Topology is not

| Concept | Why it is not Product Topology |
|---|---|
| **Backlog** | A backlog represents *work under management*. Product Topology represents *the structure that work modifies*. |
| **Framework Journey** | Journeys (Discovery, Delivery, Operation…) are the team's *work process*. Product Topology is *what exists in the product*, independent of the process. |
| **Pipeline** | A pipeline is a sequence of execution steps. Product Topology is a permanent structure — it has no beginning or end. |
| **Origin Stream** | Origin Streams classify the *origin* of the need. Product Topology classifies the *structural impact* on the product. |
| **Cycle** | A Cycle (CI Sync, CI Async, diligence-sync…) is a sequence of work Phases. Product Topology is not executable — it is descriptive. |

---

## Canonical terminology

| Use | Avoid |
|---|---|
| **Product Topology** | Layers, Domains, Architecture Domains, Streams (as a substitute) |
| **Product Dimensions** | Views, Perspectives, Pillars, Concerns |
| **Team, Flow, Data, Components** | Other names for the four dimensions |

---

## References

→ [OBC: Observable Business Contract](obc.en.md)
→ [Origin Streams: intent origins](origin-streams.en.md)
→ [Framework Ontology](ontology.en.md)
→ [Glossary](glossary.en.md)
→ [Framework Flow](flow.en.md)
