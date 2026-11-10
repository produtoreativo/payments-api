# Business Intents

> **Nota de nomenclatura:** A nomenclatura canônica é **Business Intent**. O path `prodops/artifacts/business-intents/` é preservado por compatibilidade. Ver [`framework/glossary.md`](../../framework/glossary.md#business-intent).

Uma **Business Intent** representa uma decisão estratégica de perseguir valor — nascida de um ou mais Business Signals. Não é um compromisso de implementação. um Business Signal pode gerar uma ou mais Business Intents (ou a Intent pode ser criada diretamente no BIB); a Business Intent possui um OBC como documento de contrato — o Global OBC co-nasce com a Intent; Local OBCs são criados por OBC Partitioning, um por produto.

## O que é uma Business Intent

- Uma decisão estratégica de perseguir valor, nascida de Business Signal(s)
- Tem exatamente um Origin Stream: Business, Enterprise, Team ou Technology
- Pode representar: novo Value Stream, oportunidade, problema de negócio, necessidade operacional, hipótese, requisito de compliance, melhoria de processo, evolução técnica
- Não é um compromisso de implementação — ainda não existe OBC committed, backlog ou plano de entrega

## Os quatro Origin Streams

| Origin Stream | Representa |
|---|---|
| **Business** | Mercado, cliente, produto — receita, conversão, adoção, retenção |
| **Enterprise** | Compliance, regulação, auditoria, parceiros, governança corporativa |
| **Team** | Processo, automações, produtividade, onboarding, fluxo de trabalho |
| **Technology** | Plataforma, segurança, infraestrutura, observabilidade, confiabilidade |

→ [Definição detalhada de cada Origin Stream](../../framework/origin-streams.md)

## O que acontece após o registro

A Business Intent entra em Exploration. O Continuous Assessment decide o próximo passo:

```
Business Signal (com Origin Stream declarado)
  ↓ (1:N, ou criado diretamente)
Business Intent (decisão estratégica)
  │  └─ OBC (documento de contrato — 4 dimensões: Business, Enterprise, Team, Technology)
  ↓
Exploration (Discovery / Upstream)
  ↓
Upstream (exploração) ou Downstream (entrega comprometida)
```

→ [Fluxo completo do Framework](../../framework/flow.md)

## Como registrar uma Business Intent

Utilize o template em [`prodops/templates/business-intents/`](../../templates/business-intents/).

## Business Intents ativas

*(registrar aqui à medida que Business Intents forem criadas)*

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
| [PI-017 — Cancelamento automático de boleto vencido com evento de expiração](./PI-017.md) | Business | Downstream — entregue em v0.15.0 (PR #177); OBC boleto-auto-cancellation |
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

> Os identificadores `PI-003` a `PI-017` (exceto os temáticos `PI-PILOT-*`, `PI-RT-*` e `PI-RUNTIME-*`) e `PI-PILOT-004` a `PI-PILOT-006` são **registros retroativos** criados em 2026-11-10 para ligar cada OBC e cada documento do piloto à sua origem. O Business Signal de cada Intent está na linha "Business Signal" do arquivo — arquivo `BS-*` em `prodops/artifacts/business-signals/` ou Issue do GitHub com o label `artifact-type:business-signal`.
