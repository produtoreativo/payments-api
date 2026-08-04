# Premortem — [Feature or Release Name]

<!--
  WHEN TO USE
  -----------
  Before starting a sprint or release with real failure risk:
  financial transactions, external integrations, SLO changes, sensitive
  data, high operational criticality, or cross-team dependencies.

  A premortem is not a deploy checklist. It is a controlled imagination
  exercise: project a future where the delivery failed and work backwards
  to understand why — before it happens.

  LOCATION
  --------
  prodops/artifacts/plans/reliability/premortem.md

  RELATIONSHIP WITH OTHER ARTIFACTS
  ----------------------------------
  - OBC: the premortem does not replace the OBC; it complements it with failure analysis
  - Reliability Plan: uses premortem scenarios as risk input
  - Postmortem: after real incidents, compare with the premortem — what did we get right?
  - Iteration Plan: the scope analyzed here must match features marked "In" (Entrou)
-->

> [One sentence describing the goal of this premortem — what is being delivered and why the exercise is being done now]

---

## 1. Executive context

<!--
  Explain the current state of the product/system being changed.
  Answer: where are we starting from? What technical and business
  situation makes this delivery risky?

  Include:
  - What already exists and works
  - What is broken or blocked (bugs, flags, technical debt)
  - External or cross-team dependencies
  - Relevant history of incidents or prior learnings
  - Why this sprint/release matters now
-->

[Describe the context of the product, team, and delivery. Include the current state of the involved systems, critical dependencies, known bugs, and motivation for the work.]

---

## 2. Premortem premise

<!--
  Explicitly declare the imagined failure scenario.
  Always use the same form: "It is the end of [period] and the delivery failed."
  This creates the mental starting point for the exercise.

  Specify what "failed" means for this delivery:
  - The feature was not enabled in production?
  - There was a rollback?
  - Customers were impacted?
  - SLO was violated?
-->

It is the end of [period — e.g., a 15-day sprint, go-live week] and the delivery failed or had to be rolled back. [Describe what failure means for this specific delivery: what did not work, who was impacted, what was the expected state that was not reached.]

This document answers: what probably happened, what signals would have appeared beforehand, and what actions reduce the chance of failure.

---

## 3. Expected delivery outcomes

<!--
  List the observable outcomes that define success — not tasks, but outcomes.
  "Checkout integrated" is better than "endpoint created."

  Each outcome must be verifiable: can someone confirm it was reached
  without opening the code?
-->

| Outcome | Description |
|---|---|
| [Outcome name 1] | [What it means to have reached this outcome — observable behavior] |
| [Outcome name 2] | [same] |
| [Outcome name 3] | [same] |

---

## 4. Critical hypotheses

<!--
  List the assumptions that must be true for the delivery to work.
  For each: what happens if it is false? How to validate before going to production?

  Critical hypotheses differ from risks: they are statements you are
  assuming to be true without having proven them yet. If one is false,
  the delivery fails in a non-obvious way.

  Common patterns:
  - "The contract between service A and B covers all cases"
  - "The Feature Flag fully isolates the new behavior"
  - "The expected volume is within the system's capacity"
  - "Dependent service X is available and stable"
-->

| Hypothesis | Risk if false | How to validate before go-live |
|---|---|---|
| [Statement you are assuming to be true] | [What breaks if it is false] | [How to prove it is true before going to production] |

---

## 5. Probable failure scenarios

<!--
  For each scenario: imagine the failure HAS ALREADY happened. Describe:
  - What the team/customer observes (the symptom, not the cause)
  - What probably caused it (the root cause, not the symptom)
  - The real impact on the business/customer
  - What signals would appear BEFORE or DURING — in monitoring, logs, support tickets
  - What reduces the probability or impact

  IDs in format [PREFIX]-PRE-NNN for traceability.
  Use a prefix that identifies the domain (e.g., PMT for Payments, CHK for Checkout).

  Order from most critical to least critical (P0 before P2).
-->

| ID | Imagined failure | Probable cause | Impact | Early signals | Preventive action |
|---|---|---|---|---|---|
| [PRE-001] | [What the team or customer observes when the failure occurs] | [Why this would probably happen — technical or process root cause] | [Who is affected and how — customer, operations, business] | [Metrics, logs, alerts, or behaviors that appear before or during] | [What to do now to reduce probability or impact] |

---

## 6. Questions that need answers before starting

<!--
  List concrete open questions that block engineering or product decisions.
  These are not risks — they are knowledge gaps that must be filled
  before work begins (or before go-live).

  For each: why does it matter? Who has the answer?
  If nobody knows the answer, it is a bigger risk than it seems.
-->

| Question | Why it matters | Suggested owner |
|---|---|---|
| [Concrete question that needs an answer] | [What stays unresolved if not answered] | [Team or role responsible for the answer] |

---

## 7. Readiness checklist

<!--
  Minimum criteria to enable the feature in production.
  This is not a sprint task list — it is the go-live gate.

  Each line must have a verifiable criterion and an owner.
  Status: Open | In progress | Closed — [justification or reference]

  Common areas: Product, Contracts, Idempotency, Observability,
  Alerts, Operations/Runbook, Security, Persistence, CI/CD, Feature Flag.
-->

| Area | Minimum criterion before enabling in production | Status |
|---|---|---|
| Product | [Journey described with expected states and customer messages] | Open |
| Contracts | [API/event contract documented and versioned] | Open |
| Idempotency | [Critical operations deduplicated for retry and duplicate webhooks] | Open |
| Observability | [Dashboard with success, error, and latency metrics available] | Open |
| Alerts | [Alerts defined for critical failures and SLO] | Open |
| Operations | [Runbook created or updated for known failure modes] | Open |
| Feature Flag | [Gradual rollout, audit, and rollback tested] | Open |
| Security | [Secrets and PII masked in logs; authorization reviewed] | Open |
| [Specific area] | [Criterion specific to this context] | Open |

---

## 8. Risk reduction plan

<!--
  Concrete actions to reduce the risks identified in the scenarios.
  This is not the sprint backlog — these are mitigation actions that must
  happen BEFORE or DURING the sprint for the go-live to be safe.

  Priorities: P0 = blocks go-live | P1 = highly recommended | P2 = improvement

  Each action must have a verifiable expected result and an owner.
-->

| Priority | Action | Expected result | Suggested owner |
|---|---|---|---|
| P0 | [Action that blocks go-live if not done] | [How to know it was completed successfully] | [Team or role] |
| P1 | [Highly recommended action before go-live] | [Expected result] | [Owner] |
| P2 | [Desirable improvement, not blocking] | [Expected result] | [Owner] |

---

## 9. ProdOps Definition of Done for this delivery

<!--
  Criteria each story or capability of this delivery must meet
  to be considered done — beyond functional criteria.

  Adapt by removing lines that do not apply to the context.
  Add domain-specific criteria (e.g., compliance, GDPR, financial contracts).
-->

A story in this delivery is only considered done when it meets the following criteria, where applicable:

- [ ] Functional criteria implemented and tested
- [ ] API or event contract documented and versioned
- [ ] Failure modes mapped with clear responses for consumers
- [ ] Idempotency validated for retry, timeout, and duplicate webhook
- [ ] Structured logs with the correlation identifiers defined for this domain
- [ ] Success, error, and latency metrics emitted
- [ ] Canonical event published exactly once per relevant state transition
- [ ] Dashboard or operational query available
- [ ] Minimal runbook updated for known failures
- [ ] [Context-specific criterion]

---

## 10. Alignment narrative

<!--
  Prose text to communicate the essentials to stakeholders, PMs,
  tech leads, and adjacent teams who have not read the rest of the document.

  Answer in 3-4 paragraphs:
  1. What is the context and what is being delivered?
  2. Where are the responsibility boundaries and critical dependencies?
  3. What makes this delivery risky and what has been done about it?
  4. What defines success — what goes beyond "endpoints delivered"?
-->

[Write the narrative in accessible language. Describe the context, team boundaries, main risks, and what defines real success for this delivery — not just functional, but operational and for the customer.]
