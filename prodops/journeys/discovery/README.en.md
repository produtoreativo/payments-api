# Discovery

## Purpose

Discovery is the ProdOps exploration and preparation journey. It exists in both Upstream and Downstream with different responsibilities; it is not synonymous with Upstream.

---

## Discovery in Upstream

**Objective:** Explore.

No obligation to complete artifacts. No mandatory gates. The engineer decides which Skills to use. The expected result is learning.

Can include:

- interviews and benchmarks
- Event Storming
- prototypes and spikes
- experiments and vibecoding
- research

An Upstream experiment may produce production-quality code, but that code is considered exploratory until the capability is promoted to Downstream.

---

## Discovery in Downstream

**Objective:** Prepare a committed item for Delivery.

An item enters the Icebox after being accepted in the Product Backlog. Discovery in Downstream occurs within the Icebox. The goal is to produce a Local OBC in the Committed state through refinement:

- functional — what the system must do
- technical — how the system must do it
- operational — how the system must behave in production

At the end of Discovery in Downstream, the item has a Local OBC in the Committed state and advances to the Iteration Backlog.

---

## General objectives

Discovery exists to:

- understand business problems;
- validate technical approaches;
- explore provider capabilities;
- prototype integrations;
- validate business flows;
- reduce implementation risks;
- evolve Product knowledge.

---

# Repository Scope Gate

Before creating an experiment, BDD Feature, OBC, prototype, Validation Workbench change
or any execution artifact, confirm that the capability can be developed
or validated within this repository.

Create execution artifacts only when this repository owns or can directly exercise
at least one of the following:

- API behavior;
- domain logic;
- provider integration;
- webhook handling;
- persistence;
- Payments API-owned contracts;
- Validation Workbench flow;
- executable tests or evidence.

If the request depends on implementation owned by another repository or system,
do not create a Feature, experiment, prototype or execution artifact here.
Record only as:

- external dependency;
- release risk;
- Product Tracking List item;
- Reliability Plan note;
- required evidence from the responsible system.

Examples of work outside this repository:

- Checkout Feature Flag implementation;
- Checkout rollout targeting;
- Notification Service delivery behavior;
- Order Management fulfillment behavior;
- corporate ITSM integration outside the Payments API.

Upstream can document the dependency, but must not make it appear executable in this repository.

---

# Typical Outputs

An Upstream activity may produce:

- executable code;
- Validation Workbench improvements;
- prototypes;
- BDD scenarios;
- OBC drafts;
- OpenAPI updates;
- AsyncAPI updates;
- Event Storming updates;
- Reliability Plan updates;
- Product Tracking List updates;
- architecture decisions.

---

# Workflow

A typical Upstream flow is:

Business Question

↓

Hypothesis

↓

Experiment

↓

Implementation

↓

Functional Validation

↓

Learning

↓

Decision

↓

Assessment

↓

Downstream (if approved)

---

# Experiments

Experiments live in:

```
prodops/journeys/discovery/experiments/
```

Each experiment must answer a specific question.

Examples:

- Is the provider API sufficient?
- Which architecture should be adopted?
- Can this business flow be validated?
- What are the operational risks?

Experiments should be small and focused.

## Experiment File Layout

New experiments should use a directory per experiment:

```text
prodops/journeys/discovery/experiments/NNN-short-slug/
  experiment.md
  upstream-trail.md
  evidence/
```

Use `experiment.md` for the stable hypothesis, scope, findings, recommendation and Decision Package.

Use the experiment's local `upstream-trail.md` for chronological execution notes, validation evidence, artifact changes and decisions that occurred during the experiment.

Use `evidence/` only for supporting material too detailed for the experiment document, such as command outputs, screenshots, payload examples or provider responses.

Flat experiment files restored from legacy paths are historical artifacts. Do not create new flat experiment files. If a flat file is restored from history or another branch, migrate it to the canonical directory standard before making further changes.

The global `prodops/journeys/discovery/upstream-trail.md` is not the primary location for experiment execution history. Keep it as a high-level chronological index for cross-experiment milestones, migrations, promotions and Discovery/Upstream process changes at the repository level.

---

# Validation Workbench

The Validation Workbench is the preferred environment for functional validation.

It is used to:

- validate business flows;
- validate integrations;
- validate BDD scenarios;
- simulate provider behavior;
- validate UX;
- reduce implementation uncertainty.

The Validation Workbench is part of Upstream.

---

# Relationship with Assessment

Every completed experiment must produce a Decision Package.

The Decision Package feeds the Continuous Assessment.

The Assessment decides whether a capability should:

- advance to Downstream;
- require another experiment;
- wait for business decisions;
- be discarded.

## Decision Package Review

The Decision Package is not reviewed automatically — it requires an explicit decision from those who have authority over the product and architecture.

### When to review

After the experiment reaches its Exit Criteria (hypothesis answered, recommendation produced, artifacts updated). Do not review incomplete experiments.

### Who participates

| Role | Responsibility in the review |
|---|---|
| Product Manager | Validates business value and decides whether the capability enters the Iteration Plan |
| Tech Lead | Validates technical feasibility, architectural risks and OBC |
| Experiment author | Presents the findings and defends the recommendation |

### What is reviewed

The complete Decision Package (sections of `experiment.md`):
- **Executive Summary** — shared understanding of what was discovered
- **Recommended Decision** — the author's recommendation (see options below)
- **Updated Risks** — new or mitigated risks
- **Updated Opportunities** — identified opportunities
- **Updated Tracking Items** — items that need to enter the Product Tracking Lists or Portfolio Tracking Lists
- **Updated OBCs** — proposed success criteria
- **Recommended Downstream Scope** — what enters the next iteration, if approved

### Possible review outcomes

| Recommendation | What happens |
|---|---|
| **Promote** | Start the promotion process (see "Promotion to Downstream Process" section). BDD Feature + OBC moved. Capability enters the Iteration Plan. |
| **Promote with restriction** | A subset of the capability is promoted. Restricted parts remain in Upstream for another experiment. |
| **Requires another experiment** | Create a new experiment with a more specific hypothesis. Record the decision in the current experiment's `upstream-trail.md`. |
| **Wait for business decision** | Block the experiment in the Product Tracking List with the decision-maker and expected date. Do not open a new experiment until the decision arrives. |
| **Wait for external dependency** | Record the dependency in the Reliability Plan and Product Tracking List. Monitor in Continuous Assessment. |
| **Discard** | Record the learning in `prodops/journeys/discovery/learnings.md`. Close the experiment with justification in the `upstream-trail.md`. |

### Recording the decision

Regardless of the outcome, record in the experiment's `upstream-trail.md`:
- Review date
- Participants
- Decision made
- Next steps

If the outcome generates a change in the Reliability Plan, update `prodops/journeys/assessment/risks.md` or `opportunities.md` before closing the cycle.

---

# Relationship with Downstream

Upstream prepares knowledge.

Downstream delivers software.

A capability should advance to Downstream only when:

- the business behavior is understood;
- the architecture is stable;
- the Reliability Plan has been updated;
- the OBC is sufficiently defined;
- the remaining uncertainty is acceptable.

## Promotion to Downstream Process

Promotion is an explicit decision, not an automatic consequence of a completed experiment.

### Who decides

The promotion decision belongs to the Product Manager + Tech Lead responsible for the capability, based on the Decision Package produced by the experiment.

### Promotion criteria

Before promoting, confirm that:

1. The experiment's Decision Package has a clear recommendation (`Promote` or `Promote with restriction`).
2. The expected behavior is described in a BDD Feature in `prodops/journeys/discovery/experiments/<NNN-slug>/features/` ready to be moved to `prodops/artifacts/business/bdd/`.
3. The OBC draft in `prodops/journeys/discovery/experiments/<NNN-slug>/obcs/` has measurable criteria and can be moved to `prodops/artifacts/business/obcs/`.
4. The Reliability Plan has been updated with the risks and mitigation actions identified in the experiment.
5. The remaining uncertainty is acceptable to enter Downstream with a delivery commitment.

### Promotion steps

```
1. Move BDD Feature:
   prodops/journeys/discovery/experiments/<NNN-slug>/features/<slug>.feature
   → prodops/artifacts/business/bdd/<slug>.feature

2. Move OBC:
   prodops/journeys/discovery/experiments/<NNN-slug>/obcs/<slug>.md
   → prodops/artifacts/business/obcs/<slug>.md
   (remove draft marking)

3. Create or update entry in Iteration Plan:
   prodops/artifacts/governance/plans/iteration-plan.md
   (add with decision `Entered` in the "Recommended Iteration Plan" table —
   not only in "Identified Iteration Backlog", as this section does not satisfy
   the formal Downstream precondition)

4. Update Product Tracking List if the item was there:
   prodops/artifacts/product/backlogs/tracking-list.md
   (change status to "Promoted to Downstream")

5. Record the promotion in the experiment's upstream trail:
   prodops/journeys/discovery/experiments/<NNN-slug>/upstream-trail.md

6. Record in the global upstream trail:
   prodops/journeys/discovery/upstream-trail.md
   (high-level entry: what was promoted and when)
```

### What is NOT promotion

- Moving code to production without moving ProdOps artifacts.
- Creating a committed OBC without a corresponding BDD Feature.
- Starting Downstream implementation before the OBC is in `prodops/artifacts/business/obcs/`.
- Promoting with a `Do not promote` or `Requires another experiment` recommendation in the Decision Package.

---

# Golden Rules

- Keep experiments focused.
- Answer one question at a time.
- Produce executable evidence whenever possible.
- Stop when the hypothesis has been answered.
- Update the affected ProdOps artifacts.
- Document learnings.
- Produce a clear recommendation.
- Avoid implementing unrelated capabilities.

The learning is the primary outcome.

The implementation is a means to achieve the learning.
