# EXP-002 - Asaas Sandbox Funding and Functional Validation

## Status

- [ ] Planned
- [x] In Progress
- [ ] Completed
- [ ] Cancelled

---

# Business Goal

Validate whether the Asaas Sandbox can reproduce the complete credit card
payment lifecycle required by the Payments API before promoting the capability
to Downstream.

The goal is to determine whether developers can execute end-to-end functional
validation locally using the Validation Workbench without requiring production
credentials or financial transactions.

---

# Repository Scope Gate

## Repository-owned scope

- [x] Payments API behavior
- [x] Payments domain logic
- [x] Provider integration
- [x] Webhook handling
- [ ] Persistence
- [x] API/event contract owned by Payments
- [x] Validation Workbench behavior
- [x] Local tests or executable evidence

## External dependencies

- Asaas Sandbox behavior.
- Asaas test cards and sandbox credentials.
- Provider webhook delivery in sandbox.
- Provider support for refund, chargeback, risk analysis and timeout scenarios.

## Scope decision

- [x] Continue as executable Upstream experiment in this repository
- [ ] Record only as external dependency or release risk
- [ ] Redirect to owning repository or team

The repository can validate Payments API behavior and local simulation. Real
sandbox capabilities depend on Asaas and must be documented as provider
evidence.

---

# Question to Answer

Can the Asaas Sandbox execute the complete credit card lifecycle required by
Magazine Siará?

The experiment must answer:

- How can a successful credit card payment be executed in Sandbox?
- Does Sandbox simulate available credit?
- Is there a way to "fund" or preload test accounts?
- Are predefined test cards available?
- Can approved and declined payments be reproduced?
- Can authorization, fraud analysis and refund flows be simulated?
- Which scenarios require mocks instead of the real Sandbox?

---

# Hypothesis

The Asaas Sandbox provides enough capabilities to validate most functional
payment scenarios, while unsupported scenarios can be reproduced by the
Validation Workbench through controlled simulation.

The Validation Workbench should become the primary environment for functional
validation of payment flows.

---

# Scope

Included:

- Asaas Sandbox capabilities.
- Sandbox limitations.
- Test cards and test customers.
- Sandbox authentication.
- Card authorization.
- Payment confirmation.
- Payment refusal.
- Refund and chargeback investigation.
- Webhook simulation.
- Validation Workbench deterministic simulation.

---

# Out of Scope

Not included:

- Production card processing.
- Production credentials.
- Checkout implementation.
- Financial settlement outside sandbox.
- Compliance approval.

---

# Implementation

Perform the following activities.

## Documentation

Review the official Asaas documentation to identify:

- Sandbox capabilities;
- Sandbox limitations;
- test credit cards;
- test customers;
- test environments;
- sandbox authentication;
- card authorization;
- risk analysis;
- payment confirmation;
- payment refusal;
- refund;
- chargeback;
- webhook simulation.

## Sandbox Investigation

Determine:

- whether Sandbox supports successful card payments;
- whether Sandbox supports declined payments;
- whether Sandbox simulates fraud analysis;
- whether Sandbox supports refund flows;
- whether Sandbox supports chargebacks;
- whether Sandbox supports webhook retries;
- whether Sandbox supports timeout simulation.

Investigate specifically:

**How can a developer execute a successful payment?**

If Sandbox requires card credit, determine:

- how credit is added;
- whether virtual cards exist;
- whether predefined cards are available;
- whether balances are simulated;
- whether Asaas provides special testing credentials.

## Validation Workbench

Update the Validation Workbench to support every scenario discovered.

If Sandbox cannot reproduce a scenario, implement deterministic local
simulation.

The Validation Workbench should allow developers to execute complete payment
flows repeatedly.

Create fixtures for:

- Approved Card;
- Declined Card;
- Invalid Card;
- Expired Card;
- Fraud Analysis;
- Authorization Pending;
- Authorization Approved;
- Authorization Refused;
- Payment Confirmed;
- Payment Received;
- Payment Deleted;
- Refund;
- Chargeback.

---

# Code Produced

No production code should be produced unless it directly supports sandbox or
Validation Workbench evidence.

Potential executable artifacts:

- Validation Workbench fixtures.
- Sandbox request examples.
- Local simulation payloads.
- Webhook payload samples.

---

# Functional Validation

Validate:

- invoice creation;
- hosted card payment;
- transparent payment if supported;
- webhook processing;
- provider events;
- retry behavior;
- timeout behavior;
- refund behavior;
- cancellation behavior.

---

# Technical Findings

Document:

- Sandbox capabilities;
- Sandbox limitations;
- available test cards;
- authentication model;
- required configuration;
- timeout behavior;
- idempotency behavior;
- webhook behavior;
- provider-specific restrictions.

---

# Business Findings

Identify:

- payment states that are fully reproducible;
- payment states that require simulation;
- payment states that require production validation.

Determine whether business users can validate the complete checkout journey
before Downstream.

---

# Architecture Impact

Confirmed:

- Validation Workbench should be the local repeatable environment for scenarios
  the sandbox cannot reproduce deterministically.

Open questions:

- Which card states can be triggered by Asaas Sandbox?
- Which card states require local simulation?
- Whether sandbox webhook behavior is sufficient for Downstream evidence.

---

# Reliability Impact

Update the Reliability Plan with:

- Sandbox limitations;
- validation strategy;
- required mocks;
- required telemetry;
- provider constraints;
- risks introduced by unsupported Sandbox scenarios.

---

# Artifacts Updated

Update when necessary:

- Validation Workbench.
- Repository Tracking List.
- Reliability Plan.
- Event Storming.
- OBC.
- BDD Features.
- Service Deck.

---

# Knowledge Gaps Closed

| Question | Status | Evidence |
|----------|--------|----------|
| Can Sandbox execute approved card payments? | Still Unknown | Requires sandbox execution evidence. |
| Can Sandbox simulate declined cards? | Still Unknown | Requires sandbox execution evidence. |
| Can Sandbox preload card credit? | Still Unknown | Requires Asaas sandbox evidence. |
| Does Sandbox provide predefined test cards? | Still Unknown | Requires Asaas documentation and execution evidence. |
| Can refunds be validated? | Still Unknown | Requires sandbox execution evidence. |
| Can chargebacks be simulated? | Still Unknown | Requires Asaas sandbox evidence. |
| Can webhook retries be reproduced? | Still Unknown | Requires provider or local simulation evidence. |

---

# New Backlog Items

| Item | Classification | Priority |
|------|----------------|----------|
| Collect Asaas sandbox test card evidence. | Repository Tracking List | P0 |
| Add deterministic card fixtures to Validation Workbench when sandbox cannot reproduce a scenario. | Candidate for Upstream execution | P0 |
| Document sandbox scenarios that require local simulation. | Repository Tracking List | P0 |

---

# Recommendation

- [ ] Move Downstream
- [x] Run another Upstream experiment
- [ ] Wait for business decision
- [x] Wait for external dependency
- [ ] Discard capability

Continue collecting sandbox evidence. Use local simulation only for states the
Asaas Sandbox cannot reproduce reliably.

---

# Decision Package

## Executive Summary

Sandbox evidence is required before treating credit card validation as ready for
Downstream. The repository can provide local simulation, but provider behavior
must be verified against Asaas Sandbox.

## Recommended Decision

Continue the experiment and wait for provider sandbox evidence.

## Updated Risks

- Sandbox may not reproduce every card state.
- Unsupported states may create false confidence if not simulated explicitly.
- Provider webhook timing may differ from local simulation.

## Updated Opportunities

- Use Validation Workbench as a repeatable business validation tool.
- Separate provider-supported scenarios from locally simulated scenarios.

## Updated Tracking Items

- Collect sandbox cards and webhook behavior.
- Document which states require simulation.

## Updated OBCs

No OBC is complete until sandbox-supported states are known.

## Updated Reliability Plan

Reliability Plan should include sandbox limitations as validation risk.

## Recommended Downstream Scope

No Downstream scope until sandbox evidence is classified.

---

# Output Artifacts

Lista os artefatos de produto gerados ou promovidos por este experimento.

## Artefatos gerados

| Tipo | Artefato | Situação |
|---|---|---|
| OBC | — | In Progress |
| BDD Feature | — | In Progress |

**Promovido para Downstream:** Não — experimento em andamento.
**Nota:** Objetivo é produzir evidência técnica de validação do sandbox Asaas, não gerar OBC/BDD próprios.

---

# Exit Criteria

- [ ] Original hypothesis answered
- [x] Questions classified
- [x] Knowledge gaps documented
- [x] Architecture impact documented
- [x] Reliability impact documented
- [x] Artifacts updated
- [x] Recommendation produced
- [x] Decision Package completed

---

# Next Step

Continue provider sandbox validation and document which states are reproduced by
Asaas versus simulated by the Validation Workbench.
