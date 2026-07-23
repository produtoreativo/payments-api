# DDD — Domain-Driven Design in the Payments API

Practical DDD guide applied to the payments domain.

## Index

| File | Content |
|------|---------|
| [ubiquitous-language.md](./ubiquitous-language.md) | Canonical glossary for the Payments domain |
| [bounded-context.md](./bounded-context.md) | Context boundaries, what belongs here |
| [aggregates.md](./aggregates.md) | Invoice as aggregate root, invariants |
| [entities-value-objects.md](./entities-value-objects.md) | Entities and Value Objects with examples |
| [repositories.md](./repositories.md) | Repository as persistence port |
| [domain-services.md](./domain-services.md) | When and how to create domain services |
| [domain-events.md](./domain-events.md) | Domain events and emission with EventEmitter2 |
| [application-services.md](./application-services.md) | InvoiceService as use case orchestrator |
| [anti-patterns.md](./anti-patterns.md) | Patterns to avoid with project examples |
| [examples.md](./examples.md) | Complete TypeScript examples from the real project |

---

## When to apply DDD

**Apply when:**
- The domain has a rich lifecycle (Invoice: CREATED → OPEN → CONFIRMED/CANCELLED)
- Multiple contexts with distinct languages (Checkout, Payments, Fulfillment)
- External providers with different models need to be adapted (Asaas, Itaú)
- Business rules change frequently and require isolation

**Do not apply when:**
- Simple CRUD with no state transition rules
- Migration scripts or ETL pipelines
- One-off integrations with no business logic

---

## Payments domain map

```
Application Layer
  InvoiceService            → orchestrates use cases
                              (createInvoice, cancelInvoice, processProviderWebhook)

Domain Layer
  Invoice (aggregate root)  → identity, status, valid transitions
  InvoiceRepository (port)  → persistence interface without DynamoDB

Infrastructure Layer
  InvoiceRepository (impl)  → DynamoDB via DynamoService
  AsaasService              → anti-corruption layer for the Asaas provider
```

Read `ubiquitous-language.md` if you are new to the domain.
Read `anti-patterns.md` if you are reviewing existing code.
Read `examples.md` if you want to see complete code first.
