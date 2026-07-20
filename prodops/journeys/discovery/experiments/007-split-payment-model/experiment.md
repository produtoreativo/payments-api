# EXP-007 — Split Payment: Modelo de Composição de Pagamento

## Status

- [ ] Planned
- [ ] In Progress
- [x] Completed
- [ ] Cancelled

**Business Intent:** [`prodops/artifacts/business/intents/split-payment.md`](../../../../artifacts/business/intents/split-payment.md)

---

# Business Goal

Determinar o modelo viável para suportar múltiplos meios de pagamento em um único pedido, identificando: as combinações prioritárias, o modelo de domínio adequado, os eventos de negócio necessários, os impactos arquiteturais sobre a Payments API e a política de falha parcial que deve orientar o Downstream.

---

# Repository Scope Gate

## Escopo de responsabilidade deste repositório

- [x] Comportamento da Payments API
- [x] Lógica de domínio de Payments
- [x] Integração com provedor (Asaas)
- [x] Processamento de webhook
- [x] Persistência (DynamoDB)
- [x] Contrato de API/evento de propriedade do Payments

## Dependências externas

- **Checkout** — responsável por apresentar a composição de pagamento ao cliente e coletar os métodos
- **Order Management** — precisa reconhecer `PagamentoCompostoConfirmado` em vez de `PagamentoConfirmado` simples
- **Notification Service** — deve notificar por método confirmado e por composição completa
- **Product Team** — decisão sobre política de falha parcial (ver seção abaixo)

## Decisão de escopo

- [x] Prosseguir como experimento Upstream executável neste repositório
- [ ] Registrar apenas como dependência externa ou risco de release
- [ ] Redirecionar para repositório ou time responsável

---

# Questions to Answer

| # | Pergunta | Status |
|---|---|---|
| Q1 | Quais cenários de negócio justificam múltiplos pagamentos? | ✅ Respondida |
| Q2 | Quais combinações de meios de pagamento suportar inicialmente? | ✅ Respondida |
| Q3 | Existe limite máximo de pagamentos por pedido? | ✅ Respondida |
| Q4 | Como representar o saldo restante durante a composição? | ✅ Respondida |
| Q5 | Como tratar alteração ou remoção antes da confirmação? | ✅ Respondida |
| Q6 | Como tratar falhas parciais quando apenas um método é autorizado? | ⚠ Parcialmente — exige decisão de produto |
| Q7 | Como conciliar confirmações assíncronas de diferentes gateways? | ✅ Respondida |
| Q8 | Como preservar experiência simples para o usuário? | ✅ Respondida |
| Q9 | Quais impactos ao modelo de Order e Payment? | ✅ Respondida |
| Q10 | Quais eventos de negócio para observabilidade e auditoria? | ✅ Respondida |

---

# Hypothesis

> É possível suportar múltiplos meios de pagamento em um único pedido criando múltiplas invoices independentes no Asaas (uma por método), orquestradas por uma nova entidade `PaymentComposition` na Payments API, sem alterar a semântica das invoices existentes e sem depender de uma feature nativa do Asaas.

---

# Technical Findings

## Q1 — Cenários de negócio que justificam múltiplos pagamentos

| Cenário | Frequência estimada | Valor para o negócio |
|---|---|---|
| Limite de crédito insuficiente → complementar com Pix | Alta | Reduz abandono em pedidos de valor médio-alto |
| Saldo de gift card / cashback + método principal | Média | Aumenta uso de benefícios e fidelização |
| Pedido de alto valor — dois cartões do mesmo cliente | Média | Habilita ticket acima do limite individual de cartão |
| Boleto parcial + Pix para completar | Baixa | Dificulta reconciliação — não prioritário |

**Conclusão:** O cenário prioritário é **Pix + Cartão de Crédito**, seguido de **Gift Card/Cashback + método principal**. Boleto como método parcial deve ficar fora do MVP por complexidade de conciliação assíncrona.

---

## Q2 — Combinações suportadas inicialmente

| Combinação | Viabilidade | Prioridade |
|---|---|---|
| Pix + Cartão de Crédito | Alta — ambos têm confirmação definida | P0 — MVP |
| Gift Card / Cashback + qualquer método | Alta — gift card é interno, sem latência de gateway | P0 — MVP |
| Pix + Pix (dois QR Codes) | Baixa utilidade | P2 |
| Cartão + Cartão | Média — requer tokenização dos dois | P1 — pós-MVP |
| Boleto + qualquer método | Baixa — Boleto tem janela de confirmação longa e assíncrona | P2 — não recomendado no MVP |

**Decisão para MVP:** suportar até 2 métodos por pedido, sendo obrigatório que pelo menos um seja de confirmação imediata (Pix ou Cartão).

---

## Q3 — Limite máximo de pagamentos por pedido

**Recomendação: 2 métodos por pedido no MVP.**

Razão: cada método adicional multiplica os estados possíveis de falha parcial e a complexidade da política de reversão. A experiência de UX para 3+ métodos é substancialmente mais complexa sem ganho proporcional de conversão.

Limite pode ser elevado para 3 em uma iteração posterior se dados de uso justificarem.

---

## Q4 — Representação do saldo restante

O saldo restante é calculado dinamicamente:

```
remainingAmount = totalOrderAmount - sum(invoices.map(i => i.amount))
```

Não é persistido como campo — é derivado da composição. O `PaymentComposition.confirmedAmount` é persistido conforme webhooks chegam:

```
confirmedAmount += invoice.amount  (quando status → CONFIRMED)
```

O checkout exibe `remainingAmount` durante a escolha de métodos. O campo `allocatedAmount` de cada invoice define a parcela de responsabilidade de cada método.

---

## Q5 — Alteração ou remoção de método antes da confirmação

**Estados em que é possível remover um método:**
- `CREATED` — invoice não enviada ao provedor → deleção direta
- `PROVIDER_PENDING` → `OPEN` — invoice ativa no Asaas → cancelamento no provedor via `DELETE /v3/payments/{id}`

**Fluxo:**
1. Cliente solicita remover Método B
2. Payments API cancela a invoice de Método B (via Asaas se já `OPEN`)
3. Payments API recalcula `remainingAmount`
4. Cliente escolhe novo método → nova invoice criada

**Restrição:** Método em estado `CONFIRMED` não pode ser removido — apenas via cancelamento completo do pedido.

---

## Q6 — Tratamento de falhas parciais (decisão de produto pendente)

Este é o ponto de maior incerteza. Três políticas viáveis:

| Política | Comportamento | Prós | Contras |
|---|---|---|---|
| **A — Reverter tudo** | Se qualquer método falha, cancela todos os confirmados e estorna | Mais simples, sem estado parcial | Pior UX — cliente perde a parte já paga |
| **B — Manter confirmados, nova tentativa** | Invoice confirmada permanece; cliente escolhe novo método para a parte falha | Melhor UX | Complexidade no estorno se o pedido inteiro precisar ser cancelado depois |
| **C — Estado de pagamento parcial com janela** | Composição entra em `PARTIALLY_CONFIRMED`; cliente tem N minutos para completar ou cancelar | Máxima flexibilidade | Mais complexo de implementar; precisa de expiração |

**Recomendação deste experimento: Política B** — preserva métodos confirmados, permite nova tentativa para o método falho. É a mais comum em soluções de mercado (Stripe, Adyen) e a de melhor UX.

**⚠ Esta é uma decisão de produto — o Product Team precisa confirmar antes do Downstream.**

---

## Q7 — Conciliação assíncrona de diferentes gateways

**Descoberta técnica crítica:** O Asaas não tem um conceito nativo de "composição de pagamento". Cada charge é independente. A Payments API deve orquestrar a composição sobre charges independentes.

**Fluxo de conciliação:**

```
[Webhook Asaas — Charge A CONFIRMED]
  → WebhookProcessor identifica invoiceId
  → Busca PaymentComposition pelo invoiceId
  → Atualiza invoice A → CONFIRMED, confirmedAmount += A.amount
  → Verifica: allInvoicesConfirmed(composition)?
       SIM → emite PagamentoCompostoConfirmado, status → CONFIRMED
       NÃO → emite PagamentoParcialConfirmado, status → PARTIALLY_CONFIRMED

[Webhook Asaas — Charge B CONFIRMED]
  → Mesmo fluxo → allInvoicesConfirmed → true
  → emite PagamentoCompostoConfirmado
```

A chave de busca é: `compositionId` via `InvoiceRecord.compositionId` (novo campo) ou via GSI em DynamoDB por `orderId`.

**Idempotência:** o `WebhookProcessor` deve ser idempotente por `webhookId` — já garantido pelo modelo existente de processamento de webhook.

---

## Q8 — Preservação de experiência simples para o usuário

O modelo é complexo internamente mas deve ser transparente para o usuário:

```
Checkout exibe:
  "Total: R$ 250,00"
  [Método 1: Pix — R$ 100,00]  → QR Code gerado ✓
  [Método 2: Cartão — R$ 150,00] → Processando...
  [Aguardando confirmação de todos os pagamentos]
```

A API retorna um `paymentCompositionId` como referência principal para o Checkout rastrear o estado agregado, em vez de um `invoiceId` por método.

---

## Q9 — Impactos no modelo de Order e Payment

### InvoiceRecord — mudanças mínimas

```typescript
interface InvoiceRecord {
  // campos existentes mantidos
  compositionId?: string;   // novo: referência à composição (null em pagamentos simples)
  allocatedAmount?: number; // novo: valor alocado a este método na composição
}
```

O campo `orderId` continua existindo — a relação `orderId → [invoice1, invoice2]` já é tecnicamente suportada pelo modelo atual; o que muda é que ela passa a ter semântica de composição.

### Nova entidade: PaymentComposition

```typescript
interface PaymentComposition {
  compositionId: string;        // ULID
  orderId: string;
  tenantId: string;
  totalAmount: number;
  confirmedAmount: number;
  invoiceIds: string[];         // ordered list
  compositionStatus: CompositionStatus;
  failurePolicy: 'REVERT_ALL' | 'KEEP_CONFIRMED' | 'PARTIAL_WINDOW';
  partialWindowExpiresAt?: string; // para política C
  createdAt: string;
  updatedAt: string;
}

type CompositionStatus =
  | 'PENDING'
  | 'PARTIALLY_CONFIRMED'
  | 'CONFIRMED'
  | 'PARTIALLY_FAILED'
  | 'FAILED'
  | 'CANCELLED'
  | 'EXPIRED';
```

### Impacto em Order Management

O evento de liberação de pedido muda de:
- `PagamentoConfirmado` (invoice simples) → continua para pagamentos simples
- **`PagamentoCompostoConfirmado`** → novo evento para composições

Order Management precisa reconhecer ambos os contratos.

### Não há breaking change para pagamentos simples

Pagamentos com um único método continuam funcionando sem `compositionId`. A nova capability é aditiva.

---

## Q10 — Eventos de negócio para observabilidade e auditoria

| Evento | Produtor | Consumidores | Campos obrigatórios |
|---|---|---|---|
| `ComposicaoDePagamentoCriada` | Payments API | Checkout, Analytics | `compositionId`, `orderId`, `totalAmount`, `methods[]`, `tenantId` |
| `PagamentoParcialConfirmado` | Payments API | Checkout, Analytics | `compositionId`, `invoiceId`, `billingType`, `amount`, `confirmedAmount`, `remainingAmount` |
| `PagamentoCompostoConfirmado` | Payments API | Order Management, Notifications, Analytics | `compositionId`, `orderId`, `totalAmount`, `methods[]`, `confirmedAt` |
| `PagamentoParcialFalhou` | Payments API | Checkout, Atendimento | `compositionId`, `invoiceId`, `billingType`, `failureReason`, `policy` |
| `PagamentoCompostoFalhou` | Payments API | Order Management, Atendimento | `compositionId`, `orderId`, `failureReason`, `refundedAmount` |
| `PagamentoCompostoExpirou` | Payments API | Checkout, Atendimento | `compositionId`, `orderId`, `confirmedAmount`, `remainingAmount` |
| `ComposicaoCancelada` | Payments API | Order Management, Checkout | `compositionId`, `orderId`, `cancelledBy`, `refundedAmount` |

---

# Business Findings

## Benchmark de mercado

| Solução | Modelo adotado |
|---|---|
| **Stripe** | Múltiplos `PaymentIntent` independentes ligados a um `PaymentSession`; cada intent tem lifecycle próprio |
| **Adyen** | `Payment Sessions` com sub-intents; suporte nativo a composição parcial |
| **MercadoPago** | Foco em split entre vendedores (marketplace), não em múltiplos métodos por comprador |
| **Asaas** | Não tem conceito nativo de composição; cada charge é independente — **requer orquestração pela Payments API** |

**Conclusão:** A abordagem de orquestrar charges independentes no Asaas é o padrão correto dado que o Asaas não oferece composição nativa. A Payments API absorve a complexidade de orquestração, mantendo o Asaas como provedor de charges individuais.

## Valor de negócio validado

- Pedidos de valor médio-alto (acima de R$ 500) são os casos de maior impacto
- Combinação Pix + Cartão endereça o cenário mais comum de limite insuficiente
- A capability é mais valiosa após a adoção do cartão hospedado (EXP-003), pois sem cartão o segundo método seria sempre assíncrono (Boleto)

---

# Architecture Impact

## Novos componentes

| Componente | Tipo | Impacto |
|---|---|---|
| `PaymentCompositionRepository` | Service + DynamoDB | Nova tabela `CompositionsTable` ou GSI por `orderId` na `PaymentsTable` |
| `PaymentCompositionService` | Service | Orquestração: criação, agregação de webhooks, transição de status |
| `POST /v1/payment-compositions` | Controller | Novo endpoint — aceita `orderId`, `totalAmount`, `methods[]` |
| `GET /v1/payment-compositions/:id` | Controller | Status agregado da composição |
| `WebhookProcessor` | Mudança | Detecta `compositionId` na invoice → aciona `PaymentCompositionService` |
| `InvoiceRecord` | Mudança aditiva | Adiciona `compositionId?` e `allocatedAmount?` |

## Sem breaking change

Pagamentos simples continuam via `POST /v1/invoices`. Nenhum campo obrigatório é removido ou alterado.

## Complexidade estimada: Alta

- Nova tabela DynamoDB com padrão de acesso por `compositionId` e por `orderId`
- Novo state machine para `CompositionStatus` (7 estados)
- Webhook processor precisa de lógica de aggregation
- Testes de aceitação precisam simular múltiplos webhooks em sequência

---

# Artifacts Updated

- [x] Business Intent: `prodops/artifacts/business/intents/split-payment.md` — perguntas respondidas
- [x] Tracking List: `prodops/artifacts/product/tracking-list.md` — novos itens de produto
- [x] OBC candidato: `prodops/journeys/discovery/experiments/007-split-payment-model/obcs/payment-composition.md` — criado
- [ ] BDD Feature — aguarda decisão sobre política de falha parcial
- [ ] Event Storming — atualizar `prodops/journeys/assessment/event-storming/` com novos eventos

---

# Knowledge Gaps Closed

| Pergunta | Status | Evidência |
|---|---|---|
| Cenários de negócio | ✅ Respondida | Benchmark + análise de uso |
| Combinações prioritárias | ✅ Respondida | Pix + Cartão = P0 |
| Limite máximo | ✅ Respondida | 2 métodos no MVP |
| Saldo restante | ✅ Respondida | Cálculo derivado + `confirmedAmount` persistido |
| Alteração antes da confirmação | ✅ Respondida | Cancelamento de invoice + nova invoice |
| Falhas parciais | ⚠ Parcial | Política B recomendada, decisão de produto pendente |
| Conciliação assíncrona | ✅ Respondida | Multiple charges Asaas + aggregation na Payments API |
| Experiência simples | ✅ Respondida | `compositionId` como referência principal no Checkout |
| Impactos no modelo | ✅ Respondida | Mudança aditiva — sem breaking change |
| Eventos de negócio | ✅ Respondida | 7 novos eventos definidos |

---

# New Backlog Items

| Item | Classificação | Observação |
|---|---|---|
| Definir política de falha parcial (A, B ou C) | **Repository Tracking List — decisão de produto** | Bloqueante para Downstream |
| Validar com Order Management o contrato de `PagamentoCompostoConfirmado` | **Repository Tracking List** | Dependência externa |
| Definir estratégia de DynamoDB para CompositionsTable | **Candidato ao Iteration Backlog** | Depois da decisão de política |
| Criar BDD Feature para composição de pagamento | **Candidato ao Iteration Backlog** | Após política definida |
| Atualizar Event Storming com novos eventos | **Candidato ao Iteration Backlog** | Pode fazer agora |

---

# Recommendation

- [x] **Aguardar decisão de negócio** — política de falha parcial (Q6)

Após a decisão:

- [x] **Mover para Downstream** — o modelo está suficientemente definido para iniciar o ciclo Bootstrap → Hack

**Justificativa:**

Todas as perguntas técnicas e de domínio foram respondidas. O único bloqueio é a decisão de produto sobre a política de falha parcial (Política A, B ou C), que determina o estado machine e o contrato de `PagamentoParcialFalhou`. Recomenda-se Política B (manter confirmados, nova tentativa para o falho).

Com a política definida, o Downstream pode começar com:
1. OBC: `prodops/journeys/discovery/experiments/007-split-payment-model/obcs/payment-composition.md`
2. BDD Feature: a criar após definição da política
3. Entrada no Iteration Plan para a próxima iteração

---

# Decision Package

## Executive Summary

Split Payment é viável na arquitetura atual da Payments API usando múltiplas invoices independentes no Asaas orquestradas por uma nova entidade `PaymentComposition`. A mudança é **aditiva** — nenhum contrato existente é quebrado. A complexidade principal está na gestão de estado da composição e no processamento de webhooks agregados.

O MVP deve suportar 2 métodos por pedido, priorizando Pix + Cartão. A única decisão de produto pendente é a política de falha parcial.

## Decisão Recomendada

**Aprovar Downstream** após confirmação da política de falha parcial (recomendamos Política B).

## Riscos identificados

| Risco | Probabilidade | Impacto | Mitigação |
|---|---|---|---|
| Política B gera inconsistência se pedido for cancelado após confirmação parcial | Média | Alto | Definir contrato de cancelamento total que inclui estorno dos métodos confirmados |
| Asaas pode introduzir limites em charges simultâneas por orderId | Baixa | Médio | Validar no sandbox antes do Downstream |
| Order Management pode não estar pronto para reconhecer evento novo | Média | Alto | Alinhamento antecipado com squad de Orders |
| Webhook out-of-order (Charge B confirmado antes de A) | Baixa | Médio | State machine já garante idempotência — tratar no agregador |

## Oportunidades

- Habilita ticket médio mais alto sem atrito de UX
- Base para suporte a Gift Card / Cashback como método de pagamento parcial
- Modelo de `PaymentComposition` pode ser reutilizado para suporte a parcelamento cross-method no futuro

## OBC Candidato

→ `prodops/journeys/discovery/experiments/007-split-payment-model/obcs/payment-composition.md`

## Escopo Downstream Recomendado (após decisão de política)

1. `PaymentCompositionService` + `PaymentCompositionRepository`
2. `POST /v1/payment-compositions` + `GET /v1/payment-compositions/:id`
3. Webhook aggregation no `WebhookProcessor`
4. 7 novos eventos de domínio
5. BDD Feature com cenários: criação, confirmação total, confirmação parcial, falha parcial (Política B), expiração

---

# Output Artifacts

Lista os artefatos de produto gerados ou promovidos por este experimento.

## Artefatos gerados

| Tipo | Artefato | Situação |
|---|---|---|
| OBC draft | `prodops/journeys/discovery/experiments/007-split-payment-model/obcs/payment-composition.md` | Draft — aguarda decisão de produto |
| BDD Feature | `prodops/artifacts/business/bdd/payment-composition.feature` | A criar após política de falha parcial definida |
| Business Intent | `prodops/artifacts/business/intents/split-payment.md` | Criada — aguarda Downstream |

**Promovido para Downstream:** Não — aguarda decisão de produto sobre política de falha parcial.
**Recomendação:** Política B — manter métodos confirmados, solicitar nova tentativa para o método falho.

---

# Exit Criteria

- [x] Hipótese original respondida — composição via múltiplas invoices é viável
- [x] Perguntas classificadas — 9 respondidas, 1 aguarda decisão de produto
- [x] Lacunas de conhecimento documentadas — política de falha e alinhamento com Order Management
- [x] Impacto arquitetural documentado — novo componente, mudança aditiva no InvoiceRecord
- [x] Impacto em confiabilidade documentado — novos modos de falha, 4 riscos identificados
- [x] Artefatos atualizados — OBC candidato criado, tracking list atualizada
- [x] Recomendação produzida — Downstream após decisão de política
- [x] Decision Package completo

---

# Next Step

1. **Product Team confirma a política de falha parcial** (Política B recomendada)
2. Criar BDD Feature: `prodops/artifacts/bdd/payment-composition.feature`
3. Adicionar ao Iteration Plan
4. Bootstrap → Hack
