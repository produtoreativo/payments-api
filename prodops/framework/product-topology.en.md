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
    ├── Team         ← who: organization, roles, ownership
    ├── Data         ← what: contracts, entities, schemas
    ├── Components   ← how: services, APIs, infrastructure (functional behavior)
    └── Flow         ← when/how they evolve: temporal axis transversal to the other dimensions
```

**How to read the diagram:**

- The vertical axis (Origin Streams → Local OBC) describes the **intent flow** — how a need becomes an observable contract.
- **Product Topology** is positioned after the OBC because it is the OBC that materializes changes over the product structure via Delivery.
- Product Topology is **not part of the flow** — it is permanent. The work flow ends; the product structure continues to exist and is modified by each delivered OBC.

---

## The four Product Dimensions

The four dimensions coexist in any product. They are not hierarchical. They do not represent phases or cycles. Any OBC can impact one or more dimensions simultaneously.

The **Flow** dimension is transversal to the others: any OBC, as it traverses the Framework journeys, always impacts Flow — because it always leaves a temporal trace in the product structure.

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

**What it is:** The temporal axis of Product Topology.

**Describes:** How the other Product Dimensions — Team, Data, and Components — evolve across the Framework journeys. Flow does not execute anything: it allows observing, through the journeys (Discovery, Delivery, Operation, Diligence, and future Framework journeys), how the changes produced by an OBC traverse time and become a permanent part of the product.

Flow represents:
- **evolution** — the progression of a change from intent to consolidation in the product
- **transformation** — how structural dimensions are altered by each OBC over time
- **history** — the record of when and how each change traversed the Framework journeys
- **lifecycle** — the delivery lifecycle: birth (Discovery), implementation (Delivery), operation (Operation), validation (Diligence)

**How Flow works in practice:** An OBC that adds boleto issuance creates a responsibility in Team, contracts in Data, and services in Components. Flow records how that set of changes traverses Discovery → Delivery → Operation → Diligence until it becomes a permanent part of the product. Flow created nothing — it represents the temporal path that the other dimensions traveled.

**Critical distinction:** Flow is not product functional behavior. It does not describe business processes, business rules, state machines, automations, or features. Those concepts belong to the **Components** dimension — which implements the product's behavior. Flow answers exclusively *when* and *how* dimensions evolve, never *what* the product does.

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

**What it is:** The physical and behavioral dimension of the product.

**Describes:** Applications, services, microservices, databases, queues, data pipelines, infrastructure, and repositories that compose the product's technical platform. **Components implement the product's functional behavior** — they are what execute business rules, features, integrations, APIs, and automated processes. The product's behavior emerges from the collaboration between its Components.

**Examples of OBC impact:**
- New boleto issuance service (Invoice Service) integrated with the Asaas provider
- New API exposed for invoice status queries
- New worker for asynchronous payment confirmation processing
- New message queue for decoupling between issuance and confirmation

---

## OBC → Product Topology relationship

An OBC does **not belong** to a single Product Dimension. An OBC can simultaneously modify all four dimensions — the impact depends on the scope of the intent, not its origin.

**Example: OBC "Add boleto issuance"**

| Product Dimension | Concrete impact |
|---|---|
| **Team** | New operational responsibility: the team now monitors issuance failures in the Asaas provider |
| **Data** | New invoice contract (boleto fields), new domain event `boleto.issued` |
| **Components** | Invoice Service, Asaas Provider, status query API, confirmation Worker |
| **Flow** | Records how these changes traversed Discovery → Delivery → Operation → Diligence until becoming a permanent part of the product |

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
