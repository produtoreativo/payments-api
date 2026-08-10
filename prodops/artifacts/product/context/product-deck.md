# Product Deck — Payments

> Artefato vivo. Atualizar em cada mudança de serviço, arquitetura, time ou SLO.
> Última atualização: 2026-08-10

---

## 1. Product Vision

Para **merchants e sistemas integradores da Magazine Siará**
que **precisam cobrar clientes com confiabilidade, rastreabilidade e flexibilidade de meios de pagamento**,
o **Payments API**
é uma **camada de pagamentos como System of Record**
que **autoriza, confirma e publica cada transação como eventos de domínio auditáveis, desacoplando consumidores dos contratos do PSP e suportando múltiplos meios (Pix, Boleto, Cartão, Split Payment)**.

Diferente de **acessar o provedor Asaas diretamente**,
nosso produto **centraliza o estado operacional de pagamentos sob os identificadores internos do Magazine Siará, garante idempotência por chave de pedido, mantém o histórico de transições e protege conversão com observabilidade nativa desde a tentativa até a confirmação**.

---

## 2. Product Services

Cada entrada é um Product Service com Service Deck associado. O número de confiabilidade vem do Local OBC; o lead-time, do Release Trail.

| Service / Value Stream | Tipo | Resultado de negócio | Confiabilidade | Lead-time | Service Deck | OBCs |
|---|---|---|---|---|---|---|
| **Compra com Pix** | Value Stream | Pix gerado, pago, confirmado e pedido liberado | `[apurar]` | `[apurar]` | [compra-com-pix.md](service-decks/compra-com-pix.md) | create-invoice · payment-confirmation |
| **Compra com Boleto** | Value Stream | Boleto gerado com linha digitável, confirmado via webhook do provedor | `[apurar]` | `[apurar]` | [compra-com-boleto.md](service-decks/compra-com-boleto.md) | create-invoice-boleto · payment-confirmation |
| **Compra com Cartão de Crédito** | Value Stream | Cartão autorizado via hosted flow, confirmado e pedido liberado; suporte a refund | `[apurar]` | `[apurar]` | [compra-com-cartao-de-credito.md](service-decks/compra-com-cartao-de-credito.md) | credit-card-authorization-confirmation |
| **Split Payment Pix + Boleto** | Value Stream | Compra dividida entre Pix e Boleto; pedido liberado apenas com ambos confirmados | `[apurar]` | `[apurar]` | [split-payment-pix-boleto.md](service-decks/split-payment-pix-boleto.md) | split-payment-pix-boleto |
| **Cancelamento de Invoice** | Service | Invoice pendente inativada sem valor processado após o cancelamento | `[apurar]` | `[apurar]` | [cancelamento-de-invoice.md](service-decks/cancelamento-de-invoice.md) | cancel-invoice |
| **Autenticação via API Token** | Service | Somente tenants autorizados acessam a API; acesso rastreável por tenant e token | `[apurar]` | `[apurar]` | [autenticacao-api-token.md](service-decks/autenticacao-api-token.md) | api-token-validation |
| **Configuração e Entrega de Webhook** | Service | Consumidor registra endpoint e recebe eventos de pagamento com assinatura verificável | `[apurar]` | `[apurar]` | [configuracao-e-entrega-de-webhook.md](service-decks/configuracao-e-entrega-de-webhook.md) | webhook-configuration |

> Um serviço sem Local OBC committed não aparece como Product Service — é sinalizado como pendente de contrato observável.

---

## 3. Product Team

### Core Team — responsabilidade direta sobre OBCs, BDD Features e Reliability Plan

| Papel | Nome / time | Canal | Horário | Tempo de resposta (incidente) |
|---|---|---|---|---|
| Product Manager | Eugenio (PM) | `[link]` | Comercial | < 30 min (SEV1) |
| Tech Lead | `[Tech Lead Payments]` | `[link]` | Comercial | < 15 min (SEV1) |
| Engenharia Payments | `[Squad Payments]` | `[link]` | Comercial | < 15 min (SEV1) |
| Plataforma / SRE | `[SRE/Platform]` | `[link]` | 24/7 on-call | < 5 min (pager) |

### Decision Participants — governança de roadmap e operação

| Papel | Nome / time | Decisão |
|---|---|---|
| Checkout | `[Squad Checkout]` | Priorização de UX e integração no fluxo de compra |
| Order Management | `[Squad Orders]` | Liberação de pedido e consistência pós-confirmação |
| Financeiro / Conciliação | `[Finance Ops]` | Regras de conciliação, chargeback e custo por transação |
| Atendimento / CX | `[CX/Atendimento]` | Procedimentos de suporte e feedback de clientes impactados |
| Segurança / Antifraude | `[Squad Antifraude]` | Políticas de aprovação, bloqueio e análise de risco |

---

## 4. Product Execution Architecture

> Diagrama completo: [`prodops/artifacts/architecture/overview.md`](../../architecture/overview.md) — atualizar a cada mudança estrutural.

```
Checkout / Sistemas integradores
    │ X-Api-Token
    ▼
Lambda Function URL  (AWS — AuthType: NONE · CORS *)
    │
    ├── ApiTokenGuard  (header: X-Api-Token · TenantsTable)
    │
    ├── InvoiceController        POST/GET/DELETE /invoices · POST /invoices/:id/refund
    ├── SplitPaymentController   POST /split-payments · GET /split-payments/:id
    ├── WebhookConfigController  POST/GET/DELETE /webhooks
    ├── AsaasWebhookController   POST /webhook/payments   ← evento Asaas (PSP)
    ├── SplitPaymentWebhookCtrl  POST /webhooks/split-payment/{pix,boleto}/:id
    ├── AdminTokenController     POST/GET/DELETE /admin/tokens
    └── HealthController         GET /health  (sem guard)
         │
         ▼
    InvoiceService / SplitPaymentService / WebhookService
         │                      │
         ├─ DynamoDB ────────────┤  PaymentsTable · TransactionsTable
         │  (PAY_PER_REQUEST     │  CustomersTable · TenantsTable
         │   PITR)               │  WebhooksTable
         │
         ├─ Asaas (PSP externo)  POST /v3/payments · POST /v3/customers
         │
         ├─ EventEmitter2 ───────► WebhookDeliveryService → HTTPS POST (Consumer)
         │  payment.confirmed              X-Payments-Signature
         │  payment.cancelled             X-Payments-Delivery-Id
         │  split_payment.*
         │
         └─ ObservabilityListener → Datadog APM / Métricas / Logs
                                    DD_SERVICE: payments-api

Worker Lambda  {env}-payments-webhook-worker  (SQS trigger · BatchSize 5)
    SQS  {env}-payments-webhook-queue  (async mode)
    DLQ  {env}-payments-webhook-dlq    (maxReceiveCount: 5 · retenção: 14d)

Observabilidade: Datadog Extension Layer (arn:…:Datadog-Extension:97)
Logs: CloudWatch /aws/lambda/{env}-payments-api  (retenção 30d)
```

| Componente | Tipo | Criticidade | Dono |
|---|---|---|---|
| Lambda Function URL + API Lambda | Entry + Orquestrador | Crítica | Payments |
| PaymentsTable (DynamoDB) | State store — invoices / transactions / customers / tenants | Crítica | Payments |
| WebhooksTable (DynamoDB) | State store — webhook configs e entregas | Alta | Payments |
| SQS webhook-queue + DLQ | Buffer para processamento async de webhooks do PSP | Alta | Payments |
| Worker Lambda | Processador async de eventos do PSP | Alta | Payments |
| Asaas (PSP externo) | Execução de cobranças Pix, Boleto, Cartão | Crítica | Financeiro / Payments |
| Datadog APM | Traces, métricas, alertas | Crítica | Plataforma / SRE |
| Checkout (consumidor) | Origem das solicitações de pagamento | Crítica | Checkout |
| Order Management (consumidor) | Liberação de pedido após `payment.confirmed` | Crítica | Orders |

---

## 5. Reliability Matrix

| Value Stream / Nó | Dependência | Falha possível | Impacto no cliente | Sinal de detecção | Acionamento |
|---|---|---|---|---|---|
| Compra com Pix | Asaas (PSP) | QR Code não gerado (timeout / erro) | Cliente não inicia pagamento; queda de conversão | Taxa de erro `invoice.creation_failed`; latência p95 > 3s | Payments + SRE |
| Compra com Pix | Asaas webhook | Pagamento Pix pago sem evento de confirmação | Pedido fica parado; chamados de atendimento | `payment.confirmed` ausente > N min após liquidação | Payments + Financeiro |
| Compra com Boleto | Asaas (PSP) | Boleto não gerado | Cliente sem cobrança para pagar | Taxa de erro em `create-invoice-boleto` | Payments + SRE |
| Compra com Cartão | Asaas hosted flow | Redirecionamento falha ou retorno ignorado | Autorização perdida; cliente sem feedback | Aumento de timeout em `hostedPaymentUrl`; erro em refund | Payments |
| Split Payment | Asaas (PSP) | Pix confirmado, Boleto vencido sem resolução | Pedido em limbo; operação manual necessária | `split_payment.boleto.expired` sem ação de operação | Payments + Operação |
| Entrega de webhook | Consumer endpoint | HTTPS POST falha; DLQ crescente | Consumidor perde eventos de `payment.confirmed` | DLQ lag crescente; erro de entrega em Datadog | Payments + Plataforma |
| Autenticação | TenantsTable (DynamoDB) | Tabela indisponível | Toda a API inacessível | 5xx generalizado + Datadog trace errors | SRE + Payments |
| Worker Lambda | SQS / DynamoDB | Worker parado; fila crescendo | Modo async degradado; webhooks do PSP não processados | SQS ApproximateNumberOfMessagesNotVisible ↑ | SRE + Payments |

---

## 6. Product Analytics

### Negócio — o produto está entregando valor?

| Indicador | Pergunta que responde | Fonte | Cadência |
|---|---|---|---|
| Taxa de conversão de tentativas de pagamento (sucesso / recusa conhecida / erro tratado) | Clientes conseguem pagar? | Payments events + Datadog | Tempo real |
| Compras com Pix confirmadas dentro do SLO (< 30s) | Conversão Pix está protegida? | OBC `payment-confirmation` | Tempo real |
| Volume de Split Payment completados vs. iniciados | Novo meio de pagamento está sendo adotado? | OBC `split-payment-pix-boleto` | Diária |
| Boletos vencidos sem confirmação de Split | Operação manual está sendo gerada? | OBC `split-payment-pix-boleto` | Diária |

### Confiabilidade — o produto está saudável?

| Indicador | Meta atual (SLO) | Fonte | Cadência |
|---|---|---|---|
| % de invoices Pix criadas com sucesso | 99,5% em até 3s | OBC `create-invoice` | Tempo real |
| % de pagamentos confirmados refletidos em Orders | 99% em até 30s | OBC `payment-confirmation` | Tempo real |
| % de webhooks entregues ao consumidor | 99% | OBC pendente | Tempo real |
| p95 de criação de invoice (qualquer billing type) | < 3s | Datadog APM | Tempo real |
| DLQ depth (`payments-webhook-dlq`) | 0 mensagens | CloudWatch | Tempo real |

### Delivery (DORA) — o time está evoluindo?

| Métrica | Status | Fonte |
|---|---|---|
| Lead Time for Change | `[apurar — Release Trail]` | Release Trail → pipeline |
| Release Frequency | `[apurar]` | Deploy events |
| Change Fail Rate | `[apurar]` | Pipeline + rollback events |
| Mean Time to Recovery | `[apurar — incidentes]` | Incident tool |

> Estágio atual: **MVP → IPR** · Perfil DORA: `balanced`
> Assessment de maturidade: executar no Certificare com perfil `balanced`.
> Referência: [`prodops/framework/dora-metrics.md`](../../../framework/dora-metrics.md)

---

## 7. Stakeholders

| Stakeholder | Interesse no produto | Decisão que toma | Canal |
|---|---|---|---|
| Área de Negócios / Magazine Siará | Conversão, GMV, prazo de lançamento com parceiros | Prioridade de escopo e prazo (ex.: Split Payment em 15 dias) | `[link]` |
| Produto Checkout | Experiência de pagamento no fluxo de compra | Priorização de UX, API contract com Payments | `[link]` |
| Produto Order Management | Consistência pedido ↔ pagamento | Contratos de evento `payment.confirmed` e liberação de pedido | `[link]` |
| Financeiro / Conciliação | Custo por transação, chargeback, conciliação com Asaas | Regras financeiras, limites de Split, política de cancelamento | `[link]` |
| Atendimento / CX | Redução de chamados; status confiável por paymentId / orderId | Procedimentos de suporte; acesso a ferramentas de consulta | `[link]` |
| Plataforma / SRE | Operabilidade, SLOs, on-call e incidentes | Padrões de observabilidade, alertas e runbooks | `[link]` |
| Segurança / Antifraude | Risco de fraude, chargeback, compliance PCI | Políticas de aprovação/bloqueio; requisitos de autenticação | `[link]` |

---

## Artefatos relacionados

| Artefato | Localização |
|---|---|
| Architecture Overview | [`prodops/artifacts/architecture/overview.md`](../../architecture/overview.md) |
| Service Deck — Compra com Pix | [`prodops/artifacts/product/context/service-decks/compra-com-pix.md`](service-decks/compra-com-pix.md) |
| OBCs committed | [`prodops/artifacts/obcs/`](../../obcs/) |
| Release Trail | [`prodops/artifacts/trails/release-trail.md`](../../trails/release-trail.md) |
| Iteration Plan atual | [`prodops/artifacts/plans/iteration-plan.md`](../../plans/iteration-plan.md) |
| Risks | [`prodops/artifacts/risks/risks.md`](../../risks/risks.md) |
| Business Signals | [`prodops/artifacts/business-signals/`](../../business-signals/) |
| Business Intents | [`prodops/artifacts/business-intents/`](../../business-intents/) |

---

## Próximos artefatos recomendados

- Service Deck — Compra com Boleto
- Service Deck — Compra com Cartão de Crédito
- Service Deck — Split Payment Pix + Boleto
- OBC — Configuração e Entrega de Webhook
- Runbook — Split Payment: Boleto expirado sem resolução
- Runbook — Pix pago sem confirmação
- Apurar número de confiabilidade real (SLI) para cada Value Stream (fonte: Datadog)
- Apurar lead-time real por serviço (fonte: Release Trail → pipeline)
