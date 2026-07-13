# Execution Model

Upstream and Downstream are **execution modes** of the ProdOps Framework — they are not journeys.

Each mode uses every journey, including Discovery. The difference is commitment and applied rigor, not the presence or absence of a journey.

## Upstream

Permissive, experimental mode with no delivery commitment.

**Characteristics:**
- No delivery commitment
- Freedom to select capabilities and practices as needed
- Code is disposable until promoted to Downstream
- Rapid artifact evolution
- Focus on learning, not delivery

Upstream transforms hypotheses into validated knowledge.

→ [Upstream mode details](upstream.md)

## Downstream

Delivery-commitment mode with complete application of current quality gates.

**Characteristics:**
- Formal commitment to acceptance criteria (OBC + BDD Feature)
- Complete governance and traceability
- Mandatory artifacts before start
- Evidence recorded at each step
- Full mandatory sequence

Downstream delivers software with knowledge validated by Upstream.

→ [Downstream mode details](downstream.md)

## How to choose the mode

| Situation | Mode |
|---|---|
| Hypothesis to validate, high uncertainty | Upstream |
| Committed item being guided toward complete readiness | Downstream |
| Explore a new capability | Upstream |
| Execute an item with every readiness gate satisfied | Downstream |
| Prototype integration with a provider | Upstream |
| Deliver feature with commitment | Downstream |
