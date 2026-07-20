# Local OBC - <Capability Name>

<!-- Rename this file to the capability slug: e.g. split-payment-api.md -->
<!-- Move to prodops/artifacts/business/obcs/<slug>.md when promoting to Committed -->
<!-- Full format definition: prodops/framework/obc.en.md -->
<!-- Owner: Product Manager + Tech Lead of the product -->

## Status

<!-- Declare the current state of the contract.
     Possible states: Draft | Refining | Committed | In Delivery | Operational | Archived
     Location by state:
       Draft/Refining: prodops/journeys/discovery/experiments/<NNN-slug>/obcs/<slug>.md
       Committed+:     prodops/artifacts/business/obcs/<slug>.md -->

Draft. Located at `prodops/journeys/discovery/experiments/<NNN-slug>/obcs/<slug>.md`.

## Global OBC

<!-- Mandatory field. Reference the Global OBC from which this Local OBC was derived.
     If this is a local-flow Local OBC (no Global OBC), record "Local — direct flow". -->

→ `<path-in-portfolio-repo>/obcs/<global-slug>.md` — <Intent Name>

## Product / Repository / Bounded Context

<!-- Clearly identify which product implements this contract and which bounded context is involved. -->

- **Repository:** `<repository-name>`
- **Bounded Context:** <Bounded context name>
- **Responsibility:** <What this product delivers as part of the business intent.>

## APIs and Events (this product's responsibility)

<!-- List the APIs and events THIS product is responsible for implementing.
     Do not duplicate strategic information from the Global OBC — focus on this product's technical responsibility. -->

### APIs

| Endpoint | Method | Responsibility |
|---|---|---|
| `<path>` | `<HTTP method>` | <What this API does.> |

### Published Events

| Event | Topic | When |
|---|---|---|
| `<domain>.<action>` | `<topic-name>` | <Trigger condition.> |

### Consumed Events

| Event | Source | Purpose |
|---|---|---|
| `<domain>.<action>` | `<source-repository>` | <Why this product consumes this event.> |

## BDD / Acceptance Criteria

<!-- List the acceptance criteria at the product level — verifiable behaviors.
     Reference to the BDD Feature file when committed. -->

- [ ] <Acceptance criterion 1: verifiable expected behavior.>
- [ ] <Acceptance criterion 2: expected failure behavior.>

**BDD Feature:** `prodops/artifacts/business/bdd/<slug>.feature` *(when committed)*

## Observable Events

<!-- List all observable events this capability emits.
     Include success, failure, edge-case, and security events.
     Each event must have a canonical name, meaning, and required dimensions. -->

| Event | Meaning | Required dimensions |
|---|---|---|
| `<domain>.<success_action>` | <What this success event represents.> | `<field1>`, `<field2>`, `correlationId` |
| `<domain>.<failure_action>` | <What this failure event represents.> | `<field1>`, `reason`, `correlationId` |

## Reliability Rules

<!-- List the invariants the implementation cannot violate.
     Include idempotency, safe failure, audit, and isolation rules. -->

- <Idempotency rule: what happens on retries with the same key.>
- <Transient failure rule: what the system does when a provider fails.>
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

## Technical Dependencies

<!-- List technical dependencies: other services, infrastructure, external integrations. -->

| Dependency | Type | Criticality | Note |
|---|---|---|---|
| `<service-name>` | <Sync / Async / Infra> | <High / Medium / Low> | <Relevant note.> |

## Evidence

<!-- Filled in during and after Delivery.
     Record links to implementation and operation evidence. -->

- Release Trail: `prodops/artifacts/governance/trails/sessions/<date>-<session-id>.md`
- PR: *(link to the implementation PR)*
- Production metrics: *(link to observability dashboard)*
