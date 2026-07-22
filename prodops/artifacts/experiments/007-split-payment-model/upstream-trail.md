# Upstream Trail — EXP-007: Split Payment

## Identificação

| Campo | Conteúdo |
|---|---|
| Experimento | EXP-007 |
| Business Intent | `prodops/artifacts/business/intents/split-payment.md` |
| Responsável | Product Team |
| Data de início | 2026-07-03 |
| Data de encerramento | 2026-07-03 |
| Status | Concluído — aguarda decisão de produto |

---

## Sequência de exploração

### 2026-07-03 — Análise do modelo atual

**O que foi feito:**

Leitura do modelo de domínio atual da Payments API:
- `api/src/modules/invoices/types/invoice.types.ts`
- `api/src/modules/invoices/dto/create-invoice.dto.ts`
- `api/src/modules/invoices/dto/invoice-response.dto.ts`

**Descoberta:**

O modelo atual é estritamente 1:1:1 — 1 pedido : 1 invoice : 1 método de pagamento. O campo `billingType` em `InvoiceRecord` é um campo escalar (não uma lista). O campo `orderId` existe e é único por invoice — a relação inversa (orderId → múltiplas invoices) já é tecnicamente suportada pela infraestrutura DynamoDB, mas não tem semântica de composição.

---

### 2026-07-03 — Benchmark de mercado

**O que foi feito:**

Análise comparativa de como provedores e plataformas de pagamento lidam com composição de métodos.

| Solução | Modelo | Aprendizado |
|---|---|---|
| Stripe | Múltiplos `PaymentIntent` por `PaymentSession` | Cada intent tem lifecycle independente; Session agrega o estado |
| Adyen | Sub-intents dentro de `PaymentSession` | Suporte nativo a composição parcial |
| MercadoPago | Split entre vendedores (marketplace) | Não é split de métodos por comprador — fora do escopo |
| Asaas | Charges independentes | **Sem suporte nativo a composição** — requer orquestração pela Payments API |

**Descoberta:**

A Payments API precisa absorver a responsabilidade de orquestração da composição. O Asaas opera no nível de charges individuais. O padrão correto é análogo ao Stripe: múltiplas charges independentes agregadas por uma entidade de composição gerenciada pela Payments API.

---

### 2026-07-03 — Modelagem de alternativas de domínio

**Alternativas consideradas:**

**Opção A — Múltiplas invoices por pedido com nova entidade `PaymentComposition`**

```
OrderId → PaymentComposition → [Invoice(Pix), Invoice(Cartão)]
```

- Mudança aditiva ao modelo existente
- Adiciona `compositionId?` e `allocatedAmount?` ao `InvoiceRecord`
- Nova entidade `PaymentComposition` gerencia estado agregado
- Pagamentos simples continuam funcionando sem alteração

**Opção B — Campo `paymentMethods[]` na invoice principal**

```
OrderId → Invoice { paymentMethods: [Pix(100), Cartão(150)] }
```

- Requer mudança estrutural no `InvoiceRecord`
- Mistura semântica: uma invoice passaria a representar múltiplos charges
- Quebra o modelo de estado atual (qual status reflete o estado geral?)

**Opção C — Invoice "mestre" com invoices filhas**

```
OrderId → Invoice(mestre, COMPOSITE) → [Invoice(filho-Pix), Invoice(filho-Cartão)]
```

- Complexidade adicional sem ganho em relação à Opção A
- Dificulta queries — self-join na mesma tabela

**Decisão:** Opção A é a única que preserva a semântica atual, não quebra pagamentos simples e é extensível. Selecionada.

---

### 2026-07-03 — Event Storming do novo fluxo

**Novos eventos de domínio mapeados:**

```
[Cliente seleciona Pix + Cartão no Checkout]
  → ComposicaoDePagamentoCriada
  → InvoiceCriada (Pix, R$100)
  → InvoiceCriada (Cartão, R$150)

[QR Code Pix confirmado via webhook]
  → PagamentoParcialConfirmado (Pix, R$100)

[Cartão aprovado via webhook]
  → PagamentoParcialConfirmado (Cartão, R$150)
  → PagamentoCompostoConfirmado (total R$250)

[Alternativo: Cartão recusado]
  → PagamentoParcialFalhou (Cartão)
  [Política B: manter Pix confirmado, solicitar novo método]
  → Nova InvoiceCriada (Boleto, R$150)

[Alternativo: janela de pagamento expirou]
  → PagamentoCompostoExpirou

[Alternativo: cliente cancela]
  → ComposicaoCancelada
  → [estorno de métodos confirmados]
  → PagamentoCompostoFalhou
```

---

### 2026-07-03 — Análise de impactos arquiteturais

**Novo componente:** `PaymentCompositionService`
- Cria e persiste `PaymentComposition`
- Processa webhooks agregados
- Determina transição de `CompositionStatus`
- Decide ação segundo a política de falha configurada

**Novos endpoints:**
- `POST /v1/payment-compositions` — cria composição
- `GET /v1/payment-compositions/:id` — status agregado

**Mudança no `WebhookProcessor`:**
- Detecta se a invoice tem `compositionId`
- Se sim, delega ao `PaymentCompositionService` para aggregation
- Se não, fluxo atual inalterado

**DynamoDB:**
- Nova `CompositionsTable` ou GSI `orderId-index` na `PaymentsTable`
- Acesso por `compositionId` (PK) e por `orderId` (GSI)

---

### 2026-07-03 — OBC candidato

**Criado em:** `prodops/artifacts/obcs/payment-composition-draft.md`

**Outcome definido:** Cliente consegue concluir pedido usando 2 métodos de pagamento com confirmação agregada em até 5 minutos.

**SLIs/SLOs:**
- Criação de composição: p99 < 800ms
- Confirmação agregada após ambos os webhooks: < 5 min (SLO: 95%)
- Estorno total em caso de falha após confirmação parcial: < 30 segundos (SLO: 99%)

---

## Decisão de saída

**Status:** Upstream concluído — aguarda decisão de produto

**Pergunta em aberto:** Política de falha parcial (A: reverter tudo / B: manter confirmados / C: janela parcial)

**Recomendação:** Política B — manter métodos confirmados, solicitar nova tentativa para o método falho.

**Próximo passo:**
1. Product Team decide a política de falha
2. Criar BDD Feature: `prodops/artifacts/bdd/payment-composition.feature`
3. Atualizar Iteration Plan
4. Bootstrap → Hack

---

## Referências

- `prodops/journeys/discovery/experiments/007-split-payment-model/experiment.md`
- `prodops/artifacts/business/intents/split-payment.md`
- `prodops/artifacts/obcs/payment-composition-draft.md`
- `api/src/modules/invoices/types/invoice.types.ts`
