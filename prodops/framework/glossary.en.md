# ProdOps Glossary

Canonical terms of the ProdOps Framework. One concept = one name. One name = one concept.

For the full Framework flow, see [`flow.md`](flow.en.md).
For the four Origin Streams, see [`origin-streams.md`](origin-streams.en.md).
For the backlog hierarchy, see [`backlogs.md`](backlogs.en.md).

---

## ProdOps Architecture

The four hierarchical levels that compose the ProdOps ecosystem. See [operating-model.en.md](operating-model.en.md#prodops-architecture) for the full diagram.

---

## Framework (ProdOps Framework)

**Definition:** The canonical system of principles, journeys, capabilities, skills, templates, standards, contracts, and glossary that defines how ProdOps works. Lives in a dedicated reference repository.

**Purpose:** Be the single source of truth about how to work with ProdOps — regardless of which product, portfolio, or workspace is using it.

**Contains:** Principles, glossary, official flow, Origin Streams, operating model, journeys, skills, templates, Delivery Capabilities.

**Does not contain:** Roadmap, Backlogs, Business Intents, Releases, product Features.

**Relation to other concepts:** The Framework is the top level of the hierarchy. Portfolio, Workspace, and Product Repositories adopt and extend it with their own artifacts.

---

## Portfolio

**Definition:** The platform management level of ProdOps. Responsible for coordinating multiple products, defining priorities, and managing platform versions.

**Purpose:** Decide what the platform delivers, when, and in what sequence — without directly implementing software.

**Contains:** Portfolio Tracking List (Business Signals), Business Intent Backlog (Business Intents), Roadmaps (view of BIB), Platform Releases (view of BIB), Milestones.

**Does not contain:** Software implementation, product OBCs, product BDD Features.

**Relation to other concepts:** The Portfolio sits between the Framework (which defines the rules) and the Workspaces (which execute). A Portfolio Roadmap coordinates Product Repositories. See **Platform Release**.

---

## Workspace

**Definition:** The product integration level. Responsible for running and testing multiple Product Repositories together.

**Purpose:** Ensure that products that depend on each other work correctly in an integrated manner. A Workspace has no Roadmap and no Business Intents — it exists exclusively for integration.

**Operational characteristics:** The Workspace has no state of its own. It observes GitHub (the primary operational source) and never decides priorities — priorities are decided by the Portfolio (Business Intents) or by the Product Owner (OBCs in the Product Backlog).

**Examples:** Checkout Workspace (webshop-api + payments-api + order-mgmt-api).

**Does not contain:** Roadmap, Business Intents, product code, backlog state.

**Relation to other concepts:** A Workspace is coordinated by the Portfolio and integrates Product Repositories. See **Product Repository**.

---

## Product Repository

**Definition:** The implementation and operation level for a specific product within the ProdOps architecture. This repository (`payments-api`) is a Product Repository.

**Purpose:** Implement Product Capabilities, operate the product in production, and maintain full traceability from Business Intents to operation evidence.

**Contains:** OBCs, BDD Features, Iteration Plans, Reliability Plans, Release Trail, product code, runbooks, postmortems.

**Relation to other concepts:** A Product Repository adopts the Framework, participates in Roadmaps defined by the Portfolio, and is integrated by Workspaces. It can also evolve locally through its own Business Intent flow.

---

## Platform

**Definition:** The set of Product Repositories coordinated by the Portfolio and integrated by Workspaces. The platform is the composite product — what the end customer experiences.

**Relation to other concepts:** The Platform is the result of coordination between Portfolio, Workspaces, and Product Repositories. See **Portfolio**, **Workspace**, **Product Repository**.

---

## Platform Release

**Definition:** A grouping view over the Business Intent Backlog — not a separate backlog. Represents which BIB items compose a coherent platform delivery (a specific combination of Product Repository versions to be released together).

**Nature:** View — not a queue. Items do not "pass through" the Platform Release; they remain in the BIB and are associated with a platform version.

**Purpose:** Mark a coherent delivery point for the platform as a whole — not just for a single product.

**Distinction:** A Platform Release is different from a local release of a single Product Repository. The local release (managed by the repository's CI Async) contributes to a Platform Release but does not replace it.

**Relation to other concepts:** Managed by the Portfolio. View over the Business Intent Backlog. See **Portfolio**, **Roadmap**.

---

## Roadmap

**Definition:** A strategic view over the Business Intent Backlog — not a separate backlog. Organizes BIB items by delivery horizon (now / next / later), Milestones, and cross-product dependencies.

**Nature:** View — not a queue. Items do not "enter" the Roadmap; they remain in the BIB and receive a position in the strategic horizon.

**Purpose:** Communicate platform priorities and delivery horizon to stakeholders, teams, and partners without creating a commitment.

**Who manages it:** The Portfolio. Product Repositories participate in Roadmaps but do not define them.

**Do not confuse with:** Iteration Plan (planning for one iteration within a Product Repository) or Icebox (candidates not yet prioritized).

**Relation to other concepts:** View over the Business Intent Backlog, managed by the Portfolio. See **Portfolio**, **Platform Release**, **Business Intent Backlog**.

---

## Origin Stream

**Definition:** Classification of the origin of an Intent. Identifies where the need was born and who owns it.

**Purpose:** Ensure that every change has a traceable origin and that the context, language, and success criteria are appropriate for the type of need.

**When to use:** When registering any Intent. Every Intent has exactly one Origin Stream.

**When not to use:** Origin Stream does not determine the execution mode or the journey — that is the function of the Execution Mode and Continuous Assessment.

**The four Origin Streams:** Business | Enterprise | Team | Technology

**Relationship with other concepts:** An Origin Stream generates a **Business Signal**. When investigated and recognized as strategic, a Business Signal can generate one or more **Business Intents**. See [`origin-streams.md`](origin-streams.en.md).

---

## Business Signal

**Definition:** Represents any opportunity, hypothesis, problem, benchmark, business case, value stream, complaint, new technology, or idea that deserves attention. Not a commitment. Not a contract. No OBC.

**Purpose:** Capture any signal that deserves investigation before any strategic or investment decision. Business Signals are the raw material from which strategic work is identified.

**When to use:** When registering a need not yet structured enough to be treated as a formal Business Intent. Every item captured in Tracking Lists is a Business Signal.

**Life cycle:** Persists even after generating Business Intents — represents the discovery history. A Business Signal can generate 0, 1, or N Business Intents.

**Lives in:** Portfolio Tracking List (platform) or Product Tracking List (product).

**GitHub representation:** Business Signal Issue.

**Critical rule:** Entities never change identity. A Business Signal never "becomes" a Business Intent — it **generates** new Business Intent entities.

**Relationship with other concepts:** 1 Business Signal → 0 to N Business Intents. See [`backlogs.en.md`](backlogs.en.md).

---

## Business Intent

**Definition:** Represents a strategic decision: there is clarity about which value will be pursued. Born from a Business Signal (or multiple). Has its own identity and lifecycle — does not replace the Business Signal.

**Purpose:** Formally register an investment decision before any implementation decision. The Business Intent captures the "why" without prescribing the "how".

**When to use:** When a Business Signal has been investigated and recognized as strategically relevant. Every change that enters the Business Intent Backlog is represented as a Business Intent.

**When not to use:** Business Intent is not a technical backlog, sprint task, or isolated bug ticket. It does not represent implementation — it represents strategic decision.

**Life cycle:** The Business Intent is born in the Business Intent Backlog (global flow) — at which point the Global OBC is created as a Draft. Has an OBC as its contract document — the OBC represents the commitment across 4 dimensions: Business, Enterprise, Team, and Technology. OBC Partitioning creates Local OBC documents (Markdown files) per product, but the Intent remains the trackable entity.

**Origin:** Can be created directly in the Business Intent Backlog without originating from a Business Signal. When generated from a Business Signal, it stores an optional back-reference to the originating Signal.

**GitHub representation:** Business Intent Issue.

**Relationship with other concepts:** Born from a Business Signal (or created directly in the BIB). Has an OBC as its contract document. See [`flow.en.md`](flow.en.md), [`origin-streams.en.md`](origin-streams.en.md) and [`backlogs.en.md`](backlogs.en.md).

---

## Product Stage

**Definition:** Classification of a product's maturity moment within the ProdOps lifecycle. Defines which delivery metrics carry the most weight and what the team's focus should be at that point.

**The six stages in order:** PoC → MVP → IPR → MVR → MVT → MLP

**Two macro-phases:**
- **Hypothesis Validation** (PoC, MVP, IPR): prove the idea is viable before scaling
- **Acceleration** (MVR, MVT, MLP): grow with repeatability, traction, and delight

**Relationship with other concepts:** The stage influences DORA metric weights and Reliability Plan focus. See [`product-stages.en.md`](product-stages.en.md) and [`dora-metrics.en.md`](dora-metrics.en.md).

---

## PoC (Proof of Concept)

**Definition:** First product stage. Validates whether an idea or approach is viable with a **real customer**.

**Central characteristic:** The customer is always involved. No customer means it is not a PoC — it is a Spike Solution.

**Relationship with other concepts:** See **Product Stage**, **Spike Solution**, and [`product-stages.en.md`](product-stages.en.md).

---

## DORA Metrics (Extended)

**Definition:** A 7-metric delivery health model adopted by ProdOps to assess delivery maturity. Extends the 4 original metrics from the DORA Research Program with 3 product- and operation-oriented extensions.

**The 7 metrics:**

| Metric | Type | What it measures |
|---|---|---|
| **Lead Time for Change** | DORA Core | Time from commit to production |
| **Release Frequency** | DORA Core | Deployment frequency |
| **Change Fail Rate** | DORA Core | % of changes that cause failure |
| **Mean Time to Recovery** | DORA Core | Mean time to recovery after failure |
| **Reaction Time** | ProdOps Extension | Time between external signal and first processed action |
| **Rate of Return** | ProdOps Extension | Escaped defects and rework — retries, refunds |
| **Availability** | ProdOps Extension | Service operational uptime |

**Weights by stage:** each product stage defines weights 1–8 per metric. In early stages (PoC/MVP), Lead Time and Reaction Time carry maximum weight. In advanced stages (MVT/MLP), Change Fail Rate, MTTR, and Availability dominate.

**Relationship with other concepts:** See [`dora-metrics.en.md`](dora-metrics.en.md), [`product-stages.en.md`](product-stages.en.md). Maturity assessment is run on the Certificare platform.

---

## Maturity Level (Delivery)

**Definition:** ProdOps delivery maturity scale, from 0 to 5. Used by Certificare to position the product and generate an improvement roadmap.

| Level | Name | Description |
|---|---|---|
| 0 | Inexistent | No established practices |
| 1 | Initial | Ad-hoc practices, no repeatability |
| 2 | Repeatable | Basic practices without systematization |
| 3 | Defined | Documented processes consistently followed |
| 4 | Managed | Metrics collected and used for decisions |
| 5 | Excellence | Continuous optimization based on data |

**Top-down strategy:** starts at level 5 and drops at the first unsatisfied mandatory criterion.

**Relationship with other concepts:** See [`dora-metrics.en.md`](dora-metrics.en.md).

---

## Spike Solution

**Definition:** A time-boxed technical investigation whose only output is a decision — not a product, not deliverable code. It answers a single specific technical question that is blocking progress.

**Central characteristic:** No customer is ever involved. If there is a customer, it is a PoC. Code is always disposable.

**When to use:** Any product stage, any experiment phase — including inside a PoC or any Upstream journey.

**Critical difference from PoC:**

| | PoC | Spike Solution |
|---|---|---|
| Customer involved | Always | Never |
| Objective | Validate with real feedback | Answer a technical question |
| Code | May be demonstrable | Always disposable |

**Where to record:** `prodops/journeys/discovery/spikes.md` (if isolated) or the experiment's `upstream-trail.md` (if inside an active Upstream).

**Relationship with other concepts:** See **PoC**, **Product Stage**, [`product-stages.en.md`](product-stages.en.md), and [`../journeys/discovery/spikes.md`](../journeys/discovery/spikes.md).

---

## Conception

**Definition:** Phase covering the period from the emergence of a Business Signal to entry into the Product Backlog. The Business Signal exists as a possibility — the Product Owner has not yet made a commitment.

**Central question:** Is there real value here?

**Backlogs:** Portfolio Tracking List / Product Tracking List → Business Intent Backlog (global flow).

**OBC state:** Does not exist in the Tracking Lists. In the global flow, the **Global OBC** is born as Draft upon entry into the Business Intent Backlog — when the Business Signal generates a Business Intent. In the local flow, the **Local OBC** is born as Draft upon entry into the Product Backlog.

**Commitment:** None. The Business Signal may be discarded without any formal record of learning.

**Exit boundary:** Owner Approval — entry into the Product Backlog (start of Inception).

**Relationship with other concepts:** See [`phases.en.md`](phases.en.md), [`backlogs.en.md`](backlogs.en.md).

---

## Inception

**Definition:** Phase covering the period from entry into the Product Backlog until the Local OBC reaches the Committed state (Iteration Backlog). The Product Owner has made a formal commitment to investigate.

**Central question:** Is the Product Owner committing attention and capacity to investigate this now?

**Backlogs:** Product Backlog → Icebox → Iteration Backlog.

**Local OBC state:** Draft → Refining (Icebox) → Committed (Iteration Backlog).

**Commitment:** Formal. Any closure requires a traceable learning record in the OBC.

**Execution mode:** Upstream or Downstream — they are **modes**, not phases. Defined by the Product Owner when accepting the Business Intent into the Product Backlog. May change during Inception.

**Exit boundary:** Assessment Review approved, Local OBC in Committed state, BDD Feature committed — entry into the Iteration Backlog.

**Relationship with other concepts:** See [`phases.en.md`](phases.en.md), [`backlogs.en.md`](backlogs.en.md).

---

## Business (Origin Stream)

**Definition:** Origin Stream that represents needs generated by the market, the customer, or product growth opportunities.

**Purpose:** Capture market-outcome-oriented Intents — revenue, conversion, adoption, retention, new channels, new products.

**When to use:** The need has a direct relationship with value perceived by the customer or the market.

**When not to use:** If the benefit is internal to the organization (Enterprise), to the team's process (Team), or to the technical platform (Technology).

**Examples:** Split Payment (Pix + Card), new Boleto channel, subscription recurrence support.

**Relationship with other concepts:** One of the four Origin Streams. See [`origin-streams.md`](origin-streams.en.md).

---

## Enterprise (Origin Stream)

**Definition:** Origin Stream that represents internal organizational needs — compliance, legislation, audit, partners, ERP, financial, backoffice, governance, corporate risks.

**Purpose:** Capture Intents that are mandatory for reasons external to the product — laws, regulations, contracts, corporate policies.

**When to use:** The need is imposed from outside the product or resolves an internal operational scale problem.

**When not to use:** If the benefit is for the customer (Business), for the team's process (Team), or for the platform (Technology).

**Examples:** Compliance with Central Bank regulation, integration with financial ERP, LGPD data retention policy.

**Relationship with other concepts:** One of the four Origin Streams. See [`origin-streams.md`](origin-streams.en.md).

---

## Team (Origin Stream)

**Definition:** Origin Stream that represents needs generated by the product and engineering team itself to evolve the way of working, processes, tools, and operational quality.

**Purpose:** Capture Intents for internal operational model improvement — productivity, onboarding, workflow, automations.

**When to use:** The need is about how the team works, not what the team delivers to the market.

**When not to use:** If the benefit is for the customer (Business), for the organization (Enterprise), or for the technical platform (Technology).

**Examples:** Adoption of Conventional Commits, creation of Bootstrap skill, Commit Workflow documentation.

**Relationship with other concepts:** One of the four Origin Streams. See [`origin-streams.md`](origin-streams.en.md).

---

## Technology (Origin Stream)

**Definition:** Origin Stream that represents needs generated by the evolution of the platform's technical capabilities, security, infrastructure, and system reliability.

**Purpose:** Capture technical evolution Intents — architecture, security, infrastructure, observability, reliability, cloud, database, Kubernetes, serverless, IAM, cryptography.

**When to use:** The need is technical and the primary benefit is for the system — not directly for the customer or the organization.

**When not to use:** If the technical improvement is a consequence of a product requirement (Business), corporate requirement (Enterprise), or process requirement (Team).

**Examples:** Migration to DynamoDB, automatic credential rotation, adoption of OpenTelemetry, encryption at rest.

**Relationship with other concepts:** One of the four Origin Streams. See [`origin-streams.md`](origin-streams.en.md).

---

## OBC (Observable Business Contract)

**Definition:** The living contract representing a business intent throughout its entire lifecycle. It is the source of truth for the work — connecting business, product, architecture, engineering, operation, observability, and reliability.

**Two levels:**
- **Global OBC** — strategic, belongs to BIB/Portfolio, covers the entire business intent.
- **Local OBC** — product-specific, belongs to one Product Backlog, specializes/partitions the Global OBC.

**States (contract maturity):** Draft → Refining → Committed → In Delivery → Operational → Archived.

**Creation:** Born when a Business Intent is accepted. There is no OBC for Business Signals — the OBC is only born from Business Intents. In the global flow, a **Global OBC Draft** is born upon entry into the Business Intent Backlog. In the local flow, a **Local OBC Draft** is born upon entry into the Product Backlog (either via OBC Partitioning or direct local approval).

**Relationship with other concepts:** Anchors the BDD Feature, the Iteration Plan, the Reliability Plan, and all of Delivery. Diligence keeps the OBC state synchronized across backlogs and tools. The relationship between levels is always: 1 Global OBC → N Local OBCs.

→ **Full definition, composition, lifecycle, and governance:** [`obc.en.md`](obc.en.md)

---

## Global OBC

**Definition:** Strategic-level Observable Business Contract. Represents the complete business intent — before it is decomposed by product.

**Focus:** Business goal, value, stakeholders, business rules, business events, KPIs, and the platform as a whole. Does **not** contain technical implementation details.

**Content:**
- Business Goal
- Business Value
- Stakeholders
- Business Rules
- Business Events table
- KPIs / Expected Outcomes
- Value Stream
- Products Involved
- Local OBC Traceability table (links to all derived Local OBCs)
- Discovery Notes

**Location:** Platform portfolio repository (external to product repositories).

**Lifecycle:** Draft → Refining (during Discovery in BIB) → Operational (after all derived Local OBCs are in production) → Archived

**Owner:** Portfolio PM

**Relationship with other concepts:** A Global OBC is decomposed into Local OBCs via **OBC Partitioning**. The relationship is: 1 Global OBC → N Local OBCs. Terms allowed: decomposition, specialization, partition. Terms **not** allowed: parent, child, inheritance.

→ [`obc.en.md`](obc.en.md)

---

## Local OBC

**Definition:** Product-level Observable Business Contract. Represents the specific responsibility of one product. It may specialize a Global OBC or originate directly from a local Intent.

**Focus:** Implementation contract — APIs, events, BDD, observability, reliability, response contract. **Does not duplicate** strategic content from the Global OBC.

**Content:**
- Mandatory origin reference: Global OBC in the global flow or Intent + Repository Tracking Item in the local flow
- Product / Repo / Bounded Context
- APIs and Events (this product's responsibility)
- BDD / Acceptance Criteria
- Observable Events table
- Reliability Rules
- Response Contract
- Technical Dependencies
- Evidence (after Delivery)

**Location:** `prodops/artifacts/business/obcs/<slug>.md` (when committed)

**Lifecycle:** Draft → Refining (Icebox) → Committed (Iteration Backlog) → In Delivery → Operational (Operation) → Archived

**Owner:** Product Manager + Tech Lead of the product

**Belongs to:** Exactly one Product Backlog.

**Relationship with other concepts:** In the global flow, each Local OBC derives from exactly one Global OBC and never duplicates its strategic content. In the local flow, it directly represents an accepted Business Intent and references its Product Tracking List item.

→ [`obc.en.md`](obc.en.md)

---

## OBC Partitioning

**Definition:** The capability that transforms a Global OBC into Local OBCs — one for each product involved in delivering the business intent.

**When it happens:** After Discovery in the Business Intent Backlog, when the Global OBC is sufficiently understood to identify the involved products and their responsibilities.

**Who executes:** Portfolio PM + Tech Leads of the involved products.

**What is produced:**
- Local OBC Draft for each product
- Traceability table updated in the Global OBC (linking all derived Local OBCs)
- Items created in the Product Backlogs of the involved products

**Relationship with other concepts:** OBC Partitioning is the transition step between the BIB and the Product Backlogs. It does not split the Business Intent — it specializes the responsibility per product. After Partitioning, each Product Backlog receives its Local OBC Draft and begins refinement in the Icebox.

→ [`obc.en.md`](obc.en.md#obc-partitioning)

---

## Continuous OBC Refinement

**Definition:** The process by which both Global OBC and Local OBCs evolve continuously throughout the product lifecycle — during Discovery, Delivery, and Operation. An OBC is never finalized; it accumulates evidence and evolves with the product.

**Drivers:** New operational evidence, incidents, postmortems, market changes, new measurements, strategic decisions.

**What is updated:** KPIs, observable events, response contract, reliability rules, business rules, stakeholders, discovery notes.

**Relationship with other concepts:** Continuous OBC Refinement is the last step of the official flow — and generates new Intents that restart the cycle. See [`flow.en.md`](flow.en.md), step 11.

---

## Exploration

**Definition:** Step of the Framework flow between Intent and OBC. Reduces uncertainty by transforming hypotheses into validated knowledge.

**Purpose:** Ensure that the OBC is built on real understanding, not assumptions. Without sufficient Exploration, the OBC is fragile.

**When to use:** Whenever the Intent has unvalidated hypotheses, open domain decisions, or technical uncertainty that justifies exploration before commitment.

**When not to use:** When the Intent is trivial, the behavior is already well understood, and the OBC can be written directly. In this case, Exploration is short or nonexistent.

**Relationship with other concepts:** Exploration is implemented by the Discovery Journey in both modes. Discovery describes the journey; Upstream or Downstream defines the commitment level and rigor.

| Term | Level | Meaning |
|---|---|---|
| **Exploration** | Flow step | What happens: uncertainty reduction between Intent and OBC |
| **Discovery** | Journey | The name of the Framework journey that implements Exploration |
| **Upstream / Downstream** | Execution Mode | The commitment level and rigor applied during Discovery |

Exploration operates on OBC Drafts that were born at the Business Intent Backlog (global flow) or Product Backlog (local flow) and are being refined in the Icebox.

See [`flow.en.md`](flow.en.md), [`../journeys/discovery/README.en.md`](../journeys/discovery/README.en.md) and [`../execution-model/upstream.en.md`](../execution-model/upstream.en.md).

---

## Discovery

**Definition:** ProdOps Framework journey that implements the Exploration step. Exploratory engineering flow oriented to learning.

**Purpose:** Transform hypotheses into validated knowledge through experiments, spikes, and prototypes. Produce the Decision Package that grounds the OBC.

**When to use:** When exploring an Intent in Upstream or Downstream, with the rigor corresponding to the mode.

**When not to use:** Discovery is not synonymous with Upstream (Upstream is the mode, Discovery is the journey). Discovery does not produce production software — it produces knowledge.

**Relationship with other concepts:** Discovery is the journey that implements Exploration. The execution mode (Upstream or Downstream) defines the commitment level and required rigor. See [`../journeys/discovery/README.en.md`](../journeys/discovery/README.en.md).

---

## Delivery Capability

**Definition:** Reusable technical competency consumed by the phases of the Delivery journey. Examples: Commit Workflow, Contract Management, Evidence Management, Observability, Reliability.

**Purpose:** Encapsulate cross-cutting technical practices that can be invoked by multiple phases without duplication.

**When to use:** When referencing the technical infrastructure of the delivery process.

**When not to use:** Do not confuse with "Product Capability". A Delivery Capability is a Framework mechanism, not a product feature.

**Relationship with other concepts:** Used by the Phases of the Delivery journey. See [`../journeys/delivery/capabilities/`](../journeys/delivery/capabilities/).

---

## Product Capability

**Definition:** A product feature, behavior, or characteristic being explored or delivered. Examples: split payment, Pix support, payment confirmation webhook.

**Purpose:** Name the product work scope that an Intent originates and that an OBC describes.

**When to use:** When referencing what is being built — the feature, the behavior, the product value.

**When not to use:** Do not confuse with "Delivery Capability". A Product Capability is the object of work; a Delivery Capability is a process mechanism.

**Note:** In contexts where ambiguity is possible, prefer the full term "Product Capability" or "Delivery Capability" instead of just "capability".

---

## BDD Feature

**Definition:** Gherkin specification that describes the expected behavior of a Product Capability. Lives in `prodops/artifacts/business/bdd/` (committed) or `prodops/journeys/discovery/experiments/<NNN-slug>/features/` (exploratory — inside the experiment directory). Used as TDD input in Downstream.

---

## Reliability Plan

**Definition:** Product of the transversal Assessment journey that defines risks, SLOs, and mitigation actions for a committed item. Lives in `prodops/journeys/assessment/reliability-plans/`.

**Requirement level:** Conditional and verifiable. It is a Delivery gate when there is money movement, an external integration, an SLO change, high/critical risk, or a persistence or security change. Outside those triggers it is optional.

**In the local flow (before the Product Backlog):** The Premortem is the appropriate artifact for risk analysis before Owner Approval. The formal Reliability Plan is produced during the Icebox, after the Product Owner's commitment.

---

## Portfolio Tracking List

**Definition:** Platform-level backlog that captures Business Signals not yet understood enough to generate a formal Business Intent. Managed by the Portfolio.

**Contains:** ONLY Business Signals. No Business Intents. No OBCs.

**Question:** What Business Signals deserve attention at the platform level?

**Does not contain:** OBC. Commitment. Permanent identifier.

**Relationship with other concepts:** First level of the global flow. Business Signals advance to the Business Intent Backlog when recognized as strategic — at that point, a new Business Intent entity is created. See [`backlogs.en.md`](backlogs.en.md).

---

## Business Intent Backlog

**Definition:** Platform-level backlog representing Business Intents accepted for Discovery. The **Global OBC Draft** is born upon entry into this backlog. After Discovery, **OBC Partitioning** distributes Local OBC Drafts to Product Backlogs. Managed by the Portfolio.

**Contains:** ONLY Business Intents. No Business Signals. Global OBCs are associated with Business Intents here.

**Question:** What Business Intents deserve Discovery at the platform level?

**Relationship with other concepts:** Second level of the global flow. The Global OBC Draft is born here. After Discovery → OBC Partitioning → Local OBC Drafts go to Product Backlogs. See [`backlogs.en.md`](backlogs.en.md).

---

## Product Tracking List

**Definition:** Product-level backlog that captures Business Signals already directed at this specific product or team. Artifact: `prodops/artifacts/product/backlogs/tracking-list.md`.

**Contains:** ONLY Business Signals. No Business Intents. No OBCs.

**Question:** What Business Signals deserve attention in this product?

**Does not contain:** OBC. Commitment. Permanent identifier.

**Relationship with other concepts:** First level of the local flow. Business Signals advance via Premortem + Preliminary Risk Analysis + Owner Approval to the Product Backlog — at which point a new Business Intent entity is created. When risk triggers apply, the formal Reliability Plan is produced later during the Icebox. See [`backlogs.en.md`](backlogs.en.md).

---

## Product Backlog

**Definition:** Product-level backlog representing all work formally accepted by the Product Owner. Single entry point for the product into the Delivery cycle — regardless of where the item came from (Portfolio or local flow). Contains **Local OBCs only** — never Global OBCs, never Business Signals.

**Question:** What has been officially accepted by the Product Owner?

**Two entry paths:** (1) Local OBC Draft from OBC Partitioning (global flow, born from a Business Intent); (2) Product Tracking Item via Premortem + Preliminary Risk Analysis + Owner Approval (local flow, creates Business Intent + Local OBC Draft upon entry).

**Three views of the Product Backlog:**
- **Icebox** — items in Discovery/Exploration (state: Refining)
- **Iteration Backlog** — items ready for Delivery (state: Committed)
- **Release** — items grouped by release version

**After entry, the origin no longer matters.** All items follow the same journey: Icebox → Iteration Backlog → Iteration Plan → Delivery.

**Relationship with other concepts:** Convergence point of the global and local flows. See [`backlogs.en.md`](backlogs.en.md).

---

## Icebox

**Definition:** A **view of the Product Backlog** representing items still being prepared for Delivery. The functional, technical, and operational Discovery needed occurs here. Goal: produce a Committed Local OBC ready for Delivery. Artifact: `prodops/artifacts/product/backlogs/icebox-backlog.md`.

**Nature:** View — not a separate queue. Items do not leave the Product Backlog when in this view.

**OBC state in this view:** Refining (items in active Discovery/Exploration)

**Question:** What is still being prepared for Delivery?

**Relationship with other concepts:** View over the Product Backlog. Items advance to the Iteration Backlog when Local OBC reaches Committed state. See [`backlogs.en.md`](backlogs.en.md).

---

## Iteration Backlog

**Definition:** A **view of the Product Backlog** representing items with a Committed Local OBC, ready for immediate Delivery. Not a refinement backlog — refinement happens in the Icebox. The only remaining decision is the Product Owner's priority. Artifact: `prodops/artifacts/product/backlogs/iteration-backlog.md`.

**Nature:** View — not a separate queue. Items do not leave the Product Backlog when in this view.

**OBC state in this view:** Committed (ready for Delivery — criteria validated and approved)

**Question:** What is ready to be developed?

**Relationship with other concepts:** View over the Product Backlog. Items appear here when the Local OBC reaches Committed state. Items advance to the Iteration Plan after Local OBC committed + BDD Feature committed. See [`backlogs.en.md`](backlogs.en.md).

---

## Release (view of Product Backlog)

**Definition:** Third view of the Product Backlog that groups items by release version (e.g., `v1.2.0`, `v2.0.0`). Allows the Product Owner to visualize which features will be part of each software release.

**Nature:** View — not a separate queue. Items do not leave the Product Backlog when associated with a release version.

**Purpose:** Provide a release-oriented view of committed work without creating a separate artifact. The items are the same as in the Icebox and Iteration Backlog — just grouped by release target.

**Relationship with other concepts:** One of the three Product Backlog views (Icebox, Iteration Backlog, Release). See [`backlogs.en.md`](backlogs.en.md).

---

## Iteration Plan

**Definition:** Record of Delivery execution for an iteration. Not a planning backlog — it represents exclusively the execution in progress. Contains items from the Iteration Backlog, execution strategy, CI Sync and CI Async journeys, evidence, and exit criteria. Artifact: `prodops/artifacts/governance/plans/iteration-plan.md`.

**Question:** What is being executed in this iteration?

**Relationship with other concepts:** Receives items from the Iteration Backlog with OBC committed + BDD committed. It is the last backlog before Delivery. See [`backlogs.en.md`](backlogs.en.md).

---

## CI Sync

**Definition:** The synchronous grouping of ProdOps Delivery. Represents local, collaborative work driven by the engineer. Includes Bootstrap, Hack, Sync, and Finish. Produces: closed task, PR with narrative, evidence, organized commits, local validations executed. See [`journeys/delivery/README.md`](../journeys/delivery/README.en.md).

---

## CI Async

**Definition:** The asynchronous grouping of ProdOps Delivery. Represents work driven by the platform, pipelines, and environments. Includes Ship, Validate, and Promote. Produces: published artifact, deploy completed, runtime validation, controlled promotion. See [`journeys/delivery/README.md`](../journeys/delivery/README.en.md).

---

## Bootstrap

**Definition:** The first stage of CI Sync. Installs dependencies, prepares local infrastructure, verifies configuration, and runs the smoke gate. Does not read code, tests, or product artifacts, and does not create a branch — Git flow belongs to Hack Start. See [`journeys/delivery/phases/bootstrap/README.en.md`](../journeys/delivery/phases/bootstrap/README.en.md).

---

## Upstream

**Definition:** **Execution mode** — permissive, exploratory, with no delivery commitment. Objective: transform hypotheses into validated knowledge. Code is disposable until promoted to Downstream. Upstream selects flow steps as needed — there is no mandatory sequence. A typical Upstream cycle uses Bootstrap + Hack + Sync; Ship, Validate, and Promote are used only when the experiment needs staging validation or a promotion decision.

**Not a phase** — it is a mode that can start at **any stage** of the lifecycle (including during Delivery or Operation). When finished, the item returns to the original stage.

See [`prodops/journeys/discovery/README.en.md`](../journeys/discovery/README.en.md).

---

## Downstream

**Definition:** **Execution mode** — the default, with delivery commitment. Objective: deliver with confidence using validated knowledge. Every item requires OBC + BDD Feature + risks documented + entry in the Iteration Plan. A Reliability Plan is required when the canonical risk triggers apply. Downstream requires the full flow: `Bootstrap → Hack → Sync → Finish → Ship → Validate → Promote`.

**Not a phase** — it is an execution mode. Can start at any stage of the lifecycle.

See [`prodops/execution-model/downstream.en.md`](../execution-model/downstream.en.md).

---

## Hack Flow

**Definition:** The coding phase in Upstream and Downstream. Second stage of CI Sync, follows Bootstrap. Defined in [`journeys/delivery/phases/hack/README.md`](../journeys/delivery/phases/hack/README.en.md). Execution mechanics in [`skills/hack/`](../skills/hack/).

---

## Sync

**Definition:** The third stage of CI Sync. Has two independent steps: `rebase` (synchronizes the feature branch with the base — fetch, integration, conflicts, validation) and `align` (aligns ProdOps artifacts with the implementation — BDD Features, Event Storming, architecture, Release Trail). Invoked via `/sync rebase` and `/sync align`. See [`journeys/delivery/phases/sync/README.en.md`](../journeys/delivery/phases/sync/README.en.md).

---

## Ship

**Definition:** The first stage of CI Async. Transforms the finalized implementation into an executable artifact and conducts the deploy. Organized in two families: Preparation (Build, Package, Version, Sign, SBOM, Publish Artifact) and Deployment (Deploy, Progressive Delivery, Feature Flags, Rollout, Rollback, Infrastructure Validation). Build, Package, and Publish are internal capabilities of Ship — they are not independent steps of the main flow. See phases: [Ship](../journeys/delivery/phases/ship/README.en.md), [Validate](../journeys/delivery/phases/validate/README.en.md), [Promote](../journeys/delivery/phases/promote/README.en.md).

---

## Validate

**Definition:** The second stage of CI Async. Verifies the delivery running in the target environment. Capabilities: Smoke Tests, Runtime Contract Validation, Synthetic Monitoring, Health Checks, Observability Validation, SLO Validation, Business Validation, Incident Signals. See phases: [Ship](../journeys/delivery/phases/ship/README.en.md), [Validate](../journeys/delivery/phases/validate/README.en.md), [Promote](../journeys/delivery/phases/promote/README.en.md).

---

## Promote

**Definition:** The third stage of CI Async. Officially advances the version with formal approval and recorded evidence. Capabilities: Promotion Gates, Environment Promotion, Release Approval, Release Trail, Operational Evidence, Release Documentation, Rollback Readiness. See phases: [Ship](../journeys/delivery/phases/ship/README.en.md), [Validate](../journeys/delivery/phases/validate/README.en.md), [Promote](../journeys/delivery/phases/promote/README.en.md).

---

## ProdOps TDD

**Definition:** The practice used within the Hack Flow to produce observable and reliable code. Defined in [`journeys/delivery/practices/prodops-tdd.md`](../journeys/delivery/practices/prodops-tdd.en.md).

---

## Red Bar

**Definition:** A failing test that correctly expresses the desired behavior. Confirms that the test detects the missing implementation.

---

## Green Bar

**Definition:** A passing test after the minimum implementation is in place.

---

## Yellow Bar

**Definition:** Patterns used to manage difficult test scenarios: child tests, crash dummies, log strings. Not a license to mock business logic.

---

## Progressive Substitution

**Definition:** Testing strategy where a Mock Server (contract-based) is used first, then replaced by the real integration without rewriting the tests. The tests verify behavior through the same contract surface regardless of what is behind it.

---

## Mock Server

**Definition:** Infrastructure-level test double that simulates an external dependency based on a contract (e.g.: WireMock, Prism). Distinct from Mock Object, which replaces an own service.

---

## Mock Object

**Definition:** Test double for a technical dependency (logger, clock, UUID generator, telemetry adapter). Acceptable only when it does not hide business behavior.

---

## Decision Trail

**Definition:** Record of a decision made under uncertainty, including context, alternatives, and impact. Template: [`prodops/templates/assessment/decision-trail.md`](../templates/assessment/decision-trail.en.md).

---

## Release Trail

**Definition:** The append-only log of Downstream evidence. Each agent session produces its own file at `prodops/artifacts/governance/trails/sessions/YYYY-MM-DD-<session-id>.md`. See model at [`artifacts/governance/trails/release-trail.en.md`](../artifacts/governance/trails/release-trail.en.md).

---

## Diligence

**Definition:** Cross-cutting journey of the ProdOps Framework responsible for keeping the work system synchronized and consistent throughout the product lifecycle.

**Purpose:** Close the gap between decisions produced by Assessment and work ready for Delivery. Ensure that the state of each OBC remains synchronized across all backlogs, tools, and management artifacts.

**Principle:** Diligence is the guardian of consistency of the ProdOps work system. It ensures that the state of each Observable Business Contract remains synchronized across all backlogs, tools, and management artifacts, without modifying product code.

**When to use:** Continuously. Diligence has no start and end per cycle — it accompanies the product for as long as it exists. It is activated by new risks, incidents, postmortems, strategic changes, or divergences detected between artifacts.

**What it does not do:** Does not implement software. Does not create implementation Pull Requests. Does not modify product code. Does not make product decisions that belong to Assessment.

**Relationship with other concepts:** Cross-cutting journey. Consumes Assessment artifacts and feeds Delivery with organized, traceable work. See [`../journeys/diligence/README.md`](../journeys/diligence/README.en.md) and [`backlogs.md`](backlogs.en.md).

---

## GitHub Issue

**Definition:** Work Item representing an operation being executed on one or more Knowledge Space artifacts (Business Signal, Business Intent, OBC, BDD, etc.).

**Purpose:** Make the execution work performed on ProdOps artifacts visible and traceable in GitHub Projects.

**When to use:** When recording work (exploration, refinement, delivery, review) on any Knowledge Space artifact. A Work Item must always reference the affected artifact(s) by type and ID.

**When not to use:** Do not create GitHub Issues to bypass the entity model. The OBC is a Markdown document — it does not have an Issue representation.

**GitHub as primary operational source:** GitHub Projects are the canonical management domains. GitHub Project Views are projections over those domains. Jira, Azure DevOps, and Linear are optional sync tools only — they never replace GitHub as the source of truth for work state.

**Work Items reference artifacts — they are not the artifacts.**

Every Work Item must declare: Artifact Type, Artifact ID, Operation, Journey.

Examples of correct Work Items:
- Issue: "Discovery — BI-042 Split payment support" → references Business Intent BI-042
- Issue: "Refine OBC payments-invoice-v2 — incomplete BDD section" → references Local OBC
- Issue: "Update architecture — new webhooks module" → references Architecture overview.md

A single artifact can have dozens of Work Items throughout its life.
A single Work Item can affect multiple artifacts.

**Relationship with other concepts:** Managed by Diligence. See [`backlogs.md`](backlogs.en.md) and [`../journeys/diligence/README.md`](../journeys/diligence/README.en.md).

→ [Knowledge vs Execution](knowledge-vs-execution.en.md)

---

## Business Signal Issue

**Definition:** GitHub Issue representing a Business Signal. Created when any signal is captured in the system — before any strategic decision.

**Belongs to:** Portfolio GitHub Project (views: Business Signals or Discovery).

**Relationship with other concepts:** Represents a Business Signal. May reference Business Intent Issues that were generated from it. See **Business Signal**.

---

## Business Intent Issue

**Definition:** GitHub Issue representing a Business Intent — the strategic decision to pursue value. Represents the Intent in both the Business Intent Backlog and the Product Backlog (after OBC Partitioning).

**Belongs to:** Portfolio GitHub Project (views: Business Intent Backlog, Roadmap, or Platform Releases).

**Relationship with other concepts:** Represents a Business Intent. References the Business Signal Issue(s) that originated it (when applicable). The OBC is a Markdown document — it does not have an Issue representation. See **Business Intent**.
