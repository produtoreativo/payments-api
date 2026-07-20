# Global OBC - <Intent Name>

<!-- NOTE: This template is for use in the platform PORTFOLIO repository, not in this product repository. -->
<!-- Global OBCs belong to the platform level. Product repositories contain only Local OBCs. -->
<!-- Rename this file to the intent slug: e.g. split-payment.md -->
<!-- Full format definition: prodops/framework/obc.en.md -->
<!-- Owner: Portfolio PM -->

## Status

<!-- Declare the current state of the contract.
     Possible states: Draft | Refining | Operational | Archived
     A Global OBC goes from Draft → Refining (during Discovery in BIB) → Operational (when all derived Local OBCs are in production) -->

Draft.

## Business Goal

<!-- Describe the strategic goal this intent seeks to achieve.
     Answer: what business outcome do we want to generate, for whom, and why now.
     Focus on the goal — not the technical solution. -->

<Strategic goal in one or two sentences.>

## Business Value

<!-- Describe the expected value: impact on revenue, retention, compliance, efficiency, etc.
     Include expected success metrics when known. -->

<Expected value and success metrics.>

## Stakeholders

<!-- List the stakeholders involved: who sponsors, who will be impacted, who approves. -->

| Stakeholder | Role | Responsibility |
|---|---|---|
| <Name / Role> | <Sponsor / Approver / Impacted> | <What they decide or receive> |

## Business Rules

<!-- List the business rules this intent must respect.
     These are domain constraints or invariants — not technical rules. -->

- <Business rule 1>
- <Business rule 2>

## Business Events

<!-- List the business events this intent generates or depends on.
     Strategic level — not technical. What happens in the real world? -->

| Event | Meaning | When it occurs |
|---|---|---|
| `<event-name>` | <What this event represents in the business.> | <Trigger condition.> |

## KPIs / Expected Outcomes

<!-- Define the key performance indicators and expected quantitative outcomes.
     These KPIs guide the definition of SLIs in derived Local OBCs. -->

| KPI | Current baseline | Target | Deadline |
|---|---|---|---|
| <KPI name> | <Current value> | <Expected target> | <Deadline> |

## Value Stream

<!-- Describe the value stream: how this intent fits into the broader business process.
     Identify the main touchpoints: user → system → outcome. -->

<Value stream description in business language.>

## Products Involved

<!-- List the products (repositories) that will participate in delivering this intent.
     This list will be used during OBC Partitioning to create the Local OBCs. -->

| Product / Repository | Expected responsibility |
|---|---|
| <repository-name> | <What this product delivers for this intent.> |

## Local OBC Traceability

<!-- Filled in during OBC Partitioning.
     For each involved product, record the corresponding Local OBC. -->

| Product | Local OBC | State | Last updated |
|---|---|---|---|
| <repository-name> | `prodops/artifacts/business/obcs/<slug>.md` | Draft | <date> |

## Discovery Notes

<!-- Record the learnings from Discovery in the BIB here.
     Hypotheses raised, experiments conducted, decisions made.
     Updated continuously during Discovery and afterward via Continuous OBC Refinement. -->

### Hypotheses

- <Hypothesis 1 — validated / refuted / under investigation>

### Experiments

- <Experiment: link to prodops/journeys/discovery/experiments/<NNN-slug>/>

### Decisions

- <Decision made and justification>
