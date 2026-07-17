# Literature Review Report — ProdOps Framework

**Date:** 2026-07-10
**Scope:** Review and reorganization of literature on ProdOps Framework inputs (origins of changes)
**Objective:** Conceptual consistency, unique naming, absence of ambiguities

---

## 1. Renamed concepts

| From | To | Rationale |
|---|---|---|
| **Business Intent** | **Intent** | The name "Business Intent" suggested that only market needs (Business) were capturable by the Framework. The canonical naming becomes "Intent" with a declared "Origin Stream" attribute. The directory `prodops/artifacts/business/intents/` is kept for backward compatibility. |
| **OBC (Outcome-Based Criterion)** | **OBC (Observable Business Contract)** | The previous definition was incorrect. An OBC is not an "outcome-based criterion" but an "observable business contract" — the distinction is important because the contract is verifiable and anchors the entire delivery chain. |
| **Capability** (ambiguous) | **Delivery Capability** or **Product Capability** | The term "capability" was used with two distinct meanings: (1) technical competencies of the delivery process (Commit Workflow, Contract Management, etc.) and (2) product features being built (split payment, Pix support). The ambiguity was resolved with qualified terms. |
| **Business** (top node in operating model) | **Origin Stream (Business \| Enterprise \| Team \| Technology)** | The previous operating model showed only "Business" as the top node, omitting that there are four possible types of origin. |

---

## 2. Eliminated ambiguities

### A. OBC incorrectly defined as "Outcome-Based Criterion"

**Problem:** The glossary defined OBC as "Outcome-Based Criterion" — a result-based criterion. This definition was incorrect. The OBC is an Observable Business Contract — a contract, not just a criterion.

**Impact:** The wrong definition undermined the understanding of the central role of the OBC as a verifiable contract that anchors the entire delivery chain.

**Solution applied:** Definition corrected in the glossary, the operating model, assessment/README.md, and all new documentation. Added note "Formerly incorrectly defined as".

---

### B. Origin Streams absent from documentation

**Problem:** The concept that an Intent can have four different origins (Business, Enterprise, Team, Technology) did not exist in any document. The operating model showed only "Business" as the top node, creating the false impression that the Framework only serves market needs.

**Impact:** Teams with compliance, infrastructure evolution, or process improvement needs had no vocabulary to register their Intents canonically.

**Solution applied:** Created `prodops/framework/origin-streams.md` with complete definition of the four Origin Streams, examples, counter-examples, and classification rules. The operating model was updated to show Origin Stream as the top layer.

---

### C. "Business Intent" as a restrictive naming

**Problem:** The term "Business Intent" was ambiguous for two reasons: (1) "Business" could be interpreted as the Business Origin Stream specifically, excluding the other three; (2) "Intent" preceded by "Business" created the impression that only market business intentions were capturable.

**Impact:** The naming reduced the perceived scope of the Framework, leading compliance, infrastructure, and process teams to not register Intents or to register them improvised.

**Solution applied:** The canonical naming becomes "Intent" (without qualifier). The Origin Stream is an attribute of the Intent, not part of the name. The directory `prodops/artifacts/business/intents/` is kept for backward compatibility with an explanatory note in the README.

---

### D. Exploration vs Discovery vs Upstream — three terms for the same phase

**Problem:** The three terms were used interchangeably in different documents:
- `exploration` appeared as an implicit step in the flow but was never explicitly named
- `discovery` was used both as the journey name and as a synonym for Upstream mode
- `upstream` was used both as execution mode and as the informal name for the Discovery journey

**Impact:** When reading different documents, it was unclear whether "doing Upstream", "going to Discovery", and "entering Exploration" were the same thing or distinct concepts.

**Solution applied:** Distinction table created in the glossary and flow.md:

| Term | Level | Meaning |
|---|---|---|
| **Exploration** | Flow step | What happens: uncertainty reduction between Intent and OBC |
| **Discovery** | Journey | The name of the Framework journey that implements Exploration |
| **Upstream** | Execution Mode | The execution mode (low commitment) used during Discovery |

---

### E. "Capability" with two distinct meanings

**Problem:** The term "capability" appeared in two contexts with completely different meanings:
- `operating-model.md`: "Capability — reusable competencies consumed by the phases" → Delivery Capability (Commit Workflow, Observability, etc.)
- `execution-model/upstream.md`: "explore a new capability", "Reduce uncertainty before a capability enters the flow" → Product Capability (what is being built)

**Impact:** When reading "capability" in isolation, it was unclear whether we were talking about a delivery process mechanism or a product feature.

**Solution applied:** The glossary now explicitly defines "Delivery Capability" and "Product Capability" as distinct concepts. The operating model updates the term in the hierarchical diagram to "Delivery Capability". A note in the glossary guides to always use the qualified term when there is ambiguity.

---

### F. OBC incorrectly positioned as Framework entry point

**Problem:** Several documents implicitly treated the OBC as an entry point or as the first thing to be created. The flow `Business Intent → Assessment → Upstream/Downstream` omitted the Exploration step that precedes the OBC.

**Impact:** The OBC was being confused with the system entry point, when in fact it is the result of Exploration on an Intent.

**Solution applied:** `flow.md` makes the correct sequence explicit with emphasis: "The OBC is NOT the entry. The OBC is the transformation of a sufficiently understood Intent into an observable contract." The operating model was updated to show the Exploration layer between Intent and OBC.

---

## 3. Created files

| File | Content |
|---|---|
| `prodops/framework/origin-streams.md` | Complete definition of the four Origin Streams (Business, Enterprise, Team, Technology) with examples, counter-examples, generated artifacts, and classification rules. Includes Mermaid diagram. |
| `prodops/framework/flow.md` | Official Framework flow: Origin Stream → Intent → Exploration → OBC → Iteration Plan → Reliability Plan → Delivery → Operation. For each step: objective, what happens, what is produced, when to advance. Includes Mermaid diagram and Exploration/Discovery/Upstream distinction table. |

---

## 4. Modified files

| File | Modification |
|---|---|
| `prodops/framework/glossary.md` | Corrected OBC to "Observable Business Contract". Added entries: Origin Stream, Intent, Business (Origin Stream), Enterprise (Origin Stream), Team (Origin Stream), Technology (Origin Stream), Exploration, Discovery (revised), Delivery Capability, Product Capability. All entries now have: definition, purpose, when to use, when not to use, relationship with other concepts. |
| `prodops/framework/operating-model.md` | Added Origin Stream layer at the top of the hierarchical diagram. Added Exploration layer between Intent and OBC. Renamed "Business Intent" to "Intent". Renamed "Capability" to "Delivery Capability". Updated lifecycle. Added links to `flow.md` and `origin-streams.md`. |
| `prodops/artifacts/business/intents/README.md` | Updated to reflect Intent naming with Origin Stream. Added backward compatibility note. Added table of the four Origin Streams. Updated post-registration flow to include Exploration. Active Intents table with Origin Stream column. |
| `prodops/templates/business-intents/intent.md` | Added "Origin Stream" field in the Identification table. Added explanatory note with the four Origin Streams and link to `origin-streams.md`. Renamed title from "Business Intent" to "Intent". Generalized "Business Hypotheses" to "Hypotheses". |
| `prodops/README.md` | Updated operating model to show Origin Stream at the top. Added links to `framework/flow.md` and `framework/origin-streams.md`. Updated reading order. Updated portal with new description of `framework/`. |
| `prodops/framework/canonical-paths.md` | Added entries for `flow.md` and `origin-streams.md` in the Framework section. Renamed section "Business Intents" to "Intents". Added entry for Intent template. Renamed section "Delivery — Capabilities" to "Delivery — Capabilities (Delivery Capabilities)". |
| `AGENTS.md` | Updated reading order to include `flow.md` and `origin-streams.md`. Added entries in Source of Truth: official flow, Origin Streams, registered Intents. Updated OBC naming to "Observable Business Contracts". Updated "capability" reference to "Product Capability". |
| `prodops/journeys/assessment/README.md` | Corrected OBC definition from "Outcome-Based Criteria" to "Observable Business Contracts". |

---

## 5. Removed files

No files were removed.

---

## 6. Compatibility impacts

### Preserved backward compatibility

- **Directory `prodops/artifacts/business/intents/`:** Kept with explanatory note. Existing documents were not renamed.
- **Internal links:** All existing links were preserved. New links were added.
- **Existing artifacts (split-payment.md):** Not changed. The existing artifact remains valid as a Business origin Intent.

### Visible changes

- The operating model now shows `Origin Stream (Business | Enterprise | Team | Technology)` at the top, where previously only `Business` appeared. Readers of the old model will see a richer hierarchy.
- The term `OBC` keeps the acronym but changes the expanded meaning from "Outcome-Based Criterion" to "Observable Business Contract". The expected OBC behavior does not change — only the textual definition.
- The term "Capability" in the operating model diagram now appears as "Delivery Capability" to avoid ambiguity.

---

## 7. Recommendations for future evolution

### 7.1 — Update split-payment.md artifact to include Origin Stream

The artifact `prodops/artifacts/business/intents/split-payment.md` is the only existing Intent and does not have the Origin Stream field. It is recommended to update it to include `origin_stream: Business` in the Identification table, serving as the canonical example of the new format.

### 7.2 — Review use of "capability" in journey documents

The term "capability" (without qualifier) still appears in several documents of the Delivery and Discovery journeys. A future sweep should identify each occurrence and qualify as "Product Capability" or "Delivery Capability" according to context.

### 7.3 — Create Intent examples by Origin Stream

Currently there is only one Intent example (split-payment.md, Business origin). Creating documented examples for the other three Origin Streams would help compliance, infrastructure, and engineering teams recognize and register their Intents.

### 7.4 — Consider separating the business-intents directory

In the medium term, evaluate migrating `prodops/artifacts/business/intents/` to `prodops/intents/` to definitively eliminate the ambiguity. This step requires updating all internal links and should be done with team coordination. Not recommended in this cycle to avoid disruption.

### 7.5 — Add backward compatibility note to split-payment.md

Add an opening comment to split-payment.md indicating that this artifact was registered before the introduction of Origin Streams and that its Origin Stream is Business.

---

## Architectural decisions made

**Why "Intent" and not "Business Intent"?**
Clarity surpasses familiarity. The name "Business Intent" created an entry barrier for all Origin Streams that are not Business. The choice to simplify to "Intent" (with Origin Stream as an attribute) is simultaneously more generic and more precise.

**Why keep `prodops/artifacts/business/intents/` without renaming?**
Backward compatibility. Renaming the directory would break all existing links in artifacts, skills, and training documents. The decision to rename can be made in a dedicated cycle with lower disruption impact.

**Why "Exploration" as the name of the flow step?**
To resolve the polysemy of "Discovery" (which is the journey) and "Upstream" (which is the mode). "Exploration" is the macro flow level term — neutral with respect to the journey and the mode. This allows saying "during Exploration" without connoting which journey or mode is being used.

**Why "Delivery Capability" instead of just "Capability"?**
To distinguish from the term "Product Capability" that was already used informally. "Delivery Capability" is more precise and follows the qualification pattern the Framework uses elsewhere (e.g.: "CI Sync" vs "CI Async").
