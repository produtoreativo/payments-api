# ProdOps Framework

ProdOps is a product-driven engineering framework. It organizes work into two paths — Upstream (explore and validate) and Downstream (govern and deliver) — connected by shared practices, contracts, and evidence.

This directory contains the Framework documentation as applied to this **Product Repository** (`payments-api`). The canonical Framework lives one level above — this repository adopts and extends it with its own product artifacts.

## Structure

| Directory | Purpose |
|---|---|
| `framework/` | Core principles and shared vocabulary |
| `journeys/delivery/` | Delivery phases and coding practices |
| `skills/` | Executable skills for agents |
| `templates/` | Reusable templates for plans, trails, and checklists |

## Canonical framework documents

| Document | Purpose |
|---|---|
| [glossary.en.md](glossary.en.md) | Canonical vocabulary for all terms |
| [flow.en.md](flow.en.md) | Official framework flow |
| [backlogs.en.md](backlogs.en.md) | Backlog hierarchy |
| [phases.en.md](phases.en.md) | Conception and Inception phases |
| [obc.en.md](obc.en.md) | Observable Business Contract — Global OBC, Local OBC, OBC Partitioning |
| [artifact-governance.en.md](artifact-governance.en.md) | Artifact governance |
| [origin-streams.en.md](origin-streams.en.md) | The four Intent origins |
| [product-stages.en.md](product-stages.en.md) | Product stages (PoC→MLP) |
| [dora-metrics.en.md](dora-metrics.en.md) | Extended DORA metrics |

## OBC Templates

| Template | When to use |
|---|---|
| [templates/obcs/global-obc.en.md](../templates/obcs/global-obc.en.md) | Create a Global OBC in the BIB (strategic business contract) |
| [templates/obcs/local-obc.en.md](../templates/obcs/local-obc.en.md) | Create a Local OBC in the Product Backlog (product implementation contract) |

## Capability: OBC Partitioning

**OBC Partitioning** is the capability that transforms a Global OBC into Local OBCs — one per product involved. It occurs after Discovery in the BIB. Executed by Portfolio PM + Tech Leads.

→ Full definition: [obc.en.md — OBC Partitioning](obc.en.md#obc-partitioning)

For work context, see the [assessment](../journeys/assessment/README.en.md), [product](../artifacts/product/), and [downstream](../execution-model/downstream.en.md) directories.

For agent execution, see [AGENTS.md](../../AGENTS.md) and [skills/](../skills/).
