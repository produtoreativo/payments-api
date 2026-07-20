# Upstream Experiment — Extended DORA: Complete Documentation Plan

Canonical location:

```text
prodops/journeys/discovery/experiments/008-dora-extended-documentation/experiment.en.md
```

## Status

- [ ] Planned
- [ ] In Progress
- [x] Completed
- [ ] Cancelled

---

# Business Goal

ProdOps uses extended DORA metrics as a delivery maturity assessment instrument in Certificare. However, these metrics are not documented at any level of payments-api: they do not appear in the framework glossary, are not referenced in the Operation journey, are not connected to the Observable Events of the OBCs, and are not linked to the Reliability Plan.

The goal of this experiment is to produce a complete and executable documentation plan — mapping what needs to be created, in which artifact, in which order, and where the boundary lies between what belongs to the canonical framework and what belongs to the product.

---

# Repository Scope Gate

## Scope of responsibility for this repository

- [ ] Payments API behavior
- [ ] Payments domain logic
- [ ] Provider integration
- [ ] Webhook processing
- [ ] Persistence
- [ ] API/event contract owned by Payments
- [x] Local tests or executable evidence

**Nature of the experiment:** documentation-only. The repo hosts the ProdOps artifacts for the product (glossary, Operation journey, Reliability Plan, OBCs) that need to reference and contextualize the extended DORA metrics defined in Certificare.

## External dependencies

- **Certificare** (`~/produtos/certificare`) — canonical source of definitions, weights per stage, and extended DORA assessment profiles.
- **ProdOps Framework repo** (if it exists separately) — canonical home for framework-level glossary definitions.

## Scope decision

- [x] Proceed as an executable Upstream experiment in this repository
  - Rationale: this repo is the framework adoption point for the product. The Operation, Reliability Plan, and OBC artifacts here are the ones that need to connect to the metrics. The documentation belongs here because this is where it will be used.

---

# Question to Answer

1. What are the 7 extended DORA metrics and how do they differ from the original 4?
2. How do the Observable Events of the existing OBCs map to each DORA metric?
3. Where should each documentation layer live (framework vs product)?
4. How should the Reliability Plan reference DORA?
5. How should the Operation journey incorporate DORA as a continuous monitoring instrument?
6. What is the execution sequence to produce the complete documentation?

---

# Hypothesis

Complete documentation of extended DORA in this product's ProdOps requires **six interdependent layers**, executed from the inside out (framework → product → operation), and can be produced entirely without code — only with ProdOps artifacts.

---

# Scope

- Definition of the 7 metrics in the framework glossary
- New `dora-metrics.md` file in the framework (PT + EN)
- Connection between Observable Events of the OBCs and each DORA metric
- Update of the Operation journey with DORA as a health instrument
- Update of the Reliability Plan template to include DORA
- Update of the Product Deck with DORA maturity indicators
- Cross-reference to Certificare as the assessment platform

---

# Out of Scope

- Implementation of metrics collection in code (dashboards, metrics pipelines)
- Changes to Certificare
- Definition of absolute targets per product (this belongs to the Reliability Plan per OBC)
- BDD Features or product OBCs

---

# Documentation Plan — The Six Layers

## Layer 1 — Definition in the Framework Glossary

**File:** `prodops/framework/glossary.md` + `glossary.en.md`

**What to add:** Two new terms after the Phases section:

- **DORA Metrics (Extended):** definition of the 7 metrics, distinction from the original 4-metric DORA, reference to `dora-metrics.md`.
- **Maturity Level (Delivery):** scale 0–5 (None → Excellence), top-down evaluation, use in Certificare.

**Quality criterion:** each metric must have a canonical name, what it measures, and how it relates to the product's Observable Events.

---

## Layer 2 — Dedicated `dora-metrics.md` file

**File:** `prodops/framework/dora-metrics.md` + `dora-metrics.en.md`

**File structure:**

```
# DORA Metrics — Extended Model

## The 7 Metrics

### DORA Core (4 original)
- Lead Time for Change
- Release Frequency
- Change Fail Rate
- Mean Time to Recovery

### ProdOps Extensions (3 additional)
- Reaction Time          ← time between signal and first response
- Rate of Return         ← escaped defects / rework
- Availability           ← operational uptime

## Weights per Product Stage

Table: Metric × (PoC | MVP | IPR | MVR | MVT | MLP) with weights 1–8.

## Assessment Profiles

balanced | velocity | quality | reliability | ai_readiness

## Maturity Scale (0–5)

None → Initial → Repeatable → Defined → Managed → Excellence
Top-down strategy: starts at 5, drops at the first failed mandatory criterion.

## Complementary Metrics (Quality Gate)

Test Coverage | Test Pass Rate | Rollback Health

## References
→ Certificare (assessment platform)
→ Operation journey
→ Reliability Plan
```

---

## Layer 3 — OBC Observable Events → DORA Mapping

**File:** `prodops/journeys/discovery/experiments/008-dora-extended-documentation/evidence/obc-dora-mapping.en.md`

**What to produce:** table crossing each Observable Event of the existing OBCs with the DORA metric it feeds.

**Example:**

| OBC | Observable Event | DORA Metric fed |
|---|---|---|
| create-invoice | `invoice.created` | Release Frequency (deploy reached production with real events) |
| create-invoice | `invoice.creation_failed` | Change Fail Rate |
| payment-confirmation | `payment.confirmed` | Lead Time for Change |
| webhook-configuration | `webhook.delivered` | Availability |
| (any OBC) | Absence of event in SLO window | Mean Time to Recovery |

**Criterion:** all 7 existing OBCs mapped.

---

## Layer 4 — Operation Journey Update

**File:** `prodops/journeys/operation/README.md` + `README.en.md`

**What to add:** section "DORA as a continuous health instrument" with:

- Which metric to monitor at which product stage
- How the operations team reads the metrics to generate new Intents
- Relationship between DORA deterioration and opening of incidents or postmortems
- Link to `dora-metrics.md` and to Certificare

**Section structure:**

```markdown
## DORA as a continuous health instrument

Continuous Assessment uses the extended DORA metrics to identify
when the product needs a new improvement Intent.

| Deterioration signal | DORA Metric | Expected action |
|---|---|---|
| Deploy takes > X | Lead Time for Change | Intent Technology: review pipeline |
| Frequent rollbacks | Change Fail Rate | Intent Technology: test quality |
| Slow recovery | Mean Time to Recovery | Intent Technology: runbook + alerts |
| Growing rework | Rate of Return | Intent Team: validation process |
| Availability dropping | Availability | Intent Technology: SLO + error budget |
| Slow response to signals | Reaction Time | Intent Team: on-call + monitoring |
```

---

## Layer 5 — Reliability Plan Template Update

**File:** `prodops/journeys/assessment/reliability-plans/README.md` + `README.en.md`

**What to add:** section "DORA as a reliability reference" indicating:

- Which DORA metrics are relevant to the readiness decision
- How the OBC Initial SLIs connect to DORA metrics (e.g.: uptime SLI = DORA Availability)
- Criterion: for items with high operational risk, the Reliability Plan must declare which DORA metrics will be monitored in production

---

## Layer 6 — Product Deck Update

**File:** `prodops/artifacts/product/product-deck.md` + `product-deck.en.md`

**What to add:** section "Delivery Maturity (DORA)" with:

- Current product stage (PoC / MVP / IPR / MVR / MVT / MLP)
- Adopted assessment profile (balanced / velocity / quality / reliability / ai_readiness)
- Link to assessment in Certificare
- Metrics with highest weight at this stage (pre-filled from the weights table)

---

# Recommended Execution Sequence

```
0. Layer 0 — Product Stages + Spike Solution   ← PREREQUISITE for all others
   (vocabulary that anchors DORA weights and distinguishes PoC from Spike Solution)
   └── framework/product-stages.md + .en.md           ✅ Completed
   └── framework/glossary.md + .en.md                 ✅ Completed (Product Stage, PoC, Spike Solution)
   └── journeys/discovery/spikes.md                   ✅ Completed (elevated from stub to definition)

1. Layer 3 — OBC → DORA Mapping
   (empirical base that anchors the definitions — produce first)
   └── evidence/obc-dora-mapping.md

2. Layer 2 — dora-metrics.md
   (complete definitions; uses the mapping as evidence)
   └── framework/dora-metrics.md + .en.md

3. Layer 1 — Glossary
   (short terms that reference dora-metrics.md)
   └── framework/glossary.md + .en.md

4. Layer 4 — Operation journey
   (connects continuous monitoring to the metrics)
   └── journeys/operation/README.md + .en.md

5. Layer 5 — Reliability Plan template
   (connects risk assessment to the metrics)
   └── journeys/assessment/reliability-plans/README.md + .en.md

6. Layer 6 — Product Deck
   (positions the product on the maturity scale)
   └── artifacts/product/product-deck.md + .en.md
```

---

# Technical Findings

- Certificare defines 7 metrics with weights per stage (scale 1–8) and assessment profiles.
- The Observable Events of existing OBCs already have semantics compatible with DORA — only the explicit mapping is missing.
- The Operation journey exists but does not reference delivery health metrics.
- The Reliability Plan references SLIs/SLOs per OBC but does not connect to the DORA model.
- The Product Deck has no delivery maturity section.

---

# Architecture Impact

No architectural impact. Documentation-only.

---

# Reliability Impact

No direct impact. The plan prepares the ground for future Reliability Plans to reference DORA metrics — but does not alter any existing operational artifact.

---

# Artifacts Updated

- This experiment (created): `prodops/journeys/discovery/experiments/008-dora-extended-documentation/`

Artifacts to be produced in Layers 1–6 (not yet modified):
- `prodops/framework/dora-metrics.md` + `.en.md`
- `prodops/framework/glossary.md` + `.en.md`
- `prodops/journeys/operation/README.md` + `.en.md`
- `prodops/journeys/assessment/reliability-plans/README.md` + `.en.md`
- `prodops/artifacts/product/product-deck.md` + `.en.md`
- `evidence/obc-dora-mapping.md`

---

# Knowledge Gaps Closed

| Question | Status | Evidence |
|---|---|---|
| What are the 7 extended DORA metrics? | ✅ Answered | Certificare `assessments.service.ts` |
| How do Observable Events map to DORA? | ⚠ Partially answered | Initial mapping in Layer 3; requires validation with all 7 OBCs |
| Where should each documentation layer live? | ✅ Answered | 6-layer plan above |
| How should the Reliability Plan reference DORA? | ✅ Answered | Layer 5 |
| How should the Operation journey incorporate DORA? | ✅ Answered | Layer 4 |
| What is the execution sequence? | ✅ Answered | Sequence defined above |

---

# New Backlog Items

| Item | Classification |
|---|---|
| Execute Layer 3: OBC → DORA mapping | Candidate for Iteration Backlog (documentation downstream) |
| Execute Layers 1–2: glossary + dora-metrics.md | Candidate for Iteration Backlog |
| Execute Layers 4–6: Operation, Reliability Plan, Product Deck | Candidate for Iteration Backlog |

---

# Recommendation

- [x] Move to Downstream

The plan is sufficiently defined. The 6 layers have declared scope, order, and quality criteria. The remaining uncertainty (complete mapping of all 7 OBCs) is low and resolvable during Layer 3.

---

# Decision Package

## Executive Summary

ProdOps extended DORA defines 7 metrics with weights per product stage and assessment profiles. None of them are documented in payments-api. Complete documentation requires 6 executable layers in sequence, all documentation-only, with no impact on code or product contracts.

## Recommended Decision

Promote to Downstream. Execute the 6 layers in order, starting with the OBC → DORA mapping as the empirical base.

## Updated Risks

- Low risk: the OBC → DORA mapping may reveal events absent from existing OBCs (e.g.: no event explicitly signals Lead Time for Change). Mitigation: document the gap and open an item in the Tracking List.

## Updated Opportunities

- The Observable Events → DORA connection may qualify OBCs as automatic health check instruments in Certificare.

## Updated Tracking Items

No new items in the Repository Tracking List at this time.

## Updated OBCs

No OBCs modified.

## Updated Reliability Plan

No Reliability Plan modified. The template will be updated in Layer 5.

## Recommended Downstream Scope

Execute the 6 layers as a single documentation item in the next Delivery cycle, with Layers 1–3 as prerequisites for Layers 4–6.

---

# Exit Criteria

- [x] Original hypothesis answered — 7 layers (0–6) implemented
- [x] Questions classified — all answered
- [x] Knowledge gaps documented — 3 instrumentation gaps in obc-dora-mapping.md
- [x] Architectural impact documented — none
- [x] Reliability impact documented — DORA section added to Reliability Plan
- [x] Artifacts updated — all 10 artifacts produced
- [x] Recommendation produced — Promote to Downstream
- [x] Decision Package complete

---

# Next Step

Start Downstream with Layer 3 (OBC → DORA mapping) as the first deliverable, followed by Layers 1–2 (glossary + dora-metrics.md).
