# Business Intents

> **Naming note:** The canonical naming is **Business Intent**. The path `prodops/artifacts/business-intents/` is preserved for backward compatibility. See [`framework/glossary.en.md`](../../framework/glossary.en.md#business-intent).

A **Business Intent** represents a strategic decision to pursue value — born from one or more Business Signals. It is not a commitment to implementation. a Business Signal can generate one or more Business Intents (or the Intent can be created directly in the BIB); a Business Intent has an OBC as its contract document — the Global OBC is co-born with the Intent; Local OBCs are created by OBC Partitioning, one per product.

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

→ [Detailed definition of each Origin Stream](../../framework/origin-streams.md)

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

→ [Full Framework flow](../../framework/flow.md)

## How to register a Business Intent

Use the template at [`prodops/templates/business-intents/`](../../templates/business-intents/).

## Active Business Intents

*(register here as Business Intents are created)*

| Business Intent | Origin Stream | Status |
|---|---|---|
| [PI-001 — Split Payment — Pix + Boleto em uma mesma compra](./PI-001.md) | Business | Downstream Ready — Entrou no Iteration Plan v0.14.0 em 2026-08-05 |
| [PI-002 — Pagamento via PayPal — integração com parceiro](./PI-002.md) | Business | Registrado — aguardando OBC |
| [PI-003 — Criar invoice via Pix no gateway Payments](./PI-003.md) | Business | Downstream — entregue em v0.4.0 (PR #89); OBC create-invoice |
| [PI-004 — Criar invoice via Boleto Bancário no gateway Payments](./PI-004.md) | Business | Downstream — entregue em v0.2.0 (PR #87); OBC create-invoice-boleto |
| [PI-005 — Confirmar pagamento por webhook do provedor](./PI-005.md) | Business | Downstream — entregue em v0.5.0 (retrabalho em v0.6.0) (PR #100); OBC payment-confirmation |
| [PI-006 — Cancelar invoice pendente com idempotência](./PI-006.md) | Business | Downstream — entregue em v0.10.0 (PR #125); OBC cancel-invoice |
| [PI-007 — Garantir acesso autenticado por token de API](./PI-007.md) | Technology (inferido) | Downstream — entregue em v0.5.0 (retrabalho em v0.6.0) (PR #102); OBC api-token-validation |
| [PI-008 — Configurar webhook de notificação por token de API](./PI-008.md) | Business | Downstream — entregue em v0.5.0 (retrabalho em v0.6.0) (PR #103); OBC webhook-configura… |
| [PI-009 — Aceitar pagamento com cartão de crédito hospedado](./PI-009.md) | Business | Downstream — entregue em v0.5.0 (retrabalho em v0.6.0) (PR #104); OBC credit-card-autho… |
| [PI-010 — Instrumentar a Payments API com Datadog em produção](./PI-010.md) | Technology | Downstream — entregue em v0.9.0 (PR #122 e PR #123); OBC observability-datadog |
| [PI-011 — Otimizar a persistência DynamoDB para produção](./PI-011.md) | Technology | Downstream — entregue em v0.9.0 (PR #121); OBC dynamodb-optimization |
| [PI-012 — Pipeline CI/CD para produção com gate de aprovação humana](./PI-012.md) | Technology | Downstream — entregue em v0.9.0 (PR #120); OBC production-cicd-pipeline |
| [PI-013 — Eliminar vulnerabilidades Dependabot das dependências do serviço](./PI-013.md) | Technology | Downstream — entregue em v0.7.0 (PR #116); OBC dependency-security-update |
| [PI-014 — Resolver a vulnerabilidade HIGH do postcss em validation-workbench](./PI-014.md) | Technology | Downstream — entregue em v0.10.0 (PR #126); OBC postcss-security |
| [PI-015 — Mecanismo de distribuição do ProdOps Framework](./PI-015.md) | Technology | Downstream — entregue em v0.11.0 (PR #136 · #137 · #138 · #139); OBC prodops-framework-… |
| [PI-016 — Rastrear o ciclo de vida de chargeback do Asaas](./PI-016.md) | Business | Downstream — entregue em v0.15.0 (PR #176); OBC chargeback-handling |
| [PI-017 — Cancelamento automático de boleto vencido, com evento e webhook ao consumidor](./PI-017.md) | Business | Em revisão — o comportamento de expiração foi entregue em v0.15.0 (PR #177); o contrato… |
| [PI-PILOT-001 — Invoice PIX — Happy Path Completo](./PI-PILOT-001.md) | Team · Technology | Em Discovery |
| [PI-PILOT-002 — Invoice Cartão — Happy Path sem Armazenar PAN](./PI-PILOT-002.md) | Team · Technology | Em Discovery |
| [PI-PILOT-003 — Confirmação de Pagamento — Happy Path via Webhook](./PI-PILOT-003.md) | Team · Technology | Em Discovery |
| [PI-PILOT-004 — Split Payment — Conflito no Sync](./PI-PILOT-004.md) | Team · Technology | Em Discovery |
| [PI-PILOT-005 — Split Payment Reversal — Rework](./PI-PILOT-005.md) | Team · Technology | Em Discovery |
| [PI-PILOT-006 — Split Payment Settlement — Blocking e Lookback](./PI-PILOT-006.md) | Team · Technology | Em Discovery |
| [PI-RT-001 — Event Pipeline Completeness — Bootstrap intermediários e sync de oem-state](./PI-RT-001.md) | Technology | Promovido para Product Backlog — 2026-08-04 |
| [PI-RT-002 — Continuous Operational Trail — trail contínuo por phase durante execução](./PI-RT-002.md) | Technology | Promovido para Product Backlog — 2026-08-04 |
| [PI-RT-003 — Dashboard Evolution — cycle time, iteration filter e labels](./PI-RT-003.md) | Technology | Promovido para Product Backlog — 2026-08-04 |
| [PI-RT-004 — Iteration Lifecycle Automation — auto-close e assignees](./PI-RT-004.md) | Technology | Promovido para Product Backlog — 2026-08-04 |
| [PI-RUNTIME-001 — Validate the ProdOps Operational Runtime on payments-api](./PI-RUNTIME-001.md) | Team · Technology | Em Exploration |

> Identifiers `PI-003` to `PI-017` (except the thematic `PI-PILOT-*`, `PI-RT-*` and `PI-RUNTIME-*`) and `PI-PILOT-004` to `PI-PILOT-006` are **retroactive records** created on 2026-11-10 to link each OBC and pilot document to its origin. Titles and statuses are in the language of each source file.
