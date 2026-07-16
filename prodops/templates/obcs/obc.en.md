# OBC - <Capability Name>

<!-- Rename this file to the capability slug: e.g. create-invoice.md -->
<!-- Move to prodops/artifacts/obcs/<slug>.md when promoting to Downstream -->
<!-- Full format definition: prodops/framework/obc.en.md -->

## Status

<!-- Declare the current state and where the OBC is located in the backlog cycle. -->
<!-- Possible states: Draft | Minimum OBC | Active | Operational | Archived -->

Draft. Located at `prodops/journeys/discovery/experiments/<NNN-slug>/obcs/<slug>.md` (exploratory).

## Business Outcome

<!-- Describe the business result the capability delivers.
     Answer: for whom, what, and with what guarantee.
     Focus on the result — not the technical implementation. -->

<Actor> can <do what> without <problem it solves>. <System> <main behavior>, <reliability behavior>.

### In executive language

<!-- Optional. Jargon-free explanation for non-technical stakeholders.
     Use an analogy if it helps. -->

<Analogy or executive explanation of what the feature guarantees for the business.>

## Observable Events

<!-- List all observable events the capability emits.
     Include success, failure, edge-case, and security events.
     Each event must have a canonical name, meaning, and required dimensions. -->

| Event | Meaning | Required dimensions |
|---|---|---|
| `<domain>.<success_action>` | <What this success event represents.> | `<field1>`, `<field2>`, `correlationId` |
| `<domain>.<failure_action>` | <What this failure event represents.> | `<field1>`, `reason`, `correlationId` |
| `<domain>.<edge_case>` | <What this edge-case event represents.> | `<field1>`, `correlationId` |

## Initial SLIs

<!-- Define service level indicators with quantitative targets.
     Each SLI must be observable via the events declared above.
     Use absolute percentages (e.g., 99.9%, 100%). -->

| SLI | Initial target |
|---|---|
| <Main success criterion observable via events.> | 99.9% |
| <Idempotency or critical safety criterion.> | 100% |
| <Controlled failure behavior criterion.> | 100% |

## Reliability Rules

<!-- List the invariants the implementation cannot violate.
     Include idempotency, safe failure, audit, and isolation rules.
     Each rule must be verifiable from the events and SLIs above. -->

- <Transient failure rule: what the system does when the provider fails.>
- <Idempotency rule: what happens on retries with the same key.>
- <Isolation rule: validations that occur before calling external systems.>
- <Audit rule: what is recorded and what must never be exposed.>

## Response Contract

<!-- Define the response contract: payload returned to the consumer, required fields.
     Use JSON if the capability is an API. Use narrative description if it's an async event. -->

```json
{
  "<id_field>": "...",
  "<reference_field>": "...",
  "<status_field>": "<EXPECTED_STATE>",
  "<value_field>": 0.00
}
```

## Related Artifacts

<!-- Links to directly related artifacts. Fill in as available. -->

- BDD: `prodops/artifacts/bdd/<slug>.feature`
- Iteration Plan: `prodops/artifacts/plans/iteration-plan.md`
- Icebox: `prodops/artifacts/product/icebox-backlog.md` — <Item ID>
- Related OBCs: *(list OBCs with direct dependency)*
