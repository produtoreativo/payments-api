# Business Intents

> **Naming note:** The canonical naming is **Business Intent**. The path `prodops/artifacts/business/intents/` is preserved for backward compatibility. See [`framework/glossary.en.md`](../../../framework/glossary.en.md#business-intent).

A **Business Intent** represents a strategic decision to pursue value — born from one or more Business Signals. It is not a commitment to implementation. Entities never change identity: a Business Signal **generates** a Business Intent; a Business Intent **generates** OBCs via OBC Partitioning.

## What a Business Intent is

- A strategic decision to pursue value, born from Business Signal(s)
- Has exactly one Origin Stream: Business, Enterprise, Team, or Technology
- Can represent: new Value Stream, opportunity, business problem, operational need, hypothesis, compliance requirement, process improvement, technical evolution
- Not a commitment to implementation — no OBC committed, backlog, or delivery plan exists yet

## The four Origin Streams

| Origin Stream | Represents |
|---|---|
| **Business** | Market, customer, product — revenue, conversion, adoption, retention |
| **Enterprise** | Compliance, regulation, audit, partners, corporate governance |
| **Team** | Process, automations, productivity, onboarding, workflow |
| **Technology** | Platform, security, infrastructure, observability, reliability |

→ [Detailed definition of each Origin Stream](../../../framework/origin-streams.md)

## What happens after registration

The Business Intent enters Exploration. Continuous Assessment decides the next step:

```
Business Signal (with Origin Stream declared)
  ↓ (1:N, or created directly)
Business Intent (strategic decision)
  │  └─ OBC (contract document — 4 dimensions: Business, Enterprise, Team, Technology)
  ↓
Exploration (Discovery / Upstream)
  ↓
Upstream (exploration) or Downstream (committed delivery)
```

→ [Full Framework flow](../../../framework/flow.md)

## How to register a Business Intent

Use the template at [`prodops/templates/business-intents/`](../../../templates/business-intents/).

## Active Business Intents

*(register here as Business Intents are created)*

| Business Intent | Origin Stream | Status |
|---|---|---|
| [Split Payment — Multiple Payments at Checkout](./split-payment.md) | Business | In Exploration |
