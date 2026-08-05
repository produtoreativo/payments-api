# ProdOps Framework

ProdOps is a product-driven engineering framework. It organizes work into five journeys (Discovery, Delivery, Operation, Assessment, Diligence) executed in two modes (Upstream or Downstream), connected by shared practices, contracts, and evidence.

This directory contains the canonical ProdOps Framework documentation. The content here defines the Framework — each consumer product adopts and extends it with its own local artifacts.

## Structure

| Directory | Purpose |
|---|---|
| `framework/` | Ontology, principles, glossary, and operating model |
| `journeys/` | The five journeys: Discovery, Delivery, Operation, Assessment, Diligence |
| `execution-model/` | Definition of the Upstream and Downstream modes |
| `skills/` | Executable skills for agents |
| `templates/` | Reusable templates for plans, trails, and checklists |

## Canonical framework documents

| Document | Purpose |
|---|---|
| [ontology.en.md](ontology.en.md) | **Canonical concept hierarchy:** Framework, Execution Model, Journey, Cycle, Phase, Capability, Skill, Step |
| [glossary.en.md](glossary.en.md) | Canonical vocabulary for all terms |
| [principles.en.md](principles.en.md) | The 8 foundational principles |
| [operating-model.en.md](operating-model.en.md) | Operating model and four-level architecture |
| [flow.en.md](flow.en.md) | Official framework flow |
| [backlogs.en.md](backlogs.en.md) | Backlog hierarchy |
| [phases.en.md](phases.en.md) | Business Intent lifecycle stages: Conception and Inception |
| [obc.en.md](obc.en.md) | Observable Business Contract — Global OBC, Local OBC, OBC Partitioning |
| [artifact-types.en.md](artifact-types.en.md) | Canonical artifact types — what each type is, when it is born, and how it relates to others |
| [artifact-governance.en.md](artifact-governance.en.md) | Artifact governance — owners, approvals, and lifecycle |
| [origin-streams.en.md](origin-streams.en.md) | The four Intent origins |
| [product-topology.en.md](product-topology.en.md) | Product Topology — the four permanent structural dimensions of the product |
| [product-stages.en.md](product-stages.en.md) | Product stages (PoC→MLP) |
| [dora-metrics.en.md](dora-metrics.en.md) | Extended DORA metrics |
| [positioning.en.md](positioning.en.md) | **How to explain ProdOps** — canonical communication guide for agents and humans; includes the Upstream/Downstream-as-modes differentiator, approved phrases, and common mistakes |

## OBC Templates

| Template | When to use |
|---|---|
| [templates/obcs/global-obc.en.md](../templates/obcs/global-obc.en.md) | Create a Global OBC in the BIB (strategic business contract) |
| [templates/obcs/local-obc.en.md](../templates/obcs/local-obc.en.md) | Create a Local OBC in the Product Backlog (product implementation contract) |

## OBC Partitioning

**OBC Partitioning** is the governance process that transforms a Global OBC into Local OBCs — one per product involved. It occurs after Discovery in the BIB. Executed by Portfolio PM + Tech Leads.

→ Full definition: [obc.en.md — OBC Partitioning](obc.en.md#obc-partitioning)

For work context, see the [assessment](journeys/assessment/README.en.md), [product](../artifacts/product/), and [downstream](execution-model/downstream.en.md) directories.

For agent execution, see [AGENTS.md](../../AGENTS.md) and [skills/](../skills/).
