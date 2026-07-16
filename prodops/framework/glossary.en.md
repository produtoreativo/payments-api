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

**Contains:** Global Tracking List, Business Intent Backlog, Roadmaps, Platform Releases, Milestones.

**Does not contain:** Software implementation, product OBCs, product BDD Features.

**Relation to other concepts:** The Portfolio sits between the Framework (which defines the rules) and the Workspaces (which execute). A Portfolio Roadmap coordinates Product Repositories. See **Platform Release**.

---

## Workspace

**Definition:** The product integration level. Responsible for running and testing multiple Product Repositories together.

**Purpose:** Ensure that products that depend on each other work correctly in an integrated manner. A Workspace has no Roadmap and no Business Intents — it exists exclusively for integration.

**Examples:** Checkout Workspace (webshop-api + payments-api + order-mgmt-api).

**Does not contain:** Roadmap, Business Intents, product code.

**Relation to other concepts:** A Workspace is coordinated by the Portfolio and integrates Product Repositories. See **Product Repository**.

---

## Product Repository

**Definition:** The implementation and operation level for a specific product within the ProdOps architecture. This repository (`payments-api`) is a Product Repository.

**Purpose:** Implement Product Capabilities, operate the product in production, and maintain full traceability from Intents to operation evidence.

**Contains:** OBCs, BDD Features, Iteration Plans, Reliability Plans, Release Trail, product code, runbooks, postmortems.

**Relation to other concepts:** A Product Repository adopts the Framework, participates in Roadmaps defined by the Portfolio, and is integrated by Workspaces. It can also evolve locally through its own Intent flow.

---

## Platform

**Definition:** The set of Product Repositories coordinated by the Portfolio and integrated by Workspaces. The platform is the composite product — what the end customer experiences.

**Relation to other concepts:** The Platform is the result of coordination between Portfolio, Workspaces, and Product Repositories. See **Portfolio**, **Workspace**, **Product Repository**.

---

## Platform Release

**Definition:** A platform version coordinated by the Portfolio, which includes contributions from multiple Product Repositories and is validated at the Workspace level.

**Purpose:** Mark a coherent delivery point for the platform as a whole — not just for a single product.

**Distinction:** A Platform Release is different from a local release of a single Product Repository. The local release (managed by the repository's CI Async) contributes to a Platform Release but does not replace it.

**Relation to other concepts:** Managed by the Portfolio. Composed of releases from multiple Product Repositories. See **Portfolio**, **Roadmap**.

---

## Roadmap

**Definition:** Planning of Product Capabilities over time, managed by the Portfolio. A Roadmap defines what the platform will deliver, in what order, and in which Platform Release.

**Purpose:** Communicate platform priorities and delivery horizon to stakeholders, teams, and partners.

**Who manages it:** The Portfolio. Product Repositories participate in Roadmaps but do not define them.

**Do not confuse with:** Iteration Plan (planning for one iteration within a Product Repository) or Icebox (candidates not yet prioritized).

**Relation to other concepts:** The Roadmap is managed by the Portfolio and guides which Intents from which Product Repositories will be prioritized. See **Portfolio**, **Platform Release**, **Intent**.

---

## Origin Stream

**Definition:** Classification of the origin of an Intent. Identifies where the need was born and who owns it.

**Purpose:** Ensure that every change has a traceable origin and that the context, language, and success criteria are appropriate for the type of need.

**When to use:** When registering any Intent. Every Intent has exactly one Origin Stream.

**When not to use:** Origin Stream does not determine the execution mode or the journey — that is the function of the Execution Mode and Continuous Assessment.

**The four Origin Streams:** Business | Enterprise | Team | Technology

**Relationship with other concepts:** An Origin Stream generates an Intent. The Intent enters Exploration. See [`origin-streams.md`](origin-streams.en.md).

---

## Intent

**Definition:** An intention to generate value not yet committed to implementation. It is the single entry point of the ProdOps Framework for any change.

**Purpose:** Formally register a need before any execution decision. The Intent captures the "why" without prescribing the "how".

**When to use:** Whenever a new need arises — regardless of origin, size, or urgency. Every change starts with an Intent.

**When not to use:** Intent is not a technical backlog, sprint task, or isolated bug ticket. Those are execution instances derived from an Intent, not Intents themselves.

**Life cycle:** The Intent is born in the Global Tracking List or Repository Tracking List as a signal not yet understood. When investigated and recognized as relevant, it enters the Business Intent Backlog (global flow) or the Product Intent Backlog (local flow) — at which point its OBC is created as a draft. From that point on, the OBC becomes the permanent identifier of the work.

**Relationship with other concepts:** The Intent has an Origin Stream (Business | Enterprise | Team | Technology). The Intent is transformed into an OBC by Exploration. See [`flow.md`](flow.en.md), [`origin-streams.md`](origin-streams.en.md) and [`backlogs.md`](backlogs.en.md).

**Formerly called:** Business Intent. The name was simplified to Intent to eliminate the ambiguity that only "Business" needs are capturable. The directory `prodops/business-intents/` is preserved for backward compatibility.

---

## Conception

**Definition:** Phase covering the period from the emergence of a signal to entry into the Product Intent Backlog. The Intent exists as a possibility — the Product Owner has not yet made a commitment.

**Central question:** Is there real value here?

**Backlogs:** Global Tracking List / Repository Tracking List → Business Intent Backlog (global flow).

**OBC state:** Does not exist in the Tracking Lists. Born as a Draft upon entry into the Business Intent Backlog (global flow). In the local flow, born as a Draft only upon entry into the PIB.

**Commitment:** None. The Intent may be discarded without any formal record of learning.

**Exit boundary:** Owner Approval — entry into the Product Intent Backlog (start of Inception).

**Relationship with other concepts:** See [`phases.en.md`](phases.en.md), [`backlogs.en.md`](backlogs.en.md).

---

## Inception

**Definition:** Phase covering the period from entry into the Product Intent Backlog until the OBC reaches the Minimum OBC state (Iteration Backlog). The Product Owner has made a formal commitment to investigate.

**Central question:** Is the Product Owner committing attention and capacity to investigate this now?

**Backlogs:** Product Intent Backlog → Icebox → Iteration Backlog.

**OBC state:** Draft → Draft under refinement (Icebox) → Minimum OBC (Iteration Backlog).

**Commitment:** Formal. Any closure requires a traceable learning record in the OBC.

**Execution mode:** Upstream (high uncertainty) or Downstream (sufficient clarity), defined by the Product Owner when accepting the Intent into the PIB.

**Exit boundary:** Assessment Review approved, OBC in Minimum OBC state, BDD Feature committed — entry into the Iteration Backlog.

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

**Definition:** The living contract representing a business intent throughout its entire lifecycle. It is the source of truth for the work — connecting business, product, architecture, engineering, operation, observability, and reliability. No other document should exercise this role.

**Creation:** Created automatically when a Business Intent enters the Business Intent Backlog (global flow) or the Product Intent Backlog (local flow). The OBC exists **before** Discovery, **before** Upstream, **before** Downstream.

**Purpose:** Be the shared language between product, engineering, and operation throughout the life of the intent. The OBC does not end with Delivery — it continues evolving during Operation.

**OBC States:**

| State | When | Description |
|---|---|---|
| **Draft** | Business Intent Backlog / Product Intent Backlog | Created; can be incomplete; records initial intent, hypotheses, and learnings |
| **Minimum OBC** | Iteration Backlog | Smallest set of information needed for entry into Delivery; gate between Discovery and Delivery |
| **Active** | Iteration Plan → Delivery | In execution; accompanies implementation, evidence, validations, and decisions |
| **Operational** | Operation | Feature in production; updated with operational information |
| **Archived** | — | No longer part of active product evolution; history preserved |

**Life cycle:**

| Backlog / Phase | State | What happens |
|---|---|---|
| Global Tracking List / Repository Tracking List | Does not exist | The item is not yet a recognized Intent |
| Business Intent Backlog (global flow) | Draft | OBC created; captures the Intent and initial hypotheses |
| Product Intent Backlog (local flow) | Draft | OBC created if not yet existing; records intent accepted by the Product Owner |
| Icebox (Discovery) | Draft under refinement | Discovery refines the OBC until reaching Minimum OBC |
| Iteration Backlog | Minimum OBC | Minimum validated OBC; entry gate to Delivery |
| Iteration Plan / Delivery | Active | Guides implementation; BDD Feature operationalizes it |
| Operation | Operational | In production; complemented with metrics, SLOs, incidents, postmortems |
| — | Archived | Intent closed; history preserved |

The OBC records the **living history of the work**: which backlogs it passed through, when, decisions made, how criteria evolved.

**OBC in Upstream:** During Upstream, the OBC remains in Draft, can be freely modified, can be incomplete, does not block experiments, records learnings, hypotheses, and decisions. No Skill should require a complete OBC during Upstream.

**OBC in Downstream:** When entering Downstream, the OBC is no longer just a record — it becomes the operational contract of the delivery. It is refined in the Icebox until reaching Minimum OBC, then controls all subsequent journey evolution.

**OBC and Skills:** All Downstream Skills use the OBC as the primary context source. Skills never generate parallel information that replaces the OBC. New artifacts produced by Skills complement or reference the OBC. The OBC remains the sole source of truth for the intent.

**When not to use:** Do not use the OBC as a substitute for an isolated technical task or bug ticket without a corresponding Intent.

**Relationship with other concepts:** The OBC is born at the Business Intent Backlog or Product Intent Backlog, refined through Discovery in the Icebox, reaches Minimum OBC upon entering the Iteration Backlog, becomes Active during Delivery and Operational in Operation. It anchors the BDD Feature, the Iteration Plan, the Reliability Plan, and all of Delivery. See [`flow.md`](flow.en.md) and [`backlogs.md`](backlogs.en.md).

**Formerly incorrectly defined as:** "Outcome-Based Criterion". The canonical definition is **Observable Business Contract**.

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

Exploration operates on OBC Drafts that were born at the Business Intent Backlog (global flow) or Product Intent Backlog (local flow) and are being refined in the Icebox.

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

**Definition:** Gherkin specification that describes the expected behavior of a Product Capability. Lives in `prodops/artifacts/bdd/` (committed) or `prodops/journeys/discovery/experiments/<NNN-slug>/features/` (exploratory — inside the experiment directory). Used as TDD input in Downstream.

---

## Reliability Plan

**Definition:** Product of the transversal Assessment journey that defines risks, SLOs, and mitigation actions for a committed item. Lives in `prodops/journeys/assessment/reliability-plans/`.

**Requirement level:** Recommended, not mandatory. Strongly recommended for items with relevant operational risk (high technical complexity, financial impact, new domains, or external integrations). When it exists, it must be reviewed before the Iteration Plan readiness decision.

**In the local flow (pre-PIB):** The Premortem is the appropriate artifact for risk analysis before Owner Approval. The formal Reliability Plan is produced during the Icebox, after the Product Owner's commitment.

---

## Global Tracking List

**Definition:** Platform-level backlog that captures any signal not yet understood enough to be treated as a formal Intent. Managed by the Portfolio.

**Question:** What deserves attention at the platform level?

**Does not contain:** OBC. Commitment. Permanent identifier.

**Relationship with other concepts:** First level of the global flow. Items advance to the Business Intent Backlog when recognized as Intents. See [`backlogs.en.md`](backlogs.en.md).

---

## Business Intent Backlog

**Definition:** Platform-level backlog representing Intents accepted for Discovery. The OBC is born as a Draft upon entry into this backlog. Managed by the Portfolio.

**Question:** What deserves Discovery?

**Relationship with other concepts:** Second level of the global flow. The Draft OBC is born here. Items advance to the Roadmap. See [`backlogs.en.md`](backlogs.en.md).

---

## Repository Tracking List

**Definition:** Product-level backlog that captures any local signal not yet understood enough to be treated as a formal commitment. Artifact: `prodops/artifacts/product/tracking-list.md`.

**Question:** What deserves attention in this product?

**Does not contain:** OBC. Commitment. Permanent identifier.

**Relationship with other concepts:** First level of the local flow. Items advance via Premortem + Preliminary Risk Analysis + Owner Approval to the Product Intent Backlog. (The formal Reliability Plan is produced later, during the Icebox — it is recommended, not mandatory for PIB entry.) See [`backlogs.en.md`](backlogs.en.md).

---

## Product Intent Backlog

**Definition:** Product-level backlog representing all work formally accepted by the Product Owner. Single entry point for the product into the Delivery cycle — regardless of where the item came from (Portfolio or local flow). If the item does not yet have a Draft OBC, it is created upon entry into this backlog.

**Question:** What has been officially accepted by the Product Owner?

**Two entry paths:** (1) Business Intent from the Portfolio via Platform Release; (2) Repository Tracking Item via Premortem + Preliminary Risk Analysis with Owner Approval.

**After entry, the origin no longer matters.** All items follow the same journey: Icebox → Iteration Backlog → Iteration Plan → Delivery.

**Relationship with other concepts:** Convergence point of the global and local flows. See [`backlogs.en.md`](backlogs.en.md).

---

## Icebox

**Definition:** Product-level backlog representing committed items still being prepared for Delivery. The functional, technical, and operational Discovery needed occurs here. Goal: produce a minimum acceptable OBC. Artifact: `prodops/artifacts/product/icebox-backlog.md`.

**Question:** What is still being prepared for Delivery?

**Relationship with other concepts:** Receives items from the Product Intent Backlog. Items advance to the Iteration Backlog after minimum OBC is validated. See [`backlogs.en.md`](backlogs.en.md).

---

## Iteration Backlog

**Definition:** Product-level backlog representing items with a validated minimum OBC, ready for immediate Delivery. Not a refinement backlog — refinement happens in the Icebox. The only remaining decision is the Product Owner's priority. Artifact: `prodops/artifacts/plans/iteration-backlog.md`.

**Question:** What is ready to be developed?

**Relationship with other concepts:** Receives items from the Icebox. Items advance to the Iteration Plan after OBC committed + BDD Feature committed. See [`backlogs.en.md`](backlogs.en.md).

---

## Iteration Plan

**Definition:** Record of Delivery execution for an iteration. Not a planning backlog — it represents exclusively the execution in progress. Contains items from the Iteration Backlog, execution strategy, CI Sync and CI Async journeys, evidence, and exit criteria. Artifact: `prodops/artifacts/plans/iteration-plan.md`.

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

**Definition:** The exploratory execution mode. Objective: transform hypotheses into validated knowledge. Code is disposable until promoted to Downstream. Upstream selects flow steps as needed — there is no mandatory sequence. A typical Upstream cycle uses Bootstrap + Hack + Sync; Ship, Validate, and Promote are used only when the experiment needs staging validation or a promotion decision. See [`prodops/journeys/discovery/README.en.md`](../journeys/discovery/README.en.md).

---

## Downstream

**Definition:** The governed delivery mode. Objective: deliver with confidence using validated knowledge. Every item requires OBC + BDD Feature + risks documented + entry in the Iteration Plan. The Reliability Plan is recommended but not mandatory. Downstream requires the full flow: `Bootstrap → Hack → Sync → Finish → Ship → Validate → Promote`. See [`prodops/execution-model/downstream.en.md`](../execution-model/downstream.en.md).

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

**Definition:** The append-only log of Downstream evidence. Each agent session produces its own file at `prodops/artifacts/trails/sessions/YYYY-MM-DD-<session-id>.md`. See model at [`artifacts/trails/release-trail.en.md`](../artifacts/trails/release-trail.en.md).

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

**Definition:** Operational representation of a commitment already made in the ProdOps Framework. It is not the origin of work.

**Purpose:** Make an OBC that has already entered the Product Intent Backlog or Iteration Plan visible and manageable in a management tool.

**When to use:** Normally when an OBC is committed and enters the Iteration Plan — the moment the commitment was made and the work is ready for operational execution.

**When not to use:** Issues do not replace OBCs. Do not create Issues as the work entry point — the entry point is the Global Tracking List or Repository Tracking List. Do not use Issues to capture Intents that do not yet have an OBC.

**Tool independence:** The Framework is tool-independent. A GitHub Issue, a Jira Card, and an Azure DevOps Work Item are operational representations of the same OBC in different tools. The OBC is the source of truth; the Issue is the execution instance.

**Relationship with other concepts:** Managed by Diligence. References the corresponding OBC. See [`backlogs.md`](backlogs.en.md) and [`../journeys/diligence/README.md`](../journeys/diligence/README.en.md).
