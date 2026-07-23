# DDD — Domain-Driven Design na Payments API

Guia prático de DDD aplicado ao domínio de pagamentos.

## Índice

| Arquivo | Conteúdo |
|---------|----------|
| [ubiquitous-language.md](./ubiquitous-language.md) | Glossário canônico do domínio Payments |
| [bounded-context.md](./bounded-context.md) | Fronteiras do contexto, o que pertence aqui |
| [aggregates.md](./aggregates.md) | Invoice como aggregate root, invariantes |
| [entities-value-objects.md](./entities-value-objects.md) | Entidades e Value Objects com exemplos |
| [repositories.md](./repositories.md) | Repository como port de persistência |
| [domain-services.md](./domain-services.md) | Quando e como criar domain services |
| [domain-events.md](./domain-events.md) | Eventos de domínio e emissão com EventEmitter2 |
| [application-services.md](./application-services.md) | InvoiceService como orquestrador de use cases |
| [anti-patterns.md](./anti-patterns.md) | Padrões a evitar com exemplos do projeto |
| [examples.md](./examples.md) | Exemplos completos em TypeScript do projeto real |

---

## Quando aplicar DDD

**Aplicar quando:**
- O domínio tem ciclo de vida rico (Invoice: CREATED → OPEN → CONFIRMED/CANCELLED)
- Múltiplos contextos com linguagens distintas (Checkout, Payments, Fulfillment)
- Provedores externos com modelos diferentes precisam ser adaptados (Asaas, Itaú)
- Regras de negócio mudam frequentemente e precisam de isolamento

**Não aplicar quando:**
- CRUD simples sem regras de transição de estado
- Scripts de migração ou pipelines ETL
- Integrações pontuais sem lógica de negócio

---

## Mapa do domínio Payments

```
Application Layer
  InvoiceService            → orquestra casos de uso
                              (createInvoice, cancelInvoice, processProviderWebhook)

Domain Layer
  Invoice (aggregate root)  → identidade, status, transições válidas
  InvoiceRepository (port)  → interface de persistência sem DynamoDB

Infrastructure Layer
  InvoiceRepository (impl)  → DynamoDB via DynamoService
  AsaasService              → anti-corruption layer para o provedor Asaas
```

Leia `ubiquitous-language.md` se for novo no domínio.
Leia `anti-patterns.md` se estiver revisando código existente.
Leia `examples.md` se quiser ver código completo primeiro.
