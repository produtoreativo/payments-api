# Upstream Trail — EXP-008 DORA Extended Documentation

## 2026-07-16

**Initiated by:** Christiano Milfont

**Context:** User requested a complete documentation plan for extended DORA in ProdOps. The metrics are defined in Certificare (`~/produtos/certificare`) but have no presence in payments-api.

**Actions:**
- Read Certificare: `assessments.service.ts`, `delivery-assessment-definition.service.ts`, pocket assessment YAMLs.
- Identified 7 extended DORA metrics + maturity scale 0–5 + 5 assessment profiles.
- Applied Repository Scope Gate: documentation-only, within product scope.
- Created `experiment.md` with a 6-layer plan, execution sequence, and Decision Package.

**Result:** Complete plan produced. Recommendation: Promote to Downstream.

**Next steps:** Assessment Review with PM + Tech Lead for plan approval and start of Layer 3.

---

## 2026-07-16 — Layer 0 executed

**Context:** Identified that PoC in ProdOps always involves a customer. No customer = Spike Solution. Spike Solution can occur at any stage and phase. The stages (PoC, MVP, IPR, MVR, MVT, MLP) were not documented in the framework.

**Actions:**
- Created `prodops/framework/product-stages.md` + `.en.md` — 6 stages with definitions, macro-phases, PoC vs Spike Solution table, reference to DORA.
- Updated `prodops/framework/glossary.md` + `.en.md` — added terms: Product Stage, PoC, Spike Solution.
- Elevated `prodops/journeys/discovery/spikes.md` from stub to full definition with registration structure and PoC distinction.
- EXP-008 updated with Layer 0 marked as completed.

**Result:** Stage vocabulary and Spike Solution available for Layers 1–6.

---

## 2026-07-16 — Layers 1–6 implemented (experiment completed)

**Actions:**

- **Layer 3** — Created `evidence/obc-dora-mapping.md`: 41 events from 7 OBCs mapped to the 7 DORA metrics. Coverage: Reaction Time ✅, Rate of Return ✅, Availability ✅, Change Fail Rate ✅ partial, MTTR ✅ partial, Lead Time ✗, Release Frequency ✗. 3 instrumentation gaps documented.
- **Layer 2** — Created `framework/dora-metrics.md` + `.en.md`: 7 metrics with definitions, weights table per stage (PoC→MLP), 5 assessment profiles, maturity scale 0–5, complementary metrics.
- **Layer 1** — Updated `framework/glossary.md` + `.en.md`: added terms **DORA Metrics (Extended)** and **Maturity Level (Delivery)**.
- **Layer 4** — Updated `journeys/operation/README.md` + `.en.md`: section "DORA as a continuous health instrument" with signal → action table per metric and Intent generation flow via DORA deterioration.
- **Layer 5** — Updated `journeys/assessment/reliability-plans/README.md`: section "DORA as a reliability reference" with OBC SLIs → DORA metrics mapping and coverage gaps for this Release.
- **Layer 6** — Updated `artifacts/product/product-deck.md`: section 15 "Delivery Maturity (DORA)" with current stage (MVP→IPR), balanced profile, weights per metric, and instrumentation gaps.

**Artifacts produced (10):**
1. `evidence/obc-dora-mapping.md` (new)
2. `framework/dora-metrics.md` (new)
3. `framework/dora-metrics.en.md` (new)
4. `framework/glossary.md` (updated — DORA Metrics + Maturity Level)
5. `framework/glossary.en.md` (updated)
6. `journeys/operation/README.md` (updated)
7. `journeys/operation/README.en.md` (updated)
8. `journeys/assessment/reliability-plans/README.md` (updated)
9. `artifacts/product/product-deck.md` (updated)
10. `experiment.md` (completed)

**Result:** experiment completed. Hypothesis confirmed — complete documentation in 7 layers, documentation-only, no impact on code.
