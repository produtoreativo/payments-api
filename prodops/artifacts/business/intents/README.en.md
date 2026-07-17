# Intents

> **Naming note:** This directory was originally called `business-intents/` and the concept was called "Business Intent". The current canonical naming is **Intent** with a declared **Origin Stream**. The current canonical path is `prodops/artifacts/business/intents/`. See [`framework/glossary.md`](../../../framework/glossary.md#intent).

An **Intent** represents an intention to generate value not yet committed to implementation. It is the single entry point of the ProdOps Framework for any change, regardless of its origin.

## What an Intent is

- An intention to generate value not yet committed
- Has exactly one Origin Stream: Business, Enterprise, Team, or Technology
- Can be: new Value Stream, opportunity, business problem, operational need, hypothesis, compliance requirement, process improvement, technical evolution
- No experiment, backlog, or delivery plan exists yet

## The four Origin Streams

| Origin Stream | Represents |
|---|---|
| **Business** | Market, customer, product — revenue, conversion, adoption, retention |
| **Enterprise** | Compliance, regulation, audit, partners, corporate governance |
| **Team** | Process, automations, productivity, onboarding, workflow |
| **Technology** | Platform, security, infrastructure, observability, reliability |

→ [Detailed definition of each Origin Stream](../framework/origin-streams.md)

## What happens after registration

The Intent enters Exploration. Continuous Assessment decides the next step:

```
Intent (with declared Origin Stream)
  ↓
Exploration (Discovery / Upstream)
  ↓
Observable Business Contract (OBC)
  ↓
Upstream (exploration) or Downstream (committed delivery)
```

→ [Full Framework flow](../framework/flow.md)

## How to register an Intent

Use the template at [`prodops/templates/business-intents/`](../../../templates/business-intents/).

## Active Intents

*(register here as intents are created)*

| Intent | Origin Stream | Status |
|---|---|---|
| [Split Payment — Multiple Payments at Checkout](./split-payment.md) | Business | In Exploration |
