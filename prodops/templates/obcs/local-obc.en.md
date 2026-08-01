# OBC - <Capability Name>

<!-- Rename this file to the capability slug: e.g. split-payment-api.md -->
<!-- Move to prodops/artifacts/obcs/<slug>.md when the OBC is Committed -->
<!-- Full format definition: prodops/framework/obc.en.md -->
<!-- Owner: Product Manager + Tech Lead of the product -->

## Status

<!-- Declare the current state and where it is tracked.
     Possible states: Draft | Refining | Committed | In Delivery | Operational | Archived
     Example: Downstream. Status `Entered` in prodops/artifacts/plans/iteration-plan.md. -->

Draft. Located at `prodops/artifacts/obcs/<slug>.md`.

## Business Outcome

<!-- Describe in one or two parts:
     1. What the product delivers and what guarantees it provides (technical business perspective).
     2. Optional — "### In executive language": accessible analogy for non-technical stakeholders.
     Focus on the observable OUTCOME, not the implementation. -->

<Describe the business outcome this capability delivers, the guarantees it provides, and the problems it solves.>

### In executive language

<!-- Optional. Use when the capability's behavior is not intuitive for non-technical stakeholders.
     Write as a real-world analogy, without technical jargon. -->

<Simple analogy that explains the behavior to an executive audience.>

## Observable Events

<!-- List all observable events this capability emits.
     Include success, failure, idempotency, and edge-case events.
     Each event must have a canonical snake_case name, meaning, and required dimensions.
     `correlationId` is always required. -->

| Event | Meaning | Required dimensions |
|---|---|---|
| `<domain>.<success_action>` | <What this success event represents.> | `<field1>`, `<field2>`, `correlationId` |
| `<domain>.<failure_action>` | <What this failure event represents.> | `<field1>`, `reason`, `correlationId` |

## Initial SLIs

<!-- List the initial service level indicators with measurable targets.
     Use 100% for absolute invariants; use percentages for reliability targets.
     These targets are reviewed and evolved during Operation. -->

| SLI | Initial target |
|---|---|
| <Measurable behavior the system must guarantee.> | <100% or 99.x%> |

## Reliability Rules

<!-- List the invariants the implementation cannot violate.
     Must cover: idempotency, transient failure behavior, secret isolation, audit.
     Each rule is a prescriptive statement — not a suggestion. -->

- <Idempotency rule: what happens on retries with the same idempotency key.>
- <Transient failure rule: what the system does when an external provider fails.>
- <Isolation rule: validations that occur before calling external systems.>
- <Audit rule: what is recorded and what must never be exposed in logs or responses.>

## Response Contract

<!-- Optional. Include when the capability exposes an API with a well-defined response contract.
     Use JSON for REST APIs. Omit for purely asynchronous (event-driven) capabilities. -->

```json
{
  "<id_field>": "...",
  "<reference_field>": "...",
  "<status_field>": "<EXPECTED_STATE>",
  "<value_field>": 0.00
}
```

## Related Artifacts

<!-- List the artifacts related to this capability.
     BDD and Iteration Plan are required when the OBC is In Delivery or later.
     Related OBCs list capabilities that depend on or are depended upon by this one. -->

- BDD: `prodops/artifacts/bdd/<slug>.feature`
- Iteration Plan: `prodops/artifacts/plans/iteration-plan.md`
- Related OBCs: *(links to dependent or related capability OBCs)*
