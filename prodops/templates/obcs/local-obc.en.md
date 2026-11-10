# OBC - <Capability Name>

<!-- Rename this file to the capability slug: e.g. split-payment-api.md -->
<!-- Location: while Draft/Refining inside an Upstream experiment, keep it at
     prodops/artifacts/experiments/<NNN-slug>/obcs/<slug>.md.
     Move to prodops/artifacts/obcs/<slug>.md only when the OBC is Committed (move-to-downstream). -->
<!-- Full format definition: prodops/framework/obc.en.md -->
<!-- Owner: Product Manager + Tech Lead of the product -->
<!-- Sections marked "(required for Committed)" must be filled in before the OBC becomes Committed.
     Optional sections may be removed if they do not apply — never leave `<...>` placeholders in a Committed OBC. -->

## Metadata

<!-- Required for Committed. DS-ID and Iteration are filled in when the item enters the Iteration Plan. -->

| Field | Value |
|---|---|
| Owner | <Product Manager> + <Tech Lead> |
| DS-ID | <DS-NN> *(fill in when entering the Iteration Plan)* |
| Iteration | <vX.Y.Z> *(fill in when entering the Iteration Plan)* |
| Last updated | <YYYY-MM-DD> |

## Status

<!-- Declare exactly ONE state, with no extra text on the state line:
     Draft | Refining | Committed | In Delivery | Operational | Archived
     Where the item is tracked (e.g. Status `Entered` in prodops/artifacts/plans/iteration-plan.md)
     goes on the "Tracked in" line. Do not write "Downstream. Status ..." in place of the state. -->

**State:** Draft
**Tracked in:** <Product Tracking List | Icebox | Iteration Plan v0.0.0>

## Origin

<!-- Required for Committed. Upward traceability required by the framework.
     Local flow: fill in Business Signal, Business Intent and Product Tracking Item.
     Global flow (Intent coming from the Portfolio): also fill in the originating Global OBC. -->

| Link | Reference |
|---|---|
| Business Signal | `prodops/artifacts/business-signals/<BS-ID>.md` |
| Business Intent | `prodops/artifacts/business-intents/<PI-ID>.md` |
| Product Tracking Item | <link to the item in the tracking list> |
| Global OBC *(global flow only)* | <link to the Global OBC in the portfolio repository> |

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

## Scope

<!-- Required for Committed. Defines what this capability covers and what it does NOT cover,
     so scope does not grow without an explicit decision. -->

**In scope**

- <Behavior covered by this capability.>

**Out of scope**

- <Behavior explicitly not covered, with the capability or iteration that handles it, if any.>

## Business Rules

<!-- Required for Committed. Business rules the capability applies (not to be confused with Reliability Rules,
     which are technical reliability invariants). Each rule is prescriptive and testable. -->

- <Business rule: condition → expected behavior.>

## Acceptance Criteria

<!-- Required for Committed. Verifiable conditions for considering the capability delivered.
     Each criterion must have at least one scenario in the BDD Feature (prodops/artifacts/bdd/<slug>.feature). -->

- [ ] <Verifiable criterion.>

## Enterprise Context

<!-- Required for Committed. Organizational constraints and standards that apply. -->

| Item | Content |
|---|---|
| Value Stream / Product Service | <Value Stream or Service it belongs to> — Service Deck: `prodops/artifacts/product/context/service-decks/<slug>.md` |
| Stakeholders | <Who decides or is impacted, and the decision they make.> |
| Compliance | <PCI, LGPD, audit, or "not applicable".> |

## Observable Events

<!-- Required for Committed. List all observable events this capability emits.
     Include success, failure, idempotency, and edge-case events.

     NAMING RULE: business events follow `payments.<aggregate>.<fact>` (lowercase, snake_case, English) and the
     name in the "Event" column must be IDENTICAL to the one emitted in the code — single source:
     api/src/events/payments-events.ts. Catalog and rules: prodops/artifacts/architecture/domain-events.en.md.
     Do not invent contract names the code does not use, nor emit the same fact under two names.
     Observability keys (event_key) and external webhook types do not follow this convention.

     "Status" column: `Emitted` = already exists in the code; `Planned` = does not exist yet (it is part of the
     implementation scope and must not be treated as a current contract). Do not leave a `Planned` event in an
     Operational OBC.

     `correlationId` is always required. -->

| Event | Status | Meaning | Required dimensions |
|---|---|---|---|
| `<success_event_key>` | Emitted | <What this success event represents.> | `<field1>`, `<field2>`, `correlationId` |
| `<failure_event_key>` | Emitted | <What this failure event represents.> | `<field1>`, `reason`, `correlationId` |

## Initial SLIs

<!-- Required for Committed. List the initial service level indicators with measurable targets.
     Use 100% for absolute invariants; use percentages for reliability targets.
     The "Source" column says where the number comes from: a Datadog metric, an event above, or a query.
     These targets are reviewed and evolved during Operation. -->

| SLI | Initial target | Source |
|---|---|---|
| <Measurable behavior the system must guarantee.> | <100% or 99.x%> | <Datadog metric / `event_key` / query> |

## Reliability Rules

<!-- Required for Committed. List the invariants the implementation cannot violate.
     Must cover: idempotency, transient failure behavior, secret isolation, audit.
     Each rule is a prescriptive statement — not a suggestion. -->

- <Idempotency rule: what happens on retries with the same idempotency key.>
- <Transient failure rule: what the system does when an external provider fails.>
- <Isolation rule: validations that occur before calling external systems.>
- <Audit rule: what is recorded and what must never be exposed in logs or responses.>

## APIs

<!-- Optional. Include when the capability exposes endpoints. Omit for purely asynchronous capabilities.
     Check method, path and authentication in the matching controller under api/src. -->

| Method | Path | Authentication | Description |
|---|---|---|---|
| `<GET\|POST\|DELETE>` | `/<path>` | `X-Api-Token` \| none | <What the endpoint does.> |

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

## Risks

<!-- Required for Committed. Relevant risks of this capability and where they are handled.
     When there is financial movement, external integration, an SLO change, a high/critical risk, or a persistence/
     security change, the Reliability Plan must be up to date. -->

| Risk | Severity | Handling |
|---|---|---|
| <Risk description.> | <Low \| Medium \| High \| Critical> | <Mitigation or link to `prodops/artifacts/risks/risks.md`> |

## Dependencies

<!-- Required for Committed. What this capability needs in order to work. -->

| Type | Dependency | Note |
|---|---|---|
| OBC | `prodops/artifacts/obcs/<slug>.md` | <why it depends> |
| Internal service | <e.g. DynamoDB, SQS> | <criticality> |
| External service | <e.g. Asaas> | <relevant contract or limit> |

## Decisions

<!-- Record of decisions that shaped the contract (the diligence/capture skill requires date, decision,
     rationale and source). Append rows; do not rewrite earlier ones. -->

| Date | Decision | Rationale | Source |
|---|---|---|---|
| <YYYY-MM-DD> | <Decision made.> | <Why.> | <experiment.md / risks.md / trail> |

## Related Artifacts

<!-- List the artifacts related to this capability.
     BDD and Iteration Plan are required when the OBC is In Delivery or later.
     Related OBCs list capabilities that depend on or are depended upon by this one. -->

- BDD: `prodops/artifacts/bdd/<slug>.feature`
- Iteration Plan: `prodops/artifacts/plans/iteration-plan.md`
- Service Deck: `prodops/artifacts/product/context/service-decks/<slug>.md`
- Related OBCs: *(links to dependent or related capability OBCs)*
