# Upstream Experiment

Canonical location:

```text
prodops/journeys/discovery/experiments/NNN-short-slug/experiment.md
```

Each experiment must also have:

```text
prodops/journeys/discovery/experiments/NNN-short-slug/upstream-trail.md
prodops/journeys/discovery/experiments/NNN-short-slug/evidence/
prodops/journeys/discovery/experiments/NNN-short-slug/features/   ← BDD Features (created during the experiment)
prodops/journeys/discovery/experiments/NNN-short-slug/obcs/       ← OBC drafts (created during the experiment)
```

`features/` and `obcs/` are created as needed. Artifacts stay here until `move-to-downstream`, when they are moved to `prodops/artifacts/business/bdd/` and `prodops/artifacts/business/obcs/`.

Do not create experiment files directly in `prodops/journeys/discovery/experiments/` — always inside a subdirectory with a slug.

## Status

- [ ] Planned
- [ ] In Progress
- [ ] Completed
- [ ] Cancelled

---

# Business Goal

Describe the expected business outcome of this experiment.

Why is this experiment being executed?

---

# Repository Scope Gate

Confirm whether this experiment can be developed or validated in this repository.

## Scope of responsibility of this repository

Mark all applicable items:

- [ ] Payments API behavior
- [ ] Payments domain logic
- [ ] Provider integration
- [ ] Webhook processing
- [ ] Persistence
- [ ] API/event contract owned by Payments
- [ ] Local tests or executable evidence

## External dependencies

List dependencies that are the responsibility of another repository, team, system, vendor, or platform.

Examples:

- Checkout Feature Flag
- Checkout rollout targeting
- Notification Service delivery
- Order Management fulfillment
- Corporate ITSM integration

## Scope decision

Choose one:

- [ ] Proceed as an Upstream experiment executable in this repository
- [ ] Record only as external dependency or release risk
- [ ] Redirect to the responsible repository or team

If this repository cannot develop or validate the capability, stop here. Do not create BDD Features, OBC drafts, prototypes, or implementation artifacts for this request in this repository.

---

# Question to Answer

List the questions this experiment must answer.

Examples:

- Can this capability be implemented?
- Is the provider API sufficient?
- Which architecture should be adopted?
- Can the business flow be reproduced locally?

---

# Hypothesis

Describe the expected outcome before implementation.

State what is believed to be true and will be validated during the experiment.

---

# Scope

Describe what IS included.

Examples:

- APIs
- Business flows
- Components
- Services
- Validation scripts
- Documentation

---

# Out of Scope

Explicitly describe what will NOT be investigated.

This section prevents scope expansion.

---

# Implementation

Describe the activities needed to execute the experiment.

Examples:

- study documentation
- implement code
- update contracts
- create BDD scenarios
- create prototype
- run integrations

---

# Code Produced

List the executable artifacts created.

Examples:

- endpoints
- services
- DTOs
- repositories
- scripts
- prototypes

If no code was produced, explain why.

---

# Functional Validation

Describe how the business flow was validated.

Examples:

- local execution
- integration tests
- BDD scenarios
- provider sandbox
- manual scripts

---

# Technical Findings

Document technical findings.

Examples:

- API limitations
- Provider behavior
- Timeout
- Idempotency
- Authentication
- Event model
- Integration constraints

---

# Business Findings

Document business findings.

Examples:

- New business rules
- Missing rules
- UX findings
- Process improvements
- Risks
- Opportunities

---

# Architecture Impact

Describe architectural decisions.

Include:

- Confirmed decisions
- Rejected decisions
- Assumptions
- Open questions

---

# Reliability Impact

Describe impacts on:

- Reliability Plan
- Observability
- SLOs
- Telemetry
- Resilience
- Security
- Operational readiness

---

# Artifacts Updated

List all artifacts updated.

Examples:

- Product Deck (`prodops/artifacts/product/context/product-deck.md`)
- Service Deck (`prodops/artifacts/product/context/service-decks/`)
- Repository Tracking List (`prodops/artifacts/product/backlogs/tracking-list.md`)
- Icebox (`prodops/artifacts/product/backlogs/icebox-backlog.md`)
- Event Storming (`prodops/journeys/assessment/event-storming/`)
- Reliability Plan (`prodops/journeys/assessment/reliability-plans/`)
- OBC (`prodops/artifacts/business/obcs/`)
- BDD Features (`prodops/artifacts/business/bdd/`)

---

# Knowledge Gaps Closed

Classify each original question.

| Question | Status | Evidence |
|----------|--------|----------|
| | ✅ Answered | |
| | ⚠ Partially answered | |
| | ❌ Still unknown | |

---

# New Backlog Items

List work discovered during the experiment.

Classify each item as:

- Repository Tracking List
- Icebox
- Iteration Backlog candidate
- Discarded

---

# Recommendation

Choose one:

- [ ] Move to Downstream
- [ ] Run another Upstream experiment
- [ ] Await business decision
- [ ] Await external dependency
- [ ] Discard capability

Justify.

---

# Decision Package

Summarize the information needed for Continuous Assessment.

Include:

## Executive Summary

## Recommended Decision

## Updated Risks

## Updated Opportunities

## Updated Tracking Items

## Updated OBCs

## Updated Reliability Plan

## Recommended Downstream Scope

---

# Sandbox Deploy Record

Fill in only if the experiment was deployed to real AWS via `/upstream deploy-to-sandbox`.

| Field | Value |
|---|---|
| Deploy date | |
| Branch | |
| API URL | |
| Triggered by | |
| Teardown date | |

---

# Exit Criteria

Confirm that:

- [ ] Original hypothesis answered
- [ ] Questions classified
- [ ] Knowledge gaps documented
- [ ] Architectural impact documented
- [ ] Reliability impact documented
- [ ] Artifacts updated
- [ ] Recommendation produced
- [ ] Decision Package complete

---

# Next Step

Describe the next action.

Examples:

- Start another Upstream experiment.
- Move to Downstream.
- Await Product decision.
- Await Architecture review.
- Await external dependency.
